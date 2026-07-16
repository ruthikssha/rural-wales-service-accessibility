# =============================================================================
# 05_define_facilities.R
#
# PURPOSE
#   Define the facility sets used as destinations in the accessibility analysis.
#
#   Secondary-care definition agreed with Dr Rasic (clinical steer, 2026):
#     Primary measure : the 12 Major A&E units - time-critical care such as
#                       heart attack and stroke, where distance matters most
#     Second measure  : the 24 mental health / learning disability units -
#                       an often-overlooked area where people are admitted
#                       far outside their local area
#     If time permits : community hospitals and day units
#
#   Cross-border decision: Welsh hospitals only. Cross-border use (particularly
#   Powys residents accessing English hospitals) is documented as a limitation
#   rather than modelled, since patient-flow data is not publicly available.
#
# INPUTS   Data/processed/hospitals_clean.gpkg
# OUTPUTS  Data/processed/hospitals_ae.gpkg   (12)
#          Data/processed/hospitals_mh.gpkg   (24)
# =============================================================================

library(sf)
library(dplyr)

hospitals_clean <- st_read("Data/processed/hospitals_clean.gpkg", quiet = TRUE)

# -----------------------------------------------------------------------------
# 1. Primary measure - Major A&E units
# -----------------------------------------------------------------------------

hospitals_ae <- hospitals_clean |>
  filter(hospital_type == "Major A&E Unit")

# -----------------------------------------------------------------------------
# 2. Second measure - mental health / learning disability units
# -----------------------------------------------------------------------------
# NOTE: "Elderly Mental Infirm" is included to reach the 24 units Dr Rasic
# referred to. It is a community hospital rather than a psychiatric unit,
# so worth confirming with her. Without it the group would be 21.

mh_types <- c(
  "Other - Psychiatric: Mental Illness",                      # 17
  "Other - Psychiatric: Learning disability",                 #  2
  "Other - Psychiatric: Mental Illness/Learning Disability",  #  2
  "Other - Community Hospital: Elderly Mental Infirm"         #  3
)

hospitals_mh <- hospitals_clean |>
  filter(hospital_type %in% mh_types)

# -----------------------------------------------------------------------------
# 3. Validate
# -----------------------------------------------------------------------------

stopifnot(nrow(hospitals_ae) == 12)
stopifnot(nrow(hospitals_mh) == 24)
stopifnot(st_crs(hospitals_ae)$epsg == 27700)
stopifnot(st_crs(hospitals_mh)$epsg == 27700)

# -----------------------------------------------------------------------------
# 4. Save
# -----------------------------------------------------------------------------

st_write(hospitals_ae, "Data/processed/hospitals_ae.gpkg", delete_dsn = TRUE, quiet = TRUE)
st_write(hospitals_mh, "Data/processed/hospitals_mh.gpkg", delete_dsn = TRUE, quiet = TRUE)