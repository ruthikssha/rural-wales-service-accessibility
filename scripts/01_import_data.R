
############################################################
# Rural Wales Healthcare Accessibility
# 01_import_data.R
############################################################

# Load libraries
library(sf)
library(tidyverse)
library(readxl)

############################################################
# 1. GP Surgeries
############################################################

gp <- st_read("Data/raw/GP_Surgeries/gp_surgeries.shp")

############################################################
# 2. Hospitals
############################################################

hospitals <- st_read("Data/raw/Hospitals/hospitals.shp")

############################################################
# 3. Health Boards
############################################################

health_boards <- st_read("Data/raw/Health_Boards/health_boards.shp")

############################################################
# 4. Wales LSOA Boundaries
############################################################

lsoa <- st_read("Data/raw/LSOA_Boundaries/wales_lsoa.shp")

############################################################
# 5. Population Centroids
############################################################

centroids <- st_read("Data/raw/Population_Centroids/Population_Centroids.shp")

############################################################
# 6. Rural Urban Classification
############################################################

rural <- read_csv(
  "Data/raw/Rural_Urban_Classification/rural_urban.csv"
)

############################################################
# 7. WIMD
############################################################

wimd <- read_csv(
  "Data/raw/WIMD/welsh-index-of-multiple-deprivation-wimd-2025-index-and-domain-ranks-and-groups-for-lower-layer-super-output-areas-lsoa-v7-en-gb.csv"
)

############################################################
# 8. Pharmacies
############################################################

pharmacy_powys <-
  st_read("Data/raw/Pharmacies/pharmacies_powys.geojson")

pharmacy_ceredigion <-
  st_read("Data/raw/Pharmacies/pharmacies_ceredigion.geojson")

pharmacy_pembrokeshire <-
  st_read("Data/raw/Pharmacies/pharmacies_pembrokeshire.geojson")

pharmacy_swansea <-
  st_read("Data/raw/Pharmacies/pharmacies_swansea.geojson")

############################################################
# 9. Supermarkets
############################################################

supermarket_powys <-
  st_read("Data/raw/Supermarkets/supermarkets_powys.geojson")

supermarket_ceredigion <-
  st_read("Data/raw/Supermarkets/supermarkets_ceredigion.geojson")

supermarket_pembrokeshire <-
  st_read("Data/raw/Supermarkets/supermarkets_pembrokeshire.geojson")

supermarket_swansea <-
  st_read("Data/raw/Supermarkets/supermarkets_swansea.geojson")