# ============================================================
# 06_png_maps.R
# ============================================================
# Same maps as modules 02 and 03, but written as ONE PNG IMAGE
# PER GROUP (instead of a single multi-page PDF), so each map
# can be dropped straight into a report.
#
# Outputs go to the "Claude work" folder:
#   <png_root>/full_maps_png/<group>.png      (full country map)
#   <png_root>/region_maps_png/<group>.png    (full map + zoom panels)
#
# Run from the Workflow folder, or just source this file – it
# sets the working directory itself.
# ============================================================

# ---- Make sure relative source() calls find the config -----------------
workflow_dir <- "C:/Users/herma/OneDrive/Skrivebord/Workflow"
if (file.exists(file.path(workflow_dir, "00_config.R"))) setwd(workflow_dir)

source("00_config.R")
source("01_setup.R")


# ---- Where the PNGs go -------------------------------------------------
png_root   <- "C:/Users/herma/OneDrive/Skrivebord/Claude work"
full_dir   <- file.path(png_root, "full_maps_png")
region_dir <- file.path(png_root, "region_maps_png")
ensure_dir(full_dir)
ensure_dir(region_dir)


# ---- Shared inputs (reference raster, country, regions, rasters) -------
ref_raster <- load_reference_raster()
country_v  <- load_country_outline(ref_raster)
region_v   <- build_region_polygons(ref_raster = ref_raster)

bias_list  <- load_bias_list(groups, country_v)


# ---- Shared color scale (identical to modules 02 / 03) -----------------
scale_info <- compute_shared_scale(bias_list)

breaks_rounded <- round(scale_info$breaks, 1)
breaks_rounded[1]                      <- floor(scale_info$zlim[1] * 10) / 10
breaks_rounded[length(breaks_rounded)] <- ceiling(scale_info$zlim[2] * 10) / 10

zlim_use <- c(breaks_rounded[1], breaks_rounded[length(breaks_rounded)])


# ========================================================================
# PART 1: full country map – one PNG per group  (mirrors 02_full_maps.R)
# ========================================================================
for (g in names(bias_list)) {

  png(filename = file.path(full_dir, paste0(g, ".png")),
      width = 8, height = 9, units = "in", res = 200)

  par(mar = c(4.5, 4.5, 3.5, 8))   # room for colorbar on the right

  plot(bias_list[[g]],
       main   = paste("Sampling intensity (bias mean) -", g),
       xlab   = "Easting (km, UTM33N)",
       ylab   = "Northing (km, UTM33N)",
       zlim   = zlim_use,
       breaks = breaks_rounded,
       col    = scale_info$cols,
       plg = list(title = "bias mean", title.cex = 0.9, cex = 0.85))

  plot(country_v, add = TRUE, border = "black", lwd = 0.6)

  dev.off()
  cat("Wrote:", file.path(full_dir, paste0(g, ".png")), "\n")
}


# ========================================================================
# PART 2: region map page – one PNG per group  (mirrors 03_region_maps.R)
# ========================================================================
half_size <- square_size / 2
n_regions <- nrow(region_centers)

zoom_cols <- ceiling(sqrt(n_regions))
zoom_rows <- ceiling(n_regions / zoom_cols)

for (g in names(bias_list)) {

  r <- bias_list[[g]]

  png(filename = file.path(region_dir, paste0(g, ".png")),
      width = 14, height = 9, units = "in", res = 200)

  # Layout: column 1 = full map (spans all rows); rest = zoom grid
  layout_mat <- matrix(0, nrow = zoom_rows, ncol = zoom_cols + 1)
  layout_mat[, 1] <- 1
  layout_mat[, -1] <- matrix(seq(2, n_regions + 1),
                             nrow = zoom_rows, ncol = zoom_cols,
                             byrow = TRUE)

  layout(layout_mat,
         widths  = c(1.8, rep(1, zoom_cols)),
         heights = rep(1, zoom_rows))

  # ---- LEFT: full country map with regions ----------------------------
  par(mar = c(4.5, 4.5, 3.5, 7))

  plot(r,
       main   = paste("Sampling intensity (bias mean) -", g),
       xlab   = "Easting (km, UTM33N)",
       ylab   = "Northing (km, UTM33N)",
       zlim   = zlim_use,
       breaks = breaks_rounded,
       col    = scale_info$cols,
       plg    = list(title = "bias mean", title.cex = 0.9, cex = 0.85))

  plot(country_v, add = TRUE, border = "black", lwd = 0.6)
  plot(region_v,  add = TRUE, border = "red",   lwd = 2, col = NA)

  text(x = region_centers$x, y = region_centers$y,
       labels = region_centers$region,
       col = "red", cex = 1.3, font = 2, pos = 3)

  # ---- RIGHT: zoom panels ---------------------------------------------
  par(mar = c(3, 3, 3, 2))

  for (i in seq_len(n_regions)) {
    x0 <- region_centers$x[i]
    y0 <- region_centers$y[i]

    e_zoom <- ext(x0 - half_size, x0 + half_size,
                  y0 - half_size, y0 + half_size)
    e_zoom <- align(e_zoom, r)

    r_zoom       <- crop(r, e_zoom)
    country_zoom <- crop(country_v, e_zoom)

    plot(r_zoom,
         main   = paste0(i, ". ", region_centers$region[i]),
         zlim   = zlim_use,
         breaks = breaks_rounded,
         col    = scale_info$cols,
         legend = FALSE,
         cex.main = 0.95)

    if (!is.null(country_zoom)) {
      plot(country_zoom, add = TRUE, border = "black", lwd = 0.6)
    }
  }

  dev.off()
  cat("Wrote:", file.path(region_dir, paste0(g, ".png")), "\n")
}


# ---- Reset graphics state ---------------------------------------------
layout(1)
par(mar = c(5, 4, 4, 2) + 0.1)

cat("\nDone. PNGs written to:\n  ", full_dir, "\n  ", region_dir, "\n")
