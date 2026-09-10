# Reproduce the h1_1.06 base-model ADNUTS run

This archive contains the frozen model inputs and executable source used for the
10 September 2026 run, its original R scripts, portable copies, and the original
software/settings records. Read the separate **Base-model ADNUTS** wiki document
(`base-model-adnuts.html`, alongside this README) for the completed results and
sampling diagnostics. Use the retained-sample quantiles for exploratory review.
Further sampling is required to meet parameter convergence criteria and support
reliable posterior uncertainty estimates and management inference.

## Contents and provenance

- `source/`: unchanged `jjm2.tpl`, `h1_1.06.ctl`, `1.06.dat`, fitted
  `h1_1.06.par`, and the original `h1_1.06.rep`.
- `provenance/original-scripts/`: exact scripts that generated this run and its
  diagnostics. Root-level R scripts remove only the original author's absolute
  R-library search path; the root sampling driver also requires adnuts 1.1.2.
  The portable copies use the original statistical call and seeds.
- `provenance/run-manifest.json`, `session-info.txt`, and `preflight.json`:
  original records, preserved unchanged. Historic absolute paths, preflight
  status, and the manifest's “diagnostics pending” status describe their original
  recording times; current diagnostics are in the wiki results document.
  The preflight record retains the original binary fingerprint for comparison.
- `source-notes.md`: original derivation, unit, schema, and comparison notes.
  Historical workspace paths in those notes identify their source evidence;
  the reproduction commands below use the archive's own directory layout.
- `SHA256SUMS`: fingerprints for all other files in this archive.

The packaged commands generate the executable, `fit.rds`, pooled PSV, raw
`mceval.rep`, Hessian, and covariance files in the local reproduction directory.
The published results use the completed original run and its retained draws.
Source assessment commit: `a53473feebfd28417e85b80af77e82be56e01653`.
The frozen template SHA-256 is
`4174ef904ab0c093b629370a7835cc0e3fc45e23dd53bc154b70103a6040d94a`.

## Software and fixed run identity

Use **ADMB 13.2**, its C++ build toolchain, and **R 4.6.1** with **adnuts 1.1.2**.
The original run used macOS arm64 and the safe ADMB libraries. The original
`session-info.txt` lists its other packages. The diagnostic scripts additionally
require `posterior` (originally 1.7.0), `ggplot2` (4.0.3), `jsonlite` (2.0.0), and
`data.table` (1.18.4). Make these packages available in your normal R library or
`R_LIBS_USER` before executing. Complete the package and ADMB installations
before running the commands below. Compiler and platform choices can affect
numerical trajectories; use the recorded environment for the closest reproduction.

The sampling call uses package defaults with only the executable, directory, and
model arguments supplied:

```r
adnuts::sample_nuts(model = 'jjm2', path = run,
                   admb_args = '-ind h1_1.06.ctl -fut_sel 3')
```

Defaults in adnuts 1.1.2 are 3 chains, 2,000 saved iterations per chain, 1,000
warmup iterations per chain, thinning 1, and 3,000 retained draws in total.
Initialization is `NULL` (the same saved fitted mode in all chains),
`adapt_delta = 0.8`, maximum tree depth 12, an initial unit metric with diagonal
mass adaptation, and adapted step size. `mceval = FALSE` remains the sampling
default; derived evaluation is a separate step after sampling. The driver sets
R's seed to `20260910`; the resulting package-generated chain seeds were
`4754034`, `193486`, and `8644402`. `provenance/run-manifest.json` includes every
resolved default and the complete actual per-chain commands.

## Run from a fresh extraction

These POSIX-shell commands work with the archive's own directory layout. Put
ADMB 13.2 on `PATH`, or supply its **absolute** command path through `ADMB`.
The setup script verifies the reported version. Use a fresh output directory
for each preparation, sampling, and evaluation sequence.

```sh
unzip reproducibility.zip
cd base-model-adnuts-reproduction
repro_root=$(pwd)
# On macOS, verify the packaged files (Linux: sha256sum -c SHA256SUMS):
shasum -a 256 -c SHA256SUMS

# Set an explicit ADMB 13.2 path when needed: ADMB=/absolute/path/to/admb-13.2/admb
sh prepare.sh "$repro_root"
Rscript --vanilla run-adnuts.R "$repro_root" > sampling.log 2>&1
Rscript --vanilla summarize-adnuts.R "$repro_root/fit.rds" "$repro_root" > diagnostics.log 2>&1
sh evaluate.sh "$repro_root"
Rscript --vanilla summarize-derived.R "$repro_root" "$repro_root/evaluation/mceval.rep" > derived.log 2>&1
```

`prepare.sh` compiles `source/jjm2.tpl` in `build/` with the default safe libraries,
copies the inputs into `prepared/`, duplicates the control file as
`jjm2.dat`, and uses exactly this approved preparation command:

```sh
./jjm2 -nox -ind h1_1.06.ctl -ainp h1_1.06.par -phase 1000 -maxfn 0 -hbf -fut_sel 3
```

The preparation regenerates `admodel.hes`, `jjm2.cor`, `jjm2.par`, `jjm2.bar`, and
`For_R_1.rep` at the saved fitted parameter vector. The sampling driver compares
the source and prepared objective values within 1e-6 before creating `run/`.
The original objective was 1384.75151390345 for 1,593 active parameters; its
original fitted maximum gradient component was 0.000166791692228721. Use that
original fitted value when assessing optimization; the `-maxfn 0` preparation
header records a zero gradient during fixed-parameter evaluation.
Retain `source/h1_1.06.par` and `prepared/jjm2.cor` for the sampling driver.

After `fit.rds` has been saved, the package's pooled `run/jjm2.psv` contains chain
1, then chain 2, then chain 3, each with 1,000 retained draws. `evaluate.sh` copies
that PSV and the required model files into `evaluation/` and runs:

```sh
./jjm2 -nox -ind h1_1.06.ctl -mceval -nohess -fut_sel 3
```

`-nohess` completes the draw evaluation through the model's supported reporting
path while preserving its draw calculations. Retain the successful
`prepared/For_R_1.rep` for the fitted-mode comparison. The derived script checks
complete 3,000-draw coverage, the frozen six-field output schema, all years
1970–2026, and age-1 recruitment. It writes `derived/` with SSB (thousand tonnes),
recruitment (million fish), diagnostic summaries, and plots. It distinguishes
empirical sample intervals from the original report's approximate two-SE limits.

Check every command's exit status before proceeding. Inspect
`diagnostic-summary.json`, `chain-diagnostics.csv`, and `derived/derived-status.json`
together. Reliable uncertainty estimates require satisfactory parameter,
sampler, and derived-quantity checks. The original full run took approximately
31 minutes for sampling;
allow additional time and several GB of free space for preparation, chain files,
the raw evaluation (about 1.1 GB), and summaries. Timing is machine-dependent.

## Package validation

The ZIP was extracted into a separate temporary directory and all 19 packaged
file hashes passed. Its shell scripts and all three portable R scripts passed
syntax checks. The frozen template compiled successfully with ADMB 13.2 safe
libraries, and `prepare.sh` completed successfully, generating every required
file including `jjm2.cor` and the SSB/recruitment blocks of `For_R_1.rep`.
The regenerated objective was 1384.75151390541, differing from the original by
1.96e-9. Package validation covered compilation, preparation, syntax, and file
integrity. The accompanying wiki paper documents the original full MCMC run
and pooled-draw evaluation.
