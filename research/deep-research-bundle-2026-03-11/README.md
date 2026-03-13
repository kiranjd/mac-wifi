# MacWiFi Deep Research Bundle

Prepared on March 11, 2026.

This folder is a research-ready handoff for evaluating how `MacWiFi` can become a sharper, more sellable macOS utility with a clearer target audience, stronger positioning, and a more defensible value proposition.

## What is in this folder

- `01-product-feature-inventory.md`
  Detailed grouping of the app's current shipped capabilities, commercial packaging, UX posture, and constraints.
- `02-media-asset-inventory.md`
  Grouped inventory of screenshots, videos, icons, social exports, local mockups, and duplicate build mirrors.
- `03-deep-research-prompt.md`
  The main high-value prompt to paste into a deep research system.
- `asset-metadata.tsv`
  Flat machine-readable manifest for the copied bundle assets, including dimensions, durations, and file sizes.
- `assets/01-canonical-product-shots/`
  Core screenshots currently used across the website and Product Hunt materials.
- `assets/02-demo-videos/`
  Canonical demo videos.
- `assets/03-social-exports/`
  Social and promo video exports in multiple aspect ratios.
- `assets/04-brand-and-icons/`
  App icon and iconset assets.
- `assets/05-website-mockups/`
  Local website and landing-page mockups that show adjacent positioning or presentation ideas.
- `assets/06-misc-unreferenced/`
  Miscellaneous or ambiguous media found in the repo but not clearly tied to the shipped app/site.

## How to use this bundle

1. Give the research system the prompt in `03-deep-research-prompt.md`.
2. Attach the canonical product screenshots, demo videos, and any local mockups you want it to inspect visually.
3. Keep `01-product-feature-inventory.md` and `02-media-asset-inventory.md` alongside the prompt so the model has both the raw assets and structured context.

## Important framing

- This bundle is based on what exists in the repo now, not on the original concept alone.
- The current product is broader than "better Mac Wi-Fi menu"; it already includes active connection testing, plain-English diagnosis, activity readiness, and Wi-Fi-vs-ISP issue splitting.
- Current commercial posture in the repo is a `macOS` menu bar app priced at `$9.99 one-time`, with no account and in-app license activation.
- Some media files are duplicate mirrors across `website/assets`, `public/assets`, `dist/assets`, and `docs/producthunt`. The inventory calls out canonical files and mirrors separately to reduce noise.
