# Parse selectivity age columns directly: report columns 1 and 2 are source and year.
annex_selectivity <- function(mod, kind = c("fsh", "ind")) {
  kind <- match.arg(kind)
  data <- mod[[1]]$data
  control <- mod[[1]]$control
  ages <- seq(mod[[1]]$info$data$age[1], mod[[1]]$info$data$age[2])
  sources <- if (kind == "fsh") data$Fnames else data$Inames
  rows <- list()

  for (stock in seq_along(mod[[1]]$output)) {
    output <- mod[[1]]$output[[stock]]
    keys <- grep(paste0("^sel_", kind, "_[0-9]+$"), names(output), value = TRUE)
    for (key in keys) {
      number <- as.integer(sub(paste0("sel_", kind, "_"), "", key, fixed = TRUE))
      column <- if (kind == "fsh") number else data$Fnum + number
      if (control$SelMatrix[1, column] != stock) next

      values <- output[[key]]
      stopifnot(ncol(values) == length(ages) + 2)
      stock_name <- if (control$nStocks == 1) "Single stock" else
        c("South stock", "Far North stock")[stock]
      rows[[length(rows) + 1L]] <-
        as_tibble(values[, -c(1, 2), drop = FALSE], .name_repair = "minimal") |>
        setNames(as.character(ages)) |>
        mutate(Year = values[, 2], Source = sources[number], Stock = stock_name) |>
        pivot_longer(all_of(as.character(ages)), names_to = "Age", values_to = "Selectivity") |>
        mutate(Age = as.integer(Age))
    }
  }
  bind_rows(rows)
}

annex_selectivity_plot <- function(mod, kind) {
  ggplot(annex_selectivity(mod, kind), aes(Age, Selectivity, group = Year, colour = Year)) +
    geom_line(linewidth = 0.45, alpha = 0.65) +
    facet_wrap(vars(Stock, Source), scales = "free_y", ncol = 2) +
    scale_x_continuous(breaks = 1:12) +
    scale_colour_viridis_c(option = "C", breaks = c(1970, 1990, 2010, 2026)) +
    theme_bw() +
    labs(x = "Age (years; 12 is the plus group)", y = "Selectivity (relative)") +
    theme(legend.position = "bottom")
}
