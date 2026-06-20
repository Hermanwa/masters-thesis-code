# ============================================================
# 05_randomization.R
# ============================================================
# Block-randomization test for all target groups.
# For each target group:
#   - original = all regions from that target group
#   - mixed    = (N-1) regions from target + 1 swapped region from donor
# Main statistic: variance among regional variances.
# Reads the Excel produced by module 04.
# ============================================================

source("00_config.R")
source("01_setup.R")

if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl")
library(readxl)


# ---- Load data --------------------------------------------------------
excel_path <- file.path(out_root, file_extract_xlsx)
bias_df    <- read_excel(excel_path, sheet = "bias_values_nonNA")
bias_df    <- as.data.frame(bias_df)
bias_df    <- bias_df[, c("group", "region", "cell", "x", "y", "bias_mean")]


# ---- Available groups and regions -------------------------------------
all_groups  <- sort(unique(bias_df$group))
all_regions <- sort(unique(bias_df$region))

cat("Groups in file:\n");  print(all_groups)
cat("\nRegions in file:\n"); print(all_regions)


# ---- Per-region variance ----------------------------------------------
region_variance <- function(df, label_name) {
  out <- aggregate(bias_mean ~ region, data = df, FUN = var, na.rm = TRUE)
  names(out)[2] <- "region_variance"
  out$dataset_label <- label_name
  out[, c("dataset_label", "region", "region_variance")]
}


# ---- Storage ----------------------------------------------------------
all_variance_tables <- list()
all_summary_tables  <- list()
counter <- 1


# ---- Main loop over target groups -------------------------------------
for (target_group in all_groups) {

  cat("\n=====================================================\n")
  cat("Target group:", target_group, "\n")
  cat("=====================================================\n")

  donor_groups <- setdiff(all_groups, target_group)
  original_df  <- subset(bias_df, group == target_group)

  cat("\nCell counts in target group:\n")
  print(table(original_df$region))

  if (length(unique(original_df$region)) < length(all_regions)) {
    cat("\nSkipping", target_group, "- does not contain all regions.\n")
    next
  }

  var_original <- region_variance(original_df, "original")

  original_summary <- data.frame(
    target_group           = target_group,
    swapped_region         = "none",
    donor_group            = "none",
    dataset_label          = "original",
    variance_among_regions = var(var_original$region_variance),
    mean_region_variance   = mean(var_original$region_variance)
  )

  all_variance_tables[[counter]] <- cbind(
    target_group   = target_group,
    swapped_region = "none",
    donor_group    = "none",
    var_original
  )
  all_summary_tables[[counter]] <- original_summary
  counter <- counter + 1

  for (swap_region in all_regions) {
    for (donor_group in donor_groups) {

      cat("Running swap:", target_group, "|", swap_region,
          "from", donor_group, "\n")

      keep_df  <- subset(bias_df,
                         group == target_group & region != swap_region)
      donor_df <- subset(bias_df,
                         group == donor_group  & region == swap_region)

      if (nrow(donor_df) == 0) next

      mixed_df <- rbind(keep_df, donor_df)

      if (length(unique(mixed_df$region)) < length(all_regions)) next

      mixed_df$group <- paste0(target_group, "_mixed")

      var_mixed <- region_variance(
        mixed_df,
        paste0("swap_", swap_region, "_from_", donor_group)
      )

      all_variance_tables[[counter]] <- cbind(
        target_group   = target_group,
        swapped_region = swap_region,
        donor_group    = donor_group,
        var_mixed
      )

      all_summary_tables[[counter]] <- data.frame(
        target_group           = target_group,
        swapped_region         = swap_region,
        donor_group            = donor_group,
        dataset_label          = paste0("swap_", swap_region,
                                        "_from_", donor_group),
        variance_among_regions = var(var_mixed$region_variance),
        mean_region_variance   = mean(var_mixed$region_variance)
      )
      counter <- counter + 1
    }
  }
}


# ---- Combine ----------------------------------------------------------
master_regional_variance_table <- do.call(rbind, all_variance_tables)
master_summary_table           <- do.call(rbind, all_summary_tables)


# ---- Add original statistic back onto each row ------------------------
original_stats <- subset(master_summary_table,
                         dataset_label == "original",
                         c("target_group", "variance_among_regions"))
names(original_stats)[2] <- "original_variance_among_regions"

master_summary_table <- merge(master_summary_table, original_stats,
                              by = "target_group", all.x = TRUE)

master_summary_table$change_from_original <-
  master_summary_table$variance_among_regions -
  master_summary_table$original_variance_among_regions

master_summary_table$abs_change_from_original <-
  abs(master_summary_table$change_from_original)

master_summary_table <- master_summary_table[
  order(master_summary_table$target_group,
        -master_summary_table$abs_change_from_original), ]


# ---- Top 10 changes per target group ----------------------------------
non_original <- subset(master_summary_table, dataset_label != "original")

top_changes_per_group <- do.call(
  rbind,
  lapply(split(non_original, non_original$target_group), function(df) {
    df <- df[order(-df$abs_change_from_original), ]
    head(df, 10)
  })
)


# ---- Region sensitivity summary ---------------------------------------
# For each region: how much does swapping it typically change the result?
region_sensitivity <- do.call(
  rbind,
  lapply(split(non_original, non_original$swapped_region), function(df) {
    data.frame(
      swapped_region     = df$swapped_region[1],
      n_swaps            = nrow(df),
      mean_abs_change    = mean(df$abs_change_from_original, na.rm = TRUE),
      median_abs_change  = median(df$abs_change_from_original, na.rm = TRUE),
      sd_abs_change      = sd(df$abs_change_from_original, na.rm = TRUE),
      max_abs_change     = max(df$abs_change_from_original, na.rm = TRUE)
    )
  })
)
row.names(region_sensitivity) <- NULL

# Sort by mean_abs_change (most sensitive first)
region_sensitivity <- region_sensitivity[
  order(-region_sensitivity$mean_abs_change), ]


# ---- Print summaries --------------------------------------------------
cat("\n=====================================================\n")
cat("Original summary rows for each target group\n")
cat("=====================================================\n")
print(subset(master_summary_table, dataset_label == "original"))

cat("\n=====================================================\n")
cat("Region sensitivity (most influential regions first)\n")
cat("=====================================================\n")
print(region_sensitivity)


# ---- Write CSV outputs ------------------------------------------------
ensure_dir(out_root)

write.csv(master_summary_table,
          file.path(out_root, file_rand_summary),
          row.names = FALSE)

write.csv(master_regional_variance_table,
          file.path(out_root, file_rand_variances),
          row.names = FALSE)

write.csv(top_changes_per_group,
          file.path(out_root, file_rand_top10),
          row.names = FALSE)

write.csv(region_sensitivity,
          file.path(out_root, file_rand_sensitivity),
          row.names = FALSE)

cat("\nCSV files written to", out_root, "\n")


# ---- Plots: write to a single PDF -------------------------------------
pdf(file   = file.path(out_root, file_rand_plots_pdf),
    width  = 9,
    height = 6.5)

# Use a colorblind-friendly palette for the regions
region_cols <- hcl.colors(length(unique(non_original$swapped_region)),
                          palette = "Set 2")

# --- Plot 1: Boxplot of change per region (the main answer) -----------
par(mar = c(7, 4.5, 4, 2))

# Order regions on the x-axis by mean_abs_change (highest first)
region_order <- region_sensitivity$swapped_region
non_original$swapped_region_ord <- factor(non_original$swapped_region,
                                          levels = region_order)

boxplot(abs_change_from_original ~ swapped_region_ord,
        data   = non_original,
        main   = "Region sensitivity: how much swapping each region changes the result",
        xlab   = "",
        ylab   = "Absolute change in variance among regions",
        col    = region_cols,
        las    = 2,            # rotate x-axis labels
        cex.axis = 0.9,
        outline  = TRUE)

mtext("Swapped region (sorted by mean impact, highest left)",
      side = 1, line = 5.5, cex = 0.95)

# --- Plot 2: Histogram of change from original ------------------------
par(mar = c(4.5, 4.5, 4, 2))

hist(master_summary_table$change_from_original,
     breaks = 50,
     main   = "Distribution of change in variance among regions",
     xlab   = "Change from original (mixed - original)",
     ylab   = "Number of swaps",
     col    = "grey75",
     border = "white")
abline(v = 0, col = "red", lwd = 2, lty = 2)
legend("topright", legend = "No change", col = "red",
       lwd = 2, lty = 2, bty = "n")

# --- Plot 3: Dot plot of region sensitivity ---------------------------
par(mar = c(4.5, 7, 4, 2))

# dotchart plots bottom-to-top, so reverse to get the most sensitive on top
rs <- region_sensitivity[order(region_sensitivity$mean_abs_change), ]

dotchart(rs$mean_abs_change,
         labels = rs$swapped_region,
         main   = "Region sensitivity: mean absolute change per region",
         xlab   = "Mean absolute change in variance among regions",
         pch    = 19,
         color  = rev(region_cols),
         xlim   = c(0, max(rs$max_abs_change, na.rm = TRUE)),
         cex    = 1.1)

# add the median as a hollow point and a line out to the max, for context
points(rs$median_abs_change, seq_along(rs$median_abs_change),
       pch = 1, cex = 1.1)
segments(rs$mean_abs_change, seq_along(rs$mean_abs_change),
         rs$max_abs_change,  seq_along(rs$mean_abs_change),
         col = "grey60", lty = 3)

legend("bottomright",
       legend = c("Mean", "Median", "to Max"),
       pch    = c(19, 1, NA),
       lty    = c(NA, NA, 3),
       col    = c("black", "black", "grey60"),
       bty    = "n", cex = 0.9)


dev.off()

cat("Plots written to", file.path(out_root, file_rand_plots_pdf), "\n")
