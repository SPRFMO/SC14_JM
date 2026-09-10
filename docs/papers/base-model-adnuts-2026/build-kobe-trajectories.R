#!/usr/bin/env Rscript
# Build 100 matched, retained-draw Kobe trajectories for 2007--2026.
# Usage: Rscript build-kobe-trajectories.R [run_root] [supplemented_mceval]
# To prepare the selection and extract original quantities only, pass --extract-only
# as the second argument. The supplemented evaluator uses the 100 PSV records in
# selection-manifest.csv order and adds FMSYy and FFMSYy immediately after the
# frozen template's existing get_msy_robust(i) call. No sampling is repeated.
.libPaths(c('/Users/jim/Library/R/4.6/library', .libPaths()))
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

make_selection <- function() {
  RNGkind('Mersenne-Twister', 'Inversion', 'Rejection')
  set.seed(20260910)
  selected <- rbindlist(lapply(1:3, function(ch) {
    data.table(chain = ch,
               retained_iteration = sort(sample.int(1000, c(33L, 33L, 34L)[ch])))
  }))
  selected[, pooled_draw := (chain - 1L) * 1000L + retained_iteration]
  setorder(selected, pooled_draw)
  selected[, `:=`(simulation_id = sprintf('draw-%03d', .I),
                  evaluation_draw_id = .I,
                  sampler_iteration = retained_iteration + 1000L,
                  selection_seed = 20260910L)]
  setcolorder(selected, c('simulation_id', 'evaluation_draw_id', 'pooled_draw',
                         'chain', 'retained_iteration', 'sampler_iteration',
                         'selection_seed'))
  selected
}

read_selected <- function(path, ids, types, expected_draws) {
  con <- file(path, open = 'rt')
  on.exit(close(con))
  header <- trimws(readLines(con, n = 1L, warn = FALSE))
  if (!identical(header, 'mcdraw type Year Age value')) {
    stop('Unexpected native header: ', header)
  }
  retained <- list()
  records <- 0L
  block <- 0L
  seen <- integer()
  repeat {
    lines <- readLines(con, n = 200000L, warn = FALSE)
    if (!length(lines)) break
    block <- block + 1L
    part <- fread(text = paste(lines, collapse = '\n'), header = FALSE,
                  col.names = c('mcdraw', 'type', 'unit', 'year', 'age', 'value'),
                  colClasses = c('integer', 'character', 'integer', 'character',
                                 'character', 'numeric'), showProgress = FALSE)
    if (ncol(part) != 6L || anyNA(part$mcdraw) || anyNA(part$unit) ||
        any(part$mcdraw < 1L | part$mcdraw > expected_draws)) {
      stop('Malformed native output in block ', block)
    }
    seen <- union(seen, unique(part$mcdraw))
    retained[[block]] <- part[mcdraw %in% ids & type %chin% types &
                               year %chin% as.character(2007:2026)]
    records <- records + nrow(part)
    if (block %% 25L == 0L) message('Read ', format(records, big.mark = ','), ' records')
  }
  if (!identical(sort(seen), seq_len(expected_draws))) stop('Incomplete draw IDs')
  d <- rbindlist(retained)
  d[, year := as.integer(year)]
  if (anyNA(d$year) || any(!is.finite(d$value)) || any(d$value < 0)) {
    stop('Invalid selected model quantities')
  }
  if (anyDuplicated(d, by = c('mcdraw', 'type', 'unit', 'year', 'age'))) {
    stop('Duplicate selected quantity')
  }
  setattr(d, 'records_read', records)
  d
}

validate_fields <- function(raw, ids, include_fmsy = FALSE) {
  scalar_types <- c('SSB', 'SBMSYy', if (include_fmsy) c('FMSYy', 'FFMSYy'))
  for (kind in scalar_types) {
    x <- raw[type == kind]
    stopifnot(nrow(x) == length(ids) * 20L, identical(sort(unique(x$unit)), 1L),
              identical(sort(unique(x$year)), 2007:2026),
              identical(sort(unique(x$mcdraw)), sort(ids)), all(x$age == 'all'))
  }
  x <- raw[type == 'F_faa']
  stopifnot(nrow(x) == length(ids) * 20L * 4L * 12L,
            identical(sort(unique(x$unit)), 1:4),
            identical(sort(as.integer(unique(x$age))), 1:12),
            identical(sort(unique(x$year)), 2007:2026),
            identical(sort(unique(x$mcdraw)), sort(ids)))
  stopifnot(all(x[, .N, by = .(mcdraw, year, unit)]$N == 12L))
  invisible(TRUE)
}

write_interactive <- function(d, med, lim, file) {
  if (!requireNamespace('plotly', quietly = TRUE) ||
      !requireNamespace('htmlwidgets', quietly = TRUE)) return(FALSE)
  p <- plotly::plot_ly(height = 830)
  n <- uniqueN(d$simulation_id)
  path_names <- unique(d$simulation_id)
  for (s in path_names) {
    x <- d[simulation_id == s]
    hover <- sprintf(paste0('%s | pooled draw %d<br>Chain %d, retained iteration %d',
                            '<br>Year %d<br>SSB / SSBMSY: %.3f<br>F / FMSY: %.3f',
                            '<br>SSB: %.1f kt<br>F: %.4f per year',
                            '<br>SSBMSY (2017-2026 mean): %.1f kt',
                            '<br>Annual FMSY: %.4f per year'),
                      x$simulation_id, x$pooled_draw, x$chain, x$retained_iteration,
                      x$year, x$ssb_over_ssbmsy, x$f_over_fmsy, x$ssb_kt,
                      x$f_mean_all_ages_per_year, x$ssbmsy_reference_kt,
                      x$fmsy_year_per_year)
    p <- plotly::add_trace(p, x = x$ssb_over_ssbmsy, y = x$f_over_fmsy,
                           type = 'scatter', mode = 'lines+markers',
                           name = s, text = hover, hoverinfo = 'text',
                           line = list(color = 'rgba(65,85,105,0.25)', width = 1),
                           marker = list(color = 'rgba(65,85,105,0.3)', size = 3),
                           showlegend = FALSE)
  }
  p <- plotly::add_trace(p, x = med$ssb_over_ssbmsy, y = med$f_over_fmsy,
                         type = 'scatter', mode = 'lines+markers',
                         name = 'Median of selected draws',
                         text = sprintf('Selected-draw coordinate-wise median<br>Year %d<br>SSB / SSBMSY: %.3f<br>F / FMSY: %.3f',
                                        med$year, med$ssb_over_ssbmsy, med$f_over_fmsy),
                         hoverinfo = 'text', line = list(color = '#123E67', width = 3),
                         marker = list(color = '#123E67', size = 6), showlegend = FALSE)
  labelled <- med[year %in% c(2007L, 2010L, 2015L, 2020L)]
  p <- plotly::add_trace(p, x = labelled$ssb_over_ssbmsy,
                         y = labelled$f_over_fmsy, text = labelled$year,
                         type = 'scatter', mode = 'text', name = 'Median years',
                         textposition = 'top right', hoverinfo = 'skip',
                         textfont = list(color = '#123E67', size = 12),
                         showlegend = FALSE)
  buttons <- c(list(list(label = 'All 100 paths', method = 'restyle',
                         args = list('visible', as.list(rep(TRUE, n + 2L))))),
               lapply(seq_len(n), function(i) {
                 list(label = sprintf('%s | chain %d, retained %d', path_names[i],
                                      d[simulation_id == path_names[i], chain][1],
                                      d[simulation_id == path_names[i], retained_iteration][1]),
                      method = 'restyle',
                      args = list('visible', as.list(c(seq_len(n) == i, TRUE, TRUE))))
               }))
  rect <- function(x0, x1, y0, y1, color) {
    list(type = 'rect', xref = 'x', yref = 'y', x0 = x0, x1 = x1,
         y0 = y0, y1 = y1, fillcolor = color, line = list(width = 0), layer = 'below')
  }
  shapes <- list(rect(0, 1, 1, lim[2], '#F7E0DE'),
                 rect(0, 1, 0, 1, '#FCF0CD'),
                 rect(1, lim[1], 1, lim[2], '#FCF0CD'),
                 rect(1, lim[1], 0, 1, '#DFF0E5'),
                 list(type = 'line', x0 = 1, x1 = 1, y0 = 0, y1 = lim[2],
                      line = list(color = '#555555', width = 1, dash = 'dash')),
                 list(type = 'line', x0 = 0, x1 = lim[1], y0 = 1, y1 = 1,
                      line = list(color = '#555555', width = 1, dash = 'dash')))
  p <- plotly::layout(p,
    title = list(text = paste0('h1_1.06: 100 retained-draw Kobe trajectories, 2007-2026',
                              '<br><sup>Exploratory: convergence screening failed. ',
                              'Select a path below; hover for draw and year.</sup>'),
                 x = 0.02, y = .96, yanchor = 'top'),
    xaxis = list(title = 'SSB / SSBMSY (draw-specific 2017-2026 mean)', range = c(0, lim[1])),
    yaxis = list(title = 'F / FMSY (annual reference)', range = c(0, lim[2])),
    shapes = shapes,
    updatemenus = list(list(type = 'dropdown', direction = 'down', buttons = buttons,
                           x = 0, xanchor = 'left', y = 1.035, yanchor = 'bottom')),
    annotations = list(list(text = paste0('100 selected draws: chains 1/2/3 = 33/33/34. ',
                                         'Dark line = coordinate-wise median of these draws.<br>',
                                         'F = unweighted mean across ages 1-12 of summed fleet F. ',
                                         'These are historical fitted trajectories, not forecasts or validated status probabilities.'),
                            x = 0, y = -0.17, xref = 'paper', yref = 'paper',
                            xanchor = 'left', yanchor = 'top', showarrow = FALSE,
                            align = 'left', font = list(size = 11)),
                       list(text = '<b>2026</b>', x = med[year == 2026L, ssb_over_ssbmsy],
                            y = med[year == 2026L, f_over_fmsy], ax = 45, ay = 65,
                            xref = 'x', yref = 'y', showarrow = TRUE, arrowhead = 0,
                            arrowcolor = '#123E67', bgcolor = '#FFFFFF',
                            font = list(size = 13, color = '#123E67'))),
    margin = list(t = 155, r = 25, b = 145, l = 85),
    paper_bgcolor = '#FFFFFF', plot_bgcolor = '#FFFFFF')
  p <- plotly::config(p, displaylogo = FALSE,
                      toImageButtonOptions = list(format = 'svg', filename = 'kobe-selected-path'))
  htmlwidgets::saveWidget(p, file, selfcontained = TRUE, title = 'ADNUTS Kobe trajectories: 2007-2026')
  TRUE
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  root <- normalizePath(if (length(args)) args[1] else
                          'output/base-model-mcmc-2026-09-10', mustWork = TRUE)
  out <- file.path(root, 'kobe')
  dir.create(out, showWarnings = FALSE)
  manifest <- jsonlite::read_json(file.path(root, 'run-manifest.json'), simplifyVector = TRUE)
  stopifnot(manifest$model == 'h1_1.06', manifest$chains == 3,
            manifest$iterations_per_chain == 2000, manifest$warmup_per_chain == 1000,
            manifest$thin == 1)
  selected <- make_selection()
  selection_file <- file.path(out, 'selection-manifest.csv')
  if (file.exists(selection_file)) {
    old <- fread(selection_file)
    stopifnot(isTRUE(all.equal(old, selected, check.attributes = FALSE)))
  }
  fwrite(selected, selection_file)
  original <- file.path(root, 'evaluation', 'mceval.rep')
  cache_file <- file.path(out, 'selected-native-quantities.rds')
  current_source <- list(path = normalizePath(original), bytes = file.info(original)$size,
                         mtime = as.numeric(file.info(original)$mtime))
  cached <- if (file.exists(cache_file)) readRDS(cache_file) else NULL
  if (!is.null(cached) && identical(cached$source, current_source) &&
      identical(cached$pooled_draw, selected$pooled_draw)) {
    raw <- cached$raw
  } else {
    raw <- read_selected(original, selected$pooled_draw,
                         c('SSB', 'SBMSYy', 'F_faa'), 3000L)
    validate_fields(raw, selected$pooled_draw)
    saveRDS(list(source = current_source, pooled_draw = selected$pooled_draw, raw = raw), cache_file)
  }
  validate_fields(raw, selected$pooled_draw)
  if (length(args) > 1L && identical(args[2L], '--extract-only')) {
    message('Selection and original native quantities ready: ', out)
    return(invisible(selected))
  }
  supplemental <- if (length(args) > 1L) args[2L] else
    file.path(root, 'kobe-evaluation', 'mceval.rep')
  if (!file.exists(supplemental)) stop('Annual FMSY supplement is required: ', supplemental)
  sup <- read_selected(supplemental, 1:100,
                       c('SSB', 'SBMSYy', 'F_faa', 'FMSYy', 'FFMSYy'), 100L)
  validate_fields(sup, 1:100, include_fmsy = TRUE)
  sup[, pooled_draw := selected$pooled_draw[match(mcdraw, selected$evaluation_draw_id)]]
  invariant <- sup[type %chin% c('SSB', 'SBMSYy', 'F_faa'),
                   .(mcdraw = pooled_draw, type, unit, year, age, supplemental_value = value)]
  compared <- merge(raw, invariant, by = c('mcdraw', 'type', 'unit', 'year', 'age'))
  stopifnot(nrow(compared) == nrow(raw))
  compared[, difference := abs(value - supplemental_value)]
  if (any(compared$difference > 1e-7 * pmax(1, abs(compared$value)))) {
    stop('Supplemental evaluation changed original reported quantities')
  }
  comparison <- compared[, .(rows = .N, maximum_absolute_difference = max(difference)), by = type]
  fwrite(comparison, file.path(out, 'evaluation-invariance-check.csv'))

  ssb <- raw[type == 'SSB', .(pooled_draw = mcdraw, year, ssb_kt = value)]
  # Exactly reproduces Fcur_Fmsy numerator in frozen get_msy_robust: sum over
  # fleets of mean F-at-age (all 12 model ages, no abundance weighting).
  f <- raw[type == 'F_faa', .(f_mean_all_ages_per_year = sum(value) / 12),
           by = .(pooled_draw = mcdraw, year)]
  sb <- raw[type == 'SBMSYy', .(pooled_draw = mcdraw, year, ssbmsy_year_kt = value)]
  # jjmR::fixed_bmsy() changes only the biomass axis, using the final ten years.
  fixed <- sb[year %in% 2017:2026,
              .(ssbmsy_reference_kt = mean(ssbmsy_year_kt), reference_year_count = .N),
              by = pooled_draw]
  stopifnot(all(fixed$reference_year_count == 10L), all(fixed$ssbmsy_reference_kt > 0))
  fm <- sup[type == 'FMSYy', .(pooled_draw, year, fmsy_year_per_year = value)]
  fr <- sup[type == 'FFMSYy', .(pooled_draw, year, native_f_over_fmsy = value)]
  d <- Reduce(function(x, y) merge(x, y, by = c('pooled_draw', 'year')),
              list(ssb, f, sb, fm, fr))
  d <- merge(d, fixed[, !'reference_year_count'], by = 'pooled_draw')
  d <- merge(d, selected, by = 'pooled_draw')
  stopifnot(all(d$fmsy_year_per_year > 0), all(d$ssbmsy_year_kt > 0))
  grid_boundary_hits <- sum(d$fmsy_year_per_year <= 1.00001e-4 |
                             d$fmsy_year_per_year >= 4.99995)
  if (grid_boundary_hits) stop('Selected annual FMSY hits a solver grid boundary')
  d[, `:=`(ssb_over_ssbmsy = ssb_kt / ssbmsy_reference_kt,
            f_over_fmsy = f_mean_all_ages_per_year / fmsy_year_per_year,
            ssb_reference_start_year = 2017L, ssb_reference_end_year = 2026L,
            stock_id = 1L)]
  # Native rows have six-significant-digit precision. Allow its propagated
  # rounding error when verifying the independently reconstructed F/FMSY.
  ratio_error <- max(abs(d$f_over_fmsy - d$native_f_over_fmsy))
  relative_error <- max(abs(d$f_over_fmsy - d$native_f_over_fmsy) /
                          pmax(1e-12, abs(d$native_f_over_fmsy)))
  stopifnot(relative_error < 2e-5, nrow(d) == 2000L,
            uniqueN(d$simulation_id) == 100L, all(d[, .N, by = simulation_id]$N == 20L),
            identical(sort(unique(d$year)), 2007:2026),
            !anyDuplicated(d, by = c('simulation_id', 'year')))
  setorder(d, evaluation_draw_id, year)
  setcolorder(d, c('simulation_id', 'evaluation_draw_id', 'pooled_draw', 'chain',
                  'retained_iteration', 'sampler_iteration', 'year', 'stock_id',
                  'ssb_kt', 'f_mean_all_ages_per_year', 'ssbmsy_reference_kt',
                  'fmsy_year_per_year', 'ssb_over_ssbmsy', 'f_over_fmsy',
                  'ssbmsy_year_kt', 'native_f_over_fmsy',
                  'ssb_reference_start_year', 'ssb_reference_end_year', 'selection_seed'))
  fwrite(d, file.path(out, 'kobe-trajectories-100-draws-2007-2026.csv'))
  # Conventional Kobe data columns: iter identifies a complete path; stock and
  # harvest are dimensionless biomass and fishing mortality reference ratios.
  compact <- d[, .(iter = evaluation_draw_id, year, stock = ssb_over_ssbmsy,
                    harvest = f_over_fmsy)]
  fwrite(compact, file.path(out, 'kobe-format.csv'))
  med <- d[, .(ssb_over_ssbmsy = median(ssb_over_ssbmsy),
                f_over_fmsy = median(f_over_fmsy)), by = year][order(year)]
  fwrite(med, file.path(out, 'selected-draw-median-trajectory.csv'))
  saveRDS(list(trajectories = d, kobe = compact, selection = selected,
               median = med), file.path(out, 'kobe-trajectories.rds'))

  lim <- c(max(1.6, max(d$ssb_over_ssbmsy) * 1.08),
           max(1.6, max(d$f_over_fmsy) * 1.10))
  rectangles <- data.table(xmin = c(0, 0, 1, 1), xmax = c(1, 1, lim[1], lim[1]),
                            ymin = c(1, 0, 1, 0), ymax = c(lim[2], 1, lim[2], 1),
                            fill = c('#F7E0DE', '#FCF0CD', '#FCF0CD', '#DFF0E5'))
  labelled <- med[year %in% c(2007L, 2010L, 2013L, 2016L, 2019L, 2022L)]
  terminal <- med[year == 2026L]
  p <- ggplot() +
    geom_rect(data = rectangles, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
              fill = rectangles$fill) +
    geom_hline(yintercept = 1, colour = '#4D4D4D', linetype = 'dashed', linewidth = .45) +
    geom_vline(xintercept = 1, colour = '#4D4D4D', linetype = 'dashed', linewidth = .45) +
    geom_path(data = d, aes(ssb_over_ssbmsy, f_over_fmsy, group = simulation_id,
                            colour = '100 selected trajectories'), linewidth = .34, alpha = .23) +
    geom_path(data = med, aes(ssb_over_ssbmsy, f_over_fmsy,
                              colour = 'Median of selected draws'), linewidth = 1.05,
              arrow = grid::arrow(length = grid::unit(1.4, 'mm'), type = 'closed')) +
    geom_point(data = med, aes(ssb_over_ssbmsy, f_over_fmsy), colour = '#123E67', size = 1.25) +
    geom_point(data = med[year == 2007L], aes(ssb_over_ssbmsy, f_over_fmsy),
               shape = 21, size = 3.4, fill = 'white', colour = '#123E67', stroke = .8) +
    geom_point(data = med[year == 2026L], aes(ssb_over_ssbmsy, f_over_fmsy),
               shape = 23, size = 3.8, fill = '#123E67', colour = '#123E67') +
    annotate('text', x = .025, y = lim[2] - .10,
              label = 'Below biomass reference\nAbove F reference',
              hjust = 0, vjust = 1, size = 3, colour = '#525252') +
    annotate('text', x = lim[1] - .025, y = lim[2] - .10,
              label = 'Above biomass reference\nAbove F reference',
              hjust = 1, vjust = 1, size = 3, colour = '#525252') +
    annotate('text', x = .025, y = .08,
              label = 'Below biomass reference\nBelow F reference',
              hjust = 0, vjust = 0, size = 3, colour = '#525252') +
    annotate('text', x = lim[1] - .025, y = .08,
              label = 'Above biomass reference\nBelow F reference',
              hjust = 1, vjust = 0, size = 3, colour = '#525252') +
    ggrepel::geom_text_repel(data = labelled, aes(ssb_over_ssbmsy, f_over_fmsy, label = year),
                             seed = 20260910, size = 3.2, colour = '#123E67',
                             box.padding = .5, point.padding = .4, min.segment.length = 0,
                             segment.colour = '#123E67', max.overlaps = Inf) +
    geom_segment(data = terminal,
                   aes(x = ssb_over_ssbmsy, y = f_over_fmsy,
                       xend = ssb_over_ssbmsy + .08, yend = f_over_fmsy - .34),
                   colour = '#123E67', linewidth = .45) +
    geom_label(data = terminal,
                 aes(x = ssb_over_ssbmsy + .08, y = f_over_fmsy - .40, label = year),
                 colour = '#123E67', fill = 'white', linewidth = 0,
                 size = 3.6, fontface = 'bold') +
    scale_colour_manual(values = c('100 selected trajectories' = '#526779',
                                     'Median of selected draws' = '#123E67'), name = NULL) +
    guides(colour = guide_legend(override.aes = list(alpha = c(.6, 1), linewidth = c(.5, 1.1)))) +
    coord_cartesian(xlim = c(0, lim[1]), ylim = c(0, lim[2]), expand = FALSE) +
    labs(x = 'SSB / SSBMSY (draw-specific mean for 2017-2026)',
         y = 'F / FMSY (annual reference)',
         title = 'Base model: 100 retained-draw Kobe trajectories',
         subtitle = '2007-2026 | h1_1.06 | 33, 33 and 34 draws from chains 1, 2 and 3',
         caption = paste0('Open circle: 2007 median; filled diamond: 2026 median. ',
                          'Medians are calculated separately for each coordinate and year.\n',
                          'F is the mean over ages 1-12 of summed fleet F. ',
                          'SSBMSY is fixed within each draw; FMSY varies by year.\n',
                          'Exploratory retained-draw results: convergence screening failed ',
                          '(maximum parameter R-hat 1.055).')) +
    theme_minimal(base_size = 12) +
    theme(panel.grid.minor = element_blank(), panel.grid.major = element_blank(),
           axis.line = element_line(colour = '#555555', linewidth = .4),
           legend.position = 'bottom', legend.justification = 'left',
           plot.title.position = 'plot', plot.caption.position = 'plot',
           plot.caption = element_text(hjust = 0, size = 9, lineheight = 1.25),
           plot.margin = margin(14, 18, 12, 12))
  ggsave(file.path(out, 'kobe-100-trajectories-2007-2026.png'), p,
          width = 10, height = 8, dpi = 300, bg = 'white')
  ggsave(file.path(out, 'kobe-100-trajectories-2007-2026.svg'), p,
          width = 10, height = 8, bg = 'white')
  interactive <- write_interactive(d, med, lim,
                                   file.path(out, 'kobe-100-trajectories-2007-2026.html'))
  diagnostic <- jsonlite::read_json(file.path(root, 'diagnostic-summary.json'), simplifyVector = TRUE)
  status <- list(
    generated_at = format(Sys.time(), '%Y-%m-%dT%H:%M:%S%z'), model = 'h1_1.06',
    trajectories = 100L, years = 2007:2026, rows = nrow(d),
    selection_seed = 20260910L, rng_kind = RNGkind(), draws_by_chain = c(33L, 33L, 34L),
    available_retained_draws = 3000L, selection = 'Without replacement within each chain; no quantity-based filtering.',
    selection_file = 'selection-manifest.csv',
    reference_convention = 'jjmR fixed_bmsy: each draw uses mean annual SSBMSY for 2017-2026; F uses annual FMSY.',
    f_definition = 'Sum F_faa across all four fleets and all twelve ages, divided by 12; not native emitted Fbar.',
    ssb_units = 'thousand tonnes', f_units = 'per year', ratio_units = 'dimensionless',
    median_definition = 'Coordinate-wise median of the selected 100 draws for each year; not a single sampled trajectory.',
    original_source = current_source, supplemental_source = normalizePath(supplemental),
    original_quantities_invariant = TRUE, invariance = comparison,
    reconstructed_f_ratio_max_absolute_error = ratio_error,
    reconstructed_f_ratio_max_relative_error = relative_error,
    selected_annual_fmsy_grid_boundary_hits = grid_boundary_hits,
    annual_fmsy_grid_limits = c(0.0001, 5),
    interactive_html_created = interactive,
    all_run_maximum_parameter_rhat = diagnostic$parameter_checks$maximum_finite_rhat,
    all_run_screening_status = diagnostic$screening_status,
    interpretation = 'Exploratory historical fitted trajectories conditional on the model. Convergence screening failed; not forecasts or validated stock-status probabilities.',
    package_versions = lapply(c('data.table', 'ggplot2', 'ggrepel', 'jsonlite'),
                              function(pkg) list(package = pkg, version = as.character(packageVersion(pkg))))
  )
  jsonlite::write_json(status, file.path(out, 'kobe-status.json'),
                       pretty = TRUE, auto_unbox = TRUE, na = 'null', digits = 17)
  writeLines(c(
    '# 100 retained ADNUTS draws in Kobe format, 2007-2026', '',
    'These are 100 matched historical fitted trajectories from the completed h1_1.06 default ADNUTS run. They are not new model simulations or forecasts. Full-run convergence screening failed (maximum parameter R-hat 1.055; 2026 SSB R-hat 1.018), so use them for exploratory display, not validated stock-status probabilities.', '',
    '## Files', '',
    '- `kobe-trajectories-100-draws-2007-2026.csv`: 2000 rows, preserving draw, chain, iteration, year, biological quantities, reference points and both ratios.',
    '- `kobe-format.csv`: conventional long Kobe columns `iter`, `year`, `stock` (SSB/SSBMSY), and `harvest` (F/FMSY). `iter` matches `evaluation_draw_id` in the selection manifest.',
    '- `selection-manifest.csv`: all 100 draw identities; pooled draw 1-1000 is chain 1, 1001-2000 is chain 2, and 2001-3000 is chain 3. Retained iteration is 1-1000 after warmup; sampler iteration adds 1000 warmup iterations.',
    '- `kobe-trajectories.rds`: trajectories, compact Kobe data, selection and median in an R list.',
    '- PNG and SVG: all 100 paths and coordinate-wise selected-draw median; open circle starts in 2007, filled diamond ends in 2026.',
    '- Interactive HTML: select an individual draw in the dropdown and hover over its years. The median remains visible. All 100 paths are available together.',
    '- `selected-draw-median-trajectory.csv`: medians across the 100 selected draws, computed separately for both coordinates in each year. This median curve need not itself be a possible model trajectory.',
    '- `evaluation-invariance-check.csv` and `kobe-status.json`: validation, provenance and interpretation.', '',
    '## Selection', '',
    'Seed 20260910; R RNG kinds Mersenne-Twister, Inversion, Rejection. Sample without replacement from 1000 retained iterations per chain, selecting 33, 33 and 34 draws from chains 1, 2 and 3, then sort pooled draw IDs. No draw is selected or removed based on its parameter values or status. The same draw is followed through every year from 2007 through 2026 inclusive.', '',
    '## Quantities and reference convention', '',
    '`ssb_kt` is native `SSB` = Sp_Biom(1,year), in thousand tonnes. `f_mean_all_ages_per_year` is the unweighted mean over all twelve model ages of F summed across all four fleets: sum(F_faa)/12. This exactly matches the numerator used by get_msy_robust for Fcur_Fmsy. The native emitted Fbar is a first-fleet scalar and is not used.', '',
    '`ssbmsy_year_kt` is annual SBMSYy from get_msy_robust(year). `ssbmsy_reference_kt` is its within-draw arithmetic mean for 2017-2026, repeated over all years, following jjmR::fixed_bmsy(). The biomass ratio is ssb_kt/ssbmsy_reference_kt. `fmsy_year_per_year` is matching annual FMSYy from the same robust routine, and the fishing-mortality ratio is f_mean_all_ages_per_year/fmsy_year_per_year. Annual F/FMSY remains unchanged by fixed_bmsy. Both ratios are dimensionless.', '',
    'The frozen model already computes annual robust MSY values but did not emit annual FMSY. An isolated, output-only evaluator adds FMSYy and FFMSYy immediately after its existing get_msy_robust(year) call and re-evaluates only the 100 selected saved PSV vectors. Its SSB, SBMSYy and F_faa values are checked against the original complete evaluation. Reconstructed F/FMSY is checked against the emitted native Fcur_Fmsy, allowing six-significant-digit report rounding. The native pre-loop FMSY/SBMSY pair is not used because its optimization and evaluation use differing selectivity windows.', '',
    'Frozen source: `../source/jjm2.tpl`, write_mceval lines 1975-2017, get_msy_robust lines 3744-3826, annual yld lines 3909-3960. Canonical R convention: `/Users/jim/_mymods/sprfmo/jjmR/R/fixed_bmsy.R`, lines 12-24. Source line numbers refer to the frozen source, before the supplementary output lines are added.', '',
    '## Reproduce', '',
    'From the repository root, run:', '',
    '```sh',
    'Rscript output/base-model-mcmc-2026-09-10/build-kobe-trajectories.R output/base-model-mcmc-2026-09-10 path/to/supplemented/mceval.rep',
    '```', '',
    'The selected raw-quantity RDS is an extraction cache validated against the original file path, size, modification time and selected draw IDs. It can be removed to force a fresh scan. Source model files, original draws and the complete original mceval output are not modified.'
  ), file.path(out, 'README.md'))
  print(d[year %in% c(2007L, 2026L), .(draws = .N,
           median_ssb_ratio = median(ssb_over_ssbmsy),
           median_f_ratio = median(f_over_fmsy)), by = year])
  message('Validated 100 complete Kobe paths / 2000 rows written to ', out)
  invisible(list(data = d, status = status))
}

if (sys.nframe() == 0L) main()
