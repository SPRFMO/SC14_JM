# Quarto embeds displayed images but can leave local figure-zoom links behind.
# Reuse the embedded image for each zoom link, keeping a single portable HTML file.
embed_lightbox <- function(path) {
  text <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  html <- xml2::read_html(text)
  links <- xml2::xml_find_all(html,
    '//a[contains(concat(" ", @class, " "), " lightbox ")][img]')
  for (link in links) {
    href <- xml2::xml_attr(link, "href")
    image <- xml2::xml_attr(xml2::xml_find_first(link, "./img"), "src")
    if (is.na(image) || !startsWith(image, "data:image/")) {
      stop("Figure zoom requires an embedded image: ", href, call. = FALSE)
    }
    # Edit only the href attribute; preserve the rest of the rendered bytes.
    text <- gsub(paste0('href="', href, '"'), paste0('href="', image, '"'),
                 text, fixed = TRUE)
  }
  text <- gsub("[ \t]+\n", "\n", text)
  writeBin(charToRaw(text), path)
  invisible(length(links))
}
