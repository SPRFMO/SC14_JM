# TAC calculations for 2027 and 2028

**CMP29 and CMP45 give the following catch recommendations when the 2026 TAC is set to either 1,675 or 1,092 kt.** The 2027 advice uses index data through 2025. The 2028 advice uses data through 2026 and carries forward each CMP’s full-precision 2027 recommendation.

These are deterministic applications of the candidate rules prepared for SC14, calculated on 12 September 2026 using the current Model 1.06 index data. Their status is a working calculation for discussion. All catch quantities are **kt (thousand tonnes)**.

## Main CMPs: CMP29 and CMP45

| 2026 TAC (kt) | CMP | 2027 advice: data through 2025 (kt) | 2028 advice: data through 2026 (kt) |
|---:|:---|---:|---:|
| 1,675 | CMP29 (HS+20) | **1,423.75** | **1,210.19** |
| 1,675 | CMP45 (HSsym) | **1,423.75** | **1,210.19** |
| 1,092 | CMP29 (HS+20) | **1,115.64** | **999.01** |
| 1,092 | CMP45 (HSsym) | **1,142.57** | **1,022.23** |

Starting from 1,675 kt, the **15% annual decrease limit** determines the recommendation in both years for both CMPs. Starting from 1,092 kt, the index-based rule determines both years. “Main CMPs” identifies the two candidates requested for this calculation; their formal status remains as recorded in the SC14 material.

**[Download the Excel calculations](papers/cmp-tac-advice-2027-2028/CMP_TAC_advice_2027_2028.xlsx).** The first sheet contains CMP29 and CMP45; the second contains the other six CMPs in the SC14 set. The workbook includes the input indices, standardization, rule parameters, annual limits and calculations. [Download all results as CSV](papers/cmp-tac-advice-2027-2028/all_cmp_advice.csv).

## How the index is calculated

The five series are Chile Acoustic North, Chile CPUE, Peru artisanal CPUE, Peru industrial CPUE and offshore CPUE. Each series is scaled to its own mean over **2019–2023**. The calculation gives equal weight to the available standardized indices within each year, followed by equal weight to the three annual combined indices.

1. **Reference mean for each series:** `reference mean = mean(available observations in 2019–2023)`.
2. **Standardized index:** `standardized value = observation / that series’ reference mean`.
3. **Annual combined index:** `annual index = mean(available standardized values in that year)`.
4. **Advice indicator:** `I = mean(the three annual combined indices ending at the data cutoff)`.

This sequence follows the estimator saved with the SC14 release. The indicator is dimensionless. It uses equal weighting of available indices; assessment CV adjustments do not change those weights.

| Year | Available indices | Annual combined index |
|---:|---:|---:|
| 2023 | 5 | 1.1790266300 |
| 2024 | 5 | 1.0040530352 |
| 2025 | 5 | 1.0864224544 |
| 2026 | 4 | 0.7694876534 |

For **2027 advice**, `I = (2023 annual index + 2024 annual index + 2025 annual index) / 3 = 1.0898340398`.

For **2028 advice**, `I = (2024 annual index + 2025 annual index + 2026 annual index) / 3 = 0.9533210476`.

**Data qualification:** Chile Acoustic North has no 2022 observation, so its reference mean uses four observations. Offshore CPUE ends in 2025, so the 2026 annual combination uses the other four series. Missing observations are omitted at the corresponding averaging step, and no offshore value is imputed. The through-2026 calculation is conditional on the currently available 2026 observations, including current-year CPUE values.

Both cutoffs use the same current historical data vintage, with observations after each cutoff excluded. This describes a cutoff comparison using the current Model 1.06 data; earlier meeting-year data vintages may differ.

## How the TAC is calculated

Let `I` be the three-year indicator, `trigger` be the CMP-specific threshold, and `previous TAC` be the value against which annual changes are constrained. All eight CMPs use an index limit of **0.1** and a minimum raw advice value of **270 kt**.

For the **hockey-stick rules** (HS: CMP29, CMP43, CMP45 and CMP47):

```text
If I <= 0.1:       raw TAC = 270
If 0.1 < I < trigger:
                   raw TAC = 270 + (I - 0.1) * (2000 - 270) / (trigger - 0.1)
If I >= trigger:   raw TAC = 2000
```

For the **power-ramp rules** (PR: CMP32, CMP44, CMP46 and CMP48), first calculate `x = (I - 0.1) / (trigger - 0.1)`:

```text
If I <= 0.1:       raw TAC = 270
If 0.1 < I < trigger:
                   raw TAC = 270 + (1500 - 270) * x^2.5
If I >= trigger:   raw TAC = 1500 * (0.2 + 0.8 * x)^0.6
```

The power-ramp upper branch continues to increase above the trigger. Both indicators in this calculation are between 0.1 and every CMP trigger, so the middle branch is used for all eight candidates.

The same final step applies to every CMP:

```text
Lower limit = previous TAC * lower annual multiplier
Upper limit = previous TAC * upper annual multiplier
TAC advice  = MAX(lower limit, MIN(upper limit, raw TAC))
```

For 2027, the previous TAC is the scenario value of **1,675 or 1,092 kt in 2026**. For 2028, it is the calculated 2027 advice for the same CMP and starting scenario, retained at full precision. These scenario values replace the **1,385 kt** initialization used in the simulation setup. The advice is a total TAC before allocation among fisheries or areas.

### CMP parameters

| CMP | Label | Rule | Trigger | Lower annual multiplier | Upper annual multiplier |
|:---|:---|:---|---:|---:|---:|
| CMP29 | HS+20 | Hockey stick | 2.125 | 0.85 | 1.20 |
| CMP45 | HSsym | Hockey stick | 2.0625 | 0.85 | 1.15 |
| CMP43 | HS−20 | Hockey stick | 1.9375 | 0.80 | 1.15 |
| CMP47 | HS−30 | Hockey stick | 2 | 0.70 | 1.20 |
| CMP32 | PR+20 | Power ramp | 1.640625 | 0.85 | 1.20 |
| CMP44 | PR−20 | Power ramp | 1.6015625 | 0.80 | 1.15 |
| CMP46 | PRsym | Power ramp | 1.625 | 0.85 | 1.15 |
| CMP48 | PR−30 | Power ramp | 1.578125 | 0.70 | 1.20 |

### Worked example: CMP29

For 2027, `raw TAC = 270 + (1.0898340398436 - 0.1) * 1730 / (2.125 - 0.1) = 1,115.63599453305 kt`.

With a 2026 TAC of **1,675 kt**, the annual lower limit is `1,675 * 0.85 = 1,423.75 kt`, which determines the 2027 advice. In 2028, the raw advice is `999.010080198317 kt`, and the annual lower limit is `1,423.75 * 0.85 = 1,210.1875 kt`. The resulting advice is **1,210.19 kt** when displayed to two decimals.

With a 2026 TAC of **1,092 kt**, the 2027 raw advice lies within the annual limits and becomes the recommendation. Carrying its full precision into 2028 gives a lower limit of `1,115.63599453305 * 0.85 = 948.290595353095 kt`. The 2028 raw advice of **999.01 kt** also lies within the limits.

## Other CMPs

The second Excel sheet contains the remaining six members of the same SC14 set: **CMP43, CMP47, CMP32, CMP44, CMP46 and CMP48**. The calculations use the same index data, cutoffs and 2026 TAC scenarios as the main sheet.

| 2026 TAC (kt) | CMP | 2027 advice: data through 2025 (kt) | 2028 advice: data through 2026 (kt) |
|---:|:---|---:|---:|
| 1,675 | CMP43 (HS−20) | 1,340.00 | 1,073.40 |
| 1,675 | CMP47 (HS−30) | 1,172.50 | 1,046.97 |
| 1,675 | CMP32 (PR+20) | 1,423.75 | 1,210.19 |
| 1,675 | CMP44 (PR−20) | 1,340.00 | 1,072.00 |
| 1,675 | CMP46 (PRsym) | 1,423.75 | 1,210.19 |
| 1,675 | CMP48 (PR−30) | 1,172.50 | 820.75 |
| 1,092 | CMP43 (HS−20) | 1,201.93 | 1,073.40 |
| 1,092 | CMP47 (HS−30) | 1,171.27 | 1,046.97 |
| 1,092 | CMP32 (PR+20) | 928.20 | 788.97 |
| 1,092 | CMP44 (PR−20) | 873.60 | 698.88 |
| 1,092 | CMP46 (PRsym) | 928.20 | 788.97 |
| 1,092 | CMP48 (PR−30) | 764.40 | 581.46 |

## Sources and reproducibility

The definitions come from the **SC14-MSE-2026-RC1 common 500-draw release**, using its CMP registry, candidate controls and tuning summary. The saved estimator and harvest-control functions define the calculation. The release uses identifiers `MP29`, `MP45`, and so on; this page uses the equivalent `CMP29`, `CMP45` labels. The input observations come from the current **Model 1.06 assessment input**, selected by the SC14 assessment configuration.

The calculation uses Chile CPUE from SC14-JM10, Peru industrial and artisanal updates supplied for the assessment, offshore CPUE through 2025 from SC14-JM21, and Chile Acoustic North updated through 2026. [Read the assessment](assessment/SC14.html) and [find the source papers](sources.html).

The workbook and CSV files retain full precision; the tables here display TACs to two decimals. The downloads make the raw advice, previous TAC, annual bounds, final advice and binding rule available for each calculation.

All **32 CMP/year/scenario calculations** were compared with direct calls to the saved SC14 functions. The explicit formulas agree within **0.000000000001 kt**. Additional checks cover the lower, middle and upper branches of all eight rules. The Excel formulas were also recalculated independently, with all 32 advice results reproduced. These checks establish numerical agreement with the saved candidate definitions; adoption and annual application arrangements are matters for the relevant decision record.

- [Excel workbook: main CMPs and other CMPs](papers/cmp-tac-advice-2027-2028/CMP_TAC_advice_2027_2028.xlsx).
- [All TAC calculations (CSV)](papers/cmp-tac-advice-2027-2028/all_cmp_advice.csv).
- [CMP parameters (CSV)](papers/cmp-tac-advice-2027-2028/all_cmp_parameters.csv).
- [Input indices and standardization (CSV)](papers/cmp-tac-advice-2027-2028/index_inputs_and_standardization.csv).
- [Annual combined indices (CSV)](papers/cmp-tac-advice-2027-2028/annual_combined_indices.csv).
- [Standalone R reproducer](papers/cmp-tac-advice-2027-2028/reproduce_tac_advice.R). Save this script with the three CSV files for all TAC calculations, CMP parameters, and input indices in one folder, then run `Rscript reproduce_tac_advice.R`. It uses base R and checks all 32 advice values against the downloaded results.
- [R calculations and saved-function checks](papers/cmp-tac-advice-2027-2028/all_cmp_calculations.R), run from the `jmMSE26` repository with its sibling assessment (`jjm`) and analysis (`jmMSE-500-refine`) repositories, as described in the script.
- [Calculation validation record](papers/cmp-tac-advice-2027-2028/all_cmp_validation.txt).

[Compare how the CMPs perform in simulations](mse.html).
