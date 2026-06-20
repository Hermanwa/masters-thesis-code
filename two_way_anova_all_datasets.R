# ============================================================
# two_way_anova_all_datasets.R  -- READ-ONLY on your data
# ------------------------------------------------------------
# Two-way ANOVA on the bias field, run for each dataset:
#   birds, fungi, vascularPlants, newbirds
#
#   response : bias_mean   (posterior-mean sampling-intensity per raster cell)
#   factor A : group       (the taxonomic groups within the dataset)
#   factor B : region      (the 12 named 10x10 km blocks)
#
# Each raster cell inside a region polygon, for a given group, is ONE
# observation -- the same data layout as permutation_all_datasets.R,
# reused here and fed into aov().
#
# Question this answers (per dataset):
#   "Is it the GROUPS or the REGIONS that drive the differences in the
#    bias field (and is there a group x region interaction)?"
# Read off the variance explained (eta^2) by each term, not the
# p-values -- with ~25-30k cells everything is 'significant', so effect
# size is what matters.
#
# Outputs (-> Claude work folder), per dataset <name>:
#   <name>_anova_table.csv             ANOVA table + eta^2 / partial eta^2
#   <name>_anova_celldata.csv          long-format cell data used
#   <name>_anova_groupregion_means.csv group x region cell means
#   <name>_anova_diagnostics.png       residual diagnostics
#   <name>_anova_interaction.png       group x region interaction plot
# Plus a combined:
#   anova_effectsize_summary_all_datasets.csv
# ============================================================

suppressMessages({
  library(terra); library(sf); library(rnaturalearth); library(rnaturalearthhires)
})

# ---- Settings ---------------------------------------------------------
data_root    <- "D:/"
out_dir      <- "C:/Users/herma/OneDrive/Skrivebord/Claude work"
country_name <- "Norway"; ne_scale <- "large"
square_size  <- 10; half <- square_size / 2

# Set TRUE to run on log(bias). Bias/intensity surfaces are strongly
# right-skewed; log often stabilises variance & normality. The eta^2
# ranking (which factor dominates) is robust to this either way.
LOG_RESPONSE <- FALSE

datasets <- list(
  list(name="birds",          subfolder="birds",          prefix="birds"),
  list(name="fungi",          subfolder="fungi",          prefix="fungiA"),
  list(name="vascularPlants", subfolder="vascularPlants", prefix="vascularPlantsA"),
  list(name="newbirds",       subfolder="Newbirds",       prefix="birds")
)

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

# ---- Per-dataset runner -----------------------------------------------
run_dataset <- function(ds) {
  cat("\n############################################################\n")
  cat("#  DATASET:", ds$name, "\n")
  cat("############################################################\n")

  groups   <- detect_groups(ds$subfolder, ds$prefix)
  n_groups <- length(groups)
  cat(sprintf("Groups (%d): %s\n", n_groups, paste(groups, collapse=", ")))

  ref_mean  <- unwrap(readRDS(file.path(data_root, ds$subfolder, groups[1],
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
    bp <- file.path(data_root, ds$subfolder, groups[gi], "Bias","Bias.rds")
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

  cat(sprintf("Cells used: %d  (groups=%d, regions=%d)\n",
              nrow(dat), nlevels(dat$group), nlevels(dat$region)))
  balanced <- length(unique(as.vector(table(dat$group, dat$region)))) == 1
  cat(sprintf("Balanced design: %s\n", balanced))

  # Response (optionally logged).
  dat$y <- dat$bias_mean
  if (LOG_RESPONSE) {
    if (any(dat$bias_mean <= 0, na.rm=TRUE))
      stop("LOG_RESPONSE=TRUE but bias_mean has non-positive values in ", ds$name)
    dat$y <- log(dat$bias_mean)
  }

  # ---- Two-way ANOVA --------------------------------------------------
  fit <- aov(y ~ group * region, data = dat)
  aov_tab <- summary(fit)[[1]]
  rownames(aov_tab) <- trimws(rownames(aov_tab))   # summary.aov pads names

  if (requireNamespace("car", quietly = TRUE)) {
    fit3 <- aov(y ~ group * region, data = dat,
                contrasts = list(group = contr.sum, region = contr.sum))
    cat("\n-- Type III (car::Anova) --\n"); print(car::Anova(fit3, type = 3))
  }

  # ---- Effect sizes ---------------------------------------------------
  ss        <- aov_tab[, "Sum Sq"]; names(ss) <- rownames(aov_tab)
  ss_total  <- sum(ss); ss_resid <- ss["Residuals"]
  terms     <- c("group","region","group:region","Residuals")
  eta2      <- ss / ss_total
  peta2     <- ss[c("group","region","group:region")] /
               (ss[c("group","region","group:region")] + ss_resid)

  effect_tab <- data.frame(
    term         = terms,
    df           = aov_tab[terms, "Df"],
    sum_sq       = ss[terms],
    mean_sq      = aov_tab[terms, "Mean Sq"],
    F_value      = aov_tab[terms, "F value"],
    p_value      = aov_tab[terms, "Pr(>F)"],
    eta2         = eta2[terms],
    partial_eta2 = c(peta2[["group"]], peta2[["region"]], peta2[["group:region"]], NA),
    row.names    = NULL
  )

  cat("\n-- Two-way ANOVA (Type I) --\n"); print(aov_tab)
  cat("\n-- Effect sizes (variance explained) --\n"); print(format(effect_tab, digits=4))
  winner <- terms[which.max(eta2[c("group","region","group:region")])]
  cat(sprintf("-> group %.1f%% | region %.1f%% | interaction %.1f%% | residual %.1f%%  (dominant: %s)\n",
              100*eta2["group"], 100*eta2["region"], 100*eta2["group:region"],
              100*eta2["Residuals"], winner))

  # ---- Save tables ----------------------------------------------------
  write.csv(effect_tab, file.path(out_dir, paste0(ds$name, "_anova_table.csv")),
            row.names=FALSE)
  write.csv(dat[, c("group","region","cell","bias_mean")],
            file.path(out_dir, paste0(ds$name, "_anova_celldata.csv")), row.names=FALSE)
  gr_means <- aggregate(bias_mean ~ group + region, data = dat,
                        FUN = function(z) c(mean=mean(z), sd=sd(z), n=length(z)))
  gr_means <- do.call(data.frame, gr_means)
  names(gr_means) <- c("group","region","mean","sd","n")
  write.csv(gr_means, file.path(out_dir, paste0(ds$name, "_anova_groupregion_means.csv")),
            row.names=FALSE)

  # ---- Diagnostics + interaction plot ---------------------------------
  png(file.path(out_dir, paste0(ds$name, "_anova_diagnostics.png")),
      width=1900, height=1400, res=170)
  op <- par(mfrow=c(2,2)); plot(fit); par(op); dev.off()

  png(file.path(out_dir, paste0(ds$name, "_anova_interaction.png")),
      width=2000, height=1200, res=170)
  with(dat, interaction.plot(region, group, bias_mean,
       legend = FALSE, las = 2, col = hcl.colors(n_groups, "viridis"),
       lwd = 1.6, trace.label = "group",
       ylab = "mean bias", xlab = "region",
       main = paste0(ds$name, ": group x region interaction (cell means)")))
  dev.off()

  data.frame(dataset=ds$name, n_groups=n_groups, n_cells=nrow(dat),
             balanced=balanced,
             eta2_group=eta2[["group"]], eta2_region=eta2[["region"]],
             eta2_interaction=eta2[["group:region"]], eta2_residual=eta2[["Residuals"]],
             dominant=winner)
}

# ---- Run all ----------------------------------------------------------
summary_all <- do.call(rbind, lapply(datasets, run_dataset))
row.names(summary_all) <- NULL

cat("\n=====================================================\n")
cat("EFFECT-SIZE SUMMARY (all datasets)\n")
cat("=====================================================\n")
print(format(summary_all, digits=4), row.names=FALSE)
write.csv(summary_all,
          file.path(out_dir, "anova_effectsize_summary_all_datasets.csv"),
          row.names=FALSE)
cat("\nDone. Outputs in:", out_dir, "\n")
