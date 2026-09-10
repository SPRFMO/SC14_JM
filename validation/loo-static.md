# Static LOI and LOO report checks

Date: 10 September 2026. Product: focused assessment sensitivity report (working-paper track).

The source is SPRFMO/jjm, assessment/R/loo.qmd, revision a53473feebfd28417e85b80af77e82be56e01653. It reads the existing single-stock h1_1.06 base and h1_3.01 through h1_3.08 model outputs, through jjmR. The existing Quarto workflow is retained; no asar migration or model refitting is part of this update.

| Gate | Outcome | Evidence and scope |
|---|---|---|
| Track | Pass | Focused sensitivity report; working results distinguished from Committee conclusions. |
| Provenance | Pass | Source revision above; exact rendered HTML hash in assessment/loo-sync.json. |
| Scientific consistency | Pass | All nine 2026 SSB values checked against saved outputs; 1970–2026 assessment years; thousand-tonne outputs divided by 1,000 for million tonnes. Index-error multipliers and unchanged catches/compositions checked in saved model inputs. |
| Plot consistency | Pass | Two four-panel figures; every panel contains identical base data plus its named sensitivity; common axes; line style as well as colour distinguishes the two curves. |
| Render | Pass | HTML build succeeded. Static PNGs inspected visually for labels, legends and clipping. HTML parsed to confirm no plot widgets or tab controls. |
| Accessibility: new figures | Pass | Both main figures have captions, descriptive alt text and adjacent numerical explanations. |
| Full accessibility review | Not Tested | Screen-reader behaviour and complete legacy-report accessibility were not audited. No Section 508 conformance claim. |
| Model refitting or independent model validation | Not Applicable | This task displays and summarizes saved sensitivity results. |

Terminal-year SSB (million tonnes): base 6.10887; LOI 3.01 4.61183, 3.02 7.10249, 3.03 13.21980, 3.04 24.28180; LOO 3.05 11.79530, 3.06 6.60082, 3.07 6.73180, 3.08 4.30639.
