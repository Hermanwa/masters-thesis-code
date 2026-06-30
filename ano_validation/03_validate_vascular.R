# =============================================================================
# 03_validate_vascular.R  --  Score bias-corrected predictions vs ANO hold-out
# =============================================================================
# Single-pass: each species prediction raster is read ONCE, extracted at all
# hold-out plots, then reused for overall AUC, regional AUC, and the bias link.
#
#   predicted occupancy (Richness.rds, "mean") at plot points
#   vs observed presence/absence (ANO 2024)  ->  AUC (threshold-free).
#
# Rasters are EPSG:25833 in *kilometres* (~1 km); ANO points are metres -> /1000.
# =============================================================================

source(file.path(getwd(), "ano_validation", "00_config_ano.R"))
suppressPackageStartupMessages({ library(terra); library(sf); library(pROC); library(dplyr) })

prep   <- readRDS(file.path(out_dir, "ano_prepared.rds"))
plots  <- prep$plots_sf
pa_mat <- prep$pa_mat
xy_km  <- st_coordinates(plots) / 1000                  # raster space (km)
ord    <- match(plots$plot_id, pa_mat$plot_id)          # align PA rows to plots

# ---- Index every modelled species -> its prediction raster ------------------
vasc_dir <- file.path(data_root, vasc_subfolder)
segments <- find_segments(vasc_dir)
sp_index <- do.call(rbind, lapply(segments, function(seg) {
  sp <- list.dirs(seg, recursive = FALSE)
  sp <- sp[file.exists(file.path(sp, "Richness.rds"))]
  if (!length(sp)) return(NULL)
  data.frame(sp = basename(sp), path = file.path(sp, "Richness.rds"),
             stringsAsFactors = FALSE)
}))
species_eval <- intersect(setdiff(names(pa_mat), "plot_id"), sp_index$sp)
message("Modelled species also in ANO hold-out: ", length(species_eval))

# ---- SINGLE PASS: extract every species prediction at all plots -------------
P <- matrix(NA_real_, nrow(plots), length(species_eval),
            dimnames = list(plots$plot_id, species_eval))
for (j in seq_along(species_eval)) {
  r <- tryCatch(unwrap(readRDS(sp_index$path[match(species_eval[j], sp_index$sp)]))[[pred_layer]],
                error = function(e) NULL)
  if (!is.null(r)) P[, j] <- terra::extract(r, xy_km)[[pred_layer]]
  if (j %% 25 == 0) message("  extracted ", j, "/", length(species_eval))
}

# ---- Per-species AUC --------------------------------------------------------
auc_one <- function(pred, obs) {
  keep <- !is.na(pred) & !is.na(obs)
  if (sum(obs[keep] == 1) < 3 || sum(obs[keep] == 0) < 3) return(NA_real_)
  tryCatch(as.numeric(pROC::auc(pROC::roc(obs[keep], pred[keep], quiet = TRUE))),
           error = function(e) NA_real_)
}
auc_tbl <- bind_rows(lapply(species_eval, function(sp) {
  obs <- pa_mat[[sp]][ord]
  data.frame(sp = sp, n = sum(!is.na(P[, sp]) & !is.na(obs)),
             prevalence = mean(obs, na.rm = TRUE), auc = auc_one(P[, sp], obs))
}))
write.csv(auc_tbl, file.path(out_dir, "auc_per_species.csv"), row.names = FALSE)
ok <- auc_tbl %>% filter(!is.na(auc))
cat(sprintf("\n=== Overall ===\nspecies scored: %d\nmean AUC %.3f | median AUC %.3f | %% AUC>0.7: %.0f%%\n",
            nrow(ok), mean(ok$auc), median(ok$auc), 100*mean(ok$auc > 0.7)))

# ---- Regional AUC: assign each plot to the NEAREST of your 12 centres --------
if (exists("region_centers")) {
  rc  <- region_centers
  d2  <- outer(xy_km[, 1], rc$x, "-")^2 + outer(xy_km[, 2], rc$y, "-")^2
  plots$region <- rc$region[max.col(-d2, ties.method = "first")]
  cat("\n=== Plots per region (nearest centre) ===\n"); print(table(plots$region))

  reg_tbl <- bind_rows(lapply(unique(plots$region), function(rg) {
    idx <- which(plots$region == rg); if (length(idx) < 30) return(NULL)
    a <- sapply(species_eval, function(sp) auc_one(P[idx, sp], pa_mat[[sp]][ord][idx]))
    data.frame(region = rg, n_plots = length(idx),
               mean_auc = mean(a, na.rm = TRUE), n_species = sum(!is.na(a)))
  }))
  write.csv(reg_tbl, file.path(out_dir, "auc_per_region.csv"), row.names = FALSE)
  print(reg_tbl[order(-reg_tbl$mean_auc), ])
}

# ---- Bias-field diagnostic --------------------------------------------------
# Does predictive skill depend on the estimated sampling-bias magnitude? A good
# correction should NOT systematically fail where modelled bias is high.
bias_paths <- file.path(segments, "Bias", "Bias.rds")
bias_paths <- bias_paths[file.exists(bias_paths)]
if (length(bias_paths)) {
  bias_mean  <- mean(rast(lapply(bias_paths, function(p) unwrap(readRDS(p))[[pred_layer]])),
                     na.rm = TRUE)
  plots$bias <- terra::extract(bias_mean, xy_km)[[pred_layer]]
  # per-plot Brier across species (lower = better)
  obsM <- as.matrix(pa_mat[ord, species_eval]); obsM[is.na(obsM)] <- NA
  plots$brier <- rowMeans((P - obsM)^2, na.rm = TRUE)
  cc <- cor(abs(plots$bias), plots$brier, use = "complete.obs", method = "spearman")
  cat(sprintf("\n=== Bias diagnostic ===\nSpearman(bias, per-plot Brier) = %.3f\n", cc))
  cat("  ~0 => correction holds across the bias gradient; strongly +ve => the\n",
      "  model still errs where it flags high sampling bias.\n")
  write.csv(st_drop_geometry(plots[, c("plot_id","region","bias","brier")]),
            file.path(out_dir, "plot_bias_values.csv"), row.names = FALSE)
}

saveRDS(list(auc_tbl = auc_tbl, plots = plots, P = P),
        file.path(out_dir, "validation_results.rds"))
cat("\nDone. Outputs in:", out_dir, "\n")
