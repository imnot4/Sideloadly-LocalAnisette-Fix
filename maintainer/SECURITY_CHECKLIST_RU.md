# Чеклист безопасности

Используйте перед запуском и перед публикацией.

## 1) Проверка исходников

Откройте `Fix-Sideloadly-LocalAnisette.ps1` и убедитесь, что нет:

- запроса Apple ID/пароля
- отправки логов на сторонние серверы
- несвязанных разрушительных команд

## 2) Проверка сетевых URL

Ожидаемые адреса:

- `https://sideloadly.io/anis-32.zip`
- `https://sideloadly.io/anis-64.zip`
- официальные сертификаты Apple на `https://www.apple.com/...`

Быстрая проверка:

```powershell
Select-String -Path .\Fix-Sideloadly-LocalAnisette.ps1 -Pattern 'https://'
```

## 3) Проверка SHA256

Сверьте локальный хэш с опубликованным `SHA256SUMS`:

```powershell
Get-FileHash .\Fix-Sideloadly-LocalAnisette.ps1 -Algorithm SHA256
```

## 4) Проверка подписи

```powershell
Get-AuthenticodeSignature .\Fix-Sideloadly-LocalAnisette.ps1
```

## 5) Проверка на VirusTotal

Загрузите zip релиза на VirusTotal и дайте ссылку в описании релиза.

## 6) Безопасный первый прогон

Сначала без запуска UI:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Fix-Sideloadly-LocalAnisette.ps1 -NoLaunch
```
