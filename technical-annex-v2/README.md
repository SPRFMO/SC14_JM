# Jack mackerel technical annex

This is the maintained **technical-annex-v2** in the **SC14_JM** repository.
The scientific results remain the saved September 2026 Model 1.06 results.

Open `output/technical-annex.html` to read the annex. Edit the `.qmd` files in
`report/`. Read [the handover](report/technology-transfer.qmd) to trace the
calculations and prepare the next assessment update.

From this folder:

```sh
Rscript build.R            # annex and handover in HTML
Rscript build.R all        # HTML, PDF and Word
Rscript build.R pdf annex  # just the annex PDF
Rscript build.R check      # input hashes and all 180 risk calculations
```

The workflow uses **R and Quarto**. PDF also needs XeLaTeX and the fonts listed
in `report/_quarto.yml`. Install the report packages in R:

```r
install.packages(c("tidyverse", "flextable", "knitr", "scales", "rmarkdown",
                   "digest", "xml2", "zip", "colorspace", "doBy", "foreach",
                   "ggridges", "gridExtra", "icesAdvice", "latticeExtra",
                   "patchwork", "PBSmodelling"))
install.packages("software/jjmR_1.2020.1.tar.gz", repos = NULL, type = "source")
```

The bundled `jjmR` contains the local fixes used for these reports; its version
number alone does not identify those fixes. Its source manifest and patch are
in `software/`. The build checks dependencies and writes `validation/R-session.txt`.

| Folder | Purpose |
|---|---|
| `data/assessment/` | Saved observations, controls, fitted results and retrospectives |
| `data/projections/` | Saved ten-year projection results, standard errors and run manifest |
| `data/derived/` | Regenerated CSV summaries and R objects |
| `R/` | Readable calculation and formatting helpers |
| `report/` | Editable text, R chunks, references, diagrams and document styles |
| `output/` | Generated annex and handover |
| `software/` | Matching `jjmR` source and the projection `jjm.tpl` |
| `validation/` | Build logs, environment, product hashes and migration checks |
| `archive/` | Historical sources and reviews; excluded from the build |

Every build checks `data/input-checksums.csv`. It stops if a saved input changes.
It calculates each risk probability from the saved base BMSY and projection
SSB/standard error, then compares all records with the reviewed export.
Model fitting and new projection runs belong to the JJM assessment workflow.

No Python installation is needed for this annex. The repository's separate wiki
builder retains its existing implementation. Publishing and committee acceptance
are separate from building this working assessment.
