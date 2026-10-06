# РџСЂР°РєС‚РёС‡РЅР° СЂРѕР±РѕС‚Р° в„–1. Р’Р°СЂС–Р°РЅС‚ 5

[![CI](https://github.com/VikaLykova/number_theory/actions/workflows/ci.yml/badge.svg)](https://github.com/VikaLykova/number_theory/actions/workflows/ci.yml)
[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python&logoColor=white)](https://img.shields.io/badge/Python-3.11-blue?logo=python&logoColor=white)

РњРѕРґСѓР»СЊ РґР»СЏ РїРµСЂРµРІС–СЂРєРё РїСЂРѕСЃС‚РёС… С– РїР°СЂРЅРёС… С‡РёСЃРµР» С‚Р° РѕР±С‡РёСЃР»РµРЅРЅСЏ С„Р°РєС‚РѕСЂС–Р°Р»Р°.

РђРІС‚РѕРјР°С‚РёС‡РЅС– РїРµСЂРµРІС–СЂРєРё: `pytest` С– `flake8` С‡РµСЂРµР· GitHub Actions.

## Р—Р°РїСѓСЃРє С‡РµСЂРµР· Docker

```bash
docker pull ghcr.io/vikalykova/ci-lab-app:latest
docker run --rm ghcr.io/vikalykova/ci-lab-app:latest


## CI/CD-конвеєр

Source -> Build -> Test -> Package -> Deploy

При кожному push у гілку main автоматично: встановлюються залежності, запускаються тести, збирається й публікується Docker-образ у GHCR, після чого Terraform розгортає цей образ і перевіряє результат.
