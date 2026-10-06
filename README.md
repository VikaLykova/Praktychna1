# Практична робота №1. Варіант 5

[![CI](https://github.com/VikaLykova/number_theory/actions/workflows/ci.yml/badge.svg)](https://github.com/VikaLykova/number_theory/actions/workflows/ci.yml)
[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python&logoColor=white)](https://img.shields.io/badge/Python-3.11-blue?logo=python&logoColor=white)

Модуль для перевірки простих і парних чисел та обчислення факторіала.

Автоматичні перевірки: `pytest` і `flake8` через GitHub Actions.

## Запуск через Docker

```bash
docker pull ghcr.io/vikalykova/ci-lab-app:latest
docker run --rm ghcr.io/vikalykova/ci-lab-app:latest


## CI/CD-конвеєр
Source -> Build -> Test -> Package -> Deploy
При кожному push у гілку main автоматично: встановлюються залежності,
запускаються тести, збирається й публікується Docker-образ у GHCR,
після чого Terraform розгортає цей образ і перевіряє результат.
