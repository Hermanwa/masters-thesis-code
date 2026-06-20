# ============================================================
# 02_full_maps.R
# ============================================================
# Plot ALL groups (full country maps) with ONE shared colorbar.
# Output: a single multi-page PDF under out_root.
# ============================================================

# Always reload config + setup so module reflects the latest config.
source("00_config.R")
source("01_setup.R")


# ---- Build country outline from reference raster ----------------------
ref_raster <- load_reference_raster()
country_v  <- load_country_outline(ref_raster)


# ---- Load all bias rasters --------------------------------------------
bias_list <- load_bias_list(groups, country_v)


# ---- Shared color scale -----------------------------------------------
scale_info <- compute_shared_scale(bias_list)
print(scale_info$zlim)
print(scale_info$breaks)

# Round breaks to 1 decimal for nicer legend labels.
# (Slightly widen the range so no values fall outside the rounded scale.)
breaks_rounded <- round(scale_info$breaks, 1)
breaks_rounded[1]                    <- floor(scale_info$zlim[1] * 10) / 10
breaks_rounded[length(breaks_rounded)] <- ceiling(scale_info$zlim[2] * 10) / 10


# ---- Write PDF --------------------------------------------------------
out_dir <- file.path(out_root, "bias_maps")
ensure_dir(out_dir)

pdf(file   = file.path(out_dir, file_full_maps_pdf),
    width  = 8,
    height = 9)

# c(bottom, left, top, right)
par(mar = c(4.5, 4.5, 3.5, 8))

for (g in names(bias_list)) {
  plot(bias_list[[g]],
       main   = paste("Sampling intensity (bias mean) -", g),
       xlab   = "Easting (km, UTM33N)",
       ylab   = "Northing (km, UTM33N)",
       zlim   = c(breaks_rounded[1], breaks_rounded[length(breaks_rounded)]),
       breaks = breaks_rounded,
       col    = scale_info$cols,
       # plg controls the legend (color bar) placement and styling
       plg = list(
         title    = "bias mean",
         title.cex = 0.9,
         cex      = 0.85
       ))
  plot(country_v, add = TRUE, border = "black", lwd = 0.6)
}

dev.off()

par(mar = c(5, 4, 4, 2) + 0.1)  # reset

cat("Wrote:", file.path(out_dir, file_full_maps_pdf), "\n")
