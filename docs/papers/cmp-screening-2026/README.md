# CMP working paper, 8 September 2026

Start with `cmp-screening-working-paper.html`. Both scorecards contain embedded data and work without an R server. Select among ten OMs and separate two-stock components; fixed catch is available only for the reference OM.

Editable sources are the three QMD files. Render each with `quarto render FILE.qmd --to html` in this folder.

Reproduce from the jmMSE26 repository root in this order: `R/build_cmp_screening_paper.R`, `R/extend_cmp_paper_robustness_fixedcatch.R`, `R/build_cmp_om_scorecards.R`, `R/add_fixedcatch_scorecard.R`, then `python3 R/configure_cmp_scorecard_oms.py`. R scripts run with Rscript. Sources are copied here for review; their relative input paths refer to jmMSE26 and jmMSE-500-refine. See provenance text files for input paths and checksums. The saved simulation inputs and supplied Downloads/tunfixc.rds are not duplicated here.

The fixed-catch dynamic B0 reconstruction uses a zero-catch projection of its supplied OM. It supports P(Green)=60.3% for 2041–2050 using dynamic BMSY. Reference biology matches; recruitment deviations, implementation adjustments and stored MSY values differ from the other saved reference runs. No candidate MP was retuned or rerun.

Screening is an exploratory reference-OM presentation choice with disclosed tolerances, not an agreed selection or an across-OM dominance claim. Original model outputs are unchanged.
