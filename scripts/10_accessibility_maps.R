# =============================================================================
# 10_accessibility_maps.R
#
# PURPOSE
#   Choropleth maps of road-network distance to A&E and to mental health units.
#
#   LABELLING: every legend must say "road distance (km)". Never "travel time".
#   These show distance to the nearest facility IN THE WELSH NETWORK - the
#   cross-border limitation applies, particularly for Powys.
#
# OUTPUTS  Output/maps/access_ae_road.png
#          Output/maps/access_mh_road.png
# =============================================================================

library(sf)
library(dplyr)
library(tmap)

tmap_mode("plot")

study_lsoa <- st_read("Data/processed/study_lsoa.gpkg", quiet = TRUE)
ae_road    <- readRDS("Data/processed/ae_road_distance.rds")
mh_road    <- readRDS("Data/processed/mh_road_distance.rds")

# join the distances onto the polygons
access_map <- study_lsoa |>
  left_join(ae_road, by = "lsoa_code") |>
  left_join(mh_road, by = "lsoa_code")

# every LSOA must have both distances
stopifnot(sum(is.na(access_map$ae_road_km)) == 0)
stopifnot(sum(is.na(access_map$mh_road_km)) == 0)

# Shared breaks so both maps are directly comparable.
# Top break of 125 covers the mental health maximum (119 km).
# The A&E map will not populate the top bin - that absence is informative:
# nowhere in the study areas is 100+ km from A&E, while parts of Powys and
# Ceredigion are that far from mental health provision.
breaks_km <- c(0, 10, 20, 30, 50, 75, 100, 125)

# -----------------------------------------------------------------------------
# A&E map
# -----------------------------------------------------------------------------

map_ae <-
  tm_shape(access_map) +
  tm_polygons(
    fill = "ae_road_km",
    fill.scale = tm_scale_intervals(
      breaks = breaks_km,
      values = "brewer.yl_or_rd"
    ),
    fill.legend = tm_legend(title = "Road distance (km)"),
    col_alpha = 0.3
  ) +
  tm_title("Road distance to nearest major A&E unit")

map_ae

# -----------------------------------------------------------------------------
# Mental health map
# -----------------------------------------------------------------------------

map_mh <-
  tm_shape(access_map) +
  tm_polygons(
    fill = "mh_road_km",
    fill.scale = tm_scale_intervals(
      breaks = breaks_km,
      values = "brewer.yl_or_rd"
    ),
    fill.legend = tm_legend(title = "Road distance (km)"),
    col_alpha = 0.3
  ) +
  tm_title("Road distance to nearest mental health unit")

map_mh

# -----------------------------------------------------------------------------
# Save
# -----------------------------------------------------------------------------

dir.create("Output/maps", recursive = TRUE, showWarnings = FALSE)

tmap_save(map_ae, "Output/maps/access_ae_road.png", width = 8, height = 8, dpi = 200)
tmap_save(map_mh, "Output/maps/access_mh_road.png", width = 8, height = 8, dpi = 200)