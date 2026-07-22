# =============================================================================
# 17_service_maps.R
#
# PURPOSE
#   Choropleth maps of road distance to GP, pharmacy and supermarket.
#   These are the distributed services - note the much shorter distances than
#   A&E or mental health, hence a separate (shared) scale for the three.
#
# INPUTS   data/processed/accessibility_combined.rds
#          data/processed/study_lsoa.gpkg
# OUTPUTS  Output/maps/access_{gp,pharmacy,supermarket}_road.png
# =============================================================================

library(sf)
library(dplyr)
library(tmap)

tmap_mode("plot")

accessibility <- readRDS("data/processed/accessibility_combined.rds")
study_lsoa    <- st_read("data/processed/study_lsoa.gpkg", quiet = TRUE)

service_map <- study_lsoa |>
  left_join(accessibility, by = "lsoa_code")

stopifnot(sum(is.na(service_map$gp_road_km)) == 0)


# Shared breaks so the three distributed services compare directly.
# Max across the three is ~31 km (supermarket, Powys), so 35 covers it.
breaks_svc <- c(0, 2, 5, 10, 20, 35)

make_map <- function(col, title) {
  tm_shape(service_map) +
    tm_polygons(
      fill = col,
      fill.scale = tm_scale_intervals(breaks = breaks_svc,
                                      values = "brewer.yl_or_rd"),
      fill.legend = tm_legend(title = "Road distance (km)"),
      col_alpha = 0.3
    ) +
    tm_title(title)
}

map_gp    <- make_map("gp_road_km",          "Road distance to nearest GP surgery")
map_pharm <- make_map("pharmacy_road_km",    "Road distance to nearest pharmacy")
map_super <- make_map("supermarket_road_km", "Road distance to nearest supermarket")

map_gp
map_pharm
map_super
tmap_save(map_gp,    "Output/maps/access_gp_road.png",          width = 8, height = 8, dpi = 200)
tmap_save(map_pharm, "Output/maps/access_pharmacy_road.png",    width = 8, height = 8, dpi = 200)
tmap_save(map_super, "Output/maps/access_supermarket_road.png", width = 8, height = 8, dpi = 200)