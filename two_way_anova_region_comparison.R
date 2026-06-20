# ============================================================
# two_way_anova_region_comparison.R  -- READ-ONLY on your data
# ------------------------------------------------------------
# Re-runs the two-way ANOVA of the bias field with 6 regions and
# with 12 regions, for each dataset (birds, fungi, vascularPlants,
# newbirds), to show how the variance decomposition changes with
# the number of regions.
#
#   response : bias_mean   (posterior-mean sampling-intensity per cell)
#   factor A : group       (taxonomic groups)
#   factor B : region      (6 or 12 named 10x10 km blocks)
#
# The 6-region set is the original config set (Setesdal, Oslo,
# Valdres, Trondheim, Tromso, Lakselv) -- exactly the first 6 of the
# 12, so each raster is read ONCE and both ANOVAs are fit from the
# same extraction.
#
# Outputs (-> Claude work folder):
#   <name>_anova_table_6regions.csv          per-dataset ANOVA table, 6 regions
#   anova_effectsize_summary_6regions.csv    eta^2 summary, 6 regions
#   anova_effectsize_summary_region_compare.csv   6 vs 12 combined
#   anova_effectsize_barchart_6regions.png/.pdf   standalone 6-region chart
#   anova_effectsize_barchart_6vs12.png/.pdf      grouped 6-vs-12 comparison
# ============================================================

suppressMessages({
  library(terra); library(sf); library(rnaturalearth); library(rnaturalearthhires)
})

# ---- Settings ---------------------------------------------------------
data_root    <- "D:/"
out_dir      <- "C:/Users/herma/OneDrive/Skrivebord/Claude work"
country_name <- "Norway"; ne_scale <- "large"
square_size  <- 10; half <- square_size / 2
LOG_RESPONSE <- FALSE

datasets <- list(
  list(name="birds",          subfolder="birds",          prefix="birds"),
  list(name="fungi",          subfolder="fungi",          prefix="fungiA"),
  list(name="vascularPlants", subfolder="vascularPlants", prefix="vascularPlantsA"),
  list(name="newbirds",       subfolder="Newbirds",       prefix="birds")
)

# Full 12-region set; the 6-region set is the first 6 (the original config).
region_centers_12 <- data.frame(
  region = c("Setesdal","Oslo","Valdres","Trondheim","Tromso","Lakselv",
             "Bergen","Kristiansand","Skorovatn","Bodo","Svolvar","Kirkenes"),
  x = c(100,255,200,280,650,900,-28,84,420,486,477,1075),
  y = c(6600,6655,6780,7030,7680,7800,6734,6472,7161,7467,7572,7801)
)
regions_6 <- region_centers_12$region[1:6]

# ---- Helpers ----------------------------------------------------------
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

# Long-format cell table for ALL 12 regions (single extraction per group).
build_celldata <- function(ds) {
  groups   <- detect_groups(ds$subfolder, ds$prefix)
  ref_mean <- unwrap(readRDS(file.path(data_root, ds$subfolder, groups[1],
                                       "Bias","Bias.rds")))[["mean"]]
  country_v <- vect(st_transform(
    ne_countries(country=country_name, scale=ne_scale, returnclass="sf"),
    crs(ref_mean)))
  region_v  <- build_polys(region_centers_12, half, ref_mean)
  ref_masked   <- mask(crop(ref_mean, country_v), country_v)
  ref_ex       <- terra::extract(ref_masked, region_v, cells=TRUE, touches=TRUE)
  names(ref_ex)[2] <- "val"
  region_cells <- split(ref_ex$cell, ref_ex$ID)

  rows <- lapply(seq_along(groups), function(gi) {
    bp <- file.path(data_root, ds$subfolder, groups[gi], "Bias","Bias.rds")
    rm <- mask(crop(unwrap(readRDS(bp))[["mean"]], country_v), country_v)
    ex <- terra::extract(rm, region_v, cells=TRUE, touches=TRUE)
    names(ex)[2] <- "val"
    do.call(rbind, lapply(seq_len(nrow(region_centers_12)), function(r) {
      cid <- region_cells[[as.character(r)]]
      sub <- ex[ex$ID==r, ]
      data.frame(group=groups[gi], region=region_centers_12$region[r],
                 cell=cid, bias_mean=sub$val[match(cid, sub$cell)])
    }))
  })
  dat <- do.call(rbind, rows)
  dat <- dat[!is.na(dat$bias_mean), ]
  dat$group  <- factor(dat$group, levels = groups)
  dat$region <- factor(dat$region, levels = region_centers_12$region)
  dat
}

# Fit two-way ANOVA on a region subset, return eta^2 decomposition.
fit_anova <- function(dat, keep_regions) {
  d <- dat[dat$region %in% keep_regions, ]
  d$region <- factor(d$region, levels = keep_regions)
  d$group  <- droplevels(d$group)
  d$y <- if (LOG_RESPONSE) log(d$bias_mean) else d$bias_mean

  fit <- aov(y ~ group * region, data = d)
  tab <- summary(fit)[[1]]; rownames(tab) <- trimws(rownames(tab))
  ss <- tab[, "Sum Sq"]; names(ss) <- rownames(tab)
  terms <- c("group","region","group:region","Residuals")
  eta2 <- ss / sum(ss)
  list(eta2 = eta2[terms], n_cells = nrow(d),
       n_groups = nlevels(d$group), tab = tab, terms = terms, ss = ss)
}

# ---- Run --------------------------------------------------------------
rows6 <- list(); rows_cmp <- list()
for (ds in datasets) {
  cat("\n#### ", ds$name, " ####\n", sep="")
  dat <- build_celldata(ds)

  r6  <- fit_anova(dat, regions_6)
  r12 <- fit_anova(dat, levels(dat$region))

  cat(sprintf("  6 regions:  region %.1f%% | group %.1f%% | inter %.1f%% | resid %.1f%%  (cells=%d)\n",
              100*r6$eta2["region"], 100*r6$eta2["group"],
              100*r6$eta2["group:region"], 100*r6$eta2["Residuals"], r6$n_cells))
  cat(sprintf("  12 regions: region %.1f%% | group %.1f%% | inter %.1f%% | resid %.1f%%  (cells=%d)\n",
              100*r12$eta2["region"], 100*r12$eta2["group"],
              100*r12$eta2["group:region"], 100*r12$eta2["Residuals"], r12$n_cells))

  # Save the 6-region ANOVA table (parallel to the 12-region per-dataset files).
  eff6 <- data.frame(term=r6$terms,
                     df=r6$tab[r6$terms,"Df"], sum_sq=r6$ss[r6$terms],
                     mean_sq=r6$tab[r6$terms,"Mean Sq"],
                     F_value=r6$tab[r6$terms,"F value"],
                     p_value=r6$tab[r6$terms,"Pr(>F)"],
                     eta2=r6$eta2[r6$terms], row.names=NULL)
  write.csv(eff6, file.path(out_dir, paste0(ds$name, "_anova_table_6regions.csv")),
            row.names=FALSE)

  rows6[[ds$name]] <- data.frame(
    dataset=ds$name, n_groups=r6$n_groups, n_regions=6, n_cells=r6$n_cells,
    eta2_group=r6$eta2[["group"]], eta2_region=r6$eta2[["region"]],
    eta2_interaction=r6$eta2[["group:region"]], eta2_residual=r6$eta2[["Residuals"]])
  rows_cmp[[ds$name]] <- rbind(
    data.frame(dataset=ds$name, n_regions=6,  n_cells=r6$n_cells,
               eta2_group=r6$eta2[["group"]], eta2_region=r6$eta2[["region"]],
               eta2_interaction=r6$eta2[["group:region"]], eta2_residual=r6$eta2[["Residuals"]]),
    data.frame(dataset=ds$name, n_regions=12, n_cells=r12$n_cells,
               eta2_group=r12$eta2[["group"]], eta2_region=r12$eta2[["region"]],
               eta2_interaction=r12$eta2[["group:region"]], eta2_residual=r12$eta2[["Residuals"]]))
}

summary6  <- do.call(rbind, rows6);    row.names(summary6) <- NULL
summary_cmp <- do.call(rbind, rows_cmp); row.names(summary_cmp) <- NULL
write.csv(summary6,  file.path(out_dir, "anova_effectsize_summary_6regions.csv"), row.names=FALSE)
write.csv(summary_cmp, file.path(out_dir, "anova_effectsize_summary_region_compare.csv"), row.names=FALSE)

cat("\n=========== 6 vs 12 region eta^2 summary ===========\n")
print(format(summary_cmp, digits=4), row.names=FALSE)

# ---- Chart helpers ----------------------------------------------------
nice <- c(birds="Birds", fungi="Fungi",
          vascularPlants="Vascular plants", newbirds="New birds")
cols <- c(Region="#2c7fb8", Group="#41ab5d", Interaction="#fdae61", Residual="#bdbdbd")

label_segments <- function(bp, M, thresh=3) {
  cum <- apply(M, 2, cumsum); mid <- cum - M/2
  for (j in seq_len(ncol(M))) for (i in seq_len(nrow(M))) if (M[i,j] >= thresh)
    text(bp[j], mid[i,j], sprintf("%.1f%%", M[i,j]),
         col=ifelse(rownames(M)[i]=="Region","white","black"), cex=0.72, font=2)
}

# ---- Chart 1: standalone 6-region stacked bars ------------------------
ord <- match(names(nice), summary6$dataset)
M6 <- rbind(Region=summary6$eta2_region, Group=summary6$eta2_group,
            Interaction=summary6$eta2_interaction, Residual=summary6$eta2_residual)[, ord]*100
colnames(M6) <- summary6$dataset[ord]
draw6 <- function() {
  par(mar=c(4.5,4.5,4,9), xpd=NA)
  bp <- barplot(M6, col=cols[rownames(M6)], border="white",
                names.arg=paste0(nice[colnames(M6)], "\n(", summary6$n_groups[ord], " groups)"),
                ylim=c(0,100), cex.names=0.9,
                ylab=expression("Variance explained  "*eta^2*"  (%)"),
                main="Two-way ANOVA of the bias field: region vs group (6 regions)")
  label_segments(bp, M6)
  legend(x=max(bp)+0.7, y=90, legend=rownames(M6), fill=cols[rownames(M6)],
         border=NA, bty="n", title="Source", cex=0.95)
}
png(file.path(out_dir,"anova_effectsize_barchart_6regions.png"),width=2100,height=1300,res=200);draw6();dev.off()
pdf(file.path(out_dir,"anova_effectsize_barchart_6regions.pdf"),width=10,height=6);draw6();dev.off()

# ---- Chart 2: grouped 6-vs-12 comparison ------------------------------
# Column order: per taxon a (6, 12) pair.
cmp_ord <- do.call(rbind, lapply(names(nice), function(dn)
  summary_cmp[summary_cmp$dataset==dn, ][order(summary_cmp$n_regions[summary_cmp$dataset==dn]), ]))
Mc <- rbind(Region=cmp_ord$eta2_region, Group=cmp_ord$eta2_group,
            Interaction=cmp_ord$eta2_interaction, Residual=cmp_ord$eta2_residual)*100
space <- rep(c(0.9, 0.12), length(nice))        # big gap before each pair's 1st bar
drawCmp <- function() {
  par(mar=c(5,4.5,4,9), xpd=NA)
  bp <- barplot(Mc, col=cols[rownames(Mc)], border="white", space=space,
                ylim=c(0,100), ylab=expression("Variance explained  "*eta^2*"  (%)"),
                main="Bias-field variance decomposition: 6 vs 12 regions",
                names.arg=rep(c("6","12"), length(nice)), cex.names=0.85)
  label_segments(bp, Mc)
  # Taxon labels centred under each pair.
  for (k in seq_along(nice))
    mtext(nice[k], side=1, line=2.6, at=mean(bp[(2*k-1):(2*k)]), font=2, cex=0.95)
  mtext("regions", side=1, line=1.2, at=bp[1]-0.9, cex=0.8, adj=1)
  legend(x=max(bp)+0.7, y=90, legend=rownames(Mc), fill=cols[rownames(Mc)],
         border=NA, bty="n", title="Source", cex=0.95)
}
png(file.path(out_dir,"anova_effectsize_barchart_6vs12.png"),width=2300,height=1300,res=200);drawCmp();dev.off()
pdf(file.path(out_dir,"anova_effectsize_barchart_6vs12.pdf"),width=11,height=6);drawCmp();dev.off()

cat("\nWrote 6-region tables + summaries and charts:\n",
    " anova_effectsize_barchart_6regions.png/.pdf\n",
    " anova_effectsize_barchart_6vs12.png/.pdf\n", sep="")
