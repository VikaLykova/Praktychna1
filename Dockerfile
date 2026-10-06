
# Етап 1: встановлення залежностей
FROM python:3.12-slim AS builder

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# Етап 2: фінальний образ
FROM python:3.12-slim

WORKDIR /app

COPY --from=builder /install /usr/local
COPY . .

CMD ["python", "-m", "pytest", "test_number_theory.py", "-v"]