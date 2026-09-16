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
