# ============================================================
# two_way_anova_fungi.R  -- READ-ONLY on your data
# ------------------------------------------------------------
# Two-way ANOVA on the FUNGI bias field.
#
#   response : bias_mean   (posterior-mean sampling-intensity per raster cell)
#   factor A : group       (the 20 fungi groups, fungiA1 ... fungiA40)
#   factor B : region      (the 12 named 10x10 km blocks)
#
# Each raster cell that falls inside a region polygon, for a given
# group, is ONE observation. This is exactly the data layout used in
# permutation_all_datasets.R, reused here and fed into aov().
#
# Question this answers:
#   "Is it the GROUPS or the REGIONS that drive the differences in
#    the bias field (and is there a group x region interaction)?"
# We read that off the variance explained (eta^2) by each term, not
# just the p-values -- with ~29k cells everything is 'significant',
# so effect size is what matters.
#
# Outputs (-> Claude work folder):
#   fungi_anova_table.csv         ANOVA table + eta^2 / partial eta^2
#   fungi_anova_celldata.csv      the long-format cell data used
#   fungi_anova_groupregion_means.csv
#   fungi_anova_diagnostics.png   residual diagnostics
#   fungi_anova_interaction.png   group x region interaction plot
# ============================================================

suppressMessages({
  library(terra); library(sf); library(rnaturalearth); library(rnaturalearthhires)
})

# ---- Settings ---------------------------------------------------------
data_root    <- "D:/"
subfolder    <- "fungi"
prefix       <- "fungiA"
out_dir      <- "C:/Users/herma/OneDrive/Skrivebord/Claude work"
country_name <- "Norway"; ne_scale <- "large"
square_size  <- 10; half <- square_size / 2

# Set TRUE to run the ANOVA on log(bias). Bias/intensity surfaces are
# strongly right-skewed; log often stabilises variance & normality.
# Both versions are reported either way (see diagnostics block).
LOG_RESPONSE <- FALSE

# Same 12 region centres (full 121-cell blocks) as the permutation run.
region_centers <- data.frame(
  region = c("Setesdal","Oslo","Valdres","Trondheim","Tromso","Lakselv",
             "Bergen","Kristiansand","Skorovatn","Bodo","Svolvar","Kirkenes"),
  x = c(100,255,200,280,650,900,-28,84,420,486,477,1075),
  y = c(6600,6655,6780,7030,7680,7800,6734,6472,7161,7467,7572,7801)
)
n_regions <- nrow(region_centers)

# ---- Helpers (same geometry as the permutation script) ----------------
build_polys <- function(centers, half_sz, r) {
  do.call(rbind, lapply(seq_len(nrow(centers)), function(i) {
    x<-centers$x[i]; y<-centers$y[i]
    coords<-matrix(c(x-half_sz,y-half_sz, x+half_sz,y-half_sz, x+half_sz,y+half_sz,
                     x-half_sz,y+half_sz, x-half_sz,y-half_sz), ncol=2, byrow=TRUE)
    p<-vect(list(coords), type="polygons", crs=crs(r)); p$region<-centers$region[i]; p
  }))
}

detect_groups <- function(subfolder, prefix) {
  base <- file.path(data_root, subfolder)
  dirs <- list.dirs(base, recursive = FALSE, full.names = FALSE)
  dirs <- dirs[grepl(paste0("^", prefix, "[0-9]+$"), dirs)]
  dirs <- dirs[file.exists(file.path(base, dirs, "Bias", "Bias.rds"))]
  dirs[order(as.integer(sub(prefix, "", dirs)))]
}

# ---- Build the long-format cell table ---------------------------------
groups   <- detect_groups(subfolder, prefix)
n_groups <- length(groups)
cat(sprintf("Fungi groups (%d): %s\n", n_groups, paste(groups, collapse=", ")))

ref_mean  <- unwrap(readRDS(file.path(data_root, subfolder, groups[1],
                                      "Bias","Bias.rds")))[["mean"]]
country_v <- vect(st_transform(
  ne_countries(country=country_name, scale=ne_scale, returnclass="sf"),
  crs(ref_mean)))
region_v  <- build_polys(region_centers, half, ref_mean)

# Canonical cell ids per region from the reference (Norway-masked) grid,
# so every group is read on exactly the same cells.
ref_masked   <- mask(crop(ref_mean, country_v), country_v)
ref_ex       <- terra::extract(ref_masked, region_v, cells=TRUE, touches=TRUE)
names(ref_ex)[2] <- "val"
region_cells <- split(ref_ex$cell, ref_ex$ID)

rows <- vector("list", n_groups)
for (gi in seq_along(groups)) {
  bp <- file.path(data_root, subfolder, groups[gi], "Bias","Bias.rds")
  rm <- mask(crop(unwrap(readRDS(bp))[["mean"]], country_v), country_v)
  ex <- terra::extract(rm, region_v, cells=TRUE, touches=TRUE)
  names(ex)[2] <- "val"
  per_region <- lapply(seq_len(n_regions), function(r) {
    cid <- region_cells[[as.character(r)]]
    sub <- ex[ex$ID==r, ]
    data.frame(group  = groups[gi],
               region = region_centers$region[r],
               cell   = cid,
               bias_mean = sub$val[match(cid, sub$cell)])
  })
  rows[[gi]] <- do.call(rbind, per_region)
}
dat <- do.call(rbind, rows)
dat <- dat[!is.na(dat$bias_mean), ]
dat$group  <- factor(dat$group,  levels = groups)
dat$region <- factor(dat$region, levels = region_centers$region)

cat(sprintf("\nCells used: %d  (groups=%d, regions=%d)\n",
            nrow(dat), nlevels(dat$group), nlevels(dat$region)))
cat("Per-cell balance (cells per group x region):\n")
print(table(dat$group, dat$region))

# Response (optionally logged). Guard against non-positive values.
dat$y <- dat$bias_mean
if (LOG_RESPONSE) {
  if (any(dat$bias_mean <= 0, na.rm=TRUE))
    stop("LOG_RESPONSE=TRUE but bias_mean has non-positive values.")
  dat$y <- log(dat$bias_mean)
}

# ---- Two-way ANOVA ----------------------------------------------------
fit <- aov(y ~ group * region, data = dat)

# Base R anova() is Type I (sequential). The design is balanced (equal
# cells per group within a region), so Type I = Type II = Type III here
# and order does not matter. If you ever drop cells and it becomes
# unbalanced, switch to car::Anova(fit, type=3) -- handled below.
aov_tab <- summary(fit)[[1]]
rownames(aov_tab) <- trimws(rownames(aov_tab))   # summary.aov pads names

use_car <- requireNamespace("car", quietly = TRUE)
if (use_car) {
  # Type III needs sum-to-zero contrasts to be interpretable.
  fit3 <- aov(y ~ group * region, data = dat,
              contrasts = list(group = contr.sum, region = contr.sum))
  aov_tab3 <- car::Anova(fit3, type = 3)
}

# ---- Effect sizes: which factor explains the bias field? --------------
ss     <- aov_tab[, "Sum Sq"]
names(ss) <- rownames(aov_tab)
ss_total <- sum(ss)
ss_resid <- ss["Residuals"]

eta2 <- ss / ss_total                                   # share of TOTAL variance
peta2 <- ss[c("group","region","group:region")] /       # partial eta^2
         (ss[c("group","region","group:region")] + ss_resid)

effect_tab <- data.frame(
  term      = c("group","region","group:region","Residuals"),
  df        = aov_tab[c("group","region","group:region","Residuals"), "Df"],
  sum_sq    = ss[c("group","region","group:region","Residuals")],
  mean_sq   = aov_tab[c("group","region","group:region","Residuals"), "Mean Sq"],
  F_value   = aov_tab[c("group","region","group:region","Residuals"), "F value"],
  p_value   = aov_tab[c("group","region","group:region","Residuals"), "Pr(>F)"],
  eta2      = eta2[c("group","region","group:region","Residuals")],
  partial_eta2 = c(peta2[["group"]], peta2[["region"]], peta2[["group:region"]], NA),
  row.names = NULL
)

cat("\n================ TWO-WAY ANOVA (Type I) ================\n")
print(aov_tab)
if (use_car) {
  cat("\n================ Type III (car::Anova) ================\n")
  print(aov_tab3)
}
cat("\n=========== EFFECT SIZES (variance explained) ===========\n")
print(format(effect_tab, digits = 4))

winner <- c("group","region","group:region")[which.max(
  eta2[c("group","region","group:region")])]
cat(sprintf(
  "\n-> GROUP explains %.1f%% of total variance; REGION %.1f%%; interaction %.1f%%; residual %.1f%%.\n",
  100*eta2["group"], 100*eta2["region"], 100*eta2["group:region"], 100*eta2["Residuals"]))
cat(sprintf("-> Largest systematic effect: %s.\n", winner))

# ---- Save tables ------------------------------------------------------
write.csv(effect_tab, file.path(out_dir, "fungi_anova_table.csv"), row.names=FALSE)
write.csv(dat[, c("group","region","cell","bias_mean")],
          file.path(out_dir, "fungi_anova_celldata.csv"), row.names=FALSE)

gr_means <- aggregate(bias_mean ~ group + region, data = dat,
                      FUN = function(z) c(mean=mean(z), sd=sd(z), n=length(z)))
gr_means <- do.call(data.frame, gr_means)
names(gr_means) <- c("group","region","mean","sd","n")
write.csv(gr_means, file.path(out_dir, "fungi_anova_groupregion_means.csv"),
          row.names=FALSE)

# ---- Diagnostics + interaction plot -----------------------------------
png(file.path(out_dir, "fungi_anova_diagnostics.png"),
    width=1900, height=1400, res=170)
op <- par(mfrow=c(2,2)); plot(fit); par(op); dev.off()

png(file.path(out_dir, "fungi_anova_interaction.png"),
    width=2000, height=1200, res=170)
with(dat, interaction.plot(region, group, bias_mean,
     legend = FALSE, las = 2, col = hcl.colors(n_groups, "viridis"),
     lwd = 1.6, trace.label = "group",
     ylab = "mean bias", xlab = "region",
     main = "Fungi: group x region interaction (cell means)"))
dev.off()

cat("\nWrote outputs to:", out_dir, "\n")
cat("  fungi_anova_table.csv / _celldata.csv / _groupregion_means.csv\n")
cat("  fungi_anova_diagnostics.png / _interaction.png\n")
