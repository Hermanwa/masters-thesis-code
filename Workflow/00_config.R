# ============================================================
# 00_config.R
# ============================================================
# ALL settings you typically change between datasets live here.
# Edit this file, then run run_all.R (or individual modules).
# ============================================================

# ---- 1) Paths ----------------------------------------------------------
# Root folder that contains the <group_prefix><N>/Bias/Bias.rds structure
data_root <- "D:/"

# Subfolder inside data_root where the groups live (e.g. "fungi")
data_subfolder <- "Newbirds"

# Where to write outputs (PDFs, Excel, CSV).
# Default: a "fungi" folder on the Desktop.
out_root <- "D:/Newbirds/NewbirdsOutputs"


# ---- 2) Group naming ---------------------------------------------------
# Groups are constructed as paste0(group_prefix, group_indices)
# Example: prefix = "fungiA", indices = 1:62  ->  fungiA1 ... fungiA62
group_prefix  <- "birds"
group_indices <- 1:21

# Reference group used to read CRS (must exist on disk)
group_ref <- "birds1"

# Subset of groups used in the EXTRACTION step (module 04).
# Set to group_indices to use the same groups as the rest of the pipeline.
extract_group_indices <- group_indices


# ---- 3) Country / outline ---------------------------------------------
country_name <- "Norway"
ne_scale     <- "large"   # rnaturalearth scale: "small", "medium", "large"


# ---- 4) Regions of interest -------------------------------------------
# Center coordinates (in the raster's CRS) and a square size in km.
region_centers <- data.frame(
  region = c("Setesdal", "Oslo", "Valdres", "Trondheim", "Tromsø", "Lakselv"),
  x = c(100, 255, 200, 280, 650, 900),
  y = c(6600, 6655, 6780, 7030, 7680, 7800)
)

square_size <- 10   # side length of region squares (km)
zoom_pad    <- 0    # extra padding around each zoomed panel (km)


# ---- 5) Plotting -------------------------------------------------------
n_breaks   <- 8                                 # color bins
color_pal  <- "viridis"                        # hcl.colors palette
color_rev  <- FALSE                             # reverse palette?


# ---- 6) Output filenames ----------------------------------------------
# These are written under out_root.
file_full_maps_pdf   <- "bias_mean_all_groups.pdf"
file_region_maps_pdf <- "bias_mean_region_maps.pdf"
file_extract_xlsx    <- "bias_region_values_touching_cells.xlsx"
file_rand_summary    <- "randomization_summary_all_target_groups.csv"
file_rand_variances  <- "randomization_regional_variances_all_target_groups.csv"
file_rand_top10      <- "randomization_top10_changes_per_target_group.csv"
file_rand_sensitivity <- "randomization_region_sensitivity.csv"
file_rand_plots_pdf  <- "randomization_plots.pdf"

# ---- 7) Valgfri overstyring for alternative kjøringer -----------------
# Sett ALT_CONFIG til en filsti FØR du sourcer modulene, så lastes
# overstyringene inn til slutt (f.eks. 12-regionsversjonen).
if (exists("ALT_CONFIG") && nzchar(ALT_CONFIG)) {
  source(ALT_CONFIG)
}
