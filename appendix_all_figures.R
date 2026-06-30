# ============================================================================
# appendix_all_figures.R
# ============================================================================
# ONE script that regenerates EVERY figure used in the thesis, written into a
# single organised folder tree so the whole set can be linked from the thesis
# appendix (the figures are too many to embed in the Overleaf document).
#
# What it produces, by section:
#   1. Species occurrence maps        - the four exemplar GBIF species
#   2. Full-country bias maps         - one map per group, all four datasets
#   3. Six-region bias maps           - full map + 6 zoom panels per group
#   4. Twelve-region bias maps        - full map + 12 zoom panels per group
#   5. Permutation histograms         - total-variance null per dataset
#   6. Two-way ANOVA diagnostics      - residual + QQ plots, interaction plots
#   7. Effect-size bar charts         - eta^2 decomposition (12, 6, and 6-vs-12)
#   8. Block-randomization plots      - region-sensitivity box/hist/dot charts
#   9. Mesh figures                   - SPDE mesh nodes + per-region node panels
#
# The four datasets are:
#   birds          (D:/birds,          prefix "birds")
#   fungi          (D:/fungi,          prefix "fungiA")
#   vascularPlants (D:/vascularPlants, prefix "vascularPlantsA")
#   newbirds       (D:/Newbirds,       prefix "birds")
#
# Output tree (under APPENDIX_DIR):
#   thesis_appendix_figures/
#     01_species_occurrence_maps/
#     02_full_country_bias_maps/<dataset>/
#     03_region_maps_6/<dataset>/
#     04_region_maps_12/<dataset>/
#     05_permutation_histograms/
#     06_anova_diagnostics/
#     07_effectsize_barcharts/
#     08_randomization_plots/<dataset>/
#     09_mesh_figures/
#
# HOW TO RUN
#   terra needs R 4.4.3 on this machine, so run with:
#     "C:/Program Files/R/R-4.4.3/bin/Rscript.exe" appendix_all_figures.R
#   or source() it from an R session started under R 4.4.3.
#
# NOTES
#   * Each section is wrapped in local({ ... }) so the (deliberately different)
#     region definitions and helpers do not clash between sections. The map
#     sections use the rounded config centres; the statistical sections use the
#     nudged centres (full 121-cell blocks) exactly as in the analysis scripts.
#   * Reading rasters off D:/ is read-only. Nothing on D:/ is modified.
#   * Toggle individual sections with the RUN list below.
#
# Author: Hermann  |  Thesis: sampling bias in Norwegian biodiversity data
# ============================================================================


# ============================================================================
# SECTION 0 -- Global configuration, paths, packages, helpers
# ============================================================================

# ---- Toggles: set any to FALSE to skip that section -----------------------
RUN <- list(
  species_maps      = TRUE,   # Section 1
  full_maps         = TRUE,   # Section 2
  region_maps_6     = TRUE,   # Section 3
  region_maps_12    = TRUE,   # Section 4
  permutation_hist  = TRUE,   # Section 5
  anova_diagnostics = TRUE,   # Section 6
  effectsize_bars   = TRUE,   # Section 7 (needs Section 6 to have run once)
  randomization     = TRUE,   # Section 8
  mesh_figures      = TRUE,    # Section 9
  bundle_pdfs       = TRUE     # Section 10 (combine the PNGs into PDFs)
)

# ---- Paths -----------------------------------------------------------------
DATA_ROOT  <- "D:/"
WORK_DIR   <- "C:/Users/herma/OneDrive/Skrivebord/Claude work"
APPENDIX_DIR <- file.path(WORK_DIR, "thesis_appendix_figures")

COUNTRY_NAME <- "Norway"
NE_SCALE     <- "large"
SQUARE_SIZE  <- 10          # region square side length (km)

# ---- Packages (loaded quietly; analysis sections add their own) ------------
suppressMessages({
  library(terra)
  library(sf)
  library(rnaturalearth)
})
if (!requireNamespace("rnaturalearthhires", quietly = TRUE)) {
  install.packages("rnaturalearthhires",
                   repos = "https://ropensci.r-universe.dev")
}
suppressMessages(library(rnaturalearthhires))

# ---- The four datasets -----------------------------------------------------
DATASETS <- list(
  list(name = "birds",          subfolder = "birds",          prefix = "birds"),
  list(name = "fungi",          subfolder = "fungi",          prefix = "fungiA"),
  list(name = "vascularPlants", subfolder = "vascularPlants", prefix = "vascularPlantsA"),
  list(name = "newbirds",       subfolder = "Newbirds",       prefix = "birds")
)

# ---- Region definitions ----------------------------------------------------
# Map sections use the config centres (rounded; Svolvaer x = 480, Kirkenes
# y = 7802). Statistical sections use the nudged centres (Svolvar x = 477,
# Kirkenes y = 7801) that give every block a full 121 non-NA land cells.
REGIONS_MAP_6 <- data.frame(
  region = c("Setesdal", "Oslo", "Valdres", "Trondheim", "Tromsø", "Lakselv"),
  x = c(100, 255, 200, 280, 650, 900),
  y = c(6600, 6655, 6780, 7030, 7680, 7800)
)
REGIONS_MAP_12 <- data.frame(
  region = c("Setesdal", "Oslo", "Valdres", "Trondheim", "Tromsø", "Lakselv",
             "Bergen", "Kristiansand", "Skorovatn", "Bodø", "Svolvær", "Kirkenes"),
  x = c(100, 255, 200, 280, 650, 900, -28, 84, 420, 486, 480, 1075),
  y = c(6600, 6655, 6780, 7030, 7680, 7800, 6734, 6472, 7161, 7467, 7572, 7802)
)
REGIONS_ANALYSIS_12 <- data.frame(
  region = c("Setesdal", "Oslo", "Valdres", "Trondheim", "Tromso", "Lakselv",
             "Bergen", "Kristiansand", "Skorovatn", "Bodo", "Svolvar", "Kirkenes"),
  x = c(100, 255, 200, 280, 650, 900, -28, 84, 420, 486, 477, 1075),
  y = c(6600, 6655, 6780, 7030, 7680, 7800, 6734, 6472, 7161, 7467, 7572, 7801)
)
REGIONS_ANALYSIS_6 <- REGIONS_ANALYSIS_12[1:6, ]

# ---- Shared helpers --------------------------------------------------------
ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)
  invisible(path)
}
ensure_dir(APPENDIX_DIR)

# Discover the <prefix><N> group folders that actually contain Bias/Bias.rds.
detect_groups <- function(subfolder, prefix, root = DATA_ROOT) {
  base <- file.path(root, subfolder)
  dirs <- list.dirs(base, recursive = FALSE, full.names = FALSE)
  dirs <- dirs[grepl(paste0("^", prefix, "[0-9]+$"), dirs)]
  dirs <- dirs[file.exists(file.path(base, dirs, "Bias", "Bias.rds"))]
  dirs[order(as.integer(sub(prefix, "", dirs)))]
}

# Square region polygons (terra) from a centre table, in the raster CRS.
build_polys <- function(centers, half_sz, r) {
  do.call(rbind, lapply(seq_len(nrow(centers)), function(i) {
    x <- centers$x[i]; y <- centers$y[i]
    coords <- matrix(c(x - half_sz, y - half_sz,  x + half_sz, y - half_sz,
                       x + half_sz, y + half_sz,  x - half_sz, y + half_sz,
                       x - half_sz, y - half_sz), ncol = 2, byrow = TRUE)
    p <- vect(list(coords), type = "polygons", crs = crs(r))
    p$region <- centers$region[i]; p
  }))
}

# Read a group's posterior-mean bias raster, cropped + masked to the country.
make_bias_country <- function(group_name, country_v, root, sub) {
  bias_path <- file.path(root, sub, group_name, "Bias", "Bias.rds")
  if (!file.exists(bias_path)) {
    warning("Missing Bias.rds for ", group_name, " (skipping)"); return(NULL)
  }
  bias_mean <- unwrap(readRDS(bias_path))[["mean"]]
  mask(crop(bias_mean, country_v), country_v)
}

# Country outline as a terra SpatVector in the reference raster's CRS.
load_country_outline <- function(reference_raster) {
  country_sf <- ne_countries(country = COUNTRY_NAME, scale = NE_SCALE,
                             returnclass = "sf")
  vect(st_transform(country_sf, crs(reference_raster)))
}

cat("\n==============================================================\n")
cat("Thesis appendix figures -> ", APPENDIX_DIR, "\n")
cat("==============================================================\n")


# ============================================================================
# SECTION 1 -- Species occurrence maps (four exemplar GBIF species)
# ----------------------------------------------------------------------------
# Reuses the formal occ_download() archive (same DOI) and draws one map per
# species. Needs GBIF credentials in .Renviron and a network connection to
# fetch/import the existing download. Source: gbif_norway_maps.R
# ============================================================================
if (RUN$species_maps) local({
  cat("\n[1] Species occurrence maps ...\n")
  suppressMessages({
    library(rgbif); library(ggplot2); library(dplyr)
  })

  out_dir <- file.path(APPENDIX_DIR, "01_species_occurrence_maps")
  ensure_dir(out_dir)

  gbif_user  <- Sys.getenv("GBIF_USER")
  gbif_pwd   <- Sys.getenv("GBIF_PWD")
  gbif_email <- Sys.getenv("GBIF_EMAIL")
  if (!nzchar(gbif_user) || !nzchar(gbif_pwd) || !nzchar(gbif_email)) {
    message("  GBIF credentials not set in .Renviron - skipping Section 1.")
    return(invisible(NULL))
  }

  species <- c("Fomitopsis pinicola", "Lysimachia europaea",
               "Turdus pilaris", "Falco peregrinus")
  backbone <- lapply(species, function(sp) name_backbone(name = sp))
  keys <- vapply(backbone, function(b) {
    k <- b$usageKey
    if (is.null(k) || length(k) == 0) NA_real_ else as.numeric(k)
  }, numeric(1))

  # Reuse the existing formal download (same citable DOI), no waiting.
  existing_key <- "0031086-260519110011954"

  dl <- existing_key
  dir.create("gbif_data", showWarnings = FALSE, recursive = TRUE)
  dat_raw <- occ_download_get(dl, path = "gbif_data", overwrite = TRUE) |>
    occ_download_import()
  meta <- occ_download_meta(dl)

  occ <- dat_raw |>
    filter(!is.na(decimalLongitude), !is.na(decimalLatitude)) |>
    select(species, scientificName, decimalLongitude, decimalLatitude,
           taxonKey, speciesKey, year, basisOfRecord)

  label_lookup <- setNames(species, keys)
  occ <- occ |>
    mutate(map_species = label_lookup[as.character(speciesKey)],
           map_species = ifelse(is.na(map_species),
                                label_lookup[as.character(taxonKey)],
                                map_species))

  occ_sf <- st_as_sf(occ, coords = c("decimalLongitude", "decimalLatitude"),
                     crs = 4326, remove = FALSE)

  mainland_bb <- st_bbox(c(xmin = 4, ymin = 57.5, xmax = 32, ymax = 72),
                         crs = 4326)
  norway <- ne_countries(scale = "large", country = "Norway",
                         returnclass = "sf") |> st_crop(mainland_bb)
  neighbours <- ne_countries(scale = "large", continent = "Europe",
                             returnclass = "sf") |> st_crop(mainland_bb)

  point_cols <- c("Fomitopsis pinicola" = "#8c510a",
                  "Lysimachia europaea" = "#1b7837",
                  "Turdus pilaris"      = "#762a83",
                  "Falco peregrinus"    = "#b2182b")

  make_map <- function(sp_name) {
    pts <- occ_sf |> filter(map_species == sp_name)
    if (nrow(pts) == 0) { message("  No records for ", sp_name); return(invisible()) }
    p <- ggplot() +
      geom_sf(data = neighbours, fill = "grey96", colour = "grey80",
              linewidth = 0.2) +
      geom_sf(data = norway, fill = "grey88", colour = "grey40",
              linewidth = 0.4) +
      geom_sf(data = pts, colour = point_cols[[sp_name]],
              size = 1.1, alpha = 0.6) +
      coord_sf(xlim = c(mainland_bb["xmin"], mainland_bb["xmax"]),
               ylim = c(mainland_bb["ymin"], mainland_bb["ymax"]), expand = TRUE) +
      labs(title = bquote(italic(.(sp_name))),
           subtitle = sprintf("GBIF occurrences in Norway (n = %s)",
                              format(nrow(pts), big.mark = ",")),
           caption = paste0("Source: GBIF.org  |  ", meta$doi),
           x = NULL, y = NULL) +
      theme_minimal(base_size = 11) +
      theme(panel.background = element_rect(fill = "aliceblue", colour = NA),
            panel.grid = element_line(colour = "grey90", linewidth = 0.2),
            plot.title = element_text(face = "italic"))
    fname <- file.path(out_dir,
                       paste0(gsub(" ", "_", tolower(sp_name)), "_norway.png"))
    ggsave(fname, p, width = 7, height = 8, dpi = 300)
    cat("    wrote", basename(fname), "\n")
  }
  invisible(lapply(species, make_map))
})


# ============================================================================
# SECTIONS 2-4 -- Bias maps (full country, 6 regions, 12 regions)
# ----------------------------------------------------------------------------
# One PNG per group, for every dataset, with a shared viridis colour scale
# within each dataset. Source: 06_png_maps_multi.R (modules 02 + 03).
# ============================================================================
if (RUN$full_maps || RUN$region_maps_6 || RUN$region_maps_12) local({
  cat("\n[2-4] Bias maps (full / 6-region / 12-region) ...\n")

  n_breaks  <- 8
  color_pal <- "viridis"

  full_root <- file.path(APPENDIX_DIR, "02_full_country_bias_maps")
  reg6_root <- file.path(APPENDIX_DIR, "03_region_maps_6")
  reg12_root <- file.path(APPENDIX_DIR, "04_region_maps_12")

  # Draw one "full map + zoom panel grid" PNG for a single group.
  render_region_png <- function(r, country_v, region_centers, scale_info,
                                breaks_rounded, zlim_use, fpath, group_label) {
    half_size <- SQUARE_SIZE / 2
    n_regions <- nrow(region_centers)
    zoom_cols <- ceiling(sqrt(n_regions))
    zoom_rows <- ceiling(n_regions / zoom_cols)
    region_v  <- build_polys(region_centers, half_size, r)

    png_h <- max(9, 3 * zoom_rows)
    png(filename = fpath, width = 14, height = png_h, units = "in", res = 200)

    layout_mat <- matrix(0, nrow = zoom_rows, ncol = zoom_cols + 1)
    layout_mat[, 1] <- 1
    layout_mat[, -1] <- matrix(seq(2, n_regions + 1),
                               nrow = zoom_rows, ncol = zoom_cols, byrow = TRUE)
    layout(layout_mat, widths = c(1.8, rep(1, zoom_cols)),
           heights = rep(1, zoom_rows))

    par(mar = c(4.5, 4.5, 3.5, 7))
    plot(r, main = paste("Sampling intensity (bias mean) -", group_label),
         xlab = "Easting (km, UTM33N)", ylab = "Northing (km, UTM33N)",
         zlim = zlim_use, breaks = breaks_rounded, col = scale_info$cols,
         plg = list(title = "bias mean", title.cex = 0.9, cex = 0.85))
    plot(country_v, add = TRUE, border = "black", lwd = 0.6)
    plot(region_v,  add = TRUE, border = "red",   lwd = 2, col = NA)
    text(x = region_centers$x, y = region_centers$y,
         labels = region_centers$region, col = "red", cex = 1.3, font = 2, pos = 3)

    par(mar = c(3, 3, 3, 2))
    for (i in seq_len(n_regions)) {
      x0 <- region_centers$x[i]; y0 <- region_centers$y[i]
      e_zoom <- ext(x0 - half_size, x0 + half_size,
                    y0 - half_size, y0 + half_size)
      e_zoom <- align(e_zoom, r)
      r_zoom       <- crop(r, e_zoom)
      country_zoom <- crop(country_v, e_zoom)
      plot(r_zoom, main = paste0(i, ". ", region_centers$region[i]),
           zlim = zlim_use, breaks = breaks_rounded, col = scale_info$cols,
           legend = FALSE, cex.main = 0.95)
      if (!is.null(country_zoom))
        plot(country_zoom, add = TRUE, border = "black", lwd = 0.6)
    }
    dev.off()
    layout(1); par(mar = c(5, 4, 4, 2) + 0.1)
  }

  for (ds in DATASETS) {
    cat("  dataset:", ds$name, "\n")
    groups <- detect_groups(ds$subfolder, ds$prefix)
    if (length(groups) == 0) { message("    no groups found - skipping"); next }

    ref_raster <- unwrap(readRDS(file.path(DATA_ROOT, ds$subfolder, groups[1],
                                           "Bias", "Bias.rds")))[["mean"]]
    country_v  <- load_country_outline(ref_raster)

    bias_list <- lapply(groups, make_bias_country, country_v = country_v,
                        root = DATA_ROOT, sub = ds$subfolder)
    names(bias_list) <- groups
    bias_list <- bias_list[!sapply(bias_list, is.null)]

    # Shared colour scale across this dataset's groups.
    ranges <- do.call(rbind, lapply(bias_list, global, fun = c("min", "max"),
                                    na.rm = TRUE))
    zlim   <- range(ranges, na.rm = TRUE)
    breaks <- seq(zlim[1], zlim[2], length.out = n_breaks + 1)
    cols   <- hcl.colors(n_breaks, color_pal, rev = FALSE)
    scale_info <- list(zlim = zlim, breaks = breaks, cols = cols)

    breaks_rounded <- round(scale_info$breaks, 1)
    breaks_rounded[1] <- floor(scale_info$zlim[1] * 10) / 10
    breaks_rounded[length(breaks_rounded)] <- ceiling(scale_info$zlim[2] * 10) / 10
    zlim_use <- c(breaks_rounded[1], breaks_rounded[length(breaks_rounded)])

    # --- Section 2: full country map, one PNG per group ---------------------
    if (RUN$full_maps) {
      full_dir <- file.path(full_root, ds$name); ensure_dir(full_dir)
      for (g in names(bias_list)) {
        png(filename = file.path(full_dir, paste0(g, ".png")),
            width = 8, height = 9, units = "in", res = 200)
        par(mar = c(4.5, 4.5, 3.5, 8))
        plot(bias_list[[g]],
             main = paste("Sampling intensity (bias mean) -", g),
             xlab = "Easting (km, UTM33N)", ylab = "Northing (km, UTM33N)",
             zlim = zlim_use, breaks = breaks_rounded, col = scale_info$cols,
             plg = list(title = "bias mean", title.cex = 0.9, cex = 0.85))
        plot(country_v, add = TRUE, border = "black", lwd = 0.6)
        dev.off()
      }
      par(mar = c(5, 4, 4, 2) + 0.1)
      cat("    full maps:", length(bias_list), "PNGs\n")
    }

    # --- Section 3: six-region map page, one PNG per group ------------------
    if (RUN$region_maps_6) {
      reg6_dir <- file.path(reg6_root, ds$name); ensure_dir(reg6_dir)
      for (g in names(bias_list))
        render_region_png(bias_list[[g]], country_v, REGIONS_MAP_6, scale_info,
                          breaks_rounded, zlim_use,
                          file.path(reg6_dir, paste0(g, ".png")), g)
      cat("    6-region maps:", length(bias_list), "PNGs\n")
    }

    # --- Section 4: twelve-region map page, one PNG per group ---------------
    if (RUN$region_maps_12) {
      reg12_dir <- file.path(reg12_root, ds$name); ensure_dir(reg12_dir)
      for (g in names(bias_list))
        render_region_png(bias_list[[g]], country_v, REGIONS_MAP_12, scale_info,
                          breaks_rounded, zlim_use,
                          file.path(reg12_dir, paste0(g, ".png")), g)
      cat("    12-region maps:", length(bias_list), "PNGs\n")
    }
  }
})


# ============================================================================
# SECTION 5 -- Permutation total-variance histograms
# ----------------------------------------------------------------------------
# One histogram per dataset: 1000-draw null of the pooled bias variance with
# the observed baseline marked. Run for all four datasets (birds, fungi,
# vascularPlants, newbirds). Source: permutation_all_datasets.R
# ============================================================================
if (RUN$permutation_hist) local({
  cat("\n[5] Permutation histograms ...\n")
  out_dir <- file.path(APPENDIX_DIR, "05_permutation_histograms")
  ensure_dir(out_dir)

  n_perm    <- 1000
  half      <- SQUARE_SIZE / 2
  region_centers <- REGIONS_ANALYSIS_12
  n_regions <- nrow(region_centers)

  perm_datasets <- list(
    list(name = "birds",          subfolder = "birds",          prefix = "birds"),
    list(name = "fungi",          subfolder = "fungi",          prefix = "fungiA"),
    list(name = "vascularPlants", subfolder = "vascularPlants", prefix = "vascularPlantsA"),
    list(name = "newbirds",       subfolder = "Newbirds",       prefix = "birds")
  )

  run_dataset <- function(ds) {
    cat("  dataset:", ds$name, "\n")
    groups   <- detect_groups(ds$subfolder, ds$prefix)
    n_groups <- length(groups)

    ref_mean  <- unwrap(readRDS(file.path(DATA_ROOT, ds$subfolder, groups[1],
                                          "Bias", "Bias.rds")))[["mean"]]
    country_v <- load_country_outline(ref_mean)
    region_v  <- build_polys(region_centers, half, ref_mean)

    ref_masked <- mask(crop(ref_mean, country_v), country_v)
    ref_ex <- terra::extract(ref_masked, region_v, cells = TRUE, touches = TRUE)
    names(ref_ex)[2] <- "val"
    region_cells <- split(ref_ex$cell, ref_ex$ID)

    region_mats <- lapply(seq_len(n_regions), function(r)
      matrix(NA_real_, nrow = length(region_cells[[as.character(r)]]),
             ncol = n_groups, dimnames = list(NULL, groups)))

    for (gi in seq_along(groups)) {
      bp <- file.path(DATA_ROOT, ds$subfolder, groups[gi], "Bias", "Bias.rds")
      rm <- mask(crop(unwrap(readRDS(bp))[["mean"]], country_v), country_v)
      ex <- terra::extract(rm, region_v, cells = TRUE, touches = TRUE)
      names(ex)[2] <- "val"
      for (r in seq_len(n_regions)) {
        cid <- region_cells[[as.character(r)]]
        sub <- ex[ex$ID == r, ]
        region_mats[[r]][, gi] <- sub$val[match(cid, sub$cell)]
      }
    }

    baseline_pool <- unlist(lapply(region_mats, as.vector), use.names = FALSE)
    baseline_pool <- baseline_pool[!is.na(baseline_pool)]
    baseline_var  <- var(baseline_pool)

    set.seed(1234)
    perm_var <- numeric(n_perm)
    for (p in seq_len(n_perm)) {
      pool <- vector("list", n_regions)
      for (r in seq_len(n_regions)) {
        m <- region_mats[[r]]
        draws <- sample.int(ncol(m), size = n_groups, replace = TRUE)
        pool[[r]] <- as.vector(m[, draws])
      }
      v <- unlist(pool, use.names = FALSE); v <- v[!is.na(v)]
      perm_var[p] <- var(v)
    }
    p_ge <- mean(perm_var >= baseline_var)
    cat(sprintf("    baseline=%.6f  prop>=baseline=%.3f\n", baseline_var, p_ge))

    draw_hist <- function() {
      hist(perm_var, breaks = 40, col = "grey80", border = "white",
           main = sprintf("%s: permuted total variance (1000 draws, %d groups/region w/ repl.)",
                          ds$name, n_groups),
           xlab = "Total variance of pooled bias cells",
           xlim = range(c(perm_var, baseline_var)))
      abline(v = baseline_var, col = "red", lwd = 2.5)
      text(baseline_var, par("usr")[4] * 0.92,
           labels = sprintf(" observed = %.4f", baseline_var),
           col = "red", pos = 4, font = 2)
    }
    png(file.path(out_dir, paste0(ds$name, "_permutation_histogram.png")),
        width = 1900, height = 1200, res = 200); draw_hist(); dev.off()
    pdf(file.path(out_dir, paste0(ds$name, "_permutation_histogram.pdf")),
        width = 9, height = 6); draw_hist(); dev.off()
  }
  invisible(lapply(perm_datasets, run_dataset))
})


# ============================================================================
# SECTION 6 -- Two-way ANOVA diagnostics + interaction plots
# ----------------------------------------------------------------------------
# Per dataset: the 2x2 residual diagnostics (Residuals vs Fitted, Normal Q-Q,
# Scale-Location, Residuals vs Leverage) and the group x region interaction
# plot. Also writes the eta^2 effect-size summary used by Section 7.
# Source: two_way_anova_all_datasets.R
# ============================================================================
if (RUN$anova_diagnostics || RUN$effectsize_bars) local({
  cat("\n[6] Two-way ANOVA diagnostics + interaction plots ...\n")
  out_dir <- file.path(APPENDIX_DIR, "06_anova_diagnostics")
  ensure_dir(out_dir)

  half      <- SQUARE_SIZE / 2
  region_centers <- REGIONS_ANALYSIS_12
  n_regions <- nrow(region_centers)
  LOG_RESPONSE <- FALSE

  run_dataset <- function(ds) {
    cat("  dataset:", ds$name, "\n")
    groups   <- detect_groups(ds$subfolder, ds$prefix)
    n_groups <- length(groups)

    ref_mean  <- unwrap(readRDS(file.path(DATA_ROOT, ds$subfolder, groups[1],
                                          "Bias", "Bias.rds")))[["mean"]]
    country_v <- load_country_outline(ref_mean)
    region_v  <- build_polys(region_centers, half, ref_mean)

    ref_masked <- mask(crop(ref_mean, country_v), country_v)
    ref_ex     <- terra::extract(ref_masked, region_v, cells = TRUE, touches = TRUE)
    names(ref_ex)[2] <- "val"
    region_cells <- split(ref_ex$cell, ref_ex$ID)

    rows <- vector("list", n_groups)
    for (gi in seq_along(groups)) {
      bp <- file.path(DATA_ROOT, ds$subfolder, groups[gi], "Bias", "Bias.rds")
      rm <- mask(crop(unwrap(readRDS(bp))[["mean"]], country_v), country_v)
      ex <- terra::extract(rm, region_v, cells = TRUE, touches = TRUE)
      names(ex)[2] <- "val"
      per_region <- lapply(seq_len(n_regions), function(r) {
        cid <- region_cells[[as.character(r)]]
        sub <- ex[ex$ID == r, ]
        data.frame(group = groups[gi], region = region_centers$region[r],
                   cell = cid, bias_mean = sub$val[match(cid, sub$cell)])
      })
      rows[[gi]] <- do.call(rbind, per_region)
    }
    dat <- do.call(rbind, rows)
    dat <- dat[!is.na(dat$bias_mean), ]
    dat$group  <- factor(dat$group,  levels = groups)
    dat$region <- factor(dat$region, levels = region_centers$region)
    dat$y <- if (LOG_RESPONSE) log(dat$bias_mean) else dat$bias_mean

    fit <- aov(y ~ group * region, data = dat)
    aov_tab <- summary(fit)[[1]]
    rownames(aov_tab) <- trimws(rownames(aov_tab))
    ss    <- aov_tab[, "Sum Sq"]; names(ss) <- rownames(aov_tab)
    terms <- c("group", "region", "group:region", "Residuals")
    eta2  <- ss / sum(ss)

    # Diagnostics (includes the Normal Q-Q plot) + interaction plot.
    png(file.path(out_dir, paste0(ds$name, "_anova_diagnostics.png")),
        width = 1900, height = 1400, res = 170)
    op <- par(mfrow = c(2, 2)); plot(fit); par(op); dev.off()

    png(file.path(out_dir, paste0(ds$name, "_anova_interaction.png")),
        width = 2000, height = 1200, res = 170)
    with(dat, interaction.plot(region, group, bias_mean,
         legend = FALSE, las = 2, col = hcl.colors(n_groups, "viridis"),
         lwd = 1.6, trace.label = "group",
         ylab = "mean bias", xlab = "region",
         main = paste0(ds$name, ": group x region interaction (cell means)")))
    dev.off()

    data.frame(dataset = ds$name, n_groups = n_groups, n_cells = nrow(dat),
               eta2_group = eta2[["group"]], eta2_region = eta2[["region"]],
               eta2_interaction = eta2[["group:region"]],
               eta2_residual = eta2[["Residuals"]],
               dominant = terms[which.max(eta2[c("group","region","group:region")])])
  }

  summary_all <- do.call(rbind, lapply(DATASETS, run_dataset))
  row.names(summary_all) <- NULL
  # Used by Section 7 (12-region bar chart).
  write.csv(summary_all,
            file.path(out_dir, "anova_effectsize_summary_all_datasets.csv"),
            row.names = FALSE)
})


# ============================================================================
# SECTION 7 -- Effect-size bar charts (eta^2 decomposition)
# ----------------------------------------------------------------------------
# (a) 12-region stacked bars per taxon (from Section 6's summary CSV).
# (b) 6-region stacked bars and (c) grouped 6-vs-12 comparison (re-extracted
#     here so the section is self-contained).
# Source: anova_effectsize_barchart.R + two_way_anova_region_comparison.R
# ============================================================================
if (RUN$effectsize_bars) local({
  cat("\n[7] Effect-size bar charts ...\n")
  out_dir <- file.path(APPENDIX_DIR, "07_effectsize_barcharts")
  ensure_dir(out_dir)

  nice <- c(birds = "Birds", fungi = "Fungi",
            vascularPlants = "Vascular plants", newbirds = "New birds")
  cols <- c(Region = "#2c7fb8", Group = "#41ab5d",
            Interaction = "#fdae61", Residual = "#bdbdbd")

  label_segments <- function(bp, M, thresh = 3) {
    cum <- apply(M, 2, cumsum); mid <- cum - M / 2
    for (j in seq_len(ncol(M))) for (i in seq_len(nrow(M))) if (M[i, j] >= thresh)
      text(bp[j], mid[i, j], sprintf("%.1f%%", M[i, j]),
           col = ifelse(rownames(M)[i] == "Region", "white", "black"),
           cex = 0.72, font = 2)
  }

  # --- (a) 12-region chart from Section 6's summary -------------------------
  summary_csv <- file.path(APPENDIX_DIR, "06_anova_diagnostics",
                           "anova_effectsize_summary_all_datasets.csv")
  if (file.exists(summary_csv)) {
    s <- read.csv(summary_csv)
    s <- s[match(names(nice), s$dataset), ]
    M <- rbind(Region = s$eta2_region, Group = s$eta2_group,
               Interaction = s$eta2_interaction, Residual = s$eta2_residual) * 100
    colnames(M) <- s$dataset
    labels <- paste0(nice[s$dataset], "\n(", s$n_groups, " groups)")
    draw <- function() {
      par(mar = c(4.5, 4.5, 4, 9), xpd = NA)
      bp <- barplot(M, col = cols[rownames(M)], border = "white",
                    names.arg = labels, ylim = c(0, 100), cex.names = 0.9,
                    ylab = expression("Variance explained  " * eta^2 * "  (%)"),
                    main = "Two-way ANOVA of the bias field: region vs group")
      label_segments(bp, M)
      legend(x = max(bp) + 0.7, y = 90, legend = rownames(M),
             fill = cols[rownames(M)], border = NA, bty = "n",
             title = "Source", cex = 0.95)
    }
    png(file.path(out_dir, "anova_effectsize_barchart.png"),
        width = 2100, height = 1300, res = 200); draw(); dev.off()
    pdf(file.path(out_dir, "anova_effectsize_barchart.pdf"),
        width = 10, height = 6); draw(); dev.off()
    cat("    wrote 12-region eta^2 bar chart\n")
  } else {
    message("    Section 6 summary not found - run Section 6 first for chart (a).")
  }

  # --- (b)+(c) 6-region and 6-vs-12 (re-extract per dataset) ----------------
  half <- SQUARE_SIZE / 2
  region_centers_12 <- REGIONS_ANALYSIS_12
  regions_6 <- region_centers_12$region[1:6]

  build_celldata <- function(ds) {
    groups   <- detect_groups(ds$subfolder, ds$prefix)
    ref_mean <- unwrap(readRDS(file.path(DATA_ROOT, ds$subfolder, groups[1],
                                         "Bias", "Bias.rds")))[["mean"]]
    country_v <- load_country_outline(ref_mean)
    region_v  <- build_polys(region_centers_12, half, ref_mean)
    ref_masked   <- mask(crop(ref_mean, country_v), country_v)
    ref_ex       <- terra::extract(ref_masked, region_v, cells = TRUE, touches = TRUE)
    names(ref_ex)[2] <- "val"
    region_cells <- split(ref_ex$cell, ref_ex$ID)
    rows <- lapply(seq_along(groups), function(gi) {
      bp <- file.path(DATA_ROOT, ds$subfolder, groups[gi], "Bias", "Bias.rds")
      rm <- mask(crop(unwrap(readRDS(bp))[["mean"]], country_v), country_v)
      ex <- terra::extract(rm, region_v, cells = TRUE, touches = TRUE)
      names(ex)[2] <- "val"
      do.call(rbind, lapply(seq_len(nrow(region_centers_12)), function(r) {
        cid <- region_cells[[as.character(r)]]
        sub <- ex[ex$ID == r, ]
        data.frame(group = groups[gi], region = region_centers_12$region[r],
                   cell = cid, bias_mean = sub$val[match(cid, sub$cell)])
      }))
    })
    dat <- do.call(rbind, rows); dat <- dat[!is.na(dat$bias_mean), ]
    dat$group  <- factor(dat$group, levels = groups)
    dat$region <- factor(dat$region, levels = region_centers_12$region)
    dat
  }
  fit_anova <- function(dat, keep_regions) {
    d <- dat[dat$region %in% keep_regions, ]
    d$region <- factor(d$region, levels = keep_regions); d$group <- droplevels(d$group)
    fit <- aov(bias_mean ~ group * region, data = d)
    tab <- summary(fit)[[1]]; rownames(tab) <- trimws(rownames(tab))
    ss <- tab[, "Sum Sq"]; names(ss) <- rownames(tab)
    terms <- c("group", "region", "group:region", "Residuals")
    eta2 <- ss / sum(ss)
    list(eta2 = eta2[terms], n_cells = nrow(d), n_groups = nlevels(d$group))
  }

  rows6 <- list(); rows_cmp <- list()
  for (ds in DATASETS) {
    cat("  re-extracting for 6-vs-12:", ds$name, "\n")
    dat <- build_celldata(ds)
    r6  <- fit_anova(dat, regions_6)
    r12 <- fit_anova(dat, levels(dat$region))
    rows6[[ds$name]] <- data.frame(
      dataset = ds$name, n_groups = r6$n_groups,
      eta2_group = r6$eta2[["group"]], eta2_region = r6$eta2[["region"]],
      eta2_interaction = r6$eta2[["group:region"]], eta2_residual = r6$eta2[["Residuals"]])
    rows_cmp[[ds$name]] <- rbind(
      data.frame(dataset = ds$name, n_regions = 6,
                 eta2_group = r6$eta2[["group"]], eta2_region = r6$eta2[["region"]],
                 eta2_interaction = r6$eta2[["group:region"]], eta2_residual = r6$eta2[["Residuals"]]),
      data.frame(dataset = ds$name, n_regions = 12,
                 eta2_group = r12$eta2[["group"]], eta2_region = r12$eta2[["region"]],
                 eta2_interaction = r12$eta2[["group:region"]], eta2_residual = r12$eta2[["Residuals"]]))
  }
  summary6    <- do.call(rbind, rows6);    row.names(summary6) <- NULL
  summary_cmp <- do.call(rbind, rows_cmp); row.names(summary_cmp) <- NULL

  # Chart (b): standalone 6-region stacked bars.
  ord <- match(names(nice), summary6$dataset)
  M6 <- rbind(Region = summary6$eta2_region, Group = summary6$eta2_group,
              Interaction = summary6$eta2_interaction,
              Residual = summary6$eta2_residual)[, ord] * 100
  colnames(M6) <- summary6$dataset[ord]
  draw6 <- function() {
    par(mar = c(4.5, 4.5, 4, 9), xpd = NA)
    bp <- barplot(M6, col = cols[rownames(M6)], border = "white",
                  names.arg = paste0(nice[colnames(M6)], "\n(", summary6$n_groups[ord], " groups)"),
                  ylim = c(0, 100), cex.names = 0.9,
                  ylab = expression("Variance explained  " * eta^2 * "  (%)"),
                  main = "Two-way ANOVA of the bias field: region vs group (6 regions)")
    label_segments(bp, M6)
    legend(x = max(bp) + 0.7, y = 90, legend = rownames(M6),
           fill = cols[rownames(M6)], border = NA, bty = "n", title = "Source", cex = 0.95)
  }
  png(file.path(out_dir, "anova_effectsize_barchart_6regions.png"),
      width = 2100, height = 1300, res = 200); draw6(); dev.off()
  pdf(file.path(out_dir, "anova_effectsize_barchart_6regions.pdf"),
      width = 10, height = 6); draw6(); dev.off()

  # Chart (c): grouped 6-vs-12 comparison.
  cmp_ord <- do.call(rbind, lapply(names(nice), function(dn)
    summary_cmp[summary_cmp$dataset == dn, ][order(summary_cmp$n_regions[summary_cmp$dataset == dn]), ]))
  Mc <- rbind(Region = cmp_ord$eta2_region, Group = cmp_ord$eta2_group,
              Interaction = cmp_ord$eta2_interaction, Residual = cmp_ord$eta2_residual) * 100
  space <- rep(c(0.9, 0.12), length(nice))
  drawCmp <- function() {
    par(mar = c(5, 4.5, 4, 9), xpd = NA)
    bp <- barplot(Mc, col = cols[rownames(Mc)], border = "white", space = space,
                  ylim = c(0, 100), ylab = expression("Variance explained  " * eta^2 * "  (%)"),
                  main = "Bias-field variance decomposition: 6 vs 12 regions",
                  names.arg = rep(c("6", "12"), length(nice)), cex.names = 0.85)
    label_segments(bp, Mc)
    for (k in seq_along(nice))
      mtext(nice[k], side = 1, line = 2.6, at = mean(bp[(2 * k - 1):(2 * k)]), font = 2, cex = 0.95)
    mtext("regions", side = 1, line = 1.2, at = bp[1] - 0.9, cex = 0.8, adj = 1)
    legend(x = max(bp) + 0.7, y = 90, legend = rownames(Mc),
           fill = cols[rownames(Mc)], border = NA, bty = "n", title = "Source", cex = 0.95)
  }
  png(file.path(out_dir, "anova_effectsize_barchart_6vs12.png"),
      width = 2300, height = 1300, res = 200); drawCmp(); dev.off()
  pdf(file.path(out_dir, "anova_effectsize_barchart_6vs12.pdf"),
      width = 11, height = 6); drawCmp(); dev.off()
  cat("    wrote 6-region and 6-vs-12 bar charts\n")
})


# ============================================================================
# SECTION 8 -- Block-randomization region-sensitivity plots
# ----------------------------------------------------------------------------
# Per dataset and per region set (6 and 12): swap each region in turn with the
# matching region from every other group in the same dataset, and measure the
# change in the variance among regional variances. Produces the box plot, the
# change histogram, and the dot chart. Source: 04_extract_values.R + 05_randomization.R
# ============================================================================
if (RUN$randomization) local({
  cat("\n[8] Block-randomization plots ...\n")
  out_root <- file.path(APPENDIX_DIR, "08_randomization_plots")
  ensure_dir(out_root)
  half <- SQUARE_SIZE / 2

  # Long-format bias values for all cells TOUCHING each region (mirrors module 04).
  extract_touching <- function(ds, region_centers) {
    groups <- detect_groups(ds$subfolder, ds$prefix)
    ref_mean <- unwrap(readRDS(file.path(DATA_ROOT, ds$subfolder, groups[1],
                                         "Bias", "Bias.rds")))[["mean"]]
    country_v <- load_country_outline(ref_mean)
    region_v  <- build_polys(region_centers, half, ref_mean)
    do.call(rbind, lapply(groups, function(g) {
      r <- mask(crop(unwrap(readRDS(file.path(DATA_ROOT, ds$subfolder, g,
                                              "Bias", "Bias.rds")))[["mean"]],
                     country_v), country_v)
      ex <- terra::extract(r, region_v, cells = TRUE, xy = TRUE, touches = TRUE)
      vcol <- setdiff(names(ex), c("ID", "cell", "x", "y"))
      names(ex)[names(ex) == vcol] <- "bias_mean"
      ex$group <- g; ex$region <- region_v$region[ex$ID]
      ex[, c("group", "region", "cell", "x", "y", "bias_mean")]
    }))
  }

  region_variance <- function(df) {
    out <- aggregate(bias_mean ~ region, data = df, FUN = var, na.rm = TRUE)
    names(out)[2] <- "region_variance"; out
  }

  run_one <- function(ds, region_centers, tag) {
    cat("  ", ds$name, "(", tag, ") ...\n", sep = "")
    out_dir <- file.path(out_root, ds$name); ensure_dir(out_dir)

    bias_df <- extract_touching(ds, region_centers)
    bias_df <- unique(bias_df[!is.na(bias_df$bias_mean), ])
    all_groups  <- sort(unique(bias_df$group))
    all_regions <- sort(unique(bias_df$region))

    summary_rows <- list(); ci <- 1
    for (target_group in all_groups) {
      donor_groups <- setdiff(all_groups, target_group)
      original_df  <- subset(bias_df, group == target_group)
      if (length(unique(original_df$region)) < length(all_regions)) next
      var_original <- region_variance(original_df)
      summary_rows[[ci]] <- data.frame(
        target_group = target_group, swapped_region = "none",
        dataset_label = "original",
        variance_among_regions = var(var_original$region_variance)); ci <- ci + 1
      for (swap_region in all_regions) for (donor_group in donor_groups) {
        keep_df  <- subset(bias_df, group == target_group & region != swap_region)
        donor_df <- subset(bias_df, group == donor_group  & region == swap_region)
        if (nrow(donor_df) == 0) next
        mixed_df <- rbind(keep_df, donor_df)
        if (length(unique(mixed_df$region)) < length(all_regions)) next
        var_mixed <- region_variance(mixed_df)
        summary_rows[[ci]] <- data.frame(
          target_group = target_group, swapped_region = swap_region,
          dataset_label = paste0("swap_", swap_region, "_from_", donor_group),
          variance_among_regions = var(var_mixed$region_variance)); ci <- ci + 1
      }
    }
    master <- do.call(rbind, summary_rows)
    orig <- subset(master, dataset_label == "original",
                   c("target_group", "variance_among_regions"))
    names(orig)[2] <- "original_variance_among_regions"
    master <- merge(master, orig, by = "target_group", all.x = TRUE)
    master$change_from_original <-
      master$variance_among_regions - master$original_variance_among_regions
    master$abs_change_from_original <- abs(master$change_from_original)

    non_original <- subset(master, dataset_label != "original")
    region_sensitivity <- do.call(rbind, lapply(
      split(non_original, non_original$swapped_region), function(df)
        data.frame(swapped_region = df$swapped_region[1], n_swaps = nrow(df),
                   mean_abs_change = mean(df$abs_change_from_original, na.rm = TRUE),
                   median_abs_change = median(df$abs_change_from_original, na.rm = TRUE),
                   max_abs_change = max(df$abs_change_from_original, na.rm = TRUE))))
    row.names(region_sensitivity) <- NULL
    region_sensitivity <- region_sensitivity[order(-region_sensitivity$mean_abs_change), ]
    write.csv(region_sensitivity,
              file.path(out_dir, paste0("region_sensitivity_", tag, ".csv")),
              row.names = FALSE)

    region_cols <- hcl.colors(length(unique(non_original$swapped_region)), "Set 2")

    # Plot 1: box plot of change per region (the main answer).
    png(file.path(out_dir, paste0("boxplot_region_sensitivity_", tag, ".png")),
        width = 2000, height = 1300, res = 200)
    par(mar = c(7, 4.5, 4, 2))
    non_original$swapped_region_ord <- factor(non_original$swapped_region,
                                              levels = region_sensitivity$swapped_region)
    boxplot(abs_change_from_original ~ swapped_region_ord, data = non_original,
            main = paste0(ds$name, " (", tag, "): region sensitivity"),
            xlab = "", ylab = "Absolute change in variance among regions",
            col = region_cols, las = 2, cex.axis = 0.9, outline = TRUE)
    mtext("Swapped region (sorted by mean impact, highest left)",
          side = 1, line = 5.5, cex = 0.95)
    dev.off()

    # Plot 2: histogram of change from original.
    png(file.path(out_dir, paste0("histogram_change_", tag, ".png")),
        width = 1900, height = 1200, res = 200)
    par(mar = c(4.5, 4.5, 4, 2))
    hist(master$change_from_original, breaks = 50,
         main = paste0(ds$name, " (", tag, "): change in variance among regions"),
         xlab = "Change from original (mixed - original)", ylab = "Number of swaps",
         col = "grey75", border = "white")
    abline(v = 0, col = "red", lwd = 2, lty = 2)
    legend("topright", legend = "No change", col = "red", lwd = 2, lty = 2, bty = "n")
    dev.off()

    # Plot 3: dot chart of region sensitivity.
    png(file.path(out_dir, paste0("dotchart_region_sensitivity_", tag, ".png")),
        width = 1900, height = 1300, res = 200)
    par(mar = c(4.5, 7, 4, 2))
    rs <- region_sensitivity[order(region_sensitivity$mean_abs_change), ]
    dotchart(rs$mean_abs_change, labels = rs$swapped_region,
             main = paste0(ds$name, " (", tag, "): mean absolute change per region"),
             xlab = "Mean absolute change in variance among regions",
             pch = 19, color = rev(region_cols),
             xlim = c(0, max(rs$max_abs_change, na.rm = TRUE)), cex = 1.1)
    points(rs$median_abs_change, seq_along(rs$median_abs_change), pch = 1, cex = 1.1)
    segments(rs$mean_abs_change, seq_along(rs$mean_abs_change),
             rs$max_abs_change, seq_along(rs$mean_abs_change), col = "grey60", lty = 3)
    legend("bottomright", legend = c("Mean", "Median", "to Max"),
           pch = c(19, 1, NA), lty = c(NA, NA, 3),
           col = c("black", "black", "grey60"), bty = "n", cex = 0.9)
    dev.off()
    par(mar = c(5, 4, 4, 2) + 0.1)
  }

  for (ds in DATASETS) {
    run_one(ds, REGIONS_ANALYSIS_6,  "6reg")
    run_one(ds, REGIONS_ANALYSIS_12, "12reg")
  }
})


# ============================================================================
# SECTION 9 -- SPDE mesh figures
# ----------------------------------------------------------------------------
# (a) mesh triangulation with nodes, (b) nodes only, (c) twelve per-region
# panels showing which mesh nodes fall inside each 10 km study square.
# Source: meshNodes.R + meshRegionPanels.R
# ============================================================================
if (RUN$mesh_figures) local({
  cat("\n[9] Mesh figures ...\n")
  suppressMessages({
    library(ggplot2); library(fmesher); library(patchwork)
  })
  out_dir <- file.path(APPENDIX_DIR, "09_mesh_figures")
  ensure_dir(out_dir)

  regionGeometryPath <- file.path(WORK_DIR, "regionGeometry.RDS")
  if (!file.exists(regionGeometryPath))
    regionGeometryPath <- "C:/Users/herma/Downloads/regionGeometry.RDS"
  if (!file.exists(regionGeometryPath)) {
    message("  regionGeometry.RDS not found - skipping Section 9.")
    return(invisible(NULL))
  }
  regionGeometry <- readRDS(regionGeometryPath)

  myMesh <- list(cutoff = 3 * 1000, max.edge = c(50, 300) * 1000,
                 offset = c(20, 100) * 1000)
  crs_wkt <- sf::st_crs(regionGeometry)$wkt
  hull <- fm_extensions(regionGeometry, convex = myMesh$max.edge * 2,
                        concave = myMesh$max.edge * 2)
  mesh <- fm_mesh_2d_inla(boundary = hull, max.edge = myMesh$max.edge,
                          cutoff = myMesh$cutoff, offset = myMesh$offset,
                          crs = fm_crs(crs_wkt))
  cat("    mesh:", mesh$n, "nodes,", nrow(mesh$graph$tv), "triangles\n")

  crs <- sf::st_crs(regionGeometry)
  nodes <- as.data.frame(mesh$loc[, 1:2]); names(nodes) <- c("x", "y")
  nodes_sf <- sf::st_as_sf(nodes, coords = c("x", "y"), crs = crs)
  inside <- lengths(sf::st_intersects(nodes_sf, sf::st_union(regionGeometry))) > 0
  nodes$location <- ifelse(inside, "inside region", "extension buffer")
  mesh_sfc <- fm_as_sfc(mesh)
  region_t <- sf::st_transform(regionGeometry, crs)
  loc_cols <- c("inside region" = "#1b9e77", "extension buffer" = "#d95f02")

  # (a) triangulation + nodes.
  p_mesh <- ggplot() +
    geom_sf(data = mesh_sfc, fill = NA, colour = "grey75", linewidth = 0.15) +
    geom_sf(data = region_t, fill = NA, colour = "black", linewidth = 0.4) +
    geom_point(data = nodes, aes(x = x, y = y, colour = location), size = 0.45) +
    scale_colour_manual(values = loc_cols, name = NULL) +
    labs(title = "Hotspot project mesh: triangulation and nodes",
         subtitle = sprintf("%d nodes, %d triangles | EPSG:25833",
                            mesh$n, nrow(mesh$graph$tv)), x = NULL, y = NULL) +
    coord_sf(crs = crs) + theme_minimal(base_size = 11) +
    theme(legend.position = "bottom")
  ggsave(file.path(out_dir, "mesh_triangulation_nodes.png"), p_mesh,
         width = 8, height = 8, dpi = 300)
  ggsave(file.path(out_dir, "mesh_triangulation_nodes.pdf"), p_mesh,
         width = 8, height = 8)

  # (b) nodes only.
  p_nodes <- ggplot() +
    geom_sf(data = region_t, fill = NA, colour = "grey60", linewidth = 0.4) +
    geom_point(data = nodes, aes(x = x, y = y, colour = location), size = 0.6) +
    scale_colour_manual(values = loc_cols, name = NULL) +
    labs(title = "Hotspot project mesh nodes",
         subtitle = sprintf("%d nodes (%d inside region, %d in buffer)",
                            mesh$n, sum(inside), sum(!inside)), x = NULL, y = NULL) +
    coord_sf(crs = crs) + theme_minimal(base_size = 11) +
    theme(legend.position = "bottom")
  ggsave(file.path(out_dir, "mesh_nodes.png"), p_nodes, width = 8, height = 8, dpi = 300)
  ggsave(file.path(out_dir, "mesh_nodes.pdf"), p_nodes, width = 8, height = 8)
  write.csv(nodes, file.path(out_dir, "mesh_nodes.csv"), row.names = FALSE)

  # (c) twelve per-region node panels (mesh in km).
  loc_km <- mesh$loc[, 1:2] / 1000
  nodes_km <- data.frame(x = loc_km[, 1], y = loc_km[, 2])
  tv <- mesh$graph$tv; ntri <- nrow(tv); idx <- as.vector(t(tv))
  tri_df <- data.frame(tri = rep(seq_len(ntri), each = 3),
                       x = loc_km[idx, 1], y = loc_km[idx, 2])
  tri_cent <- data.frame(tri = seq_len(ntri),
    cx = (loc_km[tv[, 1], 1] + loc_km[tv[, 2], 1] + loc_km[tv[, 3], 1]) / 3,
    cy = (loc_km[tv[, 1], 2] + loc_km[tv[, 2], 2] + loc_km[tv[, 3], 2]) / 3)

  rc <- REGIONS_MAP_12; rc <- rc[order(-rc$y), ]   # north-to-south reading order
  hf <- SQUARE_SIZE / 2; pad_km <- 1.5
  n_inside <- integer(nrow(rc))
  for (i in seq_len(nrow(rc))) {
    cx <- rc$x[i]; cy <- rc$y[i]
    n_inside[i] <- sum(nodes_km$x >= cx - hf & nodes_km$x <= cx + hf &
                       nodes_km$y >= cy - hf & nodes_km$y <= cy + hf)
  }
  rc$n_inside <- n_inside

  make_panel <- function(reg, cx, cy, n_in) {
    xlo <- cx - hf - pad_km; xhi <- cx + hf + pad_km
    ylo <- cy - hf - pad_km; yhi <- cy + hf + pad_km
    keep <- tri_cent$tri[tri_cent$cx > xlo - 80 & tri_cent$cx < xhi + 80 &
                         tri_cent$cy > ylo - 80 & tri_cent$cy < yhi + 80]
    tri_w <- tri_df[tri_df$tri %in% keep, ]
    nw <- nodes_km[nodes_km$x > xlo & nodes_km$x < xhi &
                   nodes_km$y > ylo & nodes_km$y < yhi, ]
    ins <- nw$x >= cx - hf & nw$x <= cx + hf & nw$y >= cy - hf & nw$y <= cy + hf
    ggplot() +
      geom_polygon(data = tri_w, aes(x, y, group = tri), fill = NA,
                   colour = "grey55", linewidth = 0.25) +
      annotate("rect", xmin = cx - hf, xmax = cx + hf, ymin = cy - hf, ymax = cy + hf,
               fill = NA, colour = "#d6166b", linewidth = 0.8) +
      { if (any(!ins)) geom_point(data = nw[!ins, ], aes(x, y), colour = "grey55", size = 1.4) } +
      { if (any(ins))  geom_point(data = nw[ins, ],  aes(x, y), colour = "#1b9e77", size = 2.2) } +
      coord_fixed(xlim = c(xlo, xhi), ylim = c(ylo, yhi), expand = FALSE) +
      labs(title = sprintf("%s  -  %d node%s inside", reg, n_in,
                           if (n_in == 1) "" else "s"), x = NULL, y = NULL) +
      theme_minimal(base_size = 9) +
      theme(axis.text = element_text(size = 6),
            plot.title = element_text(face = "bold", size = 9.5),
            panel.grid = element_blank(),
            panel.border = element_rect(fill = NA, colour = "grey70"))
  }
  panels <- Map(make_panel, rc$region, rc$x, rc$y, rc$n_inside)
  fig <- patchwork::wrap_plots(panels, ncol = 3) +
    patchwork::plot_annotation(
      title = "Mesh nodes within each 10 km study region",
      subtitle = "Red = 10 km region square; grey lines = mesh triangulation; green = node inside the square, grey = node just outside.")
  ggsave(file.path(out_dir, "mesh_region_panels.png"), fig, width = 11, height = 14, dpi = 300)
  ggsave(file.path(out_dir, "mesh_region_panels.pdf"), fig, width = 11, height = 14)
  cat("    wrote mesh triangulation, nodes, and 12-region panels\n")
})


# ============================================================================
# SECTION 10 -- Bundle the PNGs into PDFs
# ----------------------------------------------------------------------------
# For every leaf folder that contains PNGs, write one combined multi-page PDF
# (one PNG per page, at the image's own aspect ratio) named after the folder.
# This gives you BOTH the individual PNGs and a linkable PDF per group/section.
# ============================================================================
if (RUN$bundle_pdfs) local({
  cat("\n[10] Bundling PNGs into PDFs ...\n")
  suppressMessages(library(png))

  # All folders under APPENDIX_DIR that directly contain *.png files.
  all_dirs <- list.dirs(APPENDIX_DIR, recursive = TRUE, full.names = TRUE)
  png_dirs <- Filter(function(d)
    length(list.files(d, pattern = "\\.png$", full.names = TRUE)) > 0, all_dirs)

  for (d in png_dirs) {
    pngs <- sort(list.files(d, pattern = "\\.png$", full.names = TRUE))
    pdf_path <- file.path(d, paste0(basename(d), "_all.pdf"))
    grDevices::pdf(pdf_path, width = 10, height = 12, onefile = TRUE)
    for (f in pngs) {
      img <- tryCatch(png::readPNG(f), error = function(e) NULL)
      if (is.null(img)) next
      h <- dim(img)[1]; w <- dim(img)[2]
      op <- par(mar = c(0, 0, 1.2, 0))
      plot.new()
      plot.window(xlim = c(0, 1), ylim = c(0, 1), asp = w / h)
      rasterImage(img, 0, 0, 1, 1, interpolate = TRUE)
      title(main = sub("\\.png$", "", basename(f)), cex.main = 0.9, font.main = 1)
      par(op)
    }
    dev.off()
    cat("    bundled", length(pngs), "PNGs ->",
        file.path(basename(dirname(d)), basename(pdf_path)), "\n")
  }
})


cat("\n==============================================================\n")
cat("DONE. All appendix figures are under:\n  ", APPENDIX_DIR, "\n")
cat("==============================================================\n")
