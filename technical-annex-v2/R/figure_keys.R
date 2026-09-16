# Correct composition legend symbols in report copies of jjmR trellis objects.
# jjmR draws age predictions with panel.lines(), but its legacy key uses a dot.
# Only legend components are edited; data, panel functions and scales are retained.
annex_figure_keys <- function(diagnostics) {
  composition_types <- c("ageFitsCatch", "ageFitsSurvey",
                         "lengthFitsCatch", "lengthFitsSurvey")
  revise <- function(x, composition = NULL) {
    if (inherits(x, "trellis")) {
      if (is.null(composition)) return(x)
      for (position in seq_along(x$legend)) {
        key <- x$legend[[position]]$args$key
        if (is.null(key)) next
        if (composition %in% c("ageFitsCatch", "ageFitsSurvey")) {
          stopifnot(identical(key$text$lab, c("Observed", "Predicted")))
          key$points <- NULL
          key$lines <- list(col = c(NA_character_, "black"),
                            lty = c(0, 1), lwd = c(1, 1), alpha = c(0, 1))
          key$rectangles$col <- c("white", NA_character_)
          key$rectangles$border <- c("black", NA_character_)
          key$rectangles$alpha <- c(1, 0)
          key$rectangles$lty <- c(1, 0)
        } else if (!is.null(key$points$pch)) {
          # NA is the supported invisible symbol; keep visible length-fit dots.
          key$points$pch[key$points$pch == -1] <- NA_integer_
        }
        x$legend[[position]]$args$key <- key
      }
      return(x)
    }
    if (is.list(x)) {
      for (i in seq_along(x)) {
        name <- names(x)[i]
        kind <- if (length(name) && name %in% composition_types) name else composition
        x[i] <- list(revise(x[[i]], kind))
      }
    }
    x
  }
  revise(diagnostics)
}
