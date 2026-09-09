# Second CMP screening working document

This version focuses on MP29 (HS+20), MP45 (HSsym), and MP43 (HS−20), using the same saved 500-iteration results and format as the first paper. Fixed-catch artifacts are reused unchanged from the first document. The general all-CMP scorecard remains available for context; the selected scorecard contains the three requested CMPs plus the fixed-catch comparison.

From the jmMSE26 source checkout, after generating the current advice probabilities and the first paper:

```sh
export JMMSE_CMP_PAPER_OUT=output/cmp-working-paper-hs-2026
export JMMSE_CMP_FOCUS=tun29,tun45,tun43
export JMMSE_SCORECARD_FOCUS='HS+20 (MP29)|HSsym (MP45)|HS-20 (MP43)|Fixed catch (1,525 kt)'
export JMMSE_REUSE_FIXED_CATCH=true
Rscript R/build_cmp_screening_paper.R
Rscript R/extend_cmp_paper_robustness_fixedcatch.R
Rscript R/build_hs_screening_tables.R
python3 R/configure_cmp_scorecard_oms.py
quarto render output/cmp-working-paper-hs-2026/cmp-screening-working-paper.qmd
quarto render output/cmp-working-paper-hs-2026/scorecard-all.qmd
quarto render output/cmp-working-paper-hs-2026/scorecard-shortlist.qmd
```

The editable Quarto narrative belongs to this second comparison and must remain with its own figures. The source checkout also requires the sibling saved-run directories documented by the first paper. This workflow reads those runs and does not refit or retune models.
