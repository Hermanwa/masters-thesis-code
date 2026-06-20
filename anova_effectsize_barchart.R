# ============================================================
# anova_effectsize_barchart.R
# ------------------------------------------------------------
# Stacked eta^2 bar chart across the four taxa, from the table
# written by two_way_anova_all_datasets.R. One bar per dataset,
# segments = variance explained by region / group / interaction /
# residual. Shows at a glance that REGION dominates the bias field.
#
# Outputs (-> Claude work folder):
#   anova_effectsize_barchart.png
#   anova_effectsize_barchart.pdf
# ============================================================

out_dir <- "C:/Users/herma/OneDrive/Skrivebord/Claude work"
s <- read.csv(file.path(out_dir, "anova_effectsize_summary_all_datasets.csv"))

# Order + pretty labels for the x axis.
nice <- c(birds="Birds", fungi="Fungi",
          vascularPlants="Vascular plants", newbirds="New birds")
s <- s[match(names(nice), s$dataset), ]
labels <- paste0(nice[s$dataset], "\n(", s$n_groups, " groups)")

# Matrix [component x dataset], as percentages, stacked region-first.
M <- rbind(
  Region      = s$eta2_region,
  Group       = s$eta2_group,
  Interaction = s$eta2_interaction,
  Residual    = s$eta2_residual
) * 100
colnames(M) <- s$dataset

cols <- c(Region="#2c7fb8", Group="#41ab5d",
          Interaction="#fdae61", Residual="#bdbdbd")

draw <- function() {
  par(mar = c(4.5, 4.5, 4, 9), xpd = NA)
  bp <- barplot(M, col = cols[rownames(M)], border = "white",
                names.arg = labels, ylim = c(0, 100),
                ylab = expression("Variance explained  " * eta^2 * "  (%)"),
                main = "Two-way ANOVA of the bias field: region vs group",
                cex.names = 0.9)

  # Label each segment >=3% with its percentage.
  cum <- apply(M, 2, cumsum)
  mid <- cum - M/2
  for (j in seq_len(ncol(M))) for (i in seq_len(nrow(M))) {
    if (M[i, j] >= 3) {
      text(bp[j], mid[i, j], sprintf("%.1f%%", M[i, j]),
           col = ifelse(rownames(M)[i] %in% c("Region"), "white", "black"),
           cex = 0.8, font = 2)
    }
  }

  legend(x = max(bp) + 0.7, y = 90, legend = rownames(M),
         fill = cols[rownames(M)], border = NA, bty = "n",
         title = "Source", cex = 0.95)
}

png(file.path(out_dir, "anova_effectsize_barchart.png"),
    width = 2100, height = 1300, res = 200); draw(); dev.off()
pdf(file.path(out_dir, "anova_effectsize_barchart.pdf"),
    width = 10, height = 6); draw(); dev.off()

cat("Wrote:\n  anova_effectsize_barchart.png\n  anova_effectsize_barchart.pdf\nto", out_dir, "\n")
