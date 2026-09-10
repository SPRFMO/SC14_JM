# Reproduce the 100-draw Kobe supplement

This compact supplement preserves the two-line reporting patch, its validated
provenance, the exact draw-selection manifest, a native-output validator, the
Kobe plotting script, and a helper that builds the supplemental evaluator.
Use it alongside `reproducibility.zip` and the retained local run archive.
The packaged source and scripts generate the supplemental evaluation locally.

Use these 100 historical fitted trajectories for exploratory model review.
Further sampling is required to meet parameter convergence criteria and support
reliable uncertainty estimates and stock-status probabilities. Each selected
draw covers 2007–2026. The
biomass denominator is each draw's mean annual SSBMSY for 2017–2026; F uses its
matching annual FMSY. F is the mean over all 12 ages of summed four-fleet F.

## Required local archive and software

Use the public source ZIPs together with the retained **original run archive**
to regenerate the same draw-based results. The local archive provides:

- `run/jjm2.psv`: all 3,000 pooled post-warmup draws in the original chain order.
- `evaluation/mceval.rep`: the full original 3,000-draw native evaluation, used
  to check SSB, annual SBMSYy, and F-at-age against the supplemental evaluation.
- `run-manifest.json` and `diagnostic-summary.json`: original settings and
  completed convergence diagnostics.
- `prepared/jjm2.bar` and `prepared/jjm2.par`: the exact matching prepared
  parameter files. The helper validates their recorded hashes.
- `fit.rds`: retain the original raw fit for the full record and for regenerating
  diagnostics if needed. The Kobe plotting script reads the completed diagnostic
  summary.

Retain these raw results locally and use the original pooled draws with their
matching selection manifest. The PSV uses the original little-endian ADMB
format; use a matching little-endian host.

Use ADMB **13.2** with its C++ compiler and safe libraries, Python 3, and R **4.6.1**.
R packages used here were data.table 1.18.4, ggplot2 4.0.3, ggrepel 0.9.8,
jsonlite 2.0.0, and svglite 2.2.2. Interactive HTML additionally requires plotly
4.12.0, htmlwidgets 1.6.4, and Pandoc available to R. Install packages into the normal
R library or set `R_LIBS_USER`. The archived R script preserves its original
optional author-specific library prefix, and R resolves packages across the
available library paths. Complete software installation before running the
supplemental helper, which evaluates the selected archived draws.

## Commands in a fresh working directory

Set `retained_archive` to the absolute path of the complete original run archive.
Keep both source ZIPs available in the working directory. Set `admb13_command`
to the absolute ADMB 13.2 command.

```sh
unzip reproducibility.zip
unzip kobe-reproducibility.zip
repro_root=$(cd base-model-adnuts-reproduction && pwd)
supplement_root=$(cd kobe-reproduction && pwd)
retained_archive=/absolute/path/to/original/base-model-mcmc-2026-09-10
admb13_command=/absolute/path/to/admb-13.2/admb

# Verify the supplement (Linux: sha256sum -c SHA256SUMS).
(cd "$supplement_root" && shasum -a 256 -c SHA256SUMS)

mkdir "$repro_root/prepared" "$repro_root/run" "$repro_root/evaluation" "$repro_root/kobe"
cp "$supplement_root/selection-manifest.csv" "$repro_root/kobe/selection-manifest.csv"
cp "$repro_root/source/1.06.dat" "$repro_root/prepared/1.06.dat"
cp "$repro_root/source/h1_1.06.ctl" "$repro_root/prepared/h1_1.06.ctl"
cp "$repro_root/source/h1_1.06.ctl" "$repro_root/prepared/jjm2.dat"
cp "$retained_archive/prepared/jjm2.bar" "$repro_root/prepared/jjm2.bar"
cp "$retained_archive/prepared/jjm2.par" "$repro_root/prepared/jjm2.par"
cp "$retained_archive/run/jjm2.psv" "$repro_root/run/jjm2.psv"
cp "$retained_archive/fit.rds" "$repro_root/fit.rds"
cp "$retained_archive/evaluation/mceval.rep" "$repro_root/evaluation/mceval.rep"
cp "$retained_archive/run-manifest.json" "$repro_root/run-manifest.json"
cp "$retained_archive/diagnostic-summary.json" "$repro_root/diagnostic-summary.json"

python3 "$supplement_root/reproduce-kobe-evaluation.py" "$repro_root" --admb "$admb13_command"
Rscript --vanilla "$supplement_root/build-kobe-trajectories.R" "$repro_root" "$repro_root/kobe-evaluation/mceval.rep" > "$repro_root/kobe-build.log" 2>&1
```

Check each command's exit status. Use a fresh reproduction root for each helper
run. The helper verifies the frozen template and original pooled PSV, selects
the 100 byte-identical records in `selection-manifest.csv` order, and adds exactly
the two lines in `reporting-only.patch`. It compiles with the default safe
libraries and runs this command inside the isolated evaluation directory:

```sh
./jjm2 -nox -ind h1_1.06.ctl -mceval -nohess -fut_sel 3
```

The original source already calls `get_msy_robust(year)` for annual reporting.
The patch emits its existing `Fmsy` and `Fcur_Fmsy` values as `FMSYy` and
`FFMSYy`, retaining the original likelihood, fitted parameters, and MSY solver.
Every data row has six fields, including the unit identifier; the existing
header lists five labels. The supplied reader and validator use the complete
six-field data layout.

The helper saves the original provenance separately and writes the reproduced
run's own provenance. It checks all 5,700 draw-years (1970–2026), then the R script
selects the requested final 20 years and checks unchanged native quantities
against the full original evaluation. The script regenerates the fixed seeded
33/33/34-chain selection and verifies an existing selection manifest if present.
Outputs are written under `kobe/`: matched trajectories, compact Kobe CSV,
selection manifest, median coordinates, PNG/SVG, interactive HTML when its
packages are available, and validation/status records.

## Recorded validation

The original supplemental evaluator compiled with ADMB 13.2 safe libraries and
exited 0 in 9.85 seconds. All 100 PSV records matched the original pooled bytes;
all 5,700 annual FMSY/FFMSY records were finite, with positive SSBMSY and FMSY
values strictly inside the solver's grid bounds. Independently reconstructed F/FMSY matched
native FFMSYy within six-significant-digit output rounding. For 2007–2026,
2,000 SSB values, 2,000 SBMSYy values, and 96,000 F-at-age values were identical
to the original evaluation. See `derivation-provenance.json` for hashes and
numerical checks. The supplement uses the selected draws from the completed
MCMC run.

The supplemental reproduction helper was also tested from fresh extractions of
both small ZIPs, using the original archived parameter files and pooled PSV.
It compiled and evaluated successfully, and its 39,320,012-byte native output
was byte-identical to the original supplemental output (SHA-256
`229556a5281fd8e50e48630ffd04722163646ff4c1e0bb4f73ce19f50872e1fe`).
The current `reproducibility.zip` has SHA-256
`c61aea3b42f5dcd3df6d8ff257aa9eb9cc9ca4d7ae49d82febd07aee1cb85b84`.
Its source inputs, model and sampling code, and original run records retain
their validated fingerprints; this edition updates explanatory wording.
