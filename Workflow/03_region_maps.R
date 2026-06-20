# ============================================================
# 03_region_maps.R
# ============================================================
# For each group, write ONE page containing:
#   Left  = full country map with all regions highlighted (numbered)
#   Right = grid of N zoomed panels (same numbers as labels)
# Output: one multi-page PDF under out_root/bias_maps.
# ============================================================

# Always reload config + setup so module reflects the latest config.
source("00_config.R")
source("01_setup.R")


# ---- Reference + country + regions ------------------------------------
ref_raster <- load_reference_raster()
country_v  <- load_country_outline(ref_raster)
region_v   <- build_region_polygons(ref_raster = ref_raster)


# ---- Load all bias rasters --------------------------------------------
bias_list <- load_bias_list(groups, country_v)


# ---- Shared color scale (same as module 02) ---------------------------
scale_info <- compute_shared_scale(bias_list)
print(scale_info$zlim)
print(scale_info$breaks)

# Round breaks to 1 decimal for nicer legend labels
breaks_rounded <- round(scale_info$breaks, 1)
breaks_rounded[1]                      <- floor(scale_info$zlim[1] * 10) / 10
breaks_rounded[length(breaks_rounded)] <- ceiling(scale_info$zlim[2] * 10) / 10


# ---- Layout for zoom panels -------------------------------------------
half_size <- square_size / 2
n_regions <- nrow(region_centers)

# Grid for zoom panels (right side of page)
zoom_cols <- ceiling(sqrt(n_regions))
zoom_rows <- ceiling(n_regions / zoom_cols)


# ---- Open PDF ---------------------------------------------------------
out_dir <- file.path(out_root, "bias_maps")
ensure_dir(out_dir)

pdf(file   = file.path(out_dir, file_region_maps_pdf),
    width  = 14,
    height = 9)


# ---- Plot per group ---------------------------------------------------
for (g in names(bias_list)) {

  r <- bias_list[[g]]

  # Build a layout matrix:
  #   - column 1 = full map (spans all rows)
  #   - columns 2..(zoom_cols+1) = zoom panels in zoom_rows rows
  layout_mat <- matrix(0, nrow = zoom_rows, ncol = zoom_cols + 1)
  layout_mat[, 1] <- 1                          # full map fills first column
  layout_mat[, -1] <- matrix(seq(2, n_regions + 1),
                             nrow = zoom_rows, ncol = zoom_cols,
                             byrow = TRUE)

  # Column widths: full map column wider than each zoom column
  layout(layout_mat,
         widths  = c(1.8, rep(1, zoom_cols)),
         heights = rep(1, zoom_rows))

  # ---- LEFT: full country map -----------------------------------------
  par(mar = c(4.5, 4.5, 3.5, 7))

  plot(r,
       main   = paste("Sampling intensity (bias mean) -", g),
       xlab   = "Easting (km, UTM33N)",
       ylab   = "Northing (km, UTM33N)",
       zlim   = c(breaks_rounded[1], breaks_rounded[length(breaks_rounded)]),
       breaks = breaks_rounded,
       col    = scale_info$cols,
       plg    = list(title    = "bias mean",
                     title.cex = 0.9,
                     cex       = 0.85))

  plot(country_v, add = TRUE, border = "black", lwd = 0.6)
  plot(region_v,  add = TRUE, border = "red",   lwd = 2, col = NA)

  text(x = region_centers$x,
       y = region_centers$y,
       labels = region_centers$region,
       col = "red", cex = 1.3, font = 2, pos = 3)

  # ---- RIGHT: zoom panels --------------------------------------------
  par(mar = c(3, 3, 3, 2))

  for (i in seq_len(n_regions)) {

    x0 <- region_centers$x[i]
    y0 <- region_centers$y[i]

    e_zoom <- ext(x0 - half_size,
                  x0 + half_size,
                  y0 - half_size,
                  y0 + half_size)
    
    # Snap to whole raster cells so edges align cleanly
    e_zoom <- align(e_zoom, r)

    r_zoom       <- crop(r, e_zoom)
    region_i     <- region_v[i]
    country_zoom <- crop(country_v, e_zoom)

    # Title = "<number>. <region name>"
    panel_title <- paste0(i, ". ", region_centers$region[i])

    plot(r_zoom,
         main   = panel_title,
         zlim   = c(breaks_rounded[1], breaks_rounded[length(breaks_rounded)]),
         breaks = breaks_rounded,
         col    = scale_info$cols,
         legend   = FALSE,
         cex.main = 0.95)

    if (!is.null(country_zoom)) {
      plot(country_zoom, add = TRUE, border = "black", lwd = 0.6)
    }
    
    #plot(region_i, add = TRUE, border = "black", lwd = 2, col = NA)
  }
}


# ---- Close PDF + reset ------------------------------------------------
dev.off()

layout(1)
par(mar = c(5, 4, 4, 2) + 0.1)

cat("Wrote:", file.path(out_dir, file_region_maps_pdf), "\n")
