# Format native tables consistently in PDF and Word without changing their values.
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
flextable::set_flextable_defaults(font.family="Arial", font.size=8.5,
  padding=2, split=FALSE, border.color="#D9D9D9", border.width=0.5,
  post_process_docx=annex_table_layout, post_process_pdf=annex_table_layout)
