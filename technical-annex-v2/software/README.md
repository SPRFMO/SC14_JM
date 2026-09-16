# Software behind the saved results

`jjmR_1.2020.1.tar.gz` is the exact R source package bundled with the original
technical annex. Install it after its CRAN dependencies. The source revision,
SHA-256 checksums and local modifications are recorded in
`jjmR-source-manifest.json` and `jjmR-working-tree.patch`. The accompanying
installed-source comparison records the original 273-function comparison.

`jjm.tpl` is the unchanged template for the saved ten-year projections. Its
SHA-256 is `b3bef2d3147d967e679140be99d912119061f786c3e0eeea48f11801a31fe7bc`,
matching `data/projections/manifest.json`. It separates the global 15-year
selectivity reference from scenario 4's 3-year future-selectivity calculation.

The original base assessment outputs have a different history: their assessment
script selected the `jjm2` executable. The exact historical compiled template
version is unverified. This bundled `jjm.tpl` establishes projection provenance,
not the compiler provenance of every historical fit.

The report build reads saved results. It does not compile ADMB or estimate a
model. Historical Python export and validation scripts remain inside
`archive/september-12-history.zip`; current risk extraction is `R/risk_data.R`.
