# HTML document-link validation

Checked 8 September 2026.

- Repository: SPRFMO/SC14_JM; GitHub Pages publishes main/docs (verified using GitHub API).
- Base revision: 48f021e8b6d7d384f17a350ee0e49f4acdf6faea.
- Rebuilt all 10 pages using `python3 build.py`.
- Replaced 37 document links across seven Markdown pages and corresponding generated HTML pages.
- Seven HTML destinations fetched successfully using curl with TLS verification; page titles identify the corresponding reports. Mapping and observed titles are in document-links.json.
- Validated 152 local page, stylesheet and fragment links: no missing targets.
- No replaced PDF destinations remain in any source or rendered page.
- Official SC14 index was inspected; it exposes PDF submissions and no .html document links. Targeted web searches and the working-group sources did not establish other HTML counterparts.
- Exact equivalence between working HTML revisions and submitted PDFs was not established; sources.md explicitly distinguishes them.
- Browser check: meetings.html layout and sources.html document labels/destinations inspected successfully.
- `git diff --check` passed.
- Checks above were completed before publication; publication was subsequently authorized.

## No verified HTML counterpart found

- JM04: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM-04-Independent-desk-review-of-the-SPRFMO-JM-MSE.pdf)
- JM01: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM01-Catch-history-of-Trachurus-murphyi.pdf)
- JM10: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM10-Standardization-of-commercial-CPUE-for-CJM-rs.pdf)
- JM11: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM11-Hydroacoustic-assessment-of-CJM-in-the-northern-zone-of-Chile-2026.pdf)
- JM12: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM12_rev1-Management-Strategies-Evaluation-for-the-Jack-Mackerel-Fishery.pdf)
- JM13: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM13_rev1-Improving-Hydroacoustic-Assessment-of-Chilean-Jack-Mackerel.pdf)
- JM14: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM14-A-spatio-temporal-approach-for-standardizing-acoustic-survey-indices-of-CJM.pdf)
- JM15: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM15-Update-CJM-CPUE-Index-based-on-fishing-trip-database-and-Acoustic-Biomass-Estimates.pdf)
- JM16: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM16-Spatiotemporal-Dynamics-of-the-CJM-Fishery-off-Central-Southern-Chile-During-202026.pdf)
- JM17: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM17-Implementation-of-an-informed-creep-correction-into-the-CJM-CPUE-index.pdf)
- JM18: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM18-JM-acoustic-density-index-in-the-central-north-acoustic-surveys.pdf)
- JM19: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM19-Update-of-Chilean-Jack-Mackerel-CPUE-abundance-index-estimated.pdf)
- JM20: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM20-PFA-selfsampling-report-for-the-SPRFMO-Science-Committee-2026.pdf)
- JM21: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Jack-Mackerel/SC14-JM21-PFA-2026-SPRFMO-offshore-fleet-CPUE-standardisation-2026.pdf)
- Doc01: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Plenary/SC14-Doc01-SC14-Provisional-Agenda.pdf)
- Doc02: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Plenary/SC14-Doc02-Annotated-Provisional-SC14-Agenda-v2.pdf)
- Doc04: [official PDF](https://www.sprfmo.int/assets/Meetings/02-SC/14th-SC-2026/Plenary/SC14-Doc04_rev2-SC14-Meeting-Schedule_24-Aug.pdf)
