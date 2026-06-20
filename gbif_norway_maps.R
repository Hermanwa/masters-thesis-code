# ============================================================================
# Formal GBIF occurrence download + four occurrence maps for Norway
# Species: Fomitopsis pinicola, Lysimachia europaea (syn. Trientalis europaea),
#          Turdus pilaris, Falco peregrinus
#
# Uses occ_download() -> produces a citable DOI (required for formal use).
# Maps: four separate PNGs, ggplot2 + sf, Norway coastline/borders.
# ============================================================================

# --- 0. Packages ------------------------------------------------------------
# install.packages(c("rgbif", "sf", "ggplot2", "dplyr",
#                     "rnaturalearth", "rnaturalearthdata"))
library(rgbif)
library(sf)
library(ggplot2)
library(dplyr)
library(rnaturalearth)

# --- 1. Credentials ---------------------------------------------------------
# These are read from your .Renviron file (see README_gbif_setup.txt).
# NEVER hard-code your password in this script.
gbif_user  <- Sys.getenv("GBIF_USER")
gbif_pwd   <- Sys.getenv("GBIF_PWD")
gbif_email <- Sys.getenv("GBIF_EMAIL")

stopifnot(
  "GBIF_USER not set in .Renviron"  = nzchar(gbif_user),
  "GBIF_PWD not set in .Renviron"   = nzchar(gbif_pwd),
  "GBIF_EMAIL not set in .Renviron" = nzchar(gbif_email)
)

# --- 2. Resolve taxon keys --------------------------------------------------
# We match each name against the GBIF backbone. Filtering a download by the
# accepted usageKey automatically captures records recorded under synonyms
# (e.g. Trientalis europaea -> Lysimachia europaea).
species <- c(
  "Fomitopsis pinicola",
  "Lysimachia europaea",
  "Turdus pilaris",
  "Falco peregrinus"
)

backbone <- lapply(species, function(sp) name_backbone(name = sp))

# Coerce usageKey to numeric (GBIF may return it as character) and flag
# any species that failed to match the backbone.
keys <- vapply(backbone, function(b) {
  k <- b$usageKey
  if (is.null(k) || length(k) == 0) NA_real_ else as.numeric(k)
}, numeric(1))

# Print what GBIF matched so you can sanity-check before downloading
cat("\nTaxon matches:\n")
for (i in seq_along(species)) {
  cat(sprintf("  %-22s -> %s (key %s, status: %s, match: %s)\n",
              species[i],
              if (!is.null(backbone[[i]]$scientificName)) backbone[[i]]$scientificName else "NO MATCH",
              keys[i],
              if (!is.null(backbone[[i]]$status)) backbone[[i]]$status else NA,
              if (!is.null(backbone[[i]]$matchType)) backbone[[i]]$matchType else NA))
}

if (any(is.na(keys))) {
  stop("Some species did not match the GBIF backbone: ",
       paste(species[is.na(keys)], collapse = ", "))
}

# --- 3. Submit the formal download (or reuse an existing one) ----------------
# If you already ran a download and want to reuse it (same DOI, no waiting),
# put its key here. Set to NULL to submit a fresh download.
existing_key <- "0031086-260519110011954"   # set to NULL for a new download

# One download covering all four species, restricted to MAINLAND Norway:
# country = NO intersected with a bounding polygon that excludes Svalbard
# (lat > 74) and Jan Mayen (lon < 0). WKT ring is counter-clockwise as GBIF
# requires.
mainland_wkt <- "POLYGON((4 57.5, 32 57.5, 32 72, 4 72, 4 57.5))"

if (is.null(existing_key)) {
  dl <- occ_download(
    pred_in("taxonKey", keys),
    pred("country", "NO"),
    pred_within(mainland_wkt),
    pred("hasCoordinate", TRUE),
    pred("hasGeospatialIssue", FALSE),
    pred("occurrenceStatus", "PRESENT"),
    format = "SIMPLE_CSV",
    user = gbif_user, pwd = gbif_pwd, email = gbif_email
  )
  cat("\nDownload submitted. Key:", dl, "\n")
  occ_download_wait(dl)   # poll until GBIF finishes assembling the archive
} else {
  dl <- existing_key
  cat("\nReusing existing download. Key:", dl, "\n")
}

# --- 4. Retrieve, import, and capture the citation --------------------------
# Make sure the target folder exists first (occ_download_get won't create it).
dir.create("gbif_data", showWarnings = FALSE, recursive = TRUE)

dat_raw <- occ_download_get(dl, path = "gbif_data", overwrite = TRUE) |>
  occ_download_import()

meta <- occ_download_meta(dl)
citation_text <- gbif_citation(meta)$download
cat("\n========== CITE THIS DOWNLOAD ==========\n")
cat("DOI:", meta$doi, "\n")
cat(citation_text, "\n")
cat("========================================\n")
writeLines(c(paste("DOI:", meta$doi), citation_text),
           file.path("gbif_data", "CITATION.txt"))

# --- 5. Tidy the occurrence data --------------------------------------------
occ <- dat_raw |>
  filter(!is.na(decimalLongitude), !is.na(decimalLatitude)) |>
  select(species, scientificName, decimalLongitude, decimalLatitude,
         taxonKey, speciesKey, year, basisOfRecord)

# Tag each record with the species label we want on the map.
# Match on speciesKey so synonym records are grouped to the accepted species.
label_lookup <- setNames(species, keys)
occ <- occ |>
  mutate(map_species = label_lookup[as.character(speciesKey)],
         map_species = ifelse(is.na(map_species),
                              label_lookup[as.character(taxonKey)],
                              map_species))

cat("\nRecords per species (Norway):\n")
print(table(occ$map_species, useNA = "ifany"))

# Convert to an sf point layer (WGS84)
occ_sf <- st_as_sf(occ, coords = c("decimalLongitude", "decimalLatitude"),
                   crs = 4326, remove = FALSE)

# --- 6. Basemap -------------------------------------------------------------
# Crop everything to the mainland bounding box (matches the download polygon)
# so Svalbard / Jan Mayen don't stretch the map.
mainland_bb <- st_bbox(c(xmin = 4, ymin = 57.5, xmax = 32, ymax = 72),
                       crs = 4326)

norway <- ne_countries(scale = "large", country = "Norway",
                       returnclass = "sf") |>
  st_crop(mainland_bb)
neighbours <- ne_countries(scale = "large", continent = "Europe",
                           returnclass = "sf") |>
  st_crop(mainland_bb)

# --- 7. Plot four separate maps ---------------------------------------------
dir.create("maps", showWarnings = FALSE)

point_cols <- c(
  "Fomitopsis pinicola" = "#8c510a",
  "Lysimachia europaea" = "#1b7837",
  "Turdus pilaris"      = "#762a83",
  "Falco peregrinus"    = "#b2182b"
)

make_map <- function(sp_name) {
  pts <- occ_sf |> filter(map_species == sp_name)
  if (nrow(pts) == 0) {
    message("No records for ", sp_name, " - skipping.")
    return(invisible(NULL))
  }

  # Fixed view = mainland Norway extent (consistent across all four maps)
  bb <- mainland_bb

  p <- ggplot() +
    geom_sf(data = neighbours, fill = "grey96", colour = "grey80",
            linewidth = 0.2) +
    geom_sf(data = norway, fill = "grey88", colour = "grey40",
            linewidth = 0.4) +
    geom_sf(data = pts, colour = point_cols[[sp_name]],
            size = 1.1, alpha = 0.6) +
    coord_sf(xlim = c(bb["xmin"], bb["xmax"]),
             ylim = c(bb["ymin"], bb["ymax"]), expand = TRUE) +
    labs(
      title = bquote(italic(.(sp_name))),
      subtitle = sprintf("GBIF occurrences in Norway (n = %s)",
                         format(nrow(pts), big.mark = ",")),
      caption = paste0("Source: GBIF.org  |  ", meta$doi),
      x = NULL, y = NULL
    ) +
    theme_minimal(base_size = 11) +
    theme(panel.background = element_rect(fill = "aliceblue", colour = NA),
          panel.grid = element_line(colour = "grey90", linewidth = 0.2),
          plot.title = element_text(face = "italic"))

  fname <- file.path("maps",
                     paste0(gsub(" ", "_", tolower(sp_name)), "_norway.png"))
  ggsave(fname, p, width = 7, height = 8, dpi = 300)
  message("Saved: ", fname)
  invisible(p)
}

invisible(lapply(species, make_map))

cat("\nDone. Maps are in the 'maps/' folder; citation in 'gbif_data/CITATION.txt'.\n")
