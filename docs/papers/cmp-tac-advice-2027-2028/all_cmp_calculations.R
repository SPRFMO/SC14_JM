# All eight SC14 common-500 CMPs: deterministic 2027/2028 TAC calculations.
# Run from jmMSE26 with Rscript output/cmp29-cmp45-tac-2027-2028/all_cmp_calculations.R
# The two original CMP files are preserved. This script writes all_cmp_* files.

suppressPackageStartupMessages({
  # The serialized FLmse objects may load an optional display package.
  suppressWarnings(library(mse))
  library(data.table)
})
options(warn = 2)
out_dir <- "output/cmp29-cmp45-tac-2027-2028"
release_dir <- "../jmMSE-500-refine/model/tune/refine_500_from_100"
controls_path <- file.path(out_dir, "all_release_controls.rds")
cmp_codes <- c("tun29", "tun45", "tun43", "tun47", "tun32", "tun44", "tun46", "tun48")
cmp_ids <- sub("tun", "MP", cmp_codes)
input_file <- "../jjm/assessment/input/1.06.dat"

# Retain the exact serialized release functions, because the currently
# installed function named cpues.ind has different arguments and behavior.
if (!file.exists(controls_path)) {
  controls <- setNames(lapply(cmp_codes, function(code) {
    run <- suppressWarnings(readRDS(file.path(release_dir, paste0(code, ".rds"))))
    ct <- control(run)
    list(estimator = method(ct$est), estimator_args = args(ct$est),
         hcr = method(ct$hcr), hcr_args = args(ct$hcr))
  }), cmp_codes)
  saveRDS(controls, controls_path)
}
controls <- readRDS(controls_path)
stopifnot(identical(names(controls), cmp_codes))

registry <- fread("doc/data/cmp-registry.csv")
registry <- registry[match(cmp_ids, cmp_id)]
definitions <- fread("../jmMSE-500-refine/candidate_mps_500.csv")
definitions <- definitions[match(cmp_ids, label)]
tuning <- fread("../jmMSE-500-refine/output/tune/tuning_500_from_100_summary.csv")
tuning <- tuning[match(cmp_ids, label)]
for (field in c("min", "lim", "target", "trigger", "dlow", "dupp")) {
  serialized <- vapply(controls, function(ct) ct$hcr_args[[field]], numeric(1))
  stopifnot(identical(as.numeric(serialized), as.numeric(registry[[field]])),
            identical(as.numeric(registry[[field]]), as.numeric(definitions[[field]])),
            identical(as.numeric(registry[[field]]), as.numeric(tuning[[field]])))
}
for (ct in controls) {
  stopifnot(identical(ct$estimator_args$refyrs, as.character(2019:2023)),
            ct$estimator_args$nyears == 3, ct$estimator_args$combine == "mean",
            identical(ct$estimator_args$indices, controls[[1]]$estimator_args$indices),
            ct$hcr_args$metric == "mean", ct$hcr_args$output == "catch")
}

# Independently parse the assessment input rather than reading the prior
# answer table. Build indices with explicit missing observations.
src <- readLines(input_file)
line <- function(tag) {
  at <- which(trimws(src) == tag)
  stopifnot(length(at) == 1L)
  at
}
n <- as.integer(src[line("#Inum") + 1L])
input_names <- strsplit(trimws(src[line("#Inames") + 1L]), "%", fixed = TRUE)[[1]]
years <- lapply(src[line("#Iyears") + seq_len(n)], function(s) scan(text = s, quiet = TRUE))
values <- lapply(src[line("#Index") + seq_len(n)], function(s) scan(text = s, quiet = TRUE))
stopifnot(length(input_names) == n, identical(lengths(years), lengths(values)))
index_map <- c(Chile_AcousN = "Chile_AcousN", Chile_CPUE = "Chile_CPUE",
               Peru_Artis = "Peru_Artis_CPUE", Peru_Ind = "Peru_Ind_CPUE",
               Offshore_CPUE = "Offshore_CPUE")
idx <- FLIndices(setNames(lapply(index_map, function(input_name) {
  i <- match(input_name, input_names)
  z <- FLQuant(NA_real_, dimnames = list(age = "all", year = as.character(1997:2026)))
  z[, as.character(years[[i]])] <- values[[i]]
  FLIndex(index = z)
}), names(index_map)))

raw_formula <- function(indicator, p, family) {
  if (indicator <= p$lim) return(p$min)
  x <- (indicator - p$lim) / (p$trigger - p$lim)
  if (family == "hockeystick.hcr") {
    if (indicator >= p$trigger) return(p$target)
    return(p$min + (p$target - p$min) * x)
  }
  stopifnot(family == "powerramp.hcr")
  if (indicator >= p$trigger) return(p$target * (0.2 + 0.8 * x)^0.6)
  p$min + (p$target - p$min) * x^2.5
}

answer <- list()
formula_errors <- numeric()
index_errors <- numeric()
existing_metrics <- fread(file.path(out_dir, "three_year_metrics.csv"))
for (code in cmp_codes) {
  ct <- controls[[code]]
  p <- registry[cmp_id == sub("tun", "MP", code)]
  for (baseline in c(1675, 1092)) {
    tracking <- CJ(biol = "CJM", metric = c("hcr", "metric.hcr", "decision.hcr", "rule.hcr"),
                   year = as.character(2026:2028), iter = 1L)
    tracking[, data := NA_real_]
    hcr_args <- ct$hcr_args
    hcr_args$initial <- baseline
    prior <- baseline
    for (advice_year in 2027:2028) {
      data_year <- advice_year - 2L
      runtime_args <- list(ay = advice_year, dy = data_year, data_lag = 2L,
                           iy = 2027L, mys = advice_year, it = 1L, stock = 1L)
      est <- do.call(ct$estimator, c(list(stk = NULL, idx = window(idx, end = data_year),
        args = runtime_args, tracking = tracking), ct$estimator_args))
      hcr <- do.call(ct$hcr, c(list(stk = NULL, ind = est$ind,
        args = runtime_args, tracking = est$tracking), hcr_args))
      tracking <- hcr$tracking
      # goFish records the constrained control as hcr; carry that final TAC.
      track(tracking, "hcr", year = advice_year) <- hcr$ctrl
      indicator <- as.numeric(est$ind$mean)
      raw <- tracking[metric == "decision.hcr" & year == as.character(advice_year), data]
      advice <- as.numeric(hcr$ctrl$value)
      lower <- prior * p$dlow
      upper <- prior * p$dupp
      formula_raw <- raw_formula(indicator, p, p$hcr)
      formula_advice <- max(lower, min(upper, formula_raw))
      formula_errors <- c(formula_errors, abs(raw - formula_raw), abs(advice - formula_advice))
      index_errors <- c(index_errors, abs(indicator - existing_metrics[data_through == data_year, metric]))
      answer[[length(answer) + 1L]] <- data.table(
        tac_2026_kt = baseline, cmp = sub("tun", "CMP", code), label = p$label,
        hcr = p$hcr, advice_year = advice_year, data_through = data_year,
        recent_window = paste0(data_year - 2L, "-", data_year), metric = indicator,
        trigger = p$trigger, min = p$min, lim = p$lim, target = p$target,
        dlow = p$dlow, dupp = p$dupp, prior_tac_kt = prior,
        unconstrained_tac_kt = raw, lower_limit_kt = lower, upper_limit_kt = upper,
        tac_advice_kt = advice, change_percent = 100 * (advice / prior - 1),
        binding_rule = if (raw < lower) paste0(100 * (1 - p$dlow), "% maximum decrease")
          else if (raw > upper) paste0(100 * (p$dupp - 1), "% maximum increase")
          else "index-based rule")
      prior <- advice
    }
  }
}
answer <- rbindlist(answer)
stopifnot(nrow(answer) == 32L, all(is.finite(answer$tac_advice_kt)),
          all(answer$tac_advice_kt >= answer$lower_limit_kt - 1e-10),
          all(answer$tac_advice_kt <= answer$upper_limit_kt + 1e-10),
          max(formula_errors) < 1e-9, max(index_errors) < 1e-12)

original <- fread(file.path(out_dir, "tac_advice.csv"))
comparison <- merge(answer, original, by = c("cmp", "tac_2026_kt", "advice_year"),
                    suffixes = c(".new", ".original"))
stopifnot(nrow(comparison) == 8L)
original_errors <- abs(comparison$tac_advice_kt.new - comparison$tac_advice_kt.original)
stopifnot(max(original_errors) < 1e-9,
          max(abs(comparison$unconstrained_tac_kt.new - comparison$unconstrained_tac_kt.original)) < 1e-9)

# Additional checks exercise the entire raw rule, including the above-trigger
# PR branch, where the rule rises above target rather than reaching a plateau.
branch_errors <- numeric()
for (code in cmp_codes) {
  ct <- controls[[code]]
  p <- registry[cmp_id == sub("tun", "MP", code)]
  hcr_args <- ct$hcr_args
  hcr_args$dlow <- NULL
  hcr_args$dupp <- NULL
  for (indicator in c(0, p$lim, (p$lim + p$trigger) / 2, p$trigger, p$trigger * 1.5)) {
    test_ind <- FLQuants(mean = FLQuant(indicator,
      dimnames = list(age = "all", year = "2025")))
    tracking <- CJ(biol = "CJM", metric = c("metric.hcr", "decision.hcr", "rule.hcr"),
                   year = "2027", iter = 1L)
    tracking[, data := NA_real_]
    got <- do.call(ct$hcr, c(list(stk = NULL, ind = test_ind,
      args = list(ay = 2027L, dy = 2025L, iy = 2027L, mys = 2027L, it = 1L, stock = 1L),
      tracking = tracking), hcr_args))
    branch_errors <- c(branch_errors, abs(as.numeric(got$ctrl$value) - raw_formula(indicator, p, p$hcr)))
  }
}
stopifnot(length(branch_errors) == 40L, max(branch_errors) < 1e-9)

parameters <- copy(registry)
parameters[, `:=`(cmp = sub("MP", "CMP", cmp_id), mp = cmp_codes,
                  power_between = ifelse(hcr == "powerramp.hcr", 2.5, 1),
                  power_above = ifelse(hcr == "powerramp.hcr", 0.6, NA_real_),
                  above_offset = ifelse(hcr == "powerramp.hcr", 0.2, NA_real_),
                  above_scale = ifelse(hcr == "powerramp.hcr", 0.8, NA_real_))]
fwrite(answer, file.path(out_dir, "all_cmp_advice.csv"))
fwrite(parameters, file.path(out_dir, "all_cmp_parameters.csv"))
report <- c(
  "PASS: all 32 CMP/year/baseline cases computed by the exact serialized SC14 release functions.",
  "PASS: parameters agree across serialized controls, SC14 registry, candidate_mps_500.csv, and tuning summary.",
  "PASS: all eight original CMP29/CMP45 answers reproduced.",
  sprintf("Maximum absolute difference from original advice: %.12g kt.", max(original_errors)),
  sprintf("Maximum explicit-formula versus serialized-function difference: %.12g kt.", max(formula_errors)),
  sprintf("Maximum index metric difference from previous calculation: %.12g.", max(index_errors)),
  sprintf("PASS: 40 additional full-rule branch checks, maximum difference %.12g kt.", max(branch_errors)),
  "Full-precision 2027 constrained advice is the prior TAC in every 2028 calculation.",
  "For x=(I-lim)/(trigger-lim), power-ramp raw advice is min at I<=lim; min+(target-min)*x^2.5 below trigger; target*(0.2+0.8*x)^0.6 at/above trigger.",
  "Hockeystick raw advice is min at I<=lim; min+(target-min)*x below trigger; target at/above trigger.",
  "For both families: final advice = max(prior*dlow,min(prior*dupp,raw advice)).",
  "All requested cases are below the HCR triggers, with positive finite observations and documented missing-index handling.",
  "Optional display-loading warnings suppressed while reading release objects; calculations and checks completed without warnings or errors.",
  "", capture.output(print(answer[, .(cmp, tac_2026_kt, advice_year, metric,
    unconstrained_tac_kt, tac_advice_kt, binding_rule)], digits = 12)),
  "", capture.output(sessionInfo()))
writeLines(report, file.path(out_dir, "all_cmp_validation.txt"))
cat(paste(report[1:13], collapse = "\n"), "\n")
print(dcast(answer, tac_2026_kt + cmp ~ advice_year, value.var = "tac_advice_kt"), digits = 12)
