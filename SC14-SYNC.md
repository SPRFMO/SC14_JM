# SC14 assessment report

Keep model runs and report authoring in SPRFMO/jjm. The wiki holds an exact copy of the rendered report at `docs/assessment/SC14.html`, linked from “How is the stock doing?”. This stable address is separate from historical SCW16 material and the MSE papers.

## Render and synchronize in one step

After updating the local jjm checkout, run from this wiki checkout:

```sh
python3 render_sc14.py --jjm /absolute/path/to/jjm
```

This renders an isolated copy of `doc/SC14.qmd` against the existing assessment outputs, synchronizes the result, and rebuilds the wiki. It does not run model fits or publish.

## After rendering the assessment

The current upstream source is `jjm/doc/SC14.qmd` and already requests `embed-resources: true`. The output location depends on the Quarto project settings. Use the actual completed render, whether it is in `assessment`, `doc`, or `docs`.

From this wiki checkout:

```sh
python3 sync_sc14.py --source /absolute/path/to/SC14.html --source-repo /absolute/path/to/jjm
python3 build.py
git diff --check
git add content/assessments.md docs/assessments.html docs/assessment
git commit -m "Synchronize SC14 assessment report"
git push origin HEAD:main
```

Run the first two commands from the assessment's existing render/publish routine after a successful render. This gives an event-driven refresh: failed renders never replace the wiki report. The script never runs the assessment, modifies jjm, commits, or pushes. Publication remains the final step of the existing wiki workflow.

The first successful synchronization inserts the report link into the editable assessment page. Subsequent runs replace the same report. An unchanged render is a no-op. `docs/assessment/sync.json` records its SHA-256, source revision where available, and synchronization time without exposing local paths.

## Validation and limits

- Only the explicitly selected HTML and its referenced Quarto figure files are copied. No assessment data directories or repository credentials are copied.
- Quarto lightbox figure links are preserved. If Quarto removed their files after embedding them, synchronization restores the exact image bytes from the embedded display images. Other relative dependencies cause a failure before the existing report changes.
- Preserve the source's draft/proposed status. A working assessment is distinct from agreed Committee conclusions.
- After pushing, confirm the GitHub Pages build, open `assessment/SC14.html`, and compare the live response hash with `sync.json`.
- GitHub cannot read an uncommitted HTML file on a local computer. Fully unattended cross-repository synchronization needs a rendered artifact published by the jjm workflow and appropriate repository access. Do not create broad access tokens or mirror the private repository merely to share one report.

## Published source

The report refreshed on 10 September 2026 uses jjm revision `17d3fb1` and existing saved assessment outputs, with a local source repair for the dynamic-BMSY Kobe plot. The unsupported `fixed_bmsy(..., dyn = TRUE)` call was replaced by the annual model BMSY/B0 ratio multiplied by dynamic unfished spawning biomass, reconstructed from the saved SSB_NoFishR series. The first year is excluded because that ratio begins in year two. F/FMSY is unchanged, and the caption states the dynamic convention.

The exact HTML and figure checksums are recorded in `docs/assessment/sync.json`. The report retains its DRAFT label. Rendering and link/resource integrity were checked; model refitting and a full accessibility audit were not performed.
