# Migration checks — 15 September 2026

The annex was migrated from `jmMSE26/technical-annex-v2` to
`SC14_JM/technical-annex-v2`. The workflow now uses R and Quarto. The historical
package is retained at `jmMSE26/output/technical-annex-v2-original-2026-09-15`.
No assessment or projection model was fitted during this migration.

| Check | Result | Evidence |
|---|---|---|
| Migration scope | Pass | Scientific narrative, equations and decision status retained; handover shortened |
| Input provenance | Pass | 24 assessment files and 14 projection files byte-identical; 45 saved input/archive checksums pass |
| Risk calculations | Pass | R reads raw saved report blocks and reproduces all 180 reviewed risk records within 1e-9 |
| HTML report content | Pass | All 14,847 table cells, 50 image payloads, figure alt text and scientific bibliography unchanged |
| Scientific PDF | Pass | All 117 rendered page images pixel-identical to the previous PDF at 72 dpi |
| Word content | Pass | Text, equations and embedded image payloads unchanged; 1,515 table rows kept together; image sizes within page limits |
| Word page layout | Pass | All 107 pages pixel-identical when the old and R-formatted Word documents are converted with the same LibreOffice renderer |
| Handover | Pass | Both pages inspected in PDF and rendered Word; commands, formula, source mapping and update instructions readable |
| Render | Pass | Both documents built in HTML, PDF and Word; no unresolved citations or cross-references |
| Local links | Pass | All local annex content links resolve after the data-folder migration |
| Changed-input protection | Pass | A deliberately altered file was rejected by the input checker |
| Snapshot helper | Pass | R copied and read all 24 selected files into a separate candidate folder; existing destinations refused |
| HTML language and figure alternatives | Pass | English declared and all 50 figures retain alternative text |
| PDF tagging | Fail — inherited limitation | The direct LaTeX PDF remains untagged, as in the previous package |
| Screen reader, keyboard and reading order | Not Tested | Automated comparisons do not establish accessibility conformance |
| Fresh-computer package installation | Not Tested | Build used the recorded local R environment |
| New model estimation and scientific acceptance | Not Applicable | This is a report-workflow migration using saved working results |

`migration-checks.csv` contains the structural comparison and
`pdf-page-comparison.csv` and `word-page-comparison.csv` record page identity. `build.csv` records only products
that completed successfully, with their own build times and hashes. Logs and the
R session are retained here. Page-render images remain in the migration workspace,
outside the maintained source tree.

The PDF build emits the same six inherited font-metric warnings in three index-fit
plots as the previous build. Pixel comparison confirms unchanged pages. These
warnings are not introduced by the R migration and remain visible in the logs.

The saved reference tables and three explanatory PNG diagrams contain reviewed
September values. Their update is an explicit scientific review step, documented
in the handover; the ordinary build does not imply adoption of a new assessment.

## Table layout update — 18 September 2026

The HTML and PDF annexes retain the R flextable renderer. HTML tables now fill
the text area; Table 35 reserves about 12% for model labels and the remainder
for descriptions. PDF column widths fill the A4 text area after allowing for
cell gutters and borders, and the row-height multiplier is reduced from 1.5 to
1.0. Word formatting and scientific inputs are unchanged.

| Check | Result | Evidence |
|---|---|---|
| Input identity and risk calculations | Pass | Existing checksum and 180-record checks run during the builds |
| HTML scientific content | Pass | All 14,847 table cells and 50 embedded figure payloads match the preceding version |
| HTML width | Pass | All 37 flextables fill their containing text area in the browser; Table 35 is 799 px wide, with columns 95.875 and 703.125 px |
| PDF Table 35 | Pass | All 23 rows and their cell contents retained; table width increased from 462.566 to 480.901 pt and height decreased from 448.319 to 298.879 pt |
| PDF pagination | Pass | Annex decreased from 117 to 101 pages; no clipped borders in 40 detected table fragments; tables stay within the text margins |
| PDF visual review | Pass | Inspected pages 14, 34, 42, 45 and 51, covering risk, biological, model-progression, numbers-at-age and assessment-summary tables |
| Render warnings | Unchanged | Six inherited font-metric warnings in index-fit plots; no new render failures |
| Accessibility certification | Not Tested | The inherited PDF tagging limitation above remains; these checks establish layout and content preservation |

The rendered products and their build times are recorded in `build.csv`.

## R source cleanup — 30 September 2026

This report-only cleanup keeps the saved Model 1.06 inputs and scientific
interpretation. The active annex workflow uses R and Quarto. Historical Python
scripts remain in the archive as evidence; the separate wiki builder keeps Python.

The risk-table code is now in `R/risk_tables.R`. Selectivity extraction uses
plain loops and tidyverse transformations in `R/selectivity.R`. The Quarto pages
source those helpers; duplicate package loads, unused calculations and abandoned
table code were removed. The `check` command requires only `digest`, with report
and Word dependencies checked when their formats are selected.

| Check | Result | Evidence |
|---|---|---|
| Input identity | Pass | All 45 saved-input and archive hashes match the inventory |
| Risk calculations | Pass | All 180 records reproduce the reviewed export within 1e-9 |
| Selectivity extraction | Pass | Both source types under both stock hypotheses exactly match the original four data frames |
| Annex HTML content | Pass | All 14,847 table cells, 97 captions, figure descriptions and bibliography match the baseline at `0d66c7d` |
| Figure comparison | Pass with small raster differences | All 50 dimensions match; three images are pixel-identical; the other 47 differ by at most 6/255 per colour channel, as recorded in `figure-cleanup-comparison.csv` |
| Figure visual review | Pass | Inspected the catch-by-fleet and two-stock fishery selectivity figures |
| Figure zoom | Pass | All 50 lightbox links use their displayed embedded images; separate figure directories are unnecessary |
| Clean-session render | Pass | Annex and handover HTML rebuilt in independent R sessions, using the installed user library and excluding user startup files |
| Wiki copies and links | Pass | All 21 annex copy hashes and 370 local links/fragments across 15 pages checked |
| Search | Pass | All destinations in 24 documents and 345 passages checked; browser-search JavaScript checks pass |
| Source checks | Pass | All annex R files parse; whitespace checks pass; active code contains no credential values or absolute internal data paths |
| Model fitting and compilation | Not Applicable | This cleanup reads the saved assessment and projection products |
| PDF and Word rebuild | Not Tested in this cleanup | Existing reviewed products retain their earlier hashes and build dates in `build.csv` |
| Interactive browser review | Not Tested | Browser URL policy rejected the local `file://` preview; embedded links were checked directly |
| Accessibility certification | Not Tested | Existing PDF tagging and manual-review limitations remain |

The HTML render logs contain no new render warnings. Loading the inherited
`jjmR` dependencies emits a Tcl display-connection warning in this headless
environment; the report renders and content checks above pass. The local wiki
copies and search index were refreshed. These changes have not been published.
