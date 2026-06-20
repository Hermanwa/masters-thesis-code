# =============================================================================
# 00_config_ano.R  --  Config for ANO (vascular plant) validation chapter
# =============================================================================
# Validates the existing free-SPDE bias-corrected vascular-plant predictions
# against an independent, newer (held-out) ANO survey.
#
# Pipeline:
#   01_download_ano.R   -> pull ANO from GBIF (Norway mainland, vascular plants)
#   02_prepare_ano.R    -> build plot-level presence/absence, flag temporal holdout
#   03_validate_vascular.R -> score predictions at ANO plots (AUC, regions, bias link)
#
# NOTE: real model outputs live on D:/. Run this on that machine.
# Lines marked  ## CONFIRM  are assumptions you should check before running.
# =============================================================================

suppressPackageStartupMessages({
  library(terra); library(sf)
})

# ---- Paths to your existing model outputs -----------------------------------
data_root      <- "D:/"                       ## CONFIRM (matches your other scripts)
vasc_subfolder <- "vascularPlants"            ## CONFIRM folder name on D:/
# Per-species prediction:  <data_root>/<vasc_subfolder>/<vasc_subfolder><N>/<Species>/Richness.rds
# Bias field (group level): <data_root>/<vasc_subfolder>/<vasc_subfolder><N>/Bias/Bias.rds

# Layer name to read out of the wrapped rasters (your Bias.rds uses "mean")
pred_layer <- "mean"                          ## CONFIRM layer name inside Richness.rds

# Robustly find model segments = folders that actually hold a bias field.
# Excludes helper dirs (processedOutputs_*, *Outputs) that have no Bias/Bias.rds.
find_segments <- function(group_dir) {
  d <- list.dirs(group_dir, recursive = FALSE)
  d[file.exists(file.path(d, "Bias", "Bias.rds"))]
}

# ---- Output location --------------------------------------------------------
out_dir <- file.path(getwd(), "ano_validation", "output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Spatial reference (matches your mesh / bias rasters) --------------------
crs_model <- "EPSG:25833"   # ETRS89 / UTM 33N, metres

# ---- ANO dataset + GBIF -----------------------------------------------------
ano_dataset_key <- "edb656a0-71ad-418d-afb1-c5584283ba47"  # ANO on GBIF
max_coord_uncertainty_m <- 100   # mirror the hotspot report's filter

# GBIF credentials: stored in your .Renviron (verified working, 200 OK).
# Loaded here so a stray Sys.setenv placeholder in the session can't shadow them.
renv_path <- "C:/Users/herma/OneDrive/Dokumenter/.Renviron"
if (file.exists(renv_path)) readRenviron(renv_path)
gbif_user  <- Sys.getenv("GBIF_USER")
gbif_pwd   <- Sys.getenv("GBIF_PWD")
gbif_email <- Sys.getenv("GBIF_EMAIL")

# ---- Temporal hold-out ------------------------------------------------------
# GBIF ANO coverage is 2020-2024 (NO 2025). ANO rotates ~1/5 of its sites each
# year, so 2024 plots are at NEW locations. The hotspot model's ANO snapshot was
# accessed Nov 2024; we take 2024 as the hold-out, ASSUMING the 2024 field season
# was not yet incorporated then (state this assumption + caveat in the thesis).
holdout_from_year <- 2024

# ---- Regions (reuse your existing 12-region definition) ---------------------
# region_centers: data.frame(region, x, y) with x,y in UTM-33 *kilometres*.
src_config <- file.path(getwd(), "00_config_12_updated.R")
if (file.exists(src_config)) {
  source(src_config)          # provides region_centers
} else {
  message("00_config_12_updated.R not found - define region_centers manually.")
}
region_half_km <- 5           ## CONFIRM: half-width of region square (km). Your
                              # randomization used ~10 km squares -> half = 5 km.
