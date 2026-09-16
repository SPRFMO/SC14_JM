#!/usr/bin/env Rscript
# From this folder: Rscript build.R [html|pdf|docx|all|check] [annex|guide|all]
# The default builds the annex and handover in HTML. No model is fitted here.
args <- commandArgs(trailingOnly = TRUE)
format <- if (length(args)) args[1] else "html"
document <- if (length(args) > 1) args[2] else "all"
if (length(args) > 2 || !format %in% c("html", "pdf", "docx", "all", "check") ||
    !document %in% c("annex", "guide", "all")) {
  stop("Use Rscript build.R [html|pdf|docx|all|check] [annex|guide|all]", call. = FALSE)
}
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
root <- dirname(normalizePath(script, mustWork = TRUE))
setwd(root)
source("R/check_inputs.R")
check_packages()
check_inputs(root)
source("R/risk_data.R")
dir.create("data/derived", showWarnings = FALSE)
risk <- calculate_risk(root)
write.csv(risk, "data/derived/risk-data.csv", row.names = FALSE)
if (format == "check") {
  cat("PASS: saved input hashes and all 180 risk records agree. No models were run.\n")
  quit(status = 0)
}
quarto <- Sys.which("quarto")
if (!nzchar(quarto)) stop("Install Quarto, then rerun this command.", call. = FALSE)
if (format %in% c("pdf", "all") && !nzchar(Sys.which("xelatex"))) {
  stop("PDF requires XeLaTeX. Use html or docx while installing LaTeX.", call. = FALSE)
}
source("R/format_docx.R")
formats <- if (format == "all") c("html", "pdf", "docx") else format
documents <- c(annex = "technical-annex", guide = "technology-transfer")
selected <- if (document == "all") documents else documents[document]
dir.create("output", showWarnings = FALSE)
dir.create("validation/logs", recursive = TRUE, showWarnings = FALSE)
writeLines(capture.output(sessionInfo()), "validation/R-session.txt")
products <- character()
for (name in selected) {
  for (to in formats) {
    cat("Building", paste0(name, ".", to), "\n")
    log <- file.path(root, "validation/logs", paste0(name, "-", to, ".log"))
    setwd(file.path(root, "report"))
    status <- system2(quarto, c("render", paste0(name, ".qmd"), "--to", to),
                      stdout = log, stderr = log)
    setwd(root)
    if (status != 0) {
      cat(tail(readLines(log, warn = FALSE), 50), sep = "\n")
      stop("Render failed; see ", log, call. = FALSE)
    }
    product <- file.path("output", paste0(name, ".", to))
    stopifnot(file.exists(product), file.info(product)$size > 0)
    if (to == "docx") format_docx(product)
    products <- c(products, product)
  }
}
# Relative data links point at the single authoritative data folder.
stopifnot(file.copy("report/HCR_2022_Annex_K.pdf", "output", overwrite = TRUE))
record <- data.frame(file = products,
  sha256 = vapply(products, digest::digest, character(1), algo = "sha256", file = TRUE),
  built_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  quarto = paste(system2(quarto, "--version", stdout = TRUE), collapse = " "),
  R = R.version.string)
# Keep records for previously built formats, with their own dates and hashes.
manifest <- "validation/build.csv"
if (file.exists(manifest)) {
  previous <- read.csv(manifest, stringsAsFactors = FALSE)
  record <- rbind(previous[!previous$file %in% products, ], record)
}
write.csv(record, manifest, row.names = FALSE)
cat("Finished:", paste(products, collapse = ", "), "\n")
