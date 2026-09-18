#!/usr/bin/env Rscript
# Copy the reviewed annex into the wiki's docs tree. No rendering or model runs.
# Run from any directory: Rscript technical-annex-v2/R/sync_wiki.R
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
annex <- dirname(dirname(normalizePath(script, mustWork = TRUE)))
repo <- dirname(annex)
destination <- file.path(repo, "docs", "technical-annex-v2")
stopifnot(file.exists(file.path(repo, "content", "technical-annex.md")))
source(file.path(annex, "R", "check_inputs.R"))
check_inputs(annex)

products <- read.csv(file.path(annex, "validation", "build.csv"), stringsAsFactors = FALSE)
expected <- file.path("output", as.vector(outer(
  c("technical-annex", "technology-transfer"), c("html", "pdf", "docx"), paste, sep = ".")))
stopifnot(setequal(products$file, expected), !anyDuplicated(products$file))
hash <- function(path) digest::digest(file = path, algo = "sha256")
actual <- vapply(file.path(annex, products$file), hash, character(1))
if (!all(actual == products$sha256)) stop("A rendered annex product differs from its build record.")

# Keep this directory layout: the HTML links to ../data/projections/.
files <- sort(c(expected, "output/HCR_2022_Annex_K.pdf",
  file.path("data/projections", list.files(file.path(annex, "data/projections")))))
records <- list()
for (file in files) {
  original <- file.path(annex, file)
  target <- file.path(destination, file)
  dir.create(dirname(target), showWarnings = FALSE, recursive = TRUE)
  if (endsWith(file, ".html")) {
    text <- rawToChar(readBin(original, "raw", n = file.info(original)$size))
    stopifnot(grepl("<body", text, fixed = TRUE), !grepl("annex-wiki-nav", text, fixed = TRUE))
    label <- if (basename(file) == "technical-annex.html") "Assessment report" else "Analyst handover"
    navigation <- paste0(
      '<!-- annex-wiki-navigation:start -->\n',
      '<nav class="annex-wiki-nav" aria-label="Wiki navigation" ',
      'style="background:#173f60;color:white;padding:.75rem 1.25rem;font:16px/1.5 system-ui,sans-serif">',
      '<a style="color:white" href="../../index.html">Jack mackerel wiki</a>',
      ' <span aria-hidden="true"> / </span> ',
      '<a style="color:white" href="../../technical-annex.html">Technical annex</a>',
      ' <span aria-hidden="true"> / </span> ',
      '<span aria-current="page">', label, '</span></nav>\n',
      '<!-- annex-wiki-navigation:end -->')
    hosted <- sub("(<body[^>]*>)", paste0("\\1\n", navigation), text)
    # Removing only the added navigation must recover the original bytes.
    stopifnot(identical(gsub(paste0("\n", navigation), "", hosted, fixed = TRUE), text))
    writeBin(charToRaw(hosted), target)
  } else {
    stopifnot(file.copy(original, target, overwrite = TRUE), identical(hash(original), hash(target)))
  }
  records[[length(records) + 1L]] <- data.frame(
    source = file.path("technical-annex-v2", file),
    published = file.path("technical-annex-v2", file),
    source_sha256 = hash(original), published_sha256 = hash(target),
    change = if (endsWith(file, ".html")) "Wiki navigation added; original document preserved" else "Exact copy")
}
write.csv(do.call(rbind, records), file.path(destination, "publication.csv"), row.names = FALSE)
cat("Synchronized", length(files), "annex files into docs/technical-annex-v2.\n")
