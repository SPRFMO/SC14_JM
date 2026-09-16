# Read the saved assessment products and derive report summaries.
# This script performs report calculations; fitted model outputs are inputs.
read_annex_model <- function(model) {
  readJJM(model, path = file.path(assessment_dir, "config"), input = file.path(assessment_dir, "input"), output = file.path(assessment_dir, "results"))
}
h1_mod <- read_annex_model(h1nm)
h2_mod <- read_annex_model(h2nm)
h1_mod_ls <- read_annex_model(paste0(h1nm, ".ls"))
h2_mod_ls <- read_annex_model(paste0(h2nm, ".ls"))
grDevices::pdf(NULL)
h1_diag <- diagnostics(h1_mod, plots = FALSE)
h2_diag <- diagnostics(h2_mod, plots = FALSE)
source(file.path(report_dir, "..", "R", "figure_keys.R"), local = TRUE)
h1_diag <- annex_figure_keys(h1_diag)
h2_diag <- annex_figure_keys(h2_diag)
bmsy_diag_h1 <- diagnostics(fixed_bmsy(h1_mod), plots = FALSE)
bmsy_diag_h2 <- diagnostics(fixed_bmsy(h2_mod), plots = FALSE)
invisible(grDevices::dev.off())
read_retrospective <- function(model) {
  env <- new.env(parent = emptyenv())
  load(file.path(assessment_dir, "results", paste0(model, "_retrospective.RData")), envir = env)
  env$output
}
h1_ret <- h1_retro <- read_retrospective(h1nm)
h2_ret <- h2_retro <- read_retrospective(h2nm)
get_rho <- function(retro, stock, var, year_offset = 0L, digits = 2) {
  series <- retro[[stock]][[var]]
  deviations <- vapply(1:5, function(peel) {
    row <- match(curryr + year_offset - peel, series$time)
    stopifnot(!is.na(row))
    (series$var[row, 1, peel + 1] - series$var[row, 1, 1]) /
      series$var[row, 1, 1]
  }, numeric(1))
  value <- mean(deviations)
  if (is.null(digits)) value else round(value, digits)
}
h1_mohn_ssb <- get_rho(h1_ret, "Stock_1", "SSB")
h1_mohn_rec <- get_rho(h1_ret, "Stock_1", "R")
h2_mohn_ssb_s1 <- get_rho(h2_ret, "Stock_1", "SSB")
h2_mohn_ssb_s2 <- get_rho(h2_ret, "Stock_2", "SSB")
h2_mohn_rec_s1 <- get_rho(h2_ret, "Stock_1", "R")
h2_mohn_rec_s2 <- get_rho(h2_ret, "Stock_2", "R")
# jjmR figure titles use the last saved SSB row, one year beyond each fit.
h1_mohn_ssb_endpoint <- signif(get_rho(h1_ret, "Stock_1", "SSB", 1L, NULL), 2)
h2_mohn_ssb_endpoint_s1 <- signif(get_rho(h2_ret, "Stock_1", "SSB", 1L, NULL), 2)
h2_mohn_ssb_endpoint_s2 <- signif(get_rho(h2_ret, "Stock_2", "SSB", 1L, NULL), 2)
status_rows <- list()
for (hyp in c("h1", "h2")) {
  model <- if (hyp == "h1") h1_mod[[1]] else h2_mod[[1]]
  stopifnot(identical(as.numeric(model$data$years), c(1970, 2026)))
  for (stock in seq_along(model$output)) {
    x <- model$output[[stock]]$msy_mt
    stopifnot(identical(as.numeric(tail(x[, 1], 10)), as.numeric(2017:2026)))
    now <- x[x[, 1] == curryr, ]
    previous <- x[x[, 1] == curryr - 1, ]
    bmsy <- mean(tail(x[, 10], 10))
    status_rows[[length(status_rows) + 1]] <- tibble(
      Model = paste0(hyp, "_", finmodname),
      Component = if (hyp == "h1") "Single stock" else c("South", "Far North")[stock],
      `SSB 2025 (Mt)` = previous[12] / 1000,
      `SSB 2026 (Mt)` = now[12] / 1000,
      `Mean BMSY (Mt)` = bmsy / 1000,
      `SSB / mean BMSY` = now[12] / bmsy,
      `F / FMSY` = now[4]
    )
  }
}
status_table <- bind_rows(status_rows)

# Small, open tables for readers who prefer CSV to R objects.
derived_dir <- file.path(report_dir, "..", "data", "derived")
dir.create(derived_dir, showWarnings = FALSE, recursive = TRUE)
write.csv(status_table, file.path(derived_dir, "status-2026.csv"), row.names = FALSE)
write.csv(h1_mod[[1]]$data$Fcaton, file.path(derived_dir, "catch-by-fleet-kt.csv"))
saveRDS(list(h1=h1_mod,h2=h2_mod,h1_precautionary=h1_mod_ls,h2_precautionary=h2_mod_ls), file.path(derived_dir,"assessment-objects.rds"), compress="xz")
