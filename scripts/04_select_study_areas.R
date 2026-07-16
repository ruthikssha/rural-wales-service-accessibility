# PURPOSE
#   Select the LSOAs for the four study areas and save them for later scripts:
#     Rural comparison  : Powys, Ceredigion, Pembrokeshire
#     Urban comparator  : Swansea
#
# INPUTS   Data/processed/lsoa_analysis.gpkg       (created earlier)
#          Data/processed/centroids_analysis.gpkg  (created earlier)
#          the WIMD LSOA ranks CSV (for the LSOA -> local authority lookup)
#
# OUTPUTS  Data/processed/study_lsoa.gpkg
#          Data/processed/study_centroids.gpkg
#
# NOTE  sf must be loaded, or the spatial joins fail with a "geometry" error.
# =============================================================================

library(sf)        # keep first: spatial joins need it loaded
library(dplyr)
library(readr)
library(janitor)

# -----------------------------------------------------------------------------
# 1. Load the prepared spatial data
# -----------------------------------------------------------------------------

lsoa_analysis      <- st_read("Data/processed/lsoa_analysis.gpkg",      quiet = TRUE)
centroids_analysis <- st_read("Data/processed/centroids_analysis.gpkg", quiet = TRUE)

# -----------------------------------------------------------------------------
# 2. Read the WIMD ranks file
# -----------------------------------------------------------------------------
# The filename is long, so match it by pattern rather than typing it out.
# This should resolve to exactly one CSV.

wimd_file <- list.files(
  "Data/raw/WIMD",
  pattern    = "ranks-and-groups.*lsoa.*\\.csv$",
  full.names = TRUE
)

wimd_raw <- read_csv(wimd_file, show_col_types = FALSE) |>
  clean_names()

# -----------------------------------------------------------------------------
# 3. Build the LSOA -> local authority lookup
# -----------------------------------------------------------------------------
# WIMD is long format: each LSOA repeats for Rank / Decile / Quartile / etc.
# Keep only "Rank" rows, then reduce to one row per LSOA.
#   area_code            = LSOA code   (e.g. W01000003)
#   area_name_hierarchy  = the LSOA's local authority code (e.g. W06000023)

lsoa_la_lookup <- wimd_raw |>
  filter(data_description == "Rank") |>
  distinct(
    lsoa_code            = area_code,
    local_authority_code = area_name_hierarchy
  )

# The file also carries local-authority summary rows (LA code in the LSOA
# position, NA hierarchy). Real LSOA codes start "W01", so keep only those.
# This drops those 22 summary rows and leaves exactly 1,917 Welsh LSOAs.
lsoa_la_lookup <- lsoa_la_lookup |>
  filter(substr(lsoa_code, 1, 3) == "W01")

# Checks: one clean row per LSOA.
stopifnot(nrow(lsoa_la_lookup) == 1917)
stopifnot(sum(duplicated(lsoa_la_lookup$lsoa_code)) == 0)

# -----------------------------------------------------------------------------
# 4. Define the four study areas (by local authority code)
# -----------------------------------------------------------------------------
# data.frame() is used deliberately here (rather than tibble()) so the lookup
# is a plain table and cannot interact oddly with the spatial join below.

study_area_lookup <- data.frame(
  local_authority_code = c("W06000023", "W06000008", "W06000009", "W06000011"),
  study_area           = c("Powys", "Ceredigion", "Pembrokeshire", "Swansea"),
  comparison_group     = c("Rural", "Rural", "Rural", "Urban comparator"),
  stringsAsFactors     = FALSE
)

# -----------------------------------------------------------------------------
# 5. Attach the LA code to each LSOA, then keep only the four study areas
# -----------------------------------------------------------------------------

study_lsoa <- lsoa_analysis |>
  left_join(lsoa_la_lookup,    by = "lsoa_code") |>
  left_join(study_area_lookup, by = "local_authority_code") |>
  filter(!is.na(study_area))

study_centroids <- centroids_analysis |>
  left_join(lsoa_la_lookup,    by = "lsoa_code") |>
  left_join(study_area_lookup, by = "local_authority_code") |>
  filter(!is.na(study_area))

# -----------------------------------------------------------------------------
# 6. Validate
# -----------------------------------------------------------------------------
# Expected: 345 LSOAs total -
#   Ceredigion 45 . Pembrokeshire 71 . Powys 79 . Swansea 150
# Swansea has most (small but dense); the rural counties fewer (large, sparse).

print(table(study_lsoa$study_area))

stopifnot(nrow(study_lsoa) == nrow(study_centroids))
stopifnot(setequal(study_lsoa$lsoa_code, study_centroids$lsoa_code))

# -----------------------------------------------------------------------------

st_write(study_lsoa,      "Data/processed/study_lsoa.gpkg",      delete_dsn = TRUE, quiet = TRUE)
st_write(study_centroids, "Data/processed/study_centroids.gpkg", delete_dsn = TRUE, quiet = TRUE)