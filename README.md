# Sampling bias in Norwegian biodiversity occurrence data

R (and a little Python) code accompanying my thesis on **spatial sampling
bias in species-occurrence data from Norway**, including a validation against
independent ANO (Arealrepresentativ naturovervåking) vascular-plant survey
data.

> **Note for readers / report citation:** this repository holds the *code*
> used to produce the analyses and figures. Large input data (GBIF downloads)
> and generated outputs (maps, rasters, tables) are **not** committed — see
> [Data](#data) for how to regenerate them. The exact code state used in the
> thesis is the tagged release / commit referenced in the report.

## Repository layout

```
.
├── README.md                  ← you are here
├── Workflow/                  ← bias-map + randomization pipeline (modular, numbered)
├── ano_validation/            ← independent validation against ANO vascular-plant data
├── gbif_norway_maps.R         ← download GBIF occurrences + example country maps
├── README_gbif_setup.txt      ← one-time GBIF credential setup
│
│   # Mesh / region geometry
├── meshNodes.R                ← SPDE mesh node plots
├── meshRegionPanels.R         ← per-region mesh panels
├── fix_region_centers.R       ── region-centre fixes
├── verify_centers.R           ── region-centre checks
│
│   # Variance / ANOVA / randomization analyses
├── total_variance.R
├── new_total_variance.R
├── two_way_anova_all_datasets.R
├── two_way_anova_fungi.R
├── two_way_anova_region_comparison.R
├── anova_effectsize_barchart.R
├── permutation_all_datasets.R
├── permutation_histogram.R
├── 00_config_12_updated.R     ← shared config for the 12-region analyses
│
└── build_deck.py              ← assembles result figures into a PowerPoint (python-pptx)
```

## The `Workflow/` pipeline

Modular R workflow for plotting and analysing sampling-intensity (bias)
rasters across taxon groups (fungi, birds, …).

| File | Purpose |
|------|---------|
| `00_config.R` / `00_config_12.R` | **Edit between datasets.** Paths, group prefix/indices, regions, plotting settings, output filenames. |
| `01_setup.R` | Packages + shared helper functions. Sourced by every module. |
| `02_full_maps.R` | Multi-page PDF of full country maps for all groups, one shared colour scale. |
| `03_region_maps.R` | Per group: full map with highlighted regions + zoomed-in panels. |
| `04_extract_values.R` | Extracts bias values per region cell for a subset of groups → Excel. |
| `05_randomization.R` | Block-randomization (permutation) test using the Excel from module 04 → CSV + histogram. |
| `06_png_maps.R` / `06_png_maps_multi.R` | PNG renderings of the maps. |
| `run_all.R` / `run_all_12.R` | Run modules `02 → 05` in order (6- and 12-region variants). |

**Typical use:** edit `00_config.R` (`data_root`, `group_prefix`,
`group_indices`, `group_ref`, `extract_group_indices`), then either
`source("Workflow/run_all.R")` or source one module at a time.

Expected on-disk data structure:
`<root>/<subfolder>/<prefix><N>/Bias/Bias.rds`.

## `ano_validation/`

Independent validation of the bias signal against ANO vascular-plant survey
data (see `ano_validation/README.md`). Scripts are numbered `00 → 03`
(config → GBIF auth check → download → prepare → validate).

## Requirements

- **R** (≥ 4.x) and the following packages:

  ```r
  install.packages(c(
    "terra", "sf", "fmesher",
    "rnaturalearth", "rnaturalearthhires",
    "rgbif", "httr",
    "dplyr", "tidyr", "ggplot2", "patchwork",
    "pROC", "readxl", "writexl"
  ))
  ```
  `rnaturalearthhires` may need: `remotes::install_github("ropensci/rnaturalearthhires")`.

- **Python 3** with `python-pptx` (only for `build_deck.py`):
  `pip install python-pptx`.

## Data

Occurrence data come from **GBIF** and are downloaded by the scripts — they
are not stored in this repository.

1. Set up GBIF credentials once (see `README_gbif_setup.txt`). Credentials
   live in your R `.Renviron` file and are read via `Sys.getenv()`; they are
   **never** hard-coded and `.Renviron` is git-ignored.
2. Run `gbif_norway_maps.R` (and the `ano_validation` download script) to
   fetch data. Each download produces a DOI, saved to a `CITATION.txt`, which
   is what you cite for the data itself.

## Citing this code

When referencing this repository in the thesis, cite the specific version
(a tagged release or commit hash), not just the URL, so the citation points
at the exact code used. For a permanent, citable identifier, the repository
can be linked to [Zenodo](https://zenodo.org) to mint a DOI on release.

## License

See [`LICENSE`](LICENSE).
