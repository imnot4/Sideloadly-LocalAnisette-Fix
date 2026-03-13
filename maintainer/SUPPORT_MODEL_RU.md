# Модель поддержки (практично)

## Рекомендуемая схема

1. Код остается бесплатным и открытым.
2. Одна понятная ссылка на поддержку в `support-config.json`.
3. Окно поддержки должно быть отключаемым (уже реализовано).
4. Параллельно добавить пассивные ссылки на поддержку в README и кнопку Sponsor в репозитории.

## Почему это удобно пользователю

- Окно можно скрыть.
- Нет блокировки функций донатом.
- Исходный код полностью открыт для проверки.

## Как обычно делают другие

1. `FUNDING.yml` для кнопки Sponsor в шапке GitHub.
2. Бейджи/ссылки в README (GitHub Sponsors, Open Collective, Ko-fi, Patreon).
3. Неблокирующее напоминание после успешного использования.

## Реальные примеры

- Документация GitHub про Sponsor button и `FUNDING.yml`:
  - https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/displaying-a-sponsor-button-in-your-repository
- Пример `FUNDING.yml` (Neovim):
  - https://raw.githubusercontent.com/neovim/neovim/master/.github/FUNDING.yml
- Пример `FUNDING.yml` (bat):
  - https://raw.githubusercontent.com/sharkdp/bat/master/.github/FUNDING.yml
- Пример `custom` ссылки в `FUNDING.yml` (yt-dlp):
  - https://raw.githubusercontent.com/yt-dlp/yt-dlp/master/.github/FUNDING.yml
- Open Collective кнопки/виджеты:
  - https://documentation.opencollective.com/collectives/raising-money/adding-donation-buttons-badges-and-banners
- npm `funding` field и `npm fund`:
  - https://docs.npmjs.com/cli/v10/configuring-npm/package-json/

## Где лучше размещать донат (конверсия/лояльность)

1. Перед запуском (текущее окно), но с возможностью скрыть.
2. После успешной починки короткая строка с ссылкой.
3. Блок `Support` в начале README.
4. Кнопка Sponsor через `FUNDING.yml`.
