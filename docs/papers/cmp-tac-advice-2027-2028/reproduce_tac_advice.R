# Portable reproduction using base R only.
# Download this script, all_cmp_parameters.csv, all_cmp_advice.csv, and
# index_inputs_and_standardization.csv into one folder, then run:
# Rscript reproduce_tac_advice.R
# Calculated reference means and standardized columns are rebuilt from observed
# values, rather than taken from the precomputed columns in the input CSV.

options(warn = 2)
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
folder <- if (length(script)) dirname(normalizePath(script)) else getwd()
read <- function(name) read.csv(file.path(folder, name), stringsAsFactors = FALSE)
inputs <- read('index_inputs_and_standardization.csv')
parameters <- read('all_cmp_parameters.csv')
published <- read('all_cmp_advice.csv')
reference <- tapply(inputs$observed[inputs$year %in% 2019:2023],
                    inputs$index[inputs$year %in% 2019:2023], mean, na.rm = TRUE)
inputs$standardized_rebuilt <- inputs$observed / reference[inputs$index]
annual <- tapply(inputs$standardized_rebuilt, inputs$year, mean, na.rm = TRUE)
metric <- sapply(2025:2026, function(y) mean(annual[as.character((y-2):y)]))
answer <- list()
for (i in seq_len(nrow(parameters))) {
  p <- parameters[i, ]
  for (baseline in c(1675, 1092)) {
    prior <- baseline
    for (j in 1:2) {
      indicator <- metric[j]
      x <- (indicator - p$lim) / ifelse(p$trigger == p$lim, 1e-6, p$trigger - p$lim)
      raw <- if (indicator <= p$lim) p$min else if (indicator < p$trigger) {
        p$min + (p$target-p$min) * x^p$power_between
      } else if (p$hcr == 'hockeystick.hcr') p$target else {
        p$target * (p$above_offset + p$above_scale*x)^p$power_above
      }
      advice <- max(prior*p$dlow, min(prior*p$dupp, raw))
      answer[[length(answer)+1L]] <- data.frame(cmp=p$cmp, tac_2026_kt=baseline,
        advice_year=2026+j, data_through=2024+j, metric=indicator,
        prior_tac_kt=prior, unconstrained_tac_kt=raw,
        lower_limit_kt=prior*p$dlow, upper_limit_kt=prior*p$dupp,
        tac_advice_kt=advice)
      prior <- advice
    }
  }
}
answer <- do.call(rbind, answer)
check <- merge(answer, published, by=c('cmp','tac_2026_kt','advice_year'))
stopifnot(nrow(check) == 32L,
          max(abs(check$tac_advice_kt.x-check$tac_advice_kt.y)) < 1e-8)
print(answer, row.names=FALSE)
cat('PASS: all 32 TAC results reproduce from the downloaded observations and parameters.\n')
