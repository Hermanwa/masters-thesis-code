# ============================================================
# run_all.R
# ============================================================
# Run the full workflow end-to-end.
# Edit 00_config.R first, then source this file.
#
# You can also run individual modules independently — each one
# sources 00_config.R and 01_setup.R if they aren't loaded yet.
# ============================================================

# Make sure we run from the workflow folder
# (uncomment and adjust if needed):
# setwd("C:/path/to/fungi_workflow")

source("00_config.R")
source("01_setup.R")

cat("\n### Module 02: full maps PDF ###\n")
source("02_full_maps.R")

cat("\n### Module 03: region maps (RStudio Plots) ###\n")
source("03_region_maps.R")

cat("\n### Module 04: extract values to Excel ###\n")
source("04_extract_values.R")

cat("\n### Module 05: randomization test ###\n")
source("05_randomization.R")

cat("\nDone. Outputs in:", out_root, "\n")
