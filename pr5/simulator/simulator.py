"""Симулятор контейнерів твердих побутових відходів (ПР5, варіант 4).

Кожен контейнер — окремий MQTT-клієнт. Кожні INTERVAL секунд
публікується відстань d від датчика до відходів у тему
kharkiv/waste/<id>/telemetry, а стан online/offline — у status.
"""

import argparse
import json
import random
import time
from datetime import datetime

import paho.mqtt.client as mqtt

# ---------- Параметри мережі ----------
H = 120.0  # висота контейнера, см

BINS = [
    {"id": "bin-01", "name": "Центр",       "fill0": 42.0, "rate": 10.0},
    {"id": "bin-02", "name": "Вокзал",      "fill0": 68.0, "rate": 14.0},
    {"id": "bin-03", "name": "Ринок",       "fill0": 76.0, "rate": 30.0},
    {"id": "bin-04", "name": "Університет", "fill0": 35.0, "rate": 8.0},
    {"id": "bin-05", "name": "Парк",        "fill0": 55.0, "rate": 12.0},
]

PREFIX = "kharkiv/waste"
INTERVAL = 5
PHI = 0.8
SIGMA = 0.35
GLITCH_P = 0.02

# ---------- Сценарій подій ----------
CYCLE = 600
COLLECTION = ("bin-02", 240, 300)   # вивезення: заповнення падає до 5 %
OUTAGE = ("bin-05", 360, 480)       # знеструмлення на 2 хв


class Bin:
    def __init__(self, cfg, host, port):
        self.id = cfg["id"]
        self.name = cfg["name"]
        self.rate = cfg["rate"]
        self.x = cfg["fill0"]
        self.mu = cfg["fill0"]
        self.collecting = False
        self.online = False
        self.host, self.port = host, port

        self.c = mqtt.Client(
            mqtt.CallbackAPIVersion.VERSION2,
            client_id=f"sim-{self.id}"
        )

        self.c.will_set(
            self.topic("status"),
            "offline",
            qos=1,
            retain=True
        )
        self.c.on_connect = self.on_connect

    def topic(self, kind):
        return f"{PREFIX}/{self.id}/{kind}"

    def on_connect(self, client, userdata, flags, rc, props):
        client.publish(
            self.topic("status"),
            "online",
            qos=1,
            retain=True
        )

    def start(self):
        self.c.connect(self.host, self.port, keepalive=10)
        self.c.loop_start()
        self.online = True

    def power_cut(self):
        self.c.loop_stop()
        self.online = False

    def power_on(self):
        self.c.reconnect()
        self.c.loop_start()
        self.online = True

    def stop(self):
        self.c.publish(
            self.topic("status"),
            "offline",
            qos=1,
            retain=True
        ).wait_for_publish(2)
        self.c.disconnect()
        self.c.loop_stop()

    def collect(self):
        self.x = 5.0
        self.mu = 5.0

    def measure(self):
        prev_mu = self.mu
        self.mu = min(
            98.0,
            self.mu + self.rate * INTERVAL / 3600.0
        )

        eps = random.gauss(0, 1)

        x = (
            self.mu
            + PHI * (self.x - prev_mu)
            + SIGMA * eps
        )

        self.x = min(99.0, max(1.0, x))

        # F = (H - d) / H * 100
        d = H * (1.0 - self.x / 100.0)

        if random.random() < GLITCH_P:
            d = random.choice([-1.0, 9999.0])

        return {
            "ts": int(time.time() * 1000),
            "d": round(d, 1),
            "h": H
        }


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--host", default="localhost")
    ap.add_argument("--port", type=int, default=1883)
    ap.add_argument("--seed", type=int, default=None)

    args = ap.parse_args()
    random.seed(args.seed)

    bins = [Bin(b, args.host, args.port) for b in BINS]

    for b in bins:
        b.start()

    print(
        f"Підключено до {args.host}:{args.port}. "
        "Ctrl+C — зупинити."
    )

    t0 = time.monotonic()

    try:
        while True:
            phase = (time.monotonic() - t0) % CYCLE
            now = datetime.now()

            for b in bins:

                cut = (
                    b.id == OUTAGE[0]
                    and OUTAGE[1] <= phase < OUTAGE[2]
                )

                if cut and b.online:
                    b.power_cut()
                    print(
                        f"{now:%H:%M:%S} {b.id} ЗНЕСТРУМЛЕНО"
                    )

                elif not cut and not b.online:
                    b.power_on()
                    print(
                        f"{now:%H:%M:%S} {b.id} "
                        "живлення відновлено"
                    )

                if not b.online:
                    continue

                collecting_now = (
                    b.id == COLLECTION[0]
                    and COLLECTION[1] <= phase < COLLECTION[2]
                )

                if collecting_now and not b.collecting:
                    b.collect()
                    b.collecting = True
                    print(
                        f"{now:%H:%M:%S} {b.id} "
                        "ВИВЕЗЕННЯ: F -> 5%"
                    )

                elif not collecting_now:
                    b.collecting = False

                m = b.measure()

                b.c.publish(
                    b.topic("telemetry"),
                    json.dumps(m),
                    qos=1
                )

                if 0 <= m["d"] <= 150:
                    fill = (H - m["d"]) / H * 100

                    print(
                        f"{now:%H:%M:%S} {b.id} "
                        f"d={m['d']:>6} см  "
                        f"F≈{fill:>5.1f}%"
                    )
                else:
                    print(
                        f"{now:%H:%M:%S} {b.id} "
                        f"d={m['d']:>6} см  ЗБІЙ СЕНСОРА"
                    )

            time.sleep(INTERVAL)

    except KeyboardInterrupt:
        print("Зупинка…")

    finally:
        for b in bins:
            if b.online:
                b.stop()


if __name__ == "__main__":
    main()