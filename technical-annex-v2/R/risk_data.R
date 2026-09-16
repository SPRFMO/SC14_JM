# The report files use $name headers followed by numeric rows.
# Read only the requested block, so textual metadata is never interpreted as data.
read_rep_block <- function(path, name) {
  lines <- readLines(path, warn = FALSE)
  headers <- which(startsWith(lines, "$"))
  i <- match(paste0("$", name), trimws(lines[headers]))
  if (is.na(i)) stop("Missing block ", name, " in ", path)
  first <- headers[i] + 1L
  last <- if (i == length(headers)) length(lines) else headers[i + 1L] - 1L
  block <- lines[seq.int(first, last)]
  block <- block[nzchar(trimws(block))]
  as.matrix(read.table(text = paste(block, collapse = "\n"), header = FALSE))
}

calculate_risk <- function(root) {
  assessment <- file.path(root, "data/assessment/results")
  projections <- file.path(root, "data/projections")
  labels <- c("1 × F2026", "0.75 × F2026", "1.25 × F2026",
              "FMSY scenario", "TAC scenario (supplied TAC)", "F = 0")
  rows <- list()
  for (hypothesis in c("h1", "h2")) {
    stocks <- if (hypothesis == "h1") 1L else 1:2
    for (stock in stocks) {
      base <- file.path(assessment, paste0(hypothesis, "_1.06_", stock, "_R.rep"))
      future <- file.path(projections, paste0(hypothesis, "_1.06.ls_", stock, "_R.rep"))
      annual <- read_rep_block(base, "msy_mt")
      reference_rows <- match(2017:2026, annual[, 1])
      stopifnot(!anyNA(reference_rows))
      # Column 10 is annual BMSY in kt. The base run supplies the fixed target.
      bmsy <- mean(annual[reference_rows, 10])
      for (scenario in c(6L, 2L, 1L, 3L, 4L, 5L)) {
        biomass <- read_rep_block(future, paste0("SSB_fut_", scenario))
        catch <- read_rep_block(future, paste0("Catch_fut_", scenario))
        stopifnot(identical(as.integer(biomass[, 1]), 2027:2036),
                  identical(as.integer(biomass[, 1]), as.integer(catch[, 1])), all(biomass[, 3] > 0),
                  all(is.finite(biomass)), all(is.finite(catch)))
        # Columns 2 and 3 are projected SSB and its ADMB standard error in kt.
        # BMSY is held fixed: these are annual conditional normal probabilities.
        probability <- 100 * pnorm(bmsy, mean = biomass[, 2], sd = biomass[, 3],
                                  lower.tail = FALSE)
        rows[[length(rows) + 1L]] <- data.frame(
          Hypothesis = hypothesis, Stock = stock, Scenario_ID = scenario,
          Scenario = labels[scenario], Year = as.integer(biomass[, 1]),
          SSB_kt = biomass[, 2], SSB_SE_kt = biomass[, 3], BMSY_kt = bmsy,
          Probability_above_percent = probability, Catch_kt = catch[, 2])
      }
    }
  }
  result <- do.call(rbind, rows)
  # Compare with the reviewed export rather than silently replacing its numbers.
  saved <- read.csv(file.path(projections, "risk-data.csv"), stringsAsFactors = FALSE)
  stopifnot(identical(dim(result), dim(saved)), identical(names(result), names(saved)))
  for (column in names(saved)) {
    if (is.numeric(saved[[column]])) {
      stopifnot(max(abs(result[[column]] - saved[[column]])) < 1e-9)
    } else stopifnot(identical(result[[column]], saved[[column]]))
  }
  result
}
