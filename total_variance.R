# ============================================================
# total_variance.R
# ------------------------------------------------------------
# Computes the TOTAL VARIANCE of all bias_mean cell values that
# fall inside the regions, pooled across all regions and groups.
#
# READ-ONLY: this only reads your existing extract file. It does
# NOT modify any of your Workflow data.
# ============================================================

suppressMessages({
  if (!requireNamespace("readxl", quietly = TRUE)) {
    install.packages("readxl", repos = "https://cloud.r-project.org")
  }
  library(readxl)
})

# ---- Input: your existing 12-region extract file ----------------------
xlsx <- "D:/Newbirds/NewbirdsOutputs/bias_region_values_touching_cells_12reg.xlsx"

# Sheet of cells that have a real (non-NA) bias estimate
df <- as.data.frame(read_excel(xlsx, sheet = "bias_values_nonNA"))

cat("Sheets in file:\n"); print(excel_sheets(xlsx))

# ---- Structure check ---------------------------------------------------
cat("\n--- Structure ---\n")
cat("Total rows (group x cell):", nrow(df), "\n")
cat("Groups (n):", length(unique(df$group)), "->",
    paste(sort(unique(df$group)), collapse = ", "), "\n")
cat("Regions (n):", length(unique(df$region)), "->",
    paste(sort(unique(df$region)), collapse = ", "), "\n")
cat("Distinct raster cells across regions:",
    length(unique(df$cell)), "\n")

cat("\nDistinct cells per region:\n")
print(tapply(df$cell, df$region, function(z) length(unique(z))))

cat("\nRows per group:\n")
print(table(df$group))

# ---- TOTAL VARIANCE ----------------------------------------------------
x <- df$bias_mean
x <- x[!is.na(x)]

n        <- length(x)
mean_x   <- mean(x)
var_samp <- var(x)                 # sample variance (divides by n-1) - R default
var_pop  <- var_samp * (n - 1) / n # population variance (divides by n)
sd_samp  <- sd(x)

cat("\n=====================================================\n")
cat("TOTAL VARIANCE of all bias_mean cell values\n")
cat("(pooled across all regions and all groups)\n")
cat("=====================================================\n")
cat("n values         :", n, "\n")
cat("mean             :", format(mean_x,   digits = 10), "\n")
cat("variance (n-1)   :", format(var_samp, digits = 10), "\n")
cat("variance (n)     :", format(var_pop,  digits = 10), "\n")
cat("std. deviation   :", format(sd_samp,  digits = 10), "\n")
