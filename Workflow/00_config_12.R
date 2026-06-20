# ============================================================
# 00_config_12.R  --  overstyring for 12-regionskjøringen
# ============================================================
# Denne fila sources HELT TIL SLUTT av 00_config.R, men bare
# når ALT_CONFIG peker hit (se run_all_12.R).
#
# Her legger du KUN det som skal være annerledes enn vanlig.
# Alt annet (paths, gruppenavn, square_size, fargeskala osv.)
# arves fra 00_config.R.
# ============================================================


# ---- Regioner: de 6 gamle + 6 nye -------------------------------------
# Behold de 6 første nøyaktig som i 00_config.R, og fyll inn x/y
# for de 6 nye. NA-ene MÅ erstattes med ekte koordinater før kjøring.
region_centers <- data.frame(
  region = c("Setesdal", "Oslo", "Valdres", "Trondheim", "Tromsø", "Lakselv",
             "Bergen", "Kristiansand", "Skorovatn", "Bodø", "Svolvær", "Kirkenes"),
  x = c(100, 255, 200, 280, 650, 900,
        -28,  84,   420, 486, 480, 1075),
  y = c(6600, 6655, 6780, 7030, 7680, 7800,
        6734, 6472, 7161, 7467, 7572, 7802)
)


# ---- Nye filnavn slik at 6-regionsfilene IKKE overskrives -------------
# Samme out_root og samme bias_maps-mappe, men nye navn. Ingen kollisjon.
file_full_maps_pdf    <- "bias_mean_all_groups_12reg.pdf"
file_region_maps_pdf  <- "bias_mean_region_maps_12reg.pdf"
file_extract_xlsx     <- "bias_region_values_touching_cells_12reg.xlsx"
file_rand_summary     <- "randomization_summary_all_target_groups_12reg.csv"
file_rand_variances   <- "randomization_regional_variances_all_target_groups_12reg.csv"
file_rand_top10       <- "randomization_top10_changes_per_target_group_12reg.csv"
file_rand_sensitivity <- "randomization_region_sensitivity_12reg.csv"
file_rand_plots_pdf   <- "randomization_plots_12reg.pdf"


# ---- (valgfritt) eget utdatamappe i stedet for nye filnavn ------------
# Vil du heller skille alt i en egen mappe, kommenter ut filnavnene over
# og bruk dette i stedet (da kan du beholde de opprinnelige filnavnene):
# out_root <- file.path(out_root, "run_12regions")
