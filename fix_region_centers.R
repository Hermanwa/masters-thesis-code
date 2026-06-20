# ============================================================
# fix_region_centers.R
# ------------------------------------------------------------
# Find new centers for Svolvær and Kirkenes so their 10 km
# squares touch a FULL 121 non-NA bias cells (no ocean/NA).
#
# READ-ONLY on your data: it reads the Bias.rds rasters and the
# Norway outline; it does NOT modify any Workflow files.
# ============================================================

suppressMessages({
  library(terra)
  library(sf)
  library(rnaturalearth)
  library(rnaturalearthhires)
})

# ---- Settings (mirror your 00_config.R / 00_config_12.R) --------------
data_root      <- "D:/"
data_subfolder <- "Newbirds"
group_prefix   <- "birds"
group_ref      <- "birds1"
country_name   <- "Norway"
ne_scale       <- "large"
square_size    <- 10
half           <- square_size / 2

# Current centers we want to fix
targets <- data.frame(
  region = c("Svolvær", "Kirkenes"),
  x      = c(480, 1075),
  y      = c(7572, 7802)
)

# ---- Load reference raster (mean layer) + Norway mask -----------------
ref_path <- file.path(data_root, data_subfolder, group_ref, "Bias", "Bias.rds")
ref_mean <- unwrap(readRDS(ref_path))[["mean"]]

country_sf <- ne_countries(country = country_name, scale = ne_scale,
                           returnclass = "sf")
country_sf <- st_transform(country_sf, crs(ref_mean))
country_v  <- vect(country_sf)

ref_masked <- mask(crop(ref_mean, country_v), country_v)

cat("Raster resolution:", paste(res(ref_masked), collapse = " x "), "\n")
cat("CRS units / extent:\n"); print(ext(ref_masked))

rx <- res(ref_masked)[1]
ry <- res(ref_masked)[2]

# ---- Count touched + non-NA cells for a given center -----------------
count_cells <- function(cx, cy, r, half_sz = half) {
  coords <- matrix(
    c(cx - half_sz, cy - half_sz,
      cx + half_sz, cy - half_sz,
      cx + half_sz, cy + half_sz,
      cx - half_sz, cy + half_sz,
      cx - half_sz, cy - half_sz),
    ncol = 2, byrow = TRUE
  )
  p  <- vect(list(coords), type = "polygons", crs = crs(r))
  ex <- terra::extract(r, p, touches = TRUE)
  v  <- ex[[2]]
  c(n_touch = length(v), n_nonNA = sum(!is.na(v)))
}

# ---- 1) Confirm current counts ---------------------------------------
cat("\n--- Current centers (reference raster) ---\n")
for (i in seq_len(nrow(targets))) {
  cc <- count_cells(targets$x[i], targets$y[i], ref_masked)
  cat(sprintf("%-12s (%g, %g): touch=%d, nonNA=%d\n",
              targets$region[i], targets$x[i], targets$y[i],
              cc["n_touch"], cc["n_nonNA"]))
}

# ---- 2) Search nearby centers for a full 121 non-NA ------------------
# Shift by whole resolution steps so the square keeps touching 11x11=121
# cells; pick the candidate closest to the original center.
search_full <- function(cx0, cy0, r, max_steps = 25) {
  offs <- (-max_steps):max_steps
  best <- NULL
  for (sx in offs) {
    for (sy in offs) {
      cx <- cx0 + sx * rx
      cy <- cy0 + sy * ry
      cc <- count_cells(cx, cy, r)
      if (cc["n_touch"] == 121 && cc["n_nonNA"] == 121) {
        d <- sqrt((cx - cx0)^2 + (cy - cy0)^2)
        if (is.null(best) || d < best$dist) {
          best <- list(x = cx, y = cy, dist = d,
                       touch = cc["n_touch"], nonNA = cc["n_nonNA"])
        }
      }
    }
  }
  best
}

cat("\n--- Searching for full-121 centers ---\n")
results <- list()
for (i in seq_len(nrow(targets))) {
  b <- search_full(targets$x[i], targets$y[i], ref_masked)
  if (is.null(b)) {
    cat(sprintf("%-12s: NO fully-land center found within search window.\n",
                targets$region[i]))
    results[[targets$region[i]]] <- NA
  } else {
    cat(sprintf("%-12s: new center (%.3f, %.3f)  shift=%.2f km  nonNA=%d\n",
                targets$region[i], b$x, b$y, b$dist, b$nonNA))
    results[[targets$region[i]]] <- b
  }
}

saveRDS(results, "C:/Users/herma/OneDrive/Skrivebord/Claude work/new_centers.rds")
cat("\nSaved candidate centers to new_centers.rds\n")
