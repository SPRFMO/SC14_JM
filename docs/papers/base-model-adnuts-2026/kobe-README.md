# 100 retained ADNUTS draws in Kobe format, 2007-2026

These are 100 matched historical fitted trajectories from the completed h1_1.06 default ADNUTS run, suitable for exploratory display. They are conditional on the base model; further sampling is needed for reliable posterior stock-status probabilities. The diagnostics identify room for improved mixing: maximum parameter R-hat 1.055 and 2026 SSB R-hat 1.018.

## Files

- `kobe-trajectories-100-draws-2007-2026.csv`: 2000 rows, preserving draw, chain, iteration, year, biological quantities, reference points and both ratios.
- `kobe-format.csv`: conventional long Kobe columns `iter`, `year`, `stock` (SSB/SSBMSY), and `harvest` (F/FMSY). `iter` matches `evaluation_draw_id` in the selection manifest.
- `selection-manifest.csv`: all 100 draw identities; pooled draw 1-1000 is chain 1, 1001-2000 is chain 2, and 2001-3000 is chain 3. Retained iteration is 1-1000 after warmup; sampler iteration adds 1000 warmup iterations.
- `kobe-trajectories.rds`: trajectories, compact Kobe data, selection and median in an R list.
- PNG and SVG: all 100 paths and coordinate-wise selected-draw median; open circle starts in 2007, filled diamond ends in 2026.
- Interactive HTML: select an individual draw in the dropdown and hover over its years. The median remains visible. All 100 paths are available together.
- `selected-draw-median-trajectory.csv`: coordinate-wise medians across the 100 selected draws provide a visual summary for each year.
- `evaluation-invariance-check.csv` and `kobe-status.json`: validation, provenance and interpretation.

## Selection

Seed 20260910; R RNG kinds Mersenne-Twister, Inversion, Rejection. Sample without replacement from 1000 retained iterations per chain, selecting 33, 33 and 34 draws from chains 1, 2 and 3, then sort pooled draw IDs. Selection is random within each chain, independent of parameter values and stock status. The same draw is followed through every year from 2007 through 2026 inclusive.

## Quantities and reference convention

`ssb_kt` is native `SSB` = Sp_Biom(1,year), in thousand tonnes. `f_mean_all_ages_per_year` is the unweighted mean over all twelve model ages of F summed across all four fleets: sum(F_faa)/12. This exactly matches the numerator used by get_msy_robust for Fcur_Fmsy. Computing the Kobe numerator directly from F_faa provides the complete stock-level quantity; the native emitted Fbar contains the first-fleet scalar.

`ssbmsy_year_kt` is annual SBMSYy from get_msy_robust(year). `ssbmsy_reference_kt` is its within-draw arithmetic mean for 2017-2026, repeated over all years, following jjmR::fixed_bmsy(). The biomass ratio is ssb_kt/ssbmsy_reference_kt. `fmsy_year_per_year` is matching annual FMSYy from the same robust routine, and the fishing-mortality ratio is f_mean_all_ages_per_year/fmsy_year_per_year. Annual F/FMSY remains unchanged by fixed_bmsy. Both ratios are dimensionless.

The frozen model computes annual robust MSY values. An isolated evaluator exposes the matching FMSYy and FFMSYy through two additional output fields immediately after its existing get_msy_robust(year) call, then re-evaluates the 100 selected saved PSV vectors. Its SSB, SBMSYy and F_faa values are checked against the original complete evaluation. Reconstructed F/FMSY is checked against the emitted native Fcur_Fmsy, allowing six-significant-digit report rounding. These annual robust reference points provide consistent optimization and evaluation assumptions; the native pre-loop FMSY/SBMSY routine uses differing selectivity windows in those steps.

Frozen source: `../source/jjm2.tpl`, write_mceval lines 1975-2017, get_msy_robust lines 3744-3826, annual yld lines 3909-3960. Canonical R convention: `/Users/jim/_mymods/sprfmo/jjmR/R/fixed_bmsy.R`, lines 12-24. Source line numbers refer to the frozen source, before the supplementary output lines are added.

## Reproduce

From the repository root, run:

```sh
Rscript output/base-model-mcmc-2026-09-10/build-kobe-trajectories.R output/base-model-mcmc-2026-09-10 path/to/supplemented/mceval.rep
```

The selected raw-quantity RDS is an extraction cache validated against the original file path, size, modification time and selected draw IDs. Removing this cache triggers a fresh scan. Source model files, original draws and the complete original mceval output are preserved unchanged.
