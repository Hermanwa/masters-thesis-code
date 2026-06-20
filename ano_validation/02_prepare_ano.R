# =============================================================================
# 02_prepare_ano.R  --  Build plot-level presence/absence + temporal hold-out
# =============================================================================
# Output: sf of ANO vegetation plots (EPSG:25833, metres) + a plot x species
# presence/absence matrix for the hold-out year(s).
#
# ANO data facts (from the GBIF download, confirmed):
#   * eventDate is just the YEAR; use the clean `year` column (2020-2024).
#   * plot unit  = parentEventID  (e.g. ANO_2021:0587:51 = year:site:plot).
#   * occurrenceStatus is all PRESENT -> absences inferred by COMPLETE-LIST:
#     ANO records every vascular species rooted in the 1 m^2 plot, so a modelled
#     species not listed for a plot is a TRUE absence. (This is exactly the
#     property fungi lack, and why only plants can be validated.)
# =============================================================================

source(file.path(getwd(), "ano_validation", "00_config_ano.R"))
suppressPackageStartupMessages({ library(dplyr); library(sf); library(tidyr) })

ano_raw <- readRDS(file.path(out_dir, "ano_raw.rds"))

# ---- Clean + keys -----------------------------------------------------------
ano <- ano_raw %>%
  filter(!is.na(decimalLatitude), !is.na(decimalLongitude),
         !is.na(species), nzchar(species)) %>%       # species-level only
  mutate(
    year    = as.integer(year),                      # clean GBIF column
    plot_id = as.character(parentEventID),            # 1 m^2 vegetation plot
    sp      = gsub(" ", "_", species)                 # match model folder naming
  ) %>%
  filter(!is.na(plot_id), nzchar(plot_id))

cat("\n=== ANO year distribution (clean) ===\n")
print(table(ano$year, useNA = "ifany"))

# ---- Spatialise + reproject to model CRS (metres) ---------------------------
ano_sf <- st_as_sf(ano, coords = c("decimalLongitude", "decimalLatitude"),
                   crs = 4326, remove = FALSE) %>%
  st_transform(crs_model)

# Mainland clip: drop Svalbard/Jan Mayen via a northing ceiling (UTM33N metres).
ano_sf <- ano_sf %>% filter(st_coordinates(.)[, 2] < 7.95e6)

# ---- Hold-out year(s) -------------------------------------------------------
ano_hold <- ano_sf %>% filter(year >= holdout_from_year)
cat("\nHold-out (year >=", holdout_from_year, "): ",
    nrow(ano_hold), "records, ",
    length(unique(ano_hold$plot_id)), "plots\n")
if (nrow(ano_hold) == 0)
  stop("No hold-out records. Re-check holdout_from_year against the table above.")

# ---- One point per plot -----------------------------------------------------
plots_sf <- ano_hold %>%
  group_by(plot_id) %>% slice(1) %>% ungroup() %>%
  select(plot_id, year)

# ---- Presence/absence matrix (plot x species) -------------------------------
# Explicit absences if the archive ever ships them; else complete-list (1 where
# recorded, 0 elsewhere via fill).
has_explicit_abs <- "occurrenceStatus" %in% names(ano_hold) &&
  any(toupper(ano_hold$occurrenceStatus) == "ABSENT")

pa_long <- ano_hold %>% st_drop_geometry() %>%
  { if (has_explicit_abs)
      transmute(., plot_id, sp,
                present = as.integer(toupper(occurrenceStatus) != "ABSENT"))
    else
      transmute(., plot_id, sp, present = 1L) } %>%
  distinct(plot_id, sp, present)

pa_mat <- pa_long %>%
  pivot_wider(names_from = sp, values_from = present, values_fill = 0L)

# ---- Save -------------------------------------------------------------------
saveRDS(list(plots_sf = plots_sf, pa_mat = pa_mat,
             complete_list_inferred = !has_explicit_abs),
        file.path(out_dir, "ano_prepared.rds"))

cat("Prepared", nrow(plots_sf), "plots x", ncol(pa_mat) - 1, "species.",
    if (has_explicit_abs) "Explicit absences.\n"
    else "Absences inferred via complete-list assumption.\n")
