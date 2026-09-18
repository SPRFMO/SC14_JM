# Publication checks; accepts the SC14_JM checkout as its sole argument.
repo <- normalizePath(commandArgs(trailingOnly = TRUE)[1], mustWork = TRUE)
docs <- file.path(repo, "docs")
library(xml2)
record <- read.csv(file.path(docs, "technical-annex-v2/publication.csv"), stringsAsFactors = FALSE)
hash <- function(f) digest::digest(file = f, algo = "sha256")
stopifnot(nrow(record) == 21L,
  all(vapply(file.path(repo, record$source), hash, character(1)) == record$source_sha256),
  all(vapply(file.path(docs, record$published), hash, character(1)) == record$published_sha256))
for (f in record$source[endsWith(record$source, ".html")]) {
  original <- read_html(file.path(repo, f))
  hosted <- read_html(file.path(docs, f))
  stopifnot(identical(as.character(xml_find_first(original, "//main")),
                      as.character(xml_find_first(hosted, "//main"))))
  stopifnot(length(xml_find_all(hosted, '//nav[@aria-label="Wiki navigation"]')) == 1L)
}

files <- c(paste0(tools::file_path_sans_ext(list.files(file.path(repo, "content"), "\\.md$")), ".html"),
           record$published[endsWith(record$published, ".html")])
parsed <- new.env(parent = emptyenv())
get_document <- function(path) {
  if (!exists(path, envir = parsed, inherits = FALSE)) assign(path, read_html(path), envir = parsed)
  get(path, envir = parsed, inherits = FALSE)
}
links_checked <- 0L
for (f in files) {
  path <- file.path(docs, f)
  html <- get_document(path)
  links <- unique(c(xml_attr(xml_find_all(html, '//a[@href]|//link[@href]'), 'href'),
                    xml_attr(xml_find_all(html, '//*[@src]'), 'src')))
  links <- links[!is.na(links) & !grepl('^([[:alpha:]][[:alnum:]+.-]*:|//)', links)]
  for (url in links) {
    relative <- URLdecode(sub('[?#].*$', '', url))
    target <- if (!nzchar(relative)) path else file.path(dirname(path), relative)
    stopifnot(file.exists(target))
    if (grepl('#', url, fixed = TRUE) && endsWith(target, '.html')) {
      fragment <- URLdecode(sub('^[^#]*#', '', url))
      if (nzchar(fragment)) stopifnot(fragment %in% xml_attr(xml_find_all(get_document(target), '//*[@id]'), 'id'))
    }
    links_checked <- links_checked + 1L
  }
  if (dirname(f) == '.') {
    navigation <- xml_attr(xml_find_all(html, '//nav[@aria-label="Wiki pages"]/a'), 'href')
    stopifnot(match('technical-annex.html', navigation) == match('sources.html', navigation) + 1L,
              match('technical-annex.html', navigation) < match('contributing.html', navigation))
  }
}
cat('PASS: 21 publication hashes; both report bodies unchanged; navigation order; ',
    links_checked, ' local links and fragments across ', length(files), ' pages.\n', sep = '')
