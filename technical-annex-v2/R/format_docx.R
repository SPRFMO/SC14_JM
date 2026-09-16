# Preserve the existing page-fit rules using R's xml2 and zip packages.
# This changes layout only, after Quarto has written the Word document.
format_docx <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  temp <- tempfile("annex-word-")
  dir.create(temp)
  on.exit(unlink(temp, recursive = TRUE), add = TRUE)
  unzip(path, exdir = temp)
  document <- file.path(temp, "word/document.xml")
  xml <- xml2::read_xml(document)
  ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
          wp = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
          a = "http://schemas.openxmlformats.org/drawingml/2006/main")
  ensure <- function(parent, tag, first = FALSE) {
    node <- xml2::xml_find_first(parent, paste0("./w:", tag), ns)
    if (inherits(node, "xml_missing")) {
      fragment <- xml2::read_xml(sprintf('<w:%s xmlns:w="%s"/>', tag, ns[["w"]]))
      node <- if (first) xml2::xml_add_child(parent, fragment, .where = 0) else
        xml2::xml_add_child(parent, fragment)
    }
    node
  }
  for (table in xml2::xml_find_all(xml, ".//w:tbl", ns)) {
    properties <- ensure(table, "tblPr", first = TRUE)
    borders <- ensure(properties, "tblBorders")
    xml2::xml_remove(xml2::xml_children(borders))
    for (side in c("top", "left", "bottom", "right", "insideH", "insideV")) {
      border <- ensure(borders, side)
      # Set attributes individually: replacing all attributes also removes a
      # locally declared namespace in xml2, making Word ignore the borders.
      xml2::xml_set_attr(border, "w:val", "single", ns)
      xml2::xml_set_attr(border, "w:sz", "4", ns)
      xml2::xml_set_attr(border, "w:color", "D9D9D9", ns)
    }
    for (row in xml2::xml_find_all(table, "./w:tr", ns)) {
      ensure(ensure(row, "trPr", first = TRUE), "cantSplit")
    }
  }
  for (drawing in xml2::xml_find_all(xml, ".//wp:inline", ns)) {
    extent <- xml2::xml_find_first(drawing, "./wp:extent", ns)
    if (inherits(extent, "xml_missing")) next
    size <- as.numeric(xml2::xml_attrs(extent)[c("cx", "cy")])
    scale <- min(1, 6.3 * 914400 / size[1], 8 * 914400 / size[2])
    if (scale < 1) {
      attributes <- setNames(as.character(round(size * scale)), c("cx", "cy"))
      xml2::xml_set_attrs(extent, attributes)
      for (inner in xml2::xml_find_all(drawing, ".//a:xfrm/a:ext", ns)) {
        xml2::xml_set_attrs(inner, attributes)
      }
    }
  }
  xml2::write_xml(xml, document)
  zip::zipr(path, list.files(temp, all.files = TRUE, no.. = TRUE), root = temp)
}
