# =============================================================================
# 13_service_routing.R
#
# PURPOSE
#   Road-network distance from each study-area centroid to its nearest
#   pharmacy and nearest supermarket (supplementary access measures).
#
#   OUTCOME: road distance in km. Driving time is not an outcome.
#
# LIMITATIONS:
#   - Community-maintained; coverage and tagging vary, worse in rural areas.
#   - Supermarket tagging is noisy: rural "shop=supermarket" sweeps up village
#     shops and convenience stores (Powys 54 > Swansea 26 is not real).
#     Treat supermarket results as indicative only.
#
# INPUTS   Data/processed/study_centroids.gpkg
#          Data/processed/pharmacies_clean.gpkg
#          Data/processed/supermarkets_clean.gpkg
# OUTPUTS  Data/processed/pharmacy_road_distance.rds
#          Data/processed/supermarket_road_distance.rds
# =============================================================================

library(sf)
library(dplyr)
library(units)
library(osrm)

file.exists("Data/processed/pharmacies_clean.gpkg")
file.exists("Data/processed/supermarkets_clean.gpkg")
file.exists("Data/processed/study_centroids.gpkg")

study_centroids <- st_read("Data/processed/study_centroids.gpkg",     quiet = TRUE)
pharmacies      <- st_read("Data/processed/pharmacies_clean.gpkg",    quiet = TRUE)
supermarkets    <- st_read("Data/processed/supermarkets_clean.gpkg",  quiet = TRUE)

# quick confirmation
nrow(pharmacies)     
nrow(supermarkets)   
st_crs(pharmacies)$epsg   

# -----------------------------------------------------------------------------
# Reusable: nearest-facility road distance with shortlist + resilient routing
# -----------------------------------------------------------------------------

route_nearest <- function(centroids, facilities, name_col, k = 10, pause = 0.5) {
  
  # shortlist: k nearest facilities per centroid, by straight line
  d <- st_distance(centroids, facilities)
  k <- min(k, nrow(facilities))                      
  cand <- t(apply(d, 1, function(x) order(as.numeric(x))[seq_len(k)]))
  
  # routing copies in lon/lat
  cen_ll <- st_transform(centroids,  4326)
  fac_ll <- st_transform(facilities, 4326)
  
  results <- vector("list", nrow(cen_ll))
  
  for (i in seq_len(nrow(cen_ll))) {
    if (i %% 25 == 0) message("  ", i, " of ", nrow(cen_ll))
    idx <- cand[i, ]
    
    results[[i]] <- tryCatch({
      tab   <- osrmTable(src = cen_ll[i, ], dst = fac_ll[idx, ], measure = "distance")
      dists <- as.numeric(tab$distances)
      data.frame(
        lsoa_code = cen_ll$lsoa_code[i],
        road_km   = min(dists, na.rm = TRUE) / 1000,
        nearest   = fac_ll[[name_col]][idx[which.min(dists)]]
      )
    }, error = function(e) { message("  failed ", i); NULL })
    
    Sys.sleep(pause)
  }
  results
}

message("Pharmacies:")
pharm_results <- route_nearest(study_centroids, pharmacies, name_col = "name")

# how many completed?
sum(!sapply(pharm_results, is.null))  

missing <- which(sapply(pharm_results, is.null))
missing  

cen_ll <- st_transform(study_centroids, 4326)
fac_ll <- st_transform(pharmacies, 4326)
d      <- st_distance(study_centroids, pharmacies)
cand   <- t(apply(d, 1, function(x) order(as.numeric(x))[seq_len(min(10, nrow(pharmacies)))]))

for (i in missing) {
  idx <- cand[i, ]
  pharm_results[[i]] <- tryCatch({
    tab <- osrmTable(src = cen_ll[i, ], dst = fac_ll[idx, ], measure = "distance")
    dd  <- as.numeric(tab$distances)
    data.frame(lsoa_code = cen_ll$lsoa_code[i], road_km = min(dd, na.rm = TRUE)/1000,
               nearest = fac_ll$name[idx[which.min(dd)]])
  }, error = function(e) NULL)
  Sys.sleep(2)
}

sum(!sapply(pharm_results, is.null))  


pharmacy_road <- bind_rows(pharm_results) |>
  rename(pharmacy_road_km = road_km, nearest_pharmacy = nearest)

nrow(pharmacy_road)                        
sum(is.na(pharmacy_road$pharmacy_road_km))

saveRDS(pharmacy_road, "Data/processed/pharmacy_road_distance.rds")

pharmacy_road |>
  left_join(study_centroids |> st_drop_geometry() |> select(lsoa_code, study_area),
            by = "lsoa_code") |>
  group_by(study_area) |>
  summarise(
    n = n(),
    min_km    = round(min(pharmacy_road_km), 1),
    median_km = round(median(pharmacy_road_km), 1),
    p90_km    = round(quantile(pharmacy_road_km, 0.9), 1),
    max_km    = round(max(pharmacy_road_km), 1)
  )

super_results <- route_nearest(study_centroids, supermarkets, name_col = "name")

sum(!sapply(super_results, is.null)) 

supermarket_road <- bind_rows(super_results) |>
  rename(supermarket_road_km = road_km, nearest_supermarket = nearest)

nrow(supermarket_road)                          # 345
sum(is.na(supermarket_road$supermarket_road_km)) # 0

saveRDS(supermarket_road, "Data/processed/supermarket_road_distance.rds")

supermarket_road |>
  left_join(study_centroids |> st_drop_geometry() |> select(lsoa_code, study_area),
            by = "lsoa_code") |>
  group_by(study_area) |>
  summarise(
    n = n(),
    min_km    = round(min(supermarket_road_km), 1),
    median_km = round(median(supermarket_road_km), 1),
    p90_km    = round(quantile(supermarket_road_km, 0.9), 1),
    max_km    = round(max(supermarket_road_km), 1)
  )