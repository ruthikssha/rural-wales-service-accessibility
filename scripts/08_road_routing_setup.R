install.packages("osrm")   # one-off
# =============================================================================
# 08_road_routing_setup.R
#
# PURPOSE
#   Set up road routing and prove it works on one route before scaling.
#
#   OUTCOME MEASURE: road-network distance in km.
#   Driving time is NOT an outcome in this project.
#
#   With only 12 A&E units, every centroid is routed to all 12 and the
#   minimum taken - no shortlisting needed, so the true road-nearest is certain.
#
# NOTE FOR SUPERVISOR: this uses the public OSRM demo server. Confirm with
#   your academic supervisor whether a local OSRM instance is preferable for
#   reproducibility and to avoid the public server's usage limits.
# =============================================================================

library(sf)
library(dplyr)
library(osrm)

packageVersion("osrm")

study_centroids <- st_read("Data/processed/study_centroids.gpkg", quiet = TRUE)
hospitals_ae    <- st_read("Data/processed/hospitals_ae.gpkg",    quiet = TRUE)

# Routing needs lon/lat (EPSG:4326). Keep the analysis data in 27700 and make
# COPIES for routing.
centroids_ll <- st_transform(study_centroids, 4326)
ae_ll        <- st_transform(hospitals_ae,    4326)
test_route <- osrmRoute(src = centroids_ll[1, ], dst = ae_ll[1, ])

test_route$distance   # km
test_route$duration   # minutes - ignore, not an outcome

# route centroid 1 to all 12 A&E units
test_all <- osrmTable(
  src     = centroids_ll[1, ],
  dst     = ae_ll,
  measure = "distance"
)

# distances come back in metres
round(as.numeric(test_all$distances) / 1000, 1)

straight_ae$straight_km[1]        # straight-line for centroid 1
straight_ae$study_area[1]         # which area it's in
min(as.numeric(test_all$distances)) / 1000   # road-nearest

# Route ALL 345 centroids to ALL 12 A&E units.
# Batching to stay within the public server's limits.

batch_size <- 25
n <- nrow(centroids_ll)
batches <- split(seq_len(n), ceiling(seq_len(n) / batch_size))

results <- list()

for (b in seq_along(batches)) {
  idx <- batches[[b]]
  message("Batch ", b, " of ", length(batches))
  
  tab <- osrmTable(
    src     = centroids_ll[idx, ],
    dst     = ae_ll,
    measure = "distance"
  )
  
  results[[b]] <- data.frame(
    lsoa_code   = centroids_ll$lsoa_code[idx],
    ae_road_km  = apply(tab$distances, 1, min, na.rm = TRUE) / 1000,
    nearest_ae  = ae_ll$hospital_name[apply(tab$distances, 1, which.min)]
  )
  
  Sys.sleep(1)   # be polite to the public server
}

ae_road <- bind_rows(results)
nrow(ae_road)   # expect 345

check <- ae_road |>
  left_join(straight_ae, by = "lsoa_code") |>
  mutate(ratio = ae_road_km / straight_km)

# road must ALWAYS be >= straight-line
sum(check$ratio < 1, na.rm = TRUE)   # expect 0

summary(check$ratio)


check |>
  slice_max(ratio, n = 5) |>
  select(lsoa_code, study_area, straight_km, ae_road_km, ratio)

check |>
  group_by(study_area) |>
  summarise(median_ratio = round(median(ratio), 2))

ae_road |>
  left_join(straight_ae |> select(lsoa_code, study_area), by = "lsoa_code") |>
  group_by(study_area) |>
  summarise(
    n = n(),
    min_km    = round(min(ae_road_km), 1),
    median_km = round(median(ae_road_km), 1),
    p90_km    = round(quantile(ae_road_km, 0.9), 1),
    max_km    = round(max(ae_road_km), 1)
  )

saveRDS(ae_road, "Data/processed/ae_road_distance.rds")