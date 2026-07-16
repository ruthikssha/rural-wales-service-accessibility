# =============================================================================
# 06_exploratory_mapping.R
#
# PURPOSE
#   Quality-control maps, produced BEFORE any distance analysis.
#   These are not report maps. The purpose is to check that:
#     - the study areas look like the right parts of Wales
#     - facilities sit in plausible places (a dot in the sea = CRS problem)
#     - nothing is displaced relative to anything else
#     - each study area has the coverage expected
#
#   NOTE: several of the 12 A&E units fall OUTSIDE the four study areas.
#   That is correct and expected - A&E provision is Wales-wide, and a Powys
#   resident's nearest A&E may be in Cardiff or Wrexham. Do not clip them.
#
# INPUTS   Data/processed/study_lsoa.gpkg
#          Data/processed/hospitals_ae.gpkg
#          Data/processed/hospitals_mh.gpkg
# OUTPUTS  Output/maps/qc_*.png
# =============================================================================
install.packages("tmap")
library(sf)
library(dplyr)
library(tmap)
packageVersion("tmap")

tmap_mode("plot")

# 1. Load
# -----------------------------------------------------------------------------

study_lsoa   <- st_read("Data/processed/study_lsoa.gpkg",   quiet = TRUE)
hospitals_ae <- st_read("Data/processed/hospitals_ae.gpkg", quiet = TRUE)
hospitals_mh <- st_read("Data/processed/hospitals_mh.gpkg", quiet = TRUE)

# All layers must share one CRS or the map is meaningless.
stopifnot(st_crs(study_lsoa)$epsg   == 27700)
stopifnot(st_crs(hospitals_ae)$epsg == 27700)
stopifnot(st_crs(hospitals_mh)$epsg == 27700)

# -----------------------------------------------------------------------------
# 2. Map: the four study areas
# -----------------------------------------------------------------------------

qc_areas <-
  tm_shape(study_lsoa) +
  tm_polygons(fill = "study_area", fill.legend = tm_legend(title = "Study area")) +
  tm_title("QC: study areas")

qc_areas

# -----------------------------------------------------------------------------
# 3. Map: study areas + Major A&E units
# -----------------------------------------------------------------------------

qc_ae <-
  tm_shape(study_lsoa) +
  tm_borders(col_alpha = 0.4) +
  tm_shape(hospitals_ae) +
  tm_dots(fill = "red", size = 0.6) +
  tm_title("QC: study areas and Major A&E units (12)")

qc_ae

# how many A&E units fall inside each study area?
st_join(hospitals_ae, study_lsoa["study_area"]) |>
  st_drop_geometry() |>
  count(study_area)

# 4. Map: study areas + mental health units
# -----------------------------------------------------------------------------

qc_mh <-
  tm_shape(study_lsoa) +
  tm_borders(col_alpha = 0.4) +
  tm_shape(hospitals_mh) +
  tm_dots(fill = "purple", size = 0.4) +
  tm_title("QC: study areas and mental health units (24)")

qc_mh

st_join(hospitals_mh, study_lsoa["study_area"]) |>
  st_drop_geometry() |>
  count(study_area)

