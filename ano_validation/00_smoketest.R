# =============================================================================
# 00_smoketest.R  --  30-second check of assumptions before the full run
# =============================================================================
# Verifies, against your real D:/ outputs, that:
#   * the folder layout is what 03_validate_vascular.R expects
#   * Richness.rds and Bias.rds unwrap to rasters with a "mean" layer
#   * the CRS is EPSG:25833
# No GBIF / no ANO needed. Reads two files only.
# =============================================================================

source(file.path(getwd(), "ano_validation", "00_config_ano.R"))
suppressPackageStartupMessages(library(terra))

vasc_dir <- file.path(data_root, vasc_subfolder)
cat("data_root/vasc_subfolder ->", vasc_dir,
    if (dir.exists(vasc_dir)) "  [OK exists]\n" else "  [!! NOT FOUND]\n")
if (!dir.exists(vasc_dir)) stop("Fix `data_root` / `vasc_subfolder` in 00_config_ano.R")

segments <- find_segments(vasc_dir)            # only folders with Bias/Bias.rds
cat("valid segments (with Bias/Bias.rds):", length(segments), "\n")
if (!length(segments)) stop("No segment folders with Bias.rds under ", vasc_dir)

# ---- pick first segment that also has species Richness.rds ------------------
has_sp  <- sapply(segments, function(s) {
  any(file.exists(file.path(list.dirs(s, recursive = FALSE), "Richness.rds")))
})
seg1     <- segments[which(has_sp)[1]]
sp_dirs  <- list.dirs(seg1, recursive = FALSE)
sp_dirs  <- sp_dirs[file.exists(file.path(sp_dirs, "Richness.rds"))]
bias_path <- file.path(seg1, "Bias", "Bias.rds")

cat("\nsegment under test:", basename(seg1), "\n")
cat("species folders with Richness.rds:", length(sp_dirs), "\n")
cat("Bias.rds present:", file.exists(bias_path), "\n")

inspect <- function(label, path) {
  cat("\n----", label, "----\n", path, "\n")
  obj <- tryCatch(unwrap(readRDS(path)), error = function(e) {
    cat("  [!! could not unwrap()] ", conditionMessage(e), "\n"); return(NULL) })
  if (is.null(obj)) return(invisible())
  cat("  class      :", class(obj)[1], "\n")
  cat("  layers     :", paste(names(obj), collapse = ", "), "\n")
  cat("  '", pred_layer, "' present:", pred_layer %in% names(obj), "\n", sep = "")
  cat("  CRS (EPSG) :", terra::crs(obj, describe = TRUE)$code, "\n")
  cat("  resolution :", paste(round(res(obj)), collapse = " x "), "m\n")
  cat("  value range:", paste(round(range(values(obj[[1]]), na.rm = TRUE), 3),
                              collapse = " .. "), "\n")
}

if (length(sp_dirs)) inspect("Richness.rds (one species)",
                             file.path(sp_dirs[1], "Richness.rds"))
if (file.exists(bias_path)) inspect("Bias.rds (group/segment)", bias_path)

cat("\n=== Verdict ===\n",
    "If both show layers containing '", pred_layer, "' and CRS 25833 at 500 m,\n",
    "the full pipeline's assumptions hold. If the layer name differs, change\n",
    "`pred_layer` in 00_config_ano.R. If CRS/res differ, tell me before running.\n",
    sep = "")
