# Shared native table formatting; format-specific wrappers control page layout.
annex_table_layout <- function(x) {
  x <- flextable::fontsize(x, size=8.5, part="all")
  x <- flextable::padding(x, padding=2, part="all")
  x <- flextable::border_outer(x, border=officer::fp_border(color="#D9D9D9",width=0.5))
  x <- flextable::border_inner(x, border=officer::fp_border(color="#D9D9D9",width=0.5))
  years <- intersect(c("Year", "year", "yr"), x$col_keys)
  if (length(years)) x <- flextable::colformat_double(x, j=years, big.mark="", digits=0)
  x <- flextable::autofit(x)
  widths <- flextable::dim_pretty(x)$widths
  numeric_cols <- vapply(x$body$dataset[x$col_keys],is.numeric,logical(1))
  x <- flextable::align(x, align="left", part="body")
  if (any(numeric_cols)) {
    x <- flextable::align(x, j=x$col_keys[numeric_cols], align="right", part="body")
  }
  widths[numeric_cols] <- pmax(0.38, pmin(widths[numeric_cols],0.80))
  widths[!numeric_cols] <- pmax(0.65, pmin(widths[!numeric_cols],2.0))
  if (length(years)) widths[x$col_keys %in% years] <- 0.50
  widths <- widths * min(1, 6.3/sum(widths))
  # Risk probabilities are character labels (<1, >99); give all eight
  # result columns enough width for five-digit biomass values with commas.
  if ("Scenario" %in% x$col_keys && any(startsWith(x$col_keys, "SSB_kt_"))) {
    result_cols <- setdiff(x$col_keys, "Scenario")
    widths <- ifelse(x$col_keys == "Scenario", 1.35, (6.3-1.35)/length(result_cols))
    x <- flextable::align(x, j=result_cols, align="right", part="body")
  }
  if (setequal(x$col_keys, c("Source", "Type", "Catch", "Index", "Age", "Length"))) {
    coverage_widths <- c(Source=1.30, Type=0.58, Catch=0.65,
                         Index=1.40, Age=1.55, Length=0.82)
    widths <- unname(coverage_widths[x$col_keys])
  }
  if (identical(x$col_keys, c("Model", "Description"))) {
    widths <- c(0.75, 5.55)
  }
  x <- flextable::width(x, j=x$col_keys, width=widths)
  flextable::set_table_properties(x, layout="fixed",
    opts_word=list(split=FALSE, repeat_headers=TRUE),
    opts_pdf=list(fonts_ignore=TRUE, caption_repeat=TRUE))
}

# A4 with 20 mm margins: match report/_quarto.yml. Reserve LaTeX cell
# gutters and border widths before distributing the printable width.
annex_pdf_table_layout <- function(x) {
  x <- annex_table_layout(x)
  n <- length(x$col_keys)
  tabcolsep <- 1
  border_width <- 0.5
  available <- (210 - 2 * 20) / 25.4 -
    (2 * n * tabcolsep + (n + 1) * border_width) / 72.27
  widths <- x$body$colwidths
  widths <- floor(100 * available * widths / sum(widths)) / 100
  # flextable emits widths to two decimal places in LaTeX; round down so
  # many-column tables cannot extend beyond the page through rounding.
  widest <- which.max(widths)
  widths[widest] <- widths[widest] + floor(100 * (available - sum(widths))) / 100
  x <- flextable::width(x, j=x$col_keys, width=widths)
  x <- flextable::padding(x, padding.top=0, padding.bottom=0, part="all")
  x <- flextable::line_spacing(x, space=1, part="all")
  flextable::set_table_properties(x, layout="fixed",
    opts_pdf=list(fonts_ignore=TRUE, caption_repeat=TRUE,
                  tabcolsep=tabcolsep, arraystretch=1))
}

# Let the browser allocate columns by their content across the full text
# area. The CSS keeps wide tables scrollable on small screens.
annex_html_table_layout <- function(x) {
  if (identical(x$col_keys, c("Model", "Description"))) {
    return(flextable::set_table_properties(x, layout="autofit", width=1,
      opts_html=list(extra_class="annex-table", extra_css=paste(
        ".annex-table th:first-child, .annex-table td:first-child",
        "{ width:12%; white-space:nowrap; }"))))
  }
  flextable::set_table_properties(x, layout="autofit", width=1,
    opts_html=list(extra_class="annex-table"))
}

flextable::set_flextable_defaults(font.family="Arial", font.size=8.5,
  padding=2, split=FALSE, border.color="#D9D9D9", border.width=0.5,
  post_process_docx=annex_table_layout, post_process_pdf=annex_pdf_table_layout,
  post_process_html=annex_html_table_layout)
