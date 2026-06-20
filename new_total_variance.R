# ============================================================
# new_total_variance.R  -- READ-ONLY
# Recompute the TOTAL VARIANCE with the UPDATED Svolvær/Kirkenes
# centers, by re-extracting all 12 regions across all 20 groups.
# Mirrors module 04 (touching cells, non-NA) + the variance calc.
# Does NOT modify any Workflow files or data.
# ============================================================
suppressMessages({
  library(terra); library(sf); library(rnaturalearth); library(rnaturalearthhires)
})

data_root <- "D:/"; data_subfolder <- "Newbirds"
group_prefix <- "birds"; group_indices <- 1:21; group_ref <- "birds1"
country_name <- "Norway"; ne_scale <- "large"
square_size <- 10; half <- square_size / 2
groups <- paste0(group_prefix, group_indices)

# UPDATED centers (Svolvær x 480->477, Kirkenes y 7802->7801)
region_centers <- data.frame(
  region = c("Setesdal", "Oslo", "Valdres", "Trondheim", "Tromsø", "Lakselv",
             "Bergen", "Kristiansand", "Skorovatn", "Bodø", "Svolvær", "Kirkenes"),
  x = c(100, 255, 200, 280, 650, 900, -28, 84, 420, 486, 477, 1075),
  y = c(6600, 6655, 6780, 7030, 7680, 7800, 6734, 6472, 7161, 7467, 7572, 7801)
)

ref_mean <- unwrap(readRDS(file.path(data_root, data_subfolder, group_ref,
                                     "Bias", "Bias.rds")))[["mean"]]
country_v <- vect(st_transform(
  ne_countries(country = country_name, scale = ne_scale, returnclass = "sf"),
  crs(ref_mean)))

# Build the 12 region polygons (same construction as build_region_polygons)
build_polys <- function(centers, half_sz, r) {
  do.call(rbind, lapply(seq_len(nrow(centers)), function(i) {
    x <- centers$x[i]; y <- centers$y[i]
    coords <- matrix(c(x-half_sz, y-half_sz, x+half_sz, y-half_sz,
                       x+half_sz, y+half_sz, x-half_sz, y+half_sz,
                       x-half_sz, y-half_sz), ncol = 2, byrow = TRUE)
    p <- vect(list(coords), type = "polygons", crs = crs(r))
    p$region <- centers$region[i]; p
  }))
}
region_v <- build_polys(region_centers, half, ref_mean)

# Extract non-NA touching bias values for every group, pool them
all_vals <- c()
for (g in groups) {
  bp <- file.path(data_root, data_subfolder, g, "Bias", "Bias.rds")
  if (!file.exists(bp)) next
  rm <- mask(crop(unwrap(readRDS(bp))[["mean"]], country_v), country_v)
  ex <- terra::extract(rm, region_v, touches = TRUE)
  v  <- ex[[2]]
  all_vals <- c(all_vals, v[!is.na(v)])
}

n <- length(all_vals)
cat("=====================================================\n")
cat("NEW total variance (updated Svolvær/Kirkenes centers)\n")
cat("=====================================================\n")
cat("n values       :", n, "\n")
cat("mean           :", format(mean(all_vals), digits = 10), "\n")
cat("variance (n-1) :", format(var(all_vals), digits = 10), "\n")
cat("variance (n)   :", format(var(all_vals) * (n-1)/n, digits = 10), "\n")
cat("std. deviation :", format(sd(all_vals), digits = 10), "\n")
cat("\nOLD variance (n-1) was 0.3030083536 over n = 28940\n")
