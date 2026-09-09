# CatchDrop20 is retained as an identifier; its definition is advice cuts >19%.
# HCR advice is measured before implementation. Do not substitute realized catch.
advice_drop_events <- function(advice) {
  x <- data.table::copy(data.table::as.data.table(advice))
  stopifnot(all(c('mp','iter','year','advice') %in% names(x)),
    !anyDuplicated(x[, .(mp,iter,year)]))
  data.table::setorder(x,mp,iter,year)
  x[, `:=`(previous_advice=data.table::shift(advice),
    previous_year=data.table::shift(year)), by=.(mp,iter)]
  x[, exclusion := data.table::fcase(is.na(previous_year), 'no_previous_advice',
    year != previous_year+1L, 'nonconsecutive_year',
    !is.finite(advice) | advice<0 | !is.finite(previous_advice) |
      previous_advice<=0, 'missing_or_invalid', default='none')]
  x[, reduction := 1-advice/previous_advice]
  # Ratio form makes exact 19% equality a non-event; 20% reductions count.
  x[, flag := data.table::fifelse(exclusion=='none',
    as.integer(advice < .81*previous_advice), NA_integer_)]
  x
}
extract_advice_events <- function(run, code) {
  t <- data.table::as.data.table(mse::tracking(run))
  t <- t[metric=='hcr',.(mp=code,advice_stock=as.character(biol),
    iter=as.integer(iter),year=as.integer(year),advice=data)]
  stopifnot(nrow(t)>0, data.table::uniqueN(t$advice_stock)==1L)
  lag <- mse::args(run)$management_lag
  stopifnot(length(lag)==1L,is.finite(lag))
  t[, application_year:=year+as.integer(lag)]
  advice_drop_events(t)
}
summarize_advice_events <- function(x) {
  x[,.(events=sum(flag,na.rm=TRUE),valid_comparisons=sum(!is.na(flag)),
    available_records=.N,iterations=data.table::uniqueN(iter),
    first_advice_year=min(year),last_advice_year=max(year),
    first_comparison_year=min(year[!is.na(flag)]),
    last_comparison_year=max(year[!is.na(flag)]),
    advice_stock=unique(advice_stock)),by=mp][,
      raw_value:=data.table::fifelse(valid_comparisons>0,
        events/valid_comparisons,NA_real_)]
}
