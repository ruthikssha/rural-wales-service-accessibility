library(sf)
library(dplyr)
library(tmap)

tmap_mode("plot")

# 1. Load and join
mismatch   <- readRDS("data/processed/mismatch_analysis.rds")
study_lsoa <- st_read("data/processed/study_lsoa.gpkg", quiet = TRUE)

mismatch_map <- study_lsoa |>
  left_join(mismatch |> select(lsoa_code, mismatch_gap, ae_road_km, wimd_access_rank),
            by = "lsoa_code")

# 2. Categorise
mismatch_map <- mismatch_map |>
  mutate(mismatch_cat = case_when(
    mismatch_gap >=  50 ~ "WIMD greatly under-rates (far, ranked well)",
    mismatch_gap >=  20 ~ "WIMD under-rates",
    mismatch_gap >  -20 ~ "Broadly agree",
    mismatch_gap > -50  ~ "WIMD over-rates",
    TRUE                ~ "WIMD greatly over-rates (near, ranked poorly)"
  ),
  mismatch_cat = factor(mismatch_cat, levels = c(
    "WIMD greatly under-rates (far, ranked well)",
    "WIMD under-rates", "Broadly agree", "WIMD over-rates",
    "WIMD greatly over-rates (near, ranked poorly)")))

# 3. VERIFY before mapping - expect +85.5 and "greatly under-rates"
print(
  mismatch_map |>
    st_drop_geometry() |>
    filter(lsoa_code == "W01000431") |>
    select(lsoa_code, mismatch_gap, mismatch_cat)
)

# 4. Map with explicit colours
mismatch_cols <- c(
  "WIMD greatly under-rates (far, ranked well)"   = "#B2182B",
  "WIMD under-rates"                              = "#EF8A62",
  "Broadly agree"                                 = "#F7F7F7",
  "WIMD over-rates"                               = "#92C5DE",
  "WIMD greatly over-rates (near, ranked poorly)" = "#2166AC"
)

map_mismatch <-
  tm_shape(mismatch_map) +
  tm_polygons(
    fill = "mismatch_cat",
    fill.scale = tm_scale_categorical(values = mismatch_cols),
    fill.legend = tm_legend(title = "Access mismatch"),
    col_alpha = 0.3
  ) +
  tm_title("Where WIMD under-rates rural A&E access")

map_mismatch

tmap_save(map_mismatch, "Output/maps/mismatch_ae.png", width = 9, height = 8, dpi = 200)

