# ============================================================
# 06_png_maps_multi.R
# ============================================================
# Generalized version of 06_png_maps.R: writes ONE PNG IMAGE
# PER GROUP for ANY dataset (newbirds, fungi, vascularPlants...),
# for both the full country map (module 02) and the region map
# page (module 03).
#
# Groups are AUTO-DISCOVERED: every <prefix><N> folder under
# <data_root>/<subfolder> that actually contains Bias/Bias.rds.
# This handles non-contiguous numbering (e.g. fungiA1..10, A31..40).
#
# Usage (from a shell):
#   Rscript 06_png_maps_multi.R <subfolder> <prefix> <label>
# Example:
#   Rscript 06_png_maps_multi.R fungi fungiA fungi
#
# Or set the three variables below and source() it from RStudio.
# ============================================================

# ---- Make sure relative source() calls find the config -----------------
workflow_dir <- "C:/Users/herma/OneDrive/Skrivebord/Workflow"
if (file.exists(file.path(workflow_dir, "00_config.R"))) setwd(workflow_dir)

# ---- Dataset selection (args override the defaults below) --------------
# Optional 4th arg = a region-config file to source LAST (e.g.
# "00_config_12.R"). When supplied, ONLY the region maps are produced
# (the full country maps do not depend on regions, so they would just
# duplicate the standard run).
.args <- commandArgs(trailingOnly = TRUE)
if (length(.args) >= 3) {
  ds_subfolder <- .args[1]   # e.g. "fungi"
  ds_prefix    <- .args[2]   # e.g. "fungiA"
  ds_label     <- .args[3]   # e.g. "fungi"  (output subfolder name)
  region_cfg   <- if (length(.args) >= 4) .args[4] else ""
} else {
  ds_subfolder <- "Newbirds"
  ds_prefix    <- "birds"
  ds_label     <- "newbirds"
  region_cfg   <- ""
}

make_full_maps <- !nzchar(region_cfg)   # skip full maps for region overrides

source("00_config.R")
source("01_setup.R")

# ---- Override config globals for the chosen dataset --------------------
data_subfolder <- ds_subfolder
group_prefix   <- ds_prefix

# ---- Optional region override (e.g. the 12-region layout) -------------
if (nzchar(region_cfg)) {
  if (!file.exists(region_cfg)) stop("Region config not found: ", region_cfg)
  source(region_cfg)   # redefines region_centers (and some filenames we ignore)
  cat("Region override:", region_cfg, "->", nrow(region_centers), "regions\n")
}

# ---- Auto-discover groups that have Bias/Bias.rds ----------------------
ds_path  <- file.path(data_root, data_subfolder)
all_dirs <- list.dirs(ds_path, recursive = FALSE, full.names = FALSE)
grp      <- all_dirs[grepl(paste0("^", ds_prefix, "[0-9]+$"), all_dirs)]
has_bias <- file.exists(file.path(ds_path, grp, "Bias", "Bias.rds"))
grp      <- grp[has_bias]
grp      <- grp[order(as.integer(sub(ds_prefix, "", grp)))]   # numeric sort

if (length(grp) == 0) stop("No groups with Bias/Bias.rds found under ", ds_path)

groups    <- grp
group_ref <- grp[1]

cat("Dataset:", data_subfolder, "| prefix:", ds_prefix,
    "|", length(groups), "groups\n")
cat("Groups:", paste(groups, collapse = ", "), "\n\n")


# ---- Where the PNGs go -------------------------------------------------
png_root   <- file.path("C:/Users/herma/OneDrive/Skrivebord/Claude work", ds_label)
full_dir   <- file.path(png_root, "full_maps_png")
region_dir <- file.path(png_root, "region_maps_png")
if (make_full_maps) ensure_dir(full_dir)
ensure_dir(region_dir)


# ---- Shared inputs -----------------------------------------------------
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
# (Skipped for region overrides – full maps don't depend on regions.)
# ========================================================================
if (make_full_maps) for (g in names(bias_list)) {

  png(filename = file.path(full_dir, paste0(g, ".png")),
      width = 8, height = 9, units = "in", res = 200)

  par(mar = c(4.5, 4.5, 3.5, 8))

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

  # Taller canvas when there are many zoom rows, so panels stay readable
  png_h <- max(9, 3 * zoom_rows)

  png(filename = file.path(region_dir, paste0(g, ".png")),
      width = 14, height = png_h, units = "in", res = 200)

  layout_mat <- matrix(0, nrow = zoom_rows, ncol = zoom_cols + 1)
  layout_mat[, 1] <- 1
  layout_mat[, -1] <- matrix(seq(2, n_regions + 1),
                             nrow = zoom_rows, ncol = zoom_cols,
                             byrow = TRUE)

  layout(layout_mat,
         widths  = c(1.8, rep(1, zoom_cols)),
         heights = rep(1, zoom_rows))

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

cat("\nDone (", ds_label, "). PNGs written to:\n  ",
    full_dir, "\n  ", region_dir, "\n", sep = "")
