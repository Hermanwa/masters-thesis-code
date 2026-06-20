# ============================================================
# run_all_12.R
# ============================================================
# Kjører HELE workflowen med 12 regioner, uten å røre den
# vanlige 6-regionskjøringen. Output får egne filnavn (_12reg),
# så ingenting overskrives.
#
# Bruk: source("run_all_12.R")
# (kjør gjerne i en frisk R-økt, eller restart etter run_all.R)
# ============================================================

# Pek på overstyringsfila FØR vi sourcer modulene.
ALT_CONFIG <- "00_config_12.R"

source("00_config.R")   # laster base, og sourcer 00_config_12.R til slutt
source("01_setup.R")

cat("\n### Module 02: full maps PDF (12 reg) ###\n")
source("02_full_maps.R")

cat("\n### Module 03: region maps (12 reg) ###\n")
source("03_region_maps.R")

cat("\n### Module 04: extract values to Excel (12 reg) ###\n")
source("04_extract_values.R")

cat("\n### Module 05: randomization test (12 reg) ###\n")
source("05_randomization.R")

cat("\nDone (12 regioner). Outputs i:", out_root, "\n")

# Rydd opp så variabelen ikke henger igjen og påvirker en senere
# vanlig run_all.R i samme R-økt.
rm(ALT_CONFIG)
