# Sideloadly Local Anisette Fix (Windows)

Исправляет частые ошибки Sideloadly:

- `Local Anisette problem`
- `Local Anisette init err`
- `Failed to load ...\an\libxml2.dll`

[![Скачать последний релиз](https://img.shields.io/github/v/release/imnot4/Sideloadly-LocalAnisette-Fix?label=%D0%A1%D0%BA%D0%B0%D1%87%D0%B0%D1%82%D1%8C%20%D0%BF%D0%BE%D1%81%D0%BB%D0%B5%D0%B4%D0%BD%D0%B8%D0%B9%20%D1%80%D0%B5%D0%BB%D0%B8%D0%B7)](https://github.com/imnot4/Sideloadly-LocalAnisette-Fix/releases/latest)

Страница последнего релиза:
https://github.com/imnot4/Sideloadly-LocalAnisette-Fix/releases/latest

## Быстрый старт

1. Распакуйте архив в любую папку.
2. Дважды кликните `Start-Here.cmd`.
3. Дождитесь `Repair completed`.
4. Запустите Sideloadly обычным способом.

## Какой файл запускать?

- `Start-Here.cmd`:
  Основной вариант почти для всех пользователей. Запускает обычный фикс и при необходимости предлагает режим администратора.
- `Run-Fix-Admin.cmd`:
  Нужен только если обычный режим не прошел из-за прав доступа (например `Access is denied`, ошибки записи ADI).
- `Start-Sideloadly-Fixed.cmd`:
  Дополнительный запускатель. Используйте только если после успешного фикса Sideloadly иногда открывается нестабильно.

## Что делает фикс

1. Останавливает зависшие процессы Sideloadly.
2. Убирает конфликтные `RUNASADMIN` флаги совместимости.
3. Определяет x86/x64 и ставит подходящий anisette.
4. Чинит `%LOCALAPPDATA%\Sideloadly\an` и обновляет `PATH` при необходимости.
5. Сбрасывает устаревшие ADI-файлы, если это нужно.
6. Проверяет TLS до `gsa.apple.com`; при необходимости чинит доверие сертификатам Apple.
7. Сохраняет лог в `runs\run-<timestamp>\`.

## Безопасность

- Скрипт не запрашивает Apple ID/пароль.
- Скрипт не отправляет ваши логи на сторонние серверы.
- Сеть используется только для официальных загрузок Sideloadly/Apple, необходимых для фикса.

## Важно

- Ярлык на рабочий стол автоматически не создается.
- После успешной починки можно запускать обычный Sideloadly напрямую.
- Если проблема вернулась, снова запустите `Start-Here.cmd`.

## Поддержка

После успешного исправления лаунчер может показать необязательное окно поддержки.
Прямая ссылка: `https://boosty.to/not4/donate`
Я коплю на компьютер, чтобы обновить старый. Это не обязательно, но очень мне поможет <3
