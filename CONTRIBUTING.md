# Contributing

## Scope

This repository is a documentation-first homelab case study. Contributions should improve clarity, evidence quality, portability, or GitHub Pages presentation without changing the documented outcome of the lab.

## Recommended workflow

1. Create a branch from `main`.
2. Update the root [`README.md`](README.md) for GitHub presentation.
3. Mirror GitHub Pages content in [`docs/index.md`](docs/index.md).
4. Keep screenshots synchronized between [`assets`](assets) and [`docs/assets`](docs/assets).
5. Open a pull request using the included template.

## Content guidelines

- Keep all screenshots in chronological order.
- Prefer precise, defensive language over marketing phrasing.
- Do not add unverified claims about detections, forensics, or containment.
- Redact credentials, tokens, or sensitive identifiers before adding new evidence.

## Pull request checklist

- The GitHub README still renders correctly.
- The GitHub Pages version still renders correctly from `/docs`.
- Screenshot captions remain accurate and ordered.
- Any new files use ASCII where possible.
