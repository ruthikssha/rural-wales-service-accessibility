# =============================================================================
# 14_combine_accessibility.R
#
# PURPOSE
#   Combine the five service road-distance results into one LSOA-level
#   accessibility table, ready for the WIMD 2025 comparison.
#
# INPUTS   data/processed/{ae,mh,gp,pharmacy,supermarket}_road_distance.rds
# OUTPUTS  data/processed/accessibility_combined.rds
# =============================================================================

library(sf)
library(dplyr)

ae    <- readRDS("data/processed/ae_road_distance.rds")
mh    <- readRDS("data/processed/mh_road_distance.rds")
gp    <- readRDS("data/processed/gp_road_distance.rds")
pharm <- readRDS("data/processed/pharmacy_road_distance.rds")
super <- readRDS("data/processed/supermarket_road_distance.rds")


names(ae)
names(mh)
names(gp)
names(pharm)
names(super)


# -----------------------------------------------------------------------------
# Combine: one row per LSOA, five distances side by side
# -----------------------------------------------------------------------------

accessibility <- ae |>
  select(lsoa_code, ae_road_km) |>
  left_join(select(mh,    lsoa_code, mh_road_km),          by = "lsoa_code") |>
  left_join(select(gp,    lsoa_code, gp_road_km),          by = "lsoa_code") |>
  left_join(select(pharm, lsoa_code, pharmacy_road_km),    by = "lsoa_code") |>
  left_join(select(super, lsoa_code, supermarket_road_km), by = "lsoa_code")

nrow(accessibility)                          
sum(is.na(accessibility))                    
head(accessibility)

study_centroids <- st_read("data/processed/study_centroids.gpkg", quiet = TRUE)

accessibility <- accessibility |>
  left_join(study_centroids |> st_drop_geometry() |> select(lsoa_code, study_area),
            by = "lsoa_code")

sum(is.na(accessibility$study_area))   
table(accessibility$study_area)        

saveRDS(accessibility, "data/processed/accessibility_combined.rds")