# Support Model (Practical)

## Recommended setup

1. Keep code free and open-source.
2. Add one clear donation URL in `support-config.json`.
3. Keep popup optional and dismissible (already implemented).
4. Also add passive support links in README and repository Sponsor button.

## Why this is user-friendly

- One-time popup can be dismissed.
- No feature lock behind donations.
- Full source code remains visible and auditable.

## How others usually do it

1. `FUNDING.yml` sponsor button in repository header.
2. README badges/links (GitHub Sponsors, Open Collective, Ko-fi, Patreon).
3. Optional non-blocking reminder after successful use.

## Real references

- GitHub docs on Sponsor button + `FUNDING.yml`:
  - https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/displaying-a-sponsor-button-in-your-repository
- Example `FUNDING.yml` (Neovim):
  - https://raw.githubusercontent.com/neovim/neovim/master/.github/FUNDING.yml
- Example `FUNDING.yml` (bat):
  - https://raw.githubusercontent.com/sharkdp/bat/master/.github/FUNDING.yml
- Example `custom` funding link in `FUNDING.yml` (yt-dlp):
  - https://raw.githubusercontent.com/yt-dlp/yt-dlp/master/.github/FUNDING.yml
- Open Collective donation button widgets:
  - https://documentation.opencollective.com/collectives/raising-money/adding-donation-buttons-badges-and-banners
- npm `funding` field and `npm fund`:
  - https://docs.npmjs.com/cli/v10/configuring-npm/package-json/

## Suggested donation placement (best conversion, low irritation)

1. Before run (current popup), dismissible.
2. After successful fix, one short thank-you line + link.
3. README top section with `Support` block.
4. GitHub Sponsor button via `FUNDING.yml`.
