# CMP working paper, 8 September 2026

Start with `cmp-screening-working-paper.html`. Its two scorecard links use embedded data and work without an R server.

Editable source: `cmp-screening-working-paper.qmd`, `scorecard-all.qmd`, `scorecard-shortlist.qmd`. Render each with `quarto render FILE.qmd --to html` in this folder. The paper figures are embedded in HTML and supplied separately for reuse.

The data/figure generator `build_cmp_screening_paper.R` runs from the jmMSE26 repository root using the saved candidate-performance-500 tables and jmMSE-500-refine reference runs named in provenance.txt. The 500-draw inputs are not duplicated here. The annual event CSVs preserve the exclusions used in the existing quilt. The scorecard QMDs embed this frozen data snapshot; update their rows deliberately when regenerating analysis.

Screening is a reference-OM presentation choice with disclosed tolerances. It is not an agreed selection or an across-OM dominance claim. Numerical projection diagnostics remain outstanding. No model rerun was performed.
