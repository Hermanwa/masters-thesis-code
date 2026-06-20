# =============================================================================
# 01_download_ano.R  --  Pull ANO vascular-plant records from GBIF (Norway only)
# =============================================================================
# Reproducible, citable download via rgbif::occ_download (mints a DOI).
# Restricted to: ANO dataset, country = Norway, vascular plants (Tracheophyta),
# georeferenced, coordinate uncertainty <= 100 m (mirrors hotspot report).
#
# Alternative source (richer plot metadata): the ANO GeoPackage from
# Miljodirektoratet (kartkatalog .../Dataset/Details/2054). Use that if the GBIF
# DwC-A lacks per-plot structure you need.
# =============================================================================

source(file.path(getwd(), "ano_validation", "00_config_ano.R"))
suppressPackageStartupMessages(library(rgbif))

stopifnot(nzchar(gbif_user), nzchar(gbif_pwd), nzchar(gbif_email))

# Resolve the vascular-plant clade key (phylum Tracheophyta) from the backbone.
tracheophyta_key <- name_backbone("Tracheophyta")$usageKey
message("Tracheophyta taxonKey: ", tracheophyta_key)

# ---- Request the download ---------------------------------------------------
dl <- occ_download(
  pred("datasetKey", ano_dataset_key),
  pred("country", "NO"),
  pred("taxonKey", tracheophyta_key),
  pred("hasCoordinate", TRUE),
  pred("hasGeospatialIssue", FALSE),
  pred_lte("coordinateUncertaintyInMeters", max_coord_uncertainty_m),
  user = gbif_user, pwd = gbif_pwd, email = gbif_email
)

cat("Download key:", dl, "\n")
occ_download_wait(dl)               # blocks until GBIF finishes building it

# ---- Fetch + import ---------------------------------------------------------
zip_path <- occ_download_get(dl, path = out_dir, overwrite = TRUE)
ano_raw  <- occ_download_import(zip_path)

# Persist raw + the citation DOI (cite this in the thesis).
saveRDS(ano_raw, file.path(out_dir, "ano_raw.rds"))
writeLines(
  c(paste("GBIF download key:", dl),
    paste("DOI:", attr(zip_path, "doi")),
    paste("Downloaded:", Sys.time())),
  file.path(out_dir, "ano_download_citation.txt")
)

cat("Saved", nrow(ano_raw), "records to", file.path(out_dir, "ano_raw.rds"), "\n")
cat("NOTE: the GBIF DwC-A may include Svalbard/Jan Mayen; mainland clipping\n",
    "is done in 02_prepare_ano.R against your region geometry CRS.\n")
