# Verify saved files against the human-readable inventory before every build.
check_packages <- function() {
  packages <- c("jjmR", "tidyverse", "flextable", "knitr", "scales", "rmarkdown",
                "digest", "xml2", "zip")
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop("Missing R packages: ", paste(missing, collapse = ", "),
    ". See README.md for installation.", call. = FALSE)
}

check_inputs <- function(root) {
  inventory <- read.csv(file.path(root, "data/input-checksums.csv"), stringsAsFactors = FALSE)
  stopifnot(nrow(inventory) > 0, !anyDuplicated(inventory$file))
  if (any(grepl("^/|(^|/)\\.\\.(/|$)", inventory$file))) stop("Non-relative inventory path.")
  paths <- file.path(root, inventory$file)
  missing <- inventory$file[!file.exists(paths)]
  if (length(missing)) stop("Missing inputs: ", paste(missing, collapse = ", "))
  hashes <- vapply(paths, digest::digest, character(1), algo = "sha256", file = TRUE)
  changed <- inventory$file[hashes != inventory$sha256 | file.info(paths)$size != inventory$bytes]
  if (length(changed)) stop("Input identity changed: ", paste(changed, collapse = ", "),
    ". Review and document the replacement before updating the inventory.", call. = FALSE)
  cat("PASS:", nrow(inventory), "saved input and archive checksums\n")
  invisible(inventory)
}
