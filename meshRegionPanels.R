# ============================================================================
# meshRegionPanels.R
#
# Twelve panels, one per study region, each zoomed to the 10 x 10 km region
# square only. Purpose: check whether any mesh NODES fall inside each region.
#
# Each panel shows, for one region:
#   * the 10 km region square (red)
#   * the mesh triangulation (grey) crossing the square
#   * the mesh nodes (points); nodes strictly inside the square are highlighted
#   * a title with the count of nodes inside the square
#
# No bias field is drawn. The mesh is identical for every taxonomic group, so
# this node check applies to all of them.
#
# Units: the mesh is EPSG:25833 in metres; the region centres are UTM-33 in km.
# Everything is drawn in KILOMETRES (mesh coordinates divided by 1000).
#
# Author: Hermann  |  Thesis: sampling bias in Norwegian biodiversity data
# ============================================================================

library(sf)
library(ggplot2)
library(fmesher)
library(patchwork)

# ---- Settings --------------------------------------------------------------
regionGeometryPath <- "regionGeometry.RDS"
if (!file.exists(regionGeometryPath))
  regionGeometryPath <- "C:/Users/herma/Downloads/regionGeometry.RDS"

square_size <- 10    # region square side length (km); half-side = 5 km
pad_km      <- 1.5   # margin shown around the square so the border isn't flush

# ---- Region centres (from 00_config_12_updated.R; km, UTM-33) --------------
region_centers <- data.frame(
  region = c("Setesdal", "Oslo", "Valdres", "Trondheim", "Tromso", "Lakselv",
             "Bergen", "Kristiansand", "Skorovatn", "Bodo", "Svolvar", "Kirkenes"),
  x = c(100, 255, 200, 280, 650, 900,
        -28,  84,  420, 486, 477, 1075),
  y = c(6600, 6655, 6780, 7030, 7680, 7800,
        6734, 6472, 7161, 7467, 7572, 7801)
)
# North-to-south reading order for the panel grid.
region_centers <- region_centers[order(-region_centers$y), ]

# ---- Build the mesh (same parameters as meshCreation.R) --------------------
regionGeometry <- readRDS(regionGeometryPath)
myMesh <- list(
  cutoff   = 3   * 1000,
  max.edge = c(50, 300) * 1000,
  offset   = c(20, 100) * 1000
)
crs_wkt <- sf::st_crs(regionGeometry)$wkt
hull <- fm_extensions(regionGeometry,
                      convex  = myMesh$max.edge * 2,
                      concave = myMesh$max.edge * 2)
mesh <- fm_mesh_2d_inla(boundary = hull,
                        max.edge = myMesh$max.edge,
                        cutoff   = myMesh$cutoff,
                        offset   = myMesh$offset,
                        crs      = fm_crs(crs_wkt))
cat("Mesh:", mesh$n, "nodes,", nrow(mesh$graph$tv), "triangles\n")

# ---- Mesh geometry in kilometres -------------------------------------------
loc_km <- mesh$loc[, 1:2] / 1000
nodes  <- data.frame(x = loc_km[, 1], y = loc_km[, 2])

# Triangle outlines: 3 rows per triangle, grouped by triangle id, plus centroid.
tv     <- mesh$graph$tv
ntri   <- nrow(tv)
idx    <- as.vector(t(tv))
tri_df <- data.frame(tri = rep(seq_len(ntri), each = 3),
                     x   = loc_km[idx, 1],
                     y   = loc_km[idx, 2])
tri_cent <- data.frame(
  tri = seq_len(ntri),
  cx  = (loc_km[tv[, 1], 1] + loc_km[tv[, 2], 1] + loc_km[tv[, 3], 1]) / 3,
  cy  = (loc_km[tv[, 1], 2] + loc_km[tv[, 2], 2] + loc_km[tv[, 3], 2]) / 3
)

# ---- Per-region node count inside the square -------------------------------
hf <- square_size / 2
inside_counts <- integer(nrow(region_centers))
nearest_km    <- numeric(nrow(region_centers))
for (i in seq_len(nrow(region_centers))) {
  cx <- region_centers$x[i]; cy <- region_centers$y[i]
  inside_counts[i] <- sum(nodes$x >= cx - hf & nodes$x <= cx + hf &
                          nodes$y >= cy - hf & nodes$y <= cy + hf)
  nearest_km[i] <- min(sqrt((nodes$x - cx)^2 + (nodes$y - cy)^2))
}
region_centers$n_inside <- inside_counts
region_centers$nearest_km <- round(nearest_km, 1)

# Summary table: region, centre, nodes inside the 10 km square, and the
# distance to the nearest mesh node. Sorted nearest-node-first and written to
# CSV so anyone running the script gets the table as a tangible output.
node_summary <- region_centers[order(region_centers$nearest_km),
                               c("region", "x", "y", "n_inside", "nearest_km")]
names(node_summary) <- c("region", "x_km", "y_km",
                         "nodes_inside_square", "nearest_node_km")

cat("\nMesh nodes inside each 10 km region square:\n")
print(node_summary, row.names = FALSE)

write.csv(node_summary, "mesh_region_node_summary.csv", row.names = FALSE)
cat("\nSaved table: mesh_region_node_summary.csv\n")

# ---- One panel for a single region -----------------------------------------
make_panel <- function(reg, cx, cy, n_in) {
  xlo <- cx - hf - pad_km; xhi <- cx + hf + pad_km
  ylo <- cy - hf - pad_km; yhi <- cy + hf + pad_km

  # Triangles near the window (margin big enough to catch edges crossing it).
  keep <- tri_cent$tri[tri_cent$cx > xlo - 80 & tri_cent$cx < xhi + 80 &
                       tri_cent$cy > ylo - 80 & tri_cent$cy < yhi + 80]
  tri_w <- tri_df[tri_df$tri %in% keep, ]

  # Nodes inside vs just outside the square (within the padded window).
  nw <- nodes[nodes$x > xlo & nodes$x < xhi & nodes$y > ylo & nodes$y < yhi, ]
  inside <- nw$x >= cx - hf & nw$x <= cx + hf & nw$y >= cy - hf & nw$y <= cy + hf

  ggplot() +
    geom_polygon(data = tri_w, aes(x, y, group = tri),
                 fill = NA, colour = "grey55", linewidth = 0.25) +
    annotate("rect", xmin = cx - hf, xmax = cx + hf,
             ymin = cy - hf, ymax = cy + hf,
             fill = NA, colour = "#d6166b", linewidth = 0.8) +
    { if (any(!inside))
        geom_point(data = nw[!inside, ], aes(x, y),
                   colour = "grey55", size = 1.4) } +
    { if (any(inside))
        geom_point(data = nw[inside, ], aes(x, y),
                   colour = "#1b9e77", size = 2.2) } +
    coord_fixed(xlim = c(xlo, xhi), ylim = c(ylo, yhi), expand = FALSE) +
    labs(title = sprintf("%s  -  %d node%s inside",
                         reg, n_in, if (n_in == 1) "" else "s"),
         x = NULL, y = NULL) +
    theme_minimal(base_size = 9) +
    theme(axis.text = element_text(size = 6),
          plot.title = element_text(face = "bold", size = 9.5),
          panel.grid = element_blank(),
          panel.border = element_rect(fill = NA, colour = "grey70"))
}

panels <- Map(make_panel,
              region_centers$region, region_centers$x,
              region_centers$y, region_centers$n_inside)

# ---- Assemble the twelve panels --------------------------------------------
fig <- patchwork::wrap_plots(panels, ncol = 3) +
  patchwork::plot_annotation(
    title = "Mesh nodes within each 10 km study region",
    subtitle = "Red = 10 km region square; grey lines = mesh triangulation; green = node inside the square, grey = node just outside."
  )

ggsave("mesh_region_panels.png", fig, width = 11, height = 14, dpi = 300)
ggsave("mesh_region_panels.pdf", fig, width = 11, height = 14)
cat("\nSaved: mesh_region_panels.png / .pdf\n")
