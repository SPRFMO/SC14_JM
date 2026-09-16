#!/usr/bin/env Rscript
# Optional: copy this release's explicit assessment file set into a NEW folder.
# Rscript R/snapshot_assessment.R /path/to/jjm /path/to/new-snapshot
# Review a new snapshot before replacing the report's reviewed inputs.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop(
  "Use Rscript R/snapshot_assessment.R /path/to/jjm /path/to/new-snapshot", call. = FALSE)
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
root <- dirname(dirname(normalizePath(script)))
source <- normalizePath(file.path(args[1], "assessment"), mustWork = TRUE)
destination <- path.expand(args[2])
if (file.exists(destination) || dir.exists(destination)) stop("Choose a new, empty destination.")
dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
destination <- file.path(normalizePath(dirname(destination)), basename(destination))
if (startsWith(destination, paste0(dirname(source), "/"))) stop("Use a destination outside JJM.")
inventory <- read.csv(file.path(root, "data/input-checksums.csv"), stringsAsFactors = FALSE)
files <- sub("^data/assessment/", "", inventory$file[startsWith(inventory$file, "data/assessment/")])
stopifnot(length(files) > 0, all(file.exists(file.path(source, files))))
dir.create(destination)
for (file in files) {
  target <- file.path(destination, file)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  before <- digest::digest(file = file.path(source, file), algo = "sha256")
  stopifnot(file.copy(file.path(source, file), target))
  stopifnot(identical(before, digest::digest(file = target, algo = "sha256")),
            identical(before, digest::digest(file = file.path(source, file), algo = "sha256")))
}
# Check that each saved fit and retrospective is readable; no executable runs.
for (model in c("h1_1.06", "h2_1.06", "h1_1.06.ls", "h2_1.06.ls")) {
  fit <- jjmR::readJJM(model, path = file.path(destination, "config"),
    input = file.path(destination, "input"), output = file.path(destination, "results"))
  stopifnot(length(fit[[1]]$output) == if (startsWith(model, "h1")) 1L else 2L,
            identical(as.numeric(fit[[1]]$data$years), c(1970, 2026)))
}
for (file in files[grepl("\\.(RData|Rdat)$", files)]) {
  env <- new.env(parent = emptyenv())
  objects <- load(file.path(destination, file), envir = env)
  expected <- if (grepl("retrospective", file)) "output" else sub("\\.Rdat$", "", basename(file))
  stopifnot(expected %in% objects)
}
record <- data.frame(file = files, source = file.path(source, files),
  bytes = file.info(file.path(destination, files))$size,
  sha256 = vapply(file.path(destination, files), digest::digest, character(1),
                  algo = "sha256", file = TRUE))
write.csv(record, file.path(destination, "snapshot-checksums.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(destination, "R-session.txt"))
cat("Copied and checked", length(files), "files in", destination,
    "\nReview this candidate before updating the annex.\n")
