# =============================================================================
# 07_straight_line_validation.R
#
# PURPOSE
#   Straight-line ("as the crow flies") distance from each study-area centroid
#   to its nearest facility.
#
#   THIS IS NOT A RESULT. It is used to:
#     1. confirm origins and destinations are wired up correctly
#     2. spot implausible facility locations
#     3. shortlist candidate facilities for road routing
#     4. later, show how much the road network inflates real journeys
#
#   Never report this as travel distance. Label it:
#     "Straight-line distance from the LSOA population-weighted centroid"
#
# INPUTS   Data/processed/study_centroids.gpkg
#          Data/processed/hospitals_ae.gpkg
# OUTPUTS  Data/processed/straight_line_ae.rds
# =============================================================================

library(sf)
library(dplyr)
library(units)

study_centroids <- st_read("Data/processed/study_centroids.gpkg", quiet = TRUE)
hospitals_ae    <- st_read("Data/processed/hospitals_ae.gpkg",    quiet = TRUE)

# Both must be in a projected CRS in metres, or distances are meaningless.
stopifnot(st_crs(study_centroids)$epsg == 27700)
stopifnot(st_crs(hospitals_ae)$epsg    == 27700)

# index of the nearest A&E unit for each centroid
nearest_idx <- st_nearest_feature(study_centroids, hospitals_ae)

# distance to that nearest unit, converted to km
straight_km <- st_distance(
  study_centroids,
  hospitals_ae[nearest_idx, ],
  by_element = TRUE
) |>
  set_units("km") |>
  drop_units()

straight_ae <- study_centroids |>
  st_drop_geometry() |>
  select(lsoa_code, study_area) |>
  mutate(
    nearest_ae_straight = hospitals_ae$hospital_name[nearest_idx],
    straight_km         = straight_km
  )

# distribution by study area
straight_ae |>
  group_by(study_area) |>
  summarise(
    n      = n(),
    min_km = round(min(straight_km), 1),
    median = round(median(straight_km), 1),
    max_km = round(max(straight_km), 1)
  )

saveRDS(straight_ae, "Data/processed/straight_line_ae.rds")
