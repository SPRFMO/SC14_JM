# CMP working-document rebuild

Run the source scripts from the jmMSE26 checkout.

## Recruitment-cycle and near-term update

The focused checkpoint set is now OM11_2 and OM11_3. `R/build_cmp_nearterm.R` generates the new 2026–2035 trade-off/Kobe plots for both CMP sets and checks the reference Kobe values against the established calculation. Run it after the focused robustness build, then render both papers and regenerate their scorecards. The demonstration selectors use reference, recruitment crash and recruitment cycle.

```sh
Rscript R/build_cmp_nearterm.R
```
