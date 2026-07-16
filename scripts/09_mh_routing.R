# =============================================================================
# 09_mh_routing.R
#
# PURPOSE
#   Road-network distance from each study-area centroid to its nearest
#   mental health / learning disability unit (24 units, Welsh network only).
#
#   Second measure, per Dr Rasic's steer: mental health is often overlooked,
#   and people are frequently admitted far outside their local area.
#
#   OUTCOME: road distance in km. Driving time is not an outcome.
#
# OUTPUTS  Data/processed/mh_road_distance.rds
#          Data/processed/straight_line_mh.rds
# =============================================================================

library(sf)
library(dplyr)
library(units)
library(osrm)

study_centroids <- st_read("Data/processed/study_centroids.gpkg", quiet = TRUE)
hospitals_mh    <- st_read("Data/processed/hospitals_mh.gpkg",    quiet = TRUE)   # CHANGED

stopifnot(st_crs(study_centroids)$epsg == 27700)
stopifnot(st_crs(hospitals_mh)$epsg    == 27700)

nearest_idx <- st_nearest_feature(study_centroids, hospitals_mh)

straight_km <- st_distance(
  study_centroids,
  hospitals_mh[nearest_idx, ],
  by_element = TRUE
) |>
  set_units("km") |>
  drop_units()

straight_mh <- study_centroids |>
  st_drop_geometry() |>
  select(lsoa_code, study_area) |>
  mutate(straight_km = straight_km)

saveRDS(straight_mh, "Data/processed/straight_line_mh.rds")

centroids_ll <- st_transform(study_centroids, 4326)
mh_ll        <- st_transform(hospitals_mh,    4326)   # CHANGED

batch_size <- 25
n <- nrow(centroids_ll)
batches <- split(seq_len(n), ceiling(seq_len(n) / batch_size))

results <- list()

for (b in seq_along(batches)) {
  idx <- batches[[b]]
  message("Batch ", b, " of ", length(batches))
  
  tab <- osrmTable(src = centroids_ll[idx, ], dst = mh_ll, measure = "distance")
  
  results[[b]] <- data.frame(
    lsoa_code  = centroids_ll$lsoa_code[idx],
    mh_road_km = apply(tab$distances, 1, min, na.rm = TRUE) / 1000,
    nearest_mh = mh_ll$hospital_name[apply(tab$distances, 1, which.min)]
  )
  
  Sys.sleep(1)
}

mh_road <- bind_rows(results)
nrow(mh_road)   # expect 345

check_mh <- mh_road |>
  left_join(straight_mh, by = "lsoa_code") |>
  mutate(ratio = mh_road_km / straight_km)

sum(check_mh$ratio < 1, na.rm = TRUE)   # expect 0
sum(is.na(mh_road$mh_road_km))          # expect 0

saveRDS(mh_road, "Data/processed/mh_road_distance.rds")

mh_road |>
  left_join(straight_mh |> select(lsoa_code, study_area), by = "lsoa_code") |>
  group_by(study_area) |>
  summarise(
    n = n(),
    min_km    = round(min(mh_road_km), 1),
    median_km = round(median(mh_road_km), 1),
    p90_km    = round(quantile(mh_road_km, 0.9), 1),
    max_km    = round(max(mh_road_km), 1)
  )
