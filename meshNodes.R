# ============================================================================
# meshNodes.R
#
# Recreate the spatial mesh used in the hotspot project and plot its nodes.
# Built from the original meshCreation.R (meshTest()) plus regionGeometry.RDS.
#
# The mesh is an INLA/fmesher 2-D triangulation over mainland Norway, used as
# the spatial discretisation for the SPDE random field. This script rebuilds it
# with the exact same parameters and visualises the mesh NODES (vertices), which
# is what the spatial model is actually estimated on.
#
# Region geometry CRS: EPSG:25833 (ETRS89 / UTM zone 33N), units = metres.
# All mesh distances below are therefore in metres.
#
# Author: Hermann  |  Thesis: sampling bias in Norwegian biodiversity data
# ============================================================================

# ---- Packages --------------------------------------------------------------
# fm_extensions(), fm_mesh_2d_inla(), fm_crs() all live in the {fmesher}
# package (it is a stand-alone CRAN package and does NOT require INLA).
library(sf)
library(ggplot2)
library(fmesher)

# ---- Inputs ----------------------------------------------------------------
# Path to the region geometry. Defaults to a copy kept alongside this script;
# change it if you move the file.
regionGeometryPath <- "regionGeometry.RDS"
if (!file.exists(regionGeometryPath)) {
  # fall back to the Downloads copy
  regionGeometryPath <- "C:/Users/herma/Downloads/regionGeometry.RDS"
}
regionGeometry <- readRDS(regionGeometryPath)

# Mesh settings — identical to the hotspot project (meshCreation.R).
# cutoff   : minimum allowed edge length (nodes closer than this are merged)
# max.edge : c(inner, outer) maximum triangle edge length
# offset   : c(inner, outer) how far the two extension hulls reach out
myMesh <- list(
  cutoff   = 3   * 1000,            # 3 km
  max.edge = c(50, 300) * 1000,     # 50 km inside region, 300 km in the buffer
  offset   = c(20, 100) * 1000      # 20 km / 100 km extension
)

# ---- Mesh construction ------------------------------------------------------
# Faithful re-implementation of meshTest() from meshCreation.R, returning the
# mesh object (plotting is handled separately below).
buildMesh <- function(meshList, regionGeometry, crs = NULL) {
  # Define CRS if not provided: use the geometry's own CRS.
  if (is.null(crs)) {
    crs <- sf::st_crs(regionGeometry)$wkt
  } else {
    crs <- sf::st_crs(crs)$wkt          # standardise to WKT
  }

  # Two extension hulls (inner + outer boundary) for the spatial model.
  hull <- fm_extensions(
    regionGeometry,
    convex  = meshList$max.edge * 2,
    concave = meshList$max.edge * 2
  )

  # Build the constrained-refined Delaunay mesh.
  mesh <- fm_mesh_2d_inla(
    boundary = hull,
    max.edge = meshList$max.edge,       # km inside and outside
    cutoff   = meshList$cutoff,         # cutoff is the min edge
    offset   = meshList$offset,
    crs      = fm_crs(crs)
  )
  mesh
}

mesh <- buildMesh(myMesh, regionGeometry)

# Working CRS for plotting (geometry's own CRS).
crs <- sf::st_crs(regionGeometry)

# ---- Node extraction --------------------------------------------------------
# mesh$loc is an (n x 3) matrix of vertex coordinates; columns 1-2 are x/y in
# the mesh CRS. These points ARE the mesh nodes.
nodes <- as.data.frame(mesh$loc[, 1:2])
names(nodes) <- c("x", "y")

cat("Mesh summary\n")
cat("  nodes (vertices) :", mesh$n, "\n")
cat("  triangles        :", nrow(mesh$graph$tv), "\n")

# Flag which nodes fall inside the study region vs. in the outer buffer, so the
# plot can distinguish "interior" nodes from "extension" nodes.
nodes_sf <- sf::st_as_sf(nodes, coords = c("x", "y"), crs = crs)
region_union <- sf::st_union(regionGeometry)
inside <- lengths(sf::st_intersects(nodes_sf, region_union)) > 0
nodes$location <- ifelse(inside, "inside region", "extension buffer")
cat("  nodes inside region:", sum(inside), "\n")
cat("  nodes in buffer    :", sum(!inside), "\n")

# Mesh triangle edges as sf polygons (for drawing the triangulation without
# needing inlabru).
mesh_sfc <- fm_as_sfc(mesh)

# ---- Plot 1: mesh triangulation with nodes overlaid -------------------------
region_t <- sf::st_transform(regionGeometry, crs)

p_mesh <- ggplot() +
  geom_sf(data = mesh_sfc, fill = NA, colour = "grey75", linewidth = 0.15) +
  geom_sf(data = region_t, fill = NA, colour = "black", linewidth = 0.4) +
  geom_point(
    data = nodes,
    aes(x = x, y = y, colour = location),
    size = 0.45
  ) +
  scale_colour_manual(
    values = c("inside region" = "#1b9e77", "extension buffer" = "#d95f02"),
    name = NULL
  ) +
  labs(
    title = "Hotspot project mesh: triangulation and nodes",
    subtitle = sprintf("%d nodes, %d triangles | EPSG:25833",
                       mesh$n, nrow(mesh$graph$tv)),
    x = NULL, y = NULL
  ) +
  coord_sf(crs = crs) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

# ---- Plot 2: nodes only -----------------------------------------------------
p_nodes <- ggplot() +
  geom_sf(data = region_t, fill = NA, colour = "grey60", linewidth = 0.4) +
  geom_point(
    data = nodes,
    aes(x = x, y = y, colour = location),
    size = 0.6
  ) +
  scale_colour_manual(
    values = c("inside region" = "#1b9e77", "extension buffer" = "#d95f02"),
    name = NULL
  ) +
  labs(
    title = "Hotspot project mesh nodes",
    subtitle = sprintf("%d nodes (%d inside region, %d in buffer)",
                       mesh$n, sum(inside), sum(!inside)),
    x = NULL, y = NULL
  ) +
  coord_sf(crs = crs) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

# ---- Save -------------------------------------------------------------------
ggsave("mesh_triangulation_nodes.png", p_mesh, width = 8, height = 8, dpi = 300)
ggsave("mesh_triangulation_nodes.pdf", p_mesh, width = 8, height = 8)
ggsave("mesh_nodes.png", p_nodes, width = 8, height = 8, dpi = 300)
ggsave("mesh_nodes.pdf", p_nodes, width = 8, height = 8)

# Also export the node coordinates for downstream use / the thesis appendix.
write.csv(nodes, "mesh_nodes.csv", row.names = FALSE)

cat("\nSaved:\n",
    " mesh_triangulation_nodes.png / .pdf\n",
    " mesh_nodes.png / .pdf\n",
    " mesh_nodes.csv\n")
