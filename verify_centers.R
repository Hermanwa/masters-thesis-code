# ============================================================
# verify_centers.R  -- READ-ONLY
# Check the proposed new centers give 121 non-NA cells for ALL groups.
# ============================================================
suppressMessages({
  library(terra); library(sf); library(rnaturalearth); library(rnaturalearthhires)
})

data_root <- "D:/"; data_subfolder <- "Newbirds"
group_prefix <- "birds"; group_indices <- 1:21; group_ref <- "birds1"
country_name <- "Norway"; ne_scale <- "large"
square_size <- 10; half <- square_size / 2

groups <- paste0(group_prefix, group_indices)

new_centers <- data.frame(
  region = c("Svolvær", "Kirkenes"),
  x      = c(477, 1075),
  y      = c(7572, 7801)
)

ref_mean <- unwrap(readRDS(file.path(data_root, data_subfolder, group_ref,
                                     "Bias", "Bias.rds")))[["mean"]]
country_v <- vect(st_transform(
  ne_countries(country = country_name, scale = ne_scale, returnclass = "sf"),
  crs(ref_mean)))

count_nonNA <- function(cx, cy, r, half_sz = half) {
  coords <- matrix(c(cx-half_sz, cy-half_sz, cx+half_sz, cy-half_sz,
                     cx+half_sz, cy+half_sz, cx-half_sz, cy+half_sz,
                     cx-half_sz, cy-half_sz), ncol = 2, byrow = TRUE)
  p  <- vect(list(coords), type = "polygons", crs = crs(r))
  ex <- terra::extract(r, p, touches = TRUE)
  sum(!is.na(ex[[2]]))
}

cat("group     Svolvaer  Kirkenes\n")
cat("-------------------------------\n")
res_tab <- data.frame()
for (g in groups) {
  bp <- file.path(data_root, data_subfolder, g, "Bias", "Bias.rds")
  if (!file.exists(bp)) next
  rm <- mask(crop(unwrap(readRDS(bp))[["mean"]], country_v), country_v)
  s <- count_nonNA(new_centers$x[1], new_centers$y[1], rm)
  k <- count_nonNA(new_centers$x[2], new_centers$y[2], rm)
  cat(sprintf("%-9s %7d %9d\n", g, s, k))
  res_tab <- rbind(res_tab, data.frame(group = g, Svolvaer = s, Kirkenes = k))
}

cat("\nSummary:\n")
cat("Svolvaer  -> min:", min(res_tab$Svolvaer), " all 121? ",
    all(res_tab$Svolvaer == 121), "\n")
cat("Kirkenes  -> min:", min(res_tab$Kirkenes), " all 121? ",
    all(res_tab$Kirkenes == 121), "\n")
