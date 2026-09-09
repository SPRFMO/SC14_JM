# CatchDrop20 revision — 9 September 2026

Working-paper update. Existing saved model runs and tuning are unchanged.

Definition: pooled proportion of all valid consecutive HCR-advice comparisons with current advice strictly below 81% of previous advice. Reductions only. No biomass or near-20% exclusion. Missing/negative advice, nonpositive previous advice and nonconsecutive years do not enter the denominator. Advice is pre-implementation; realized catch is not substituted.

Advice is saved in 2025–2049, applied one year later. Valid comparisons cover advice years 2025–2049, applied in 2026–2050. All 81 OM/CMP series contain 500 iterations and 12,500 valid comparisons. Direct arithmetic checks pass for all 1,012,500 records, including all initialized first years. The first comparison uses saved HCR initial advice; fixed catch uses its constant advice target. Two-stock advice is for Southern, and is shared across scorecard component views.

- Track/provenance: Pass. Saved reference and robustness runs plus supplied fixed-catch run; source hashes in provenance.csv. No model fitting.
- Scientific calculation: Pass. Boundary and unequal-denominator tests in tests/catchdrop_advice.R. Direct arithmetic check of every retained event. All other reference and all-OM scorecard indicator values unchanged.
- Consistency: Revised scorecards and screening table use the new definition. Four earlier exclusions no longer hold; the prior three-CMP display is qualified as a discussion set requiring review. The old 0.1-events/10-years screening tolerance is represented as 1 percentage point and explicitly requires review for the new metric.
- Accessibility: Existing semantic HTML and numeric table labels retained. Full accessibility audit and screen-reader testing not performed.

Rebuild: Rscript R/extract_catchdrop_advice.R; Rscript R/build_candidate_evidence_figures.R; Rscript R/build_cmp_om_scorecards.R; Rscript R/add_fixedcatch_scorecard.R; Rscript R/build_cmp_screening_paper.R; python3 R/configure_cmp_scorecard_oms.py. Render the affected Quarto documents after rebuilding.
