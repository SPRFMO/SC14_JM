# Annual posterior probability of Kobe green, 2007–2026

This supplement uses all 3,000 retained draws from the existing h1_1.06 ADNUTS run. Each chain contributes 1,000 draws. The annual estimate is the number of draws satisfying both SSB/SSBMSY > 1 and F/FMSY < 1 divided by 3,000. Both conditions are evaluated jointly within each draw. Equality at a boundary falls outside green.

SSBMSY is the within-draw mean of annual robust MSY spawning biomass for 2017–2026. F is the mean across all 12 ages of F summed across the four fleets. FMSY is the matching annual robust reference. This matches the published 100-trajectory Kobe display. Historical trajectories are conditional on the base model; further sampling is needed to improve full-model chain agreement and strengthen these exploratory posterior estimates.

## Data and diagnostics

- `kobe-green-probability-2007-2026.csv`: 20 annual probabilities, draw counts, chain-specific proportions, indicator R-hat, effective sample size for the mean, and Monte Carlo standard error (MCSE).
- `kobe-green-by-chain-2007-2026.csv`: 60 chain/year summaries.
- `kobe-green-draws-2007-2026.csv.gz`: all 60,000 draw/year coordinates and joint green indicators; draw order preserves the original 1,000 retained draws per chain.
- `green-evaluation-status.json`: hashes, complete native stream record counts, and reference-coordinate checks.
- `kobe-green-status.json`: calculation definitions, validation against the previously published 100 draws, and terminal summary.

MCSE and ESS use the binary green indicator and preserve chain structure through the `posterior` R package. A constant indicator produces the observed proportion and an unavailable MCSE/ESS/R-hat entry (`NA` in CSV). A zero count describes the sampled draws and remains conditional on finite MCMC exploration. Chain agreement and full-model diagnostics support interpretation alongside these Monte Carlo precision estimates.

## Reproduce summaries from public files

Create `archive/kobe-green` and `archive/kobe`. Download the compressed draw-level file into `archive/kobe-green`, and the original detailed 100-trajectory CSV into `archive/kobe`. Decompress the all-draw file to `archive/kobe-green/kobe-all-draws-2007-2026.csv`. Run:

```sh
Rscript summarize-kobe-green.R archive
```

The R script requires data.table, ggplot2, posterior, jsonlite and svglite. It rechecks 3,000 complete paths, equal chain contributions, joint event counts and the original 100-draw coordinates, then writes probability summaries, diagnostics and figures. Its optional local R-library path supports the original workstation; installed libraries elsewhere remain available through R's normal search paths.

## Reproduce the native reference-point evaluation

Use the original MCMC archive and the previously supplied Kobe reproduction supplement to reconstruct the validated two-line reporting-only evaluator in `kobe-evaluation/`. Place `evaluate-kobe-all-draws.py` at the archive root and run it with Python 3 on a POSIX system. It verifies frozen source and retained PSV hashes, stages all 3,000 existing parameter vectors, and uses the same `-mceval -nohess -fut_sel 3` command. A named pipe streams the native report into compact annual coordinates while hashing the full native output. This preserves disk space and the existing model calculations. The archived input and sampling files remain the inputs to the workflow.

Then run the R summary script as above. This evaluation uses the completed MCMC draws and the existing annual robust MSY routine. The reporting-only patch is included for source comparison. Native F/FMSY is cross-checked against reconstructed F-at-age ratios, and positive reference points and grid bounds are checked.
