# Fungi bias workflow

Modular R workflow for plotting and analysing sampling-intensity (bias)
rasters across fungi groups.

## Files

| File | Purpose |
|------|---------|
| `00_config.R` | **Edit this between datasets.** Paths, group prefix/indices, regions, plotting settings, output filenames. |
| `01_setup.R` | Packages + shared helper functions. Sourced by every module. |
| `02_full_maps.R` | Multi-page PDF of full country maps for all groups, one shared color scale. |
| `03_region_maps.R` | Per group: full map with highlighted regions + zoomed-in panels. Plots in the RStudio Plots pane. |
| `04_extract_values.R` | Extracts bias values per region cell for the extract subset of groups → Excel. |
| `05_randomization.R` | Block-randomization test using the Excel from module 04 → CSV outputs + histogram. |
| `run_all.R` | Runs modules 02 → 05 in order. |

## Typical use

1. Open `00_config.R`.
2. Change `data_root`, `group_prefix`, `group_indices`, and (if needed) `group_ref` / `extract_group_indices`.
3. Either:
   - Source `run_all.R` to run everything, **or**
   - Source one module at a time (e.g. `source("02_full_maps.R")`).

## Switching datasets

For a new dataset following the same `<root>/<subfolder>/<prefix><N>/Bias/Bias.rds`
structure, only `00_config.R` should need editing — typically:

- `data_root`
- `group_prefix` and `group_indices`
- `group_ref` (must be a group that exists on disk)
- `extract_group_indices` (subset used in module 04)

Region coordinates, country, plotting, and output filenames also live in
`00_config.R` if you want to change them.

## Dependencies

Auto-installed if missing: `rnaturalearthhires`, `writexl`, `readxl`.
Must already be installed: `terra`, `sf`, `rnaturalearth`.
