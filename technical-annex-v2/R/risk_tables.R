# Prepare the three risk tables from the checked annual probabilities.
risk_years <- c(2028L, 2031L, 2036L)
risk_catch_years <- c(2027L, 2028L)
risk_scenario_order <- c(6L, 2L, 1L, 3L, 4L, 5L)
risk_data <- calculate_risk(normalizePath(file.path(report_dir, "..")))
write.csv(risk_data, file.path(derived_dir, "risk-data.csv"), row.names = FALSE)
stopifnot(nrow(risk_data) == 180L, all(risk_data$SSB_SE_kt > 0),
          max(abs(risk_data$Probability_above_percent - 100 * pnorm(
            risk_data$BMSY_kt, risk_data$SSB_kt, risk_data$SSB_SE_kt,
            lower.tail = FALSE))) < 1e-10,
          all(risk_data$Probability_above_percent >= 0 &
              risk_data$Probability_above_percent <= 100))
for (hyp in c("h1", "h2")) {
  base <- if (hyp == "h1") h1_mod else h2_mod
  for (stock in seq_along(base[[1]]$output)) {
    ref <- base[[1]]$output[[stock]]$msy_mt
    threshold <- mean(ref[match(2017:2026, ref[, 1]), 10])
    x <- filter(risk_data, Hypothesis == hyp, Stock == stock)
    stopifnot(all(abs(x$BMSY_kt - threshold) < 1e-8),
              all(table(x$Scenario_ID) == 10), setequal(x$Year, 2027:2036))
  }
}
risk_display_data <- function(hyp, stock) {
  x <- risk_data |> filter(Hypothesis == hyp, Stock == stock)
  biomass <- x |> filter(Year %in% risk_years) |>
    select(Scenario_ID, Scenario, Year, SSB_kt, Probability_above_percent) |>
    mutate(SSB_kt = round(SSB_kt),
           Probability_above_percent = case_when(
             Probability_above_percent < 1 ~ "<1",
             Probability_above_percent > 99 ~ ">99",
             TRUE ~ as.character(round(Probability_above_percent)))) |>
    pivot_wider(names_from = Year, values_from = c(SSB_kt, Probability_above_percent),
                names_vary = "slowest")
  catches <- x |> filter(Year %in% risk_catch_years) |>
    select(Scenario_ID, Year, Catch_kt) |> mutate(Catch_kt = round(Catch_kt)) |>
    pivot_wider(names_from = Year, values_from = Catch_kt, names_prefix = "Catch_")
  biomass |> left_join(catches, by = "Scenario_ID") |>
    arrange(match(Scenario_ID, risk_scenario_order)) |> select(-Scenario_ID)
}
risk_table <- function(hyp, stock) {
  risk_display_data(hyp, stock) |> flextable() |>
    set_header_labels(Scenario = "Fishing scenario",
      SSB_kt_2028 = "B 2028", Probability_above_percent_2028 = "P(B > Bmsy) in 2028",
      SSB_kt_2031 = "B 2031", Probability_above_percent_2031 = "P(B > Bmsy) in 2031",
      SSB_kt_2036 = "B 2036", Probability_above_percent_2036 = "P(B > Bmsy) in 2036",
      Catch_2027 = "Catch 2027", Catch_2028 = "Catch 2028") |>
    compose(j = "Probability_above_percent_2028", part = "header",
      value = as_paragraph(as_chunk("P(B > B"), as_sub("msy"), as_chunk(") in 2028"))) |>
    compose(j = "Probability_above_percent_2031", part = "header",
      value = as_paragraph(as_chunk("P(B > B"), as_sub("msy"), as_chunk(") in 2031"))) |>
    compose(j = "Probability_above_percent_2036", part = "header",
      value = as_paragraph(as_chunk("P(B > B"), as_sub("msy"), as_chunk(") in 2036"))) |>
    colformat_double(j = c("SSB_kt_2028", "SSB_kt_2031", "SSB_kt_2036", "Catch_2027", "Catch_2028"), digits = 0) |>
    fontsize(size = 9, part = "all") |> autofit()
}
