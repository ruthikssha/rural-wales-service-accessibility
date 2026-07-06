wales_lsoa <-
  lsoa %>%
  filter(substr(LSOA21CD,1,1)=="W")
wales_centroids <-
  centroids %>%
  filter(substr(LSOA21CD,1,1)=="W")
wales_rural <-
  rural %>%
  filter(substr(LSOA21CD,1,1)=="W")