# ============================================================
# 01_setup.R
# ============================================================
# Packages + shared helper functions used by all modules.
# Sourced automatically by every module after 00_config.R.
# ============================================================

# ---- Packages ----------------------------------------------------------
library(terra)
library(sf)
library(rnaturalearth)

if (!requireNamespace("rnaturalearthhires", quietly = TRUE)) {
  install.packages("rnaturalearthhires",
                   repos = "https://ropensci.r-universe.dev")
}
library(rnaturalearthhires)


# ---- Build full group list from config --------------------------------
groups         <- paste0(group_prefix, group_indices)
groups_extract <- paste0(group_prefix, extract_group_indices)


# ---- Helper: read, unpack, extract mean, crop+mask to country ---------
make_bias_country <- function(group_name, country_v,
                              root = data_root,
                              sub  = data_subfolder) {
  bias_path <- file.path(root, sub, group_name, "Bias", "Bias.rds")

  if (!file.exists(bias_path)) {
    warning("Missing Bias.rds for ", group_name, " (skipping)")
    return(NULL)
  }

  bias_object <- readRDS(bias_path)
  bias_r      <- unwrap(bias_object)        # PackedSpatRaster -> SpatRaster
  bias_mean   <- bias_r[["mean"]]           # posterior mean layer

  bias_country <- mask(crop(bias_mean, country_v), country_v)
  return(bias_country)
}


# ---- Helper: reference raster (for CRS) -------------------------------
load_reference_raster <- function(ref = group_ref,
                                  root = data_root,
                                  sub  = data_subfolder) {
  ref_path <- file.path(root, sub, ref, "Bias", "Bias.rds")
  ref_obj  <- readRDS(ref_path)
  unwrap(ref_obj)[["mean"]]
}


# ---- Helper: country outline as SpatVector in raster CRS --------------
load_country_outline <- function(reference_raster,
                                 country = country_name,
                                 scale   = ne_scale) {
  country_sf <- ne_countries(country = country,
                             scale = scale,
                             returnclass = "sf")
  country_sf <- st_transform(country_sf, crs(reference_raster))
  vect(country_sf)
}


# ---- Helper: build region polygons from region_centers ----------------
build_region_polygons <- function(centers   = region_centers,
                                  side_km   = square_size,
                                  ref_raster) {
  half <- side_km / 2

  polys <- lapply(seq_len(nrow(centers)), function(i) {
    x <- centers$x[i]
    y <- centers$y[i]
    coords <- matrix(
      c(x - half, y - half,
        x + half, y - half,
        x + half, y + half,
        x - half, y + half,
        x - half, y - half),
      ncol = 2, byrow = TRUE
    )
    p <- vect(list(coords), type = "polygons", crs = crs(ref_raster))
    p$region <- centers$region[i]
    p
  })

  do.call(rbind, polys)
}


# ---- Helper: load all bias rasters as named list ----------------------
load_bias_list <- function(group_names, country_v) {
  bl <- lapply(group_names, make_bias_country, country_v = country_v)
  names(bl) <- group_names
  bl[!sapply(bl, is.null)]
}


# ---- Helper: compute shared color scale across all rasters ------------
compute_shared_scale <- function(bias_list, n_breaks_local = n_breaks) {
  ranges <- lapply(bias_list, global, fun = c("min", "max"), na.rm = TRUE)
  ranges <- do.call(rbind, ranges)

  zlim   <- range(ranges, na.rm = TRUE)
  breaks <- seq(zlim[1], zlim[2], length.out = n_breaks_local + 1)
  cols   <- hcl.colors(n_breaks_local, color_pal, rev = color_rev)

  list(zlim = zlim, breaks = breaks, cols = cols)
}


# ---- Helper: ensure output directory exists ---------------------------
ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
  invisible(path)
}
