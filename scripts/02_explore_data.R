library(sf)
library(tidyverse)

# Object names
names(gp)
names(hospitals)
names(health_boards)
names(wales_lsoa)
names(wales_centroids)
names(wales_rural)
names(wimd)

# Rows
nrow(gp)
nrow(hospitals)
nrow(health_boards)
nrow(wales_lsoa)
nrow(wales_centroids)
nrow(wales_rural)
nrow(wimd)

# Structure
glimpse(gp)
glimpse(hospitals)
glimpse(health_boards)
glimpse(wales_lsoa)
glimpse(wales_centroids)
glimpse(wales_rural)
glimpse(wimd)

# First rows
head(gp)
head(hospitals)
head(health_boards)
head(wales_lsoa)
head(wales_centroids)
head(wales_rural)
head(wimd)

summary(wales_lsoa)

summary(wales_centroids)

summary(wales_rural)

summary(wimd)