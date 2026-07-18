# =============================================================================
# 11_gp_routing.R
#
# PURPOSE
#   Road-network distance from each study-area centroid to its nearest
#   GP main site (primary care access).
#
#   OUTCOME: road distance in km. Driving time is not an outcome.
#
# LIMITATION TO RECORD
#   The GP dataset covers MAIN SITES only (369). Branch surgeries are
#   excluded, so GP distances are overstated - a community served by a
#   branch surgery will appear further from primary care than it is.
#
# INPUTS   Data/processed/study_centroids.gpkg
#          Data/processed/gp_clean.gpkg
# OUTPUTS  Data/processed/gp_road_distance.rds
#          Data/processed/straight_line_gp.rds
# =============================================================================

library(sf)
library(dplyr)
library(units)
library(osrm)

# -----------------------------------------------------------------------------
# 1. Load and inspect
# -----------------------------------------------------------------------------

gp_clean <- st_read("Data/processed/gp_clean.gpkg", quiet = TRUE)

table(st_geometry_type(gp_clean))
names(gp_clean)
nrow(gp_clean)          
st_crs(gp_clean)$epsg   

table(st_geometry_type(gp_clean))
sum(duplicated(gp_clean$gp_code))   

# how many points inside each multipoint?
pts_per_gp <- lengths(st_geometry(gp_clean))
table(pts_per_gp)
gp_pts <- st_cast(gp_clean, "POINT")
nrow(gp_pts)                      
sum(duplicated(gp_pts$gp_code))  

# -----------------------------------------------------------------------------
# 2. Straight-line baseline (validation + candidate shortlist)
# -----------------------------------------------------------------------------

study_centroids <- st_read("Data/processed/study_centroids.gpkg", quiet = TRUE)

nearest_idx <- st_nearest_feature(study_centroids, gp_pts)

straight_km <- st_distance(
  study_centroids,
  gp_pts[nearest_idx, ],
  by_element = TRUE
) |>
  set_units("km") |>
  drop_units()

straight_gp <- study_centroids |>
  st_drop_geometry() |>
  select(lsoa_code, study_area) |>
  mutate(straight_km = straight_km)

saveRDS(straight_gp, "Data/processed/straight_line_gp.rds")

# shortlist: 10 nearest GPs per centroid, by straight line
d <- st_distance(study_centroids, gp_pts)          # 345 x 369
k <- 10
cand_gp <- t(apply(d, 1, function(x) order(as.numeric(x))[seq_len(k)]))

stopifnot(nrow(cand_gp) == nrow(study_centroids), ncol(cand_gp) == k)

centroids_ll <- st_transform(study_centroids, 4326)
gp_ll        <- st_transform(gp_pts,          4326)

results <- vector("list", nrow(centroids_ll))

for (i in seq_len(nrow(centroids_ll))) {
  if (i %% 25 == 0) message("centroid ", i, " of ", nrow(centroids_ll))
  
  cand <- cand_gp[i, ]
  tab  <- osrmTable(src = centroids_ll[i, ], dst = gp_ll[cand, ], measure = "distance")
  dists <- as.numeric(tab$distances)
  
  results[[i]] <- data.frame(
    lsoa_code  = centroids_ll$lsoa_code[i],
    gp_road_km = min(dists, na.rm = TRUE) / 1000,
    nearest_gp = gp_ll$gp_name[cand[which.min(dists)]]
  )
  
  Sys.sleep(0.3)
}

# which centroids are still missing?
missing <- which(sapply(results, is.null))
length(missing)   

for (i in missing) {
  message("centroid ", i)
  
  cand <- cand_gp[i, ]
  
  r <- tryCatch({
    tab   <- osrmTable(src = centroids_ll[i, ], dst = gp_ll[cand, ], measure = "distance")
    dists <- as.numeric(tab$distances)
    data.frame(
      lsoa_code  = centroids_ll$lsoa_code[i],
      gp_road_km = min(dists, na.rm = TRUE) / 1000,
      nearest_gp = gp_ll$gp_name[cand[which.min(dists)]]
    )
  }, error = function(e) {
    message("  failed: ", conditionMessage(e))
    NULL
  })
  
  results[[i]] <- r
  Sys.sleep(2)
}

sum(!sapply(results, is.null))   

gp_road <- bind_rows(results)
nrow(gp_road)   

check_gp <- gp_road |>
  left_join(straight_gp, by = "lsoa_code") |>
  mutate(ratio = gp_road_km / straight_km)

sum(check_gp$ratio < 1, na.rm = TRUE)   # expect 0
sum(is.na(gp_road$gp_road_km))          # expect 0

saveRDS(gp_road, "Data/processed/gp_road_distance.rds")

gp_road |>
  left_join(straight_gp |> select(lsoa_code, study_area), by = "lsoa_code") |>
  group_by(study_area) |>
  summarise(
    n = n(),
    min_km    = round(min(gp_road_km), 1),
    median_km = round(median(gp_road_km), 1),
    p90_km    = round(quantile(gp_road_km, 0.9), 1),
    max_km    = round(max(gp_road_km), 1)
  )

