# ============================================================
# permutation_histogram.R  -- READ-ONLY on your data
# ------------------------------------------------------------
# Null/bootstrap distribution of TOTAL VARIANCE:
#   For each of 1000 permutations:
#     - for each of the 12 regions, draw 20 groups WITH REPLACEMENT
#       (duplicates ok, some groups may be omitted)
#     - take that region's 121 cell values from each drawn group
#       -> 20 * 121 = 2420 values per region
#     - pool all 12 regions (29040 values) and compute total variance
#   Histogram of the 1000 variances, with the observed baseline marked.
#
# Uses the UPDATED Svolvær/Kirkenes centers (full 121 everywhere).
# Outputs go to the Claude work folder only.
# ============================================================
suppressMessages({
  library(terra); library(sf); library(rnaturalearth); library(rnaturalearthhires)
})

set.seed(1234)
n_perm <- 1000

data_root <- "D:/"; data_subfolder <- "Newbirds"
group_prefix <- "birds"; group_indices <- 1:21; group_ref <- "birds1"
country_name <- "Norway"; ne_scale <- "large"
square_size <- 10; half <- square_size / 2
groups <- paste0(group_prefix, group_indices)
out_dir <- "C:/Users/herma/OneDrive/Skrivebord/Claude work"

region_centers <- data.frame(
  region = c("Setesdal", "Oslo", "Valdres", "Trondheim", "Tromso", "Lakselv",
             "Bergen", "Kristiansand", "Skorovatn", "Bodo", "Svolvar", "Kirkenes"),
  x = c(100, 255, 200, 280, 650, 900, -28, 84, 420, 486, 477, 1075),
  y = c(6600, 6655, 6780, 7030, 7680, 7800, 6734, 6472, 7161, 7467, 7572, 7801)
)
n_regions <- nrow(region_centers)

# ---- Reference raster + Norway mask -----------------------------------
ref_mean <- unwrap(readRDS(file.path(data_root, data_subfolder, group_ref,
                                     "Bias", "Bias.rds")))[["mean"]]
country_v <- vect(st_transform(
  ne_countries(country = country_name, scale = ne_scale, returnclass = "sf"),
  crs(ref_mean)))

build_polys <- function(centers, half_sz, r) {
  do.call(rbind, lapply(seq_len(nrow(centers)), function(i) {
    x <- centers$x[i]; y <- centers$y[i]
    coords <- matrix(c(x-half_sz, y-half_sz, x+half_sz, y-half_sz,
                       x+half_sz, y+half_sz, x-half_sz, y+half_sz,
                       x-half_sz, y-half_sz), ncol = 2, byrow = TRUE)
    p <- vect(list(coords), type = "polygons", crs = crs(r)); p$region <- centers$region[i]; p
  }))
}
region_v <- build_polys(region_centers, half, ref_mean)

# ---- Build, per region, a matrix of [121 cells x 20 groups] -----------
# region_mats[[r]] is a numeric matrix: rows = cells (121), cols = groups.
cat("Extracting region x group cell values (loads 20 rasters once)...\n")
group_vecs <- vector("list", length(groups))   # each: list of region value-vectors
valid_groups <- character(0)

gi <- 0
for (g in groups) {
  bp <- file.path(data_root, data_subfolder, g, "Bias", "Bias.rds")
  if (!file.exists(bp)) next
  rm <- mask(crop(unwrap(readRDS(bp))[["mean"]], country_v), country_v)
  ex <- terra::extract(rm, region_v, touches = TRUE)   # cols: ID, value
  names(ex)[2] <- "val"
  # split values by region ID, keep cell order
  per_region <- split(ex$val, ex$ID)
  gi <- gi + 1
  group_vecs[[gi]] <- per_region
  valid_groups <- c(valid_groups, g)
}
group_vecs <- group_vecs[seq_len(gi)]
n_groups <- gi
cat("Groups loaded:", n_groups, "\n")

# Re-organise into region_mats[[r]] = matrix (cells x groups)
region_mats <- vector("list", n_regions)
for (r in seq_len(n_regions)) {
  cols <- lapply(group_vecs, function(gv) gv[[as.character(r)]])
  region_mats[[r]] <- do.call(cbind, cols)   # 121 x n_groups
}

# Sanity: report dimensions and any NAs
for (r in seq_len(n_regions)) {
  m <- region_mats[[r]]
  cat(sprintf("  %-13s cells=%d groups=%d  NA=%d\n",
              region_centers$region[r], nrow(m), ncol(m), sum(is.na(m))))
}

# ---- Observed baseline: every group used exactly once -----------------
baseline_pool <- unlist(lapply(region_mats, as.vector), use.names = FALSE)
baseline_pool <- baseline_pool[!is.na(baseline_pool)]
baseline_var  <- var(baseline_pool)
cat(sprintf("\nObserved baseline total variance: %.10f  (n=%d)\n",
            baseline_var, length(baseline_pool)))

# ---- Permutations ------------------------------------------------------
cat("Running", n_perm, "permutations...\n")
perm_var <- numeric(n_perm)
for (p in seq_len(n_perm)) {
  pool <- vector("list", n_regions)
  for (r in seq_len(n_regions)) {
    m <- region_mats[[r]]
    draws <- sample.int(ncol(m), size = n_groups, replace = TRUE)  # 20 groups w/ replacement
    pool[[r]] <- as.vector(m[, draws])
  }
  v <- unlist(pool, use.names = FALSE)
  v <- v[!is.na(v)]
  perm_var[p] <- var(v)
}

# ---- Summary + p-value-like positions ---------------------------------
p_ge <- mean(perm_var >= baseline_var)
p_le <- mean(perm_var <= baseline_var)
cat("\n--- Permutation distribution ---\n")
cat(sprintf("mean   : %.8f\n", mean(perm_var)))
cat(sprintf("sd     : %.8f\n", sd(perm_var)))
cat(sprintf("range  : %.8f to %.8f\n", min(perm_var), max(perm_var)))
cat(sprintf("baseline = %.8f\n", baseline_var))
cat(sprintf("proportion of permutations >= baseline: %.3f\n", p_ge))
cat(sprintf("proportion of permutations <= baseline: %.3f\n", p_le))

# ---- Save values + histogram ------------------------------------------
write.csv(data.frame(permutation = seq_len(n_perm), total_variance = perm_var),
          file.path(out_dir, "permutation_variances.csv"), row.names = FALSE)

draw_hist <- function() {
  hist(perm_var, breaks = 40, col = "grey80", border = "white",
       main = "Permuted total variance (1000 draws, 20 groups/region w/ replacement)",
       xlab = "Total variance of pooled bias cells",
       xlim = range(c(perm_var, baseline_var)))
  abline(v = baseline_var, col = "red", lwd = 2.5)
  text(baseline_var, par("usr")[4]*0.92,
       labels = sprintf(" observed = %.4f", baseline_var),
       col = "red", pos = 4, font = 2)
}

png(file.path(out_dir, "permutation_histogram.png"),
    width = 1900, height = 1200, res = 200)
draw_hist(); dev.off()

pdf(file.path(out_dir, "permutation_histogram.pdf"), width = 9, height = 6)
draw_hist(); dev.off()

cat("\nSaved:\n",
    file.path(out_dir, "permutation_histogram.png"), "\n",
    file.path(out_dir, "permutation_histogram.pdf"), "\n",
    file.path(out_dir, "permutation_variances.csv"), "\n")
