# ANO validation chapter (vascular plants)

Validates the existing free-SPDE, bias-corrected **vascular-plant** predictions
against an independent, newer (held-out) **ANO** survey. Vascular plants only —
fungi and birds cannot serve this role (see thesis limitations).

## Run order (on the machine with `D:/`)
1. Set GBIF creds: `Sys.setenv(GBIF_USER=..., GBIF_PWD=..., GBIF_EMAIL=...)`
2. `source("ano_validation/01_download_ano.R")`  — pull ANO (Norway, vascular, ≤100 m)
3. `source("ano_validation/02_prepare_ano.R")`   — **read the printed year table**,
   set `holdout_from_year` in `00_config_ano.R`, re-run
4. `source("ano_validation/03_validate_vascular.R")` — AUC + regions + bias diagnostic

## Outputs (`ano_validation/output/`)
- `auc_per_species.csv`  — per-species discrimination on the hold-out
- `auc_per_region.csv`   — AUC across your 12 regions
- `plot_bias_values.csv` — modelled bias sampled at each plot
- `ano_download_citation.txt` — GBIF DOI to cite

## Check before trusting results (`## CONFIRM` markers in the code)
- `data_root` / `vasc_subfolder` paths on `D:/`
- layer name inside `Richness.rds` (assumed `"mean"`, as in `Bias.rds`)
- the plot key (`eventID`) and the mainland northing cutoff
- whether the GBIF archive carries explicit `occurrenceStatus = ABSENT`
  (else absences use the complete-list assumption — valid for ANO plots)

## Coordinate gotcha (already handled in the code)
The saved `Richness.rds` / `Bias.rds` rasters are EPSG:25833 but stored in
**kilometres** (extent ~[-90,1124] x [6443,7944] km), CRS labelled "unknown",
effective resolution **1 km** (not the 500 m modelling grid). ANO points are
reprojected to 25833 *metres* in `02`, then **divided by 1000** and extracted by
raw coordinate in `03`. Verified: extraction returns sensible occupancy (alpine
species high in the north) and bias (most negative in Tromsø). Validation is
therefore at the **1 km** saved-prediction resolution

## Key modelling note
This validates the **corrected predictions** against an unbiased survey. The
absence logic relies on ANO plots being exhaustive for vascular plants, so a
non-recorded modelled species is a true absence. That assumption is exactly what
fails for fungi (no exhaustive survey, no real absences).
