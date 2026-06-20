# ============================================================
# 04_extract_values.R
# ============================================================
# Extract bias_mean for every raster cell that TOUCHES each
# region polygon, for the groups in groups_extract.
# Writes a single Excel file with multiple sheets.
# ============================================================

source("00_config.R")
source("01_setup.R")

if (!requireNamespace("writexl", quietly = TRUE)) install.packages("writexl")
library(writexl)


# ---- Reference + country + regions ------------------------------------
ref_raster <- load_reference_raster()
country_v  <- load_country_outline(ref_raster)
region_v   <- build_region_polygons(ref_raster = ref_raster)


# ---- Load bias rasters for extract subset -----------------------------
bias_list <- load_bias_list(groups_extract, country_v)


# ---- Extract function -------------------------------------------------
extract_bias_cells_touching <- function(r, group_name, region_v) {

  ex <- terra::extract(r, region_v,
                       cells = TRUE, xy = TRUE, touches = TRUE)

  if (is.null(ex) || nrow(ex) == 0) return(NULL)

  value_col <- setdiff(names(ex), c("ID", "cell", "x", "y"))
  if (length(value_col) != 1) {
    stop("Could not uniquely identify raster value column for ", group_name)
  }

  names(ex)[names(ex) == value_col] <- "bias_mean"

  ex$group  <- group_name
  ex$region <- region_v$region[ex$ID]

  ex[, c("group", "region", "cell", "x", "y", "bias_mean")]
}


# ---- Run extraction ---------------------------------------------------
bias_region_list <- lapply(names(bias_list), function(g) {
  extract_bias_cells_touching(bias_list[[g]], g, region_v)
})

bias_region_df <- do.call(rbind, bias_region_list)
row.names(bias_region_df) <- NULL
bias_region_df <- unique(bias_region_df)


# ---- Cell counts + non-NA version -------------------------------------
cell_counts <- aggregate(cell ~ group + region,
                         data = bias_region_df,
                         FUN  = function(z) length(unique(z)))
names(cell_counts)[names(cell_counts) == "cell"] <- "n_cells"

cat("Number of cells per group-region:\n")
print(cell_counts)

bias_region_df_nonNA <- bias_region_df[!is.na(bias_region_df$bias_mean), ]


# ---- Write Excel ------------------------------------------------------
ensure_dir(out_root)
out_xlsx <- file.path(out_root, file_extract_xlsx)

write_xlsx(
  list(
    bias_values_all_touching_cells = bias_region_df,
    bias_values_nonNA              = bias_region_df_nonNA,
    cell_counts                    = cell_counts,
    region_centers                 = region_centers
  ),
  path = out_xlsx
)

cat("\nExcel file written to:\n", out_xlsx, "\n")

str(bias_region_df)
head(bias_region_df)
