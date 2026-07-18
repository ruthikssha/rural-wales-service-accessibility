# =============================================================================
# 12_prepare_osm_services.R
#
# PURPOSE
#   Combine and clean the OpenStreetMap pharmacy and supermarket extracts
#   into two clean POINT layers in British National Grid (EPSG:27700).
#
# LIMITATION: OSM is community-maintained; coverage and tagging vary,
#   especially in rural areas. These are SUPPLEMENTARY measures.
# =============================================================================

library(sf)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. Inspect before combining
# -----------------------------------------------------------------------------
# The four extracts have different column counts (33/25/32/36), so they carry
# different OSM tags. Check geometry types and find the id column first.

table(st_geometry_type(pharmacy_powys))
table(st_geometry_type(pharmacy_swansea))

# find the id column - OSM usually calls it "osm_id" or "@id" or "id"
names(pharmacy_powys)

# -----------------------------------------------------------------------------
# 2. Combine pharmacies - keep only the columns we need
# -----------------------------------------------------------------------------

keep_cols <- function(x, area) {
  x |>
    select(id, name) |>          # geometry is kept automatically by sf
    mutate(source_area = area)
}

pharmacies_all <- bind_rows(
  keep_cols(pharmacy_powys,         "Powys"),
  keep_cols(pharmacy_ceredigion,    "Ceredigion"),
  keep_cols(pharmacy_pembrokeshire, "Pembrokeshire"),
  keep_cols(pharmacy_swansea,       "Swansea")
)

nrow(pharmacies_all)   

# reproject to British National Grid (OSM comes in EPSG:4326)
pharmacies_all <- st_transform(pharmacies_all, 27700)

# deduplicate - the four extracts overlap at boundaries, so the same
# pharmacy can appear in two of them
pharmacies_all <- pharmacies_all |>
  distinct(id, .keep_all = TRUE)

nrow(pharmacies_all)                       
sum(st_is_empty(pharmacies_all))           
st_crs(pharmacies_all)$epsg                
table(pharmacies_all$source_area)          

st_write(pharmacies_all, "Data/processed/pharmacies_clean.gpkg", delete_dsn = TRUE, quiet = TRUE)

# -----------------------------------------------------------------------------
# 3. Supermarkets
# -----------------------------------------------------------------------------

table(st_geometry_type(supermarket_powys))
table(st_geometry_type(supermarket_swansea))
names(supermarket_powys)   

table(st_geometry_type(supermarket_powys))
table(st_geometry_type(supermarket_swansea))

to_points <- function(x) {
  x |>
    st_make_valid() |>   # repair any malformed polygons first
    st_centroid()        # polygon -> its centre point; a point stays put
}

supermarkets_all <- bind_rows(
  keep_cols(supermarket_powys,         "Powys"),
  keep_cols(supermarket_ceredigion,    "Ceredigion"),
  keep_cols(supermarket_pembrokeshire, "Pembrokeshire"),
  keep_cols(supermarket_swansea,       "Swansea")
)

supermarkets_all <- st_transform(supermarkets_all, 27700)

supermarkets_all <- supermarkets_all |>
  distinct(id, .keep_all = TRUE)

nrow(supermarkets_all)
sum(st_is_empty(supermarkets_all))
st_crs(supermarkets_all)$epsg
table(supermarkets_all$source_area)

st_write(supermarkets_all, "Data/processed/supermarkets_clean.gpkg", delete_dsn = TRUE, quiet = TRUE)