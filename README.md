# Jack mackerel research for management

A public, source-linked working guide to jack mackerel research and the material prepared for SC14. Research findings, proposed work and agreed decisions retain their distinct status. Initial coverage focuses on the 2026 workshops and SC14 submissions.

Read the guide: https://sprfmo.github.io/SC14_JM/

## Updating the guide

Edit the Markdown pages in `content/`, then run `python3 build.py` with Python and Quarto installed. Commit the edited sources and the generated `docs/` pages together. GitHub Pages publishes `main/docs`.

The build also refreshes the contents search from the HTML pages hosted in `docs/`, including nested reports and readable scorecards. It excludes navigation, scripts, the search page itself, and the plot-only Kobe widget. External papers, PDFs and spreadsheets are covered by their wiki descriptions rather than their full contents. The technical annex is not included. After synchronizing a hosted report, rerun `python3 build.py` to refresh search. Search uses local assets without an external service; `CMP29`, `MP29` and `MP 29` are equivalent. Verify the generated index with `python3 validation/check_search.py` and `node validation/check_search.js`.

Source-paper links prefer verified HTML reading versions on SPRFMO working-group websites. Where no HTML counterpart is verified, retain the official PDF and identify the limitation on the sources page. Working HTML publications may differ from submitted SC14 revisions; preserve this distinction. The checked mapping and remaining PDFs are recorded in `validation/document-links.json`. This repository contains the guide, not copies of the research PDFs. Add meeting outcomes only with an authoritative record and preserve qualifications and uncertainties.

## Current SC14 assessment

Run `python3 render_sc14.py --jjm /absolute/path/to/jjm` after updating the assessment checkout. This renders the report from existing outputs and synchronizes the report and its figure links into the wiki. See [SC14 synchronization](SC14-SYNC.md) for review and publication steps.
