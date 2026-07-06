############################################################
# Rural Wales Healthcare Accessibility
# 03_prepare_analysis_data.R
#
# Purpose:
# Prepare clean datasets for accessibility analysis.
############################################################

library(sf)
library(tidyverse)
library(janitor)

############################################################
# 1. Clean Wales LSOA boundaries
############################################################

wales_lsoa_clean <- wales_lsoa %>%
  select(
    lsoa_code = LSOA21CD,
    lsoa_name = LSOA21NM,
    rural_urban = Urban_rura,
    rural_urban_detail = RUC21NM,
    geometry
  )

############################################################
# 2. Clean Wales population-weighted centroids
############################################################

wales_centroids_clean <- wales_centroids %>%
  select(
    lsoa_code = LSOA21CD,
    geometry
  )

############################################################
# 3. Clean GP surgery data
############################################################

gp_clean <- gp %>%
  select(
    gp_code = wcode,
    gp_name = practicena,
    health_board_code = lhbwcode,
    health_board_name = lhb_name_e,
    local_authority_code = lacode,
    lsoa_code = lsoa21cd,
    latitude,
    longitude,
    geometry
  )

############################################################
# 4. Clean hospital data
############################################################

hospitals_clean <- hospitals %>%
  select(
    hospital_name = name_en,
    health_board_name = h_board_en,
    local_authority = la_en,
    hospital_type = type_en,
    postcode,
    twenty_four_hour = X_24hr,
    geometry
  )

############################################################
# 5. Clean Health Board boundaries
############################################################

health_boards_clean <- health_boards %>%
  select(
    health_board_code = area_code,
    short_code = code,
    health_board_name = name_en,
    geometry
  )

############################################################
# 6. Clean WIMD data
############################################################

wimd_clean <- wimd %>%
  clean_names()

# Check available WIMD domains
unique(wimd_clean$domain)

# Keep ranks only
wimd_ranks <- wimd_clean %>%
  filter(data_description == "Rank") %>%
  select(
    lsoa_code = area_code,
    lsoa_name_wimd = area_name,
    domain,
    domain_reference,
    rank = data_values
  )

# Convert WIMD from long to wide format
wimd_wide <- wimd_ranks %>%
  select(lsoa_code, domain_reference, rank) %>%
  pivot_wider(
    names_from = domain_reference,
    values_from = rank,
    names_prefix = "wimd_rank_"
  )

############################################################
# 7. Join LSOA boundaries with WIMD
############################################################

lsoa_analysis <- wales_lsoa_clean %>%
  left_join(wimd_wide, by = "lsoa_code")

############################################################
# 8. Join centroids with LSOA attributes and WIMD
############################################################

centroids_analysis <- wales_centroids_clean %>%
  left_join(
    st_drop_geometry(wales_lsoa_clean),
    by = "lsoa_code"
  ) %>%
  left_join(
    wimd_wide,
    by = "lsoa_code"
  )

############################################################
# 9. Basic validation checks
############################################################

nrow(lsoa_analysis)
nrow(centroids_analysis)

sum(is.na(lsoa_analysis$lsoa_code))
sum(is.na(centroids_analysis$lsoa_code))

summary(lsoa_analysis)
summary(centroids_analysis)

############################################################
# 10. Save processed datasets
############################################################

st_write(
  lsoa_analysis,
  "Data/processed/lsoa_analysis.gpkg",
  delete_dsn = TRUE
)

st_write(
  centroids_analysis,
  "Data/processed/centroids_analysis.gpkg",
  delete_dsn = TRUE
)

st_write(
  gp_clean,
  "Data/processed/gp_clean.gpkg",
  delete_dsn = TRUE
)

st_write(
  hospitals_clean,
  "Data/processed/hospitals_clean.gpkg",
  delete_dsn = TRUE
)

st_write(
  health_boards_clean,
  "Data/processed/health_boards_clean.gpkg",
  delete_dsn = TRUE
)

############################################################
# End of script
############################################################