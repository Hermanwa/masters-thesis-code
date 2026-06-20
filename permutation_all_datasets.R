# ============================================================
# permutation_all_datasets.R  -- READ-ONLY on your data
# ------------------------------------------------------------
# Runs the permutation total-variance test on three datasets:
#   birds, fungi, vascularPlants
# Uses ONLY the group folders present in each primary dataset
# folder (skips anything stored elsewhere, e.g. "Tidligere jobb...").
#
# Procedure (per dataset), identical to the birds run:
#   - 12 regions, updated centers (full 121 cells each)
#   - baseline total variance = each present group used once
#   - 1000 permutations: per region draw n_groups groups WITH
#     replacement, take that region's 121 cells from each draw,
#     pool all 12 regions, compute total variance
#   - histogram with observed baseline marked
# Outputs (per dataset) -> Claude work folder.
# ============================================================
suppressMessages({
  library(terra); library(sf); library(rnaturalearth); library(rnaturalearthhires)
})

n_perm    <- 1000
data_root <- "D:/"
out_dir   <- "C:/Users/herma/OneDrive/Skrivebord/Claude work"
country_name <- "Norway"; ne_scale <- "large"
square_size  <- 10; half <- square_size / 2

region_centers <- data.frame(
  region = c("Setesdal","Oslo","Valdres","Trondheim","Tromso","Lakselv",
             "Bergen","Kristiansand","Skorovatn","Bodo","Svolvar","Kirkenes"),
  x = c(100,255,200,280,650,900,-28,84,420,486,477,1075),
  y = c(6600,6655,6780,7030,7680,7800,6734,6472,7161,7467,7572,7801)
)
n_regions <- nrow(region_centers)

datasets <- list(
  list(name="birds",          subfolder="birds",          prefix="birds"),
  list(name="fungi",          subfolder="fungi",          prefix="fungiA"),
  list(name="vascularPlants", subfolder="vascularPlants", prefix="vascularPlantsA")
)

build_polys <- function(centers, half_sz, r) {
  do.call(rbind, lapply(seq_len(nrow(centers)), function(i) {
    x<-centers$x[i]; y<-centers$y[i]
    coords<-matrix(c(x-half_sz,y-half_sz, x+half_sz,y-half_sz, x+half_sz,y+half_sz,
                     x-half_sz,y+half_sz, x-half_sz,y-half_sz), ncol=2, byrow=TRUE)
    p<-vect(list(coords), type="polygons", crs=crs(r)); p$region<-centers$region[i]; p
  }))
}

# Detect present groups in a dataset's primary folder (numeric suffix, has Bias.rds)
detect_groups <- function(subfolder, prefix) {
  base <- file.path(data_root, subfolder)
  dirs <- list.dirs(base, recursive = FALSE, full.names = FALSE)
  keep <- grepl(paste0("^", prefix, "[0-9]+$"), dirs)
  dirs <- dirs[keep]
  ok   <- file.exists(file.path(base, dirs, "Bias", "Bias.rds"))
  dirs <- dirs[ok]
  dirs[order(as.integer(sub(prefix, "", dirs)))]
}

run_dataset <- function(ds) {
  cat("\n############################################################\n")
  cat("#  DATASET:", ds$name, "\n")
  cat("############################################################\n")

  groups <- detect_groups(ds$subfolder, ds$prefix)
  n_groups <- length(groups)
  cat("Groups used (", n_groups, "):\n", paste(groups, collapse=", "), "\n", sep="")

  ref_mean <- unwrap(readRDS(file.path(data_root, ds$subfolder, groups[1],
                                       "Bias","Bias.rds")))[["mean"]]
  country_v <- vect(st_transform(
    ne_countries(country=country_name, scale=ne_scale, returnclass="sf"),
    crs(ref_mean)))
  region_v <- build_polys(region_centers, half, ref_mean)

  # canonical cell ids per region (from reference grid)
  ref_masked <- mask(crop(ref_mean, country_v), country_v)
  ref_ex <- terra::extract(ref_masked, region_v, cells=TRUE, touches=TRUE)
  names(ref_ex)[2] <- "val"
  region_cells <- split(ref_ex$cell, ref_ex$ID)

  # Build region matrices [cells x groups]
  region_mats <- lapply(seq_len(n_regions), function(r)
    matrix(NA_real_, nrow=length(region_cells[[as.character(r)]]), ncol=n_groups,
           dimnames=list(NULL, groups)))

  for (gi in seq_along(groups)) {
    bp <- file.path(data_root, ds$subfolder, groups[gi], "Bias","Bias.rds")
    rm <- mask(crop(unwrap(readRDS(bp))[["mean"]], country_v), country_v)
    ex <- terra::extract(rm, region_v, cells=TRUE, touches=TRUE)
    names(ex)[2] <- "val"
    for (r in seq_len(n_regions)) {
      cid <- region_cells[[as.character(r)]]
      sub <- ex[ex$ID==r, ]
      region_mats[[r]][, gi] <- sub$val[match(cid, sub$cell)]
    }
  }

  cat("\nPer-region cell counts / NA:\n")
  for (r in seq_len(n_regions)) {
    m <- region_mats[[r]]
    cat(sprintf("  %-13s cells=%d groups=%d NA=%d\n",
                region_centers$region[r], nrow(m), ncol(m), sum(is.na(m))))
  }

  # Baseline: every group once
  baseline_pool <- unlist(lapply(region_mats, as.vector), use.names=FALSE)
  baseline_pool <- baseline_pool[!is.na(baseline_pool)]
  baseline_var  <- var(baseline_pool)
  cat(sprintf("\nBaseline total variance: %.10f  (n=%d)\n",
              baseline_var, length(baseline_pool)))

  # Permutations
  set.seed(1234)
  perm_var <- numeric(n_perm)
  for (p in seq_len(n_perm)) {
    pool <- vector("list", n_regions)
    for (r in seq_len(n_regions)) {
      m <- region_mats[[r]]
      draws <- sample.int(ncol(m), size=n_groups, replace=TRUE)
      pool[[r]] <- as.vector(m[, draws])
    }
    v <- unlist(pool, use.names=FALSE); v <- v[!is.na(v)]
    perm_var[p] <- var(v)
  }

  p_ge <- mean(perm_var >= baseline_var)
  cat(sprintf("Perm mean=%.6f sd=%.6f range=[%.6f, %.6f]\n",
              mean(perm_var), sd(perm_var), min(perm_var), max(perm_var)))
  cat(sprintf("Proportion of permutations >= baseline: %.3f\n", p_ge))

  # Save CSV + histograms
  write.csv(data.frame(permutation=seq_len(n_perm), total_variance=perm_var),
            file.path(out_dir, paste0(ds$name, "_permutation_variances.csv")),
            row.names=FALSE)

  draw_hist <- function() {
    hist(perm_var, breaks=40, col="grey80", border="white",
         main=sprintf("%s: permuted total variance (1000 draws, %d groups/region w/ repl.)",
                      ds$name, n_groups),
         xlab="Total variance of pooled bias cells",
         xlim=range(c(perm_var, baseline_var)))
    abline(v=baseline_var, col="red", lwd=2.5)
    text(baseline_var, par("usr")[4]*0.92,
         labels=sprintf(" observed = %.4f", baseline_var),
         col="red", pos=4, font=2)
  }
  png(file.path(out_dir, paste0(ds$name, "_permutation_histogram.png")),
      width=1900, height=1200, res=200); draw_hist(); dev.off()
  pdf(file.path(out_dir, paste0(ds$name, "_permutation_histogram.pdf")),
      width=9, height=6); draw_hist(); dev.off()

  data.frame(dataset=ds$name, n_groups=n_groups, n_cells=length(baseline_pool),
             baseline_var=baseline_var, perm_mean=mean(perm_var),
             perm_sd=sd(perm_var), prop_ge_baseline=p_ge)
}

summary_all <- do.call(rbind, lapply(datasets, run_dataset))

cat("\n=====================================================\n")
cat("SUMMARY (all datasets)\n")
cat("=====================================================\n")
print(summary_all, row.names=FALSE)
write.csv(summary_all, file.path(out_dir, "permutation_summary_all_datasets.csv"),
          row.names=FALSE)
cat("\nDone. Outputs in:", out_dir, "\n")
