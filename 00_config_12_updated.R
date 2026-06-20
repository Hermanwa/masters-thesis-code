# ============================================================
# 00_config_12.R  --  overstyring for 12-regionskjøringen
# ============================================================
# UPDATED: Svolvær and Kirkenes centers nudged so each region's
# 10 km square touches a full 121 non-NA bias cells.
#   Svolvær : x 480 -> 477   (3 km west)
#   Kirkenes: y 7802 -> 7801 (1 km south)
# Verified to give 121 non-NA cells for all 20 groups.
# ============================================================


# ---- Regioner: de 6 gamle + 6 nye -------------------------------------
region_centers <- data.frame(
  region = c("Setesdal", "Oslo", "Valdres", "Trondheim", "Tromsø", "Lakselv",
             "Bergen", "Kristiansand", "Skorovatn", "Bodø", "Svolvær", "Kirkenes"),
  x = c(100, 255, 200, 280, 650, 900,
        -28,  84,   420, 486, 477, 1075),
  y = c(6600, 6655, 6780, 7030, 7680, 7800,
        6734, 6472, 7161, 7467, 7572, 7801)
)


# ---- Nye filnavn slik at 6-regionsfilene IKKE overskrives -------------
file_full_maps_pdf    <- "bias_mean_all_groups_12reg.pdf"
file_region_maps_pdf  <- "bias_mean_region_maps_12reg.pdf"
file_extract_xlsx     <- "bias_region_values_touching_cells_12reg.xlsx"
file_rand_summary     <- "randomization_summary_all_target_groups_12reg.csv"
file_rand_variances   <- "randomization_regional_variances_all_target_groups_12reg.csv"
file_rand_top10       <- "randomization_top10_changes_per_target_group_12reg.csv"
file_rand_sensitivity <- "randomization_region_sensitivity_12reg.csv"
file_rand_plots_pdf   <- "randomization_plots_12reg.pdf"


# ---- (valgfritt) eget utdatamappe i stedet for nye filnavn ------------
# out_root <- file.path(out_root, "run_12regions")
