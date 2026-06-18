# Rural-wales-service-accessibility

Using current datasets to measure travel-time access to care and everyday
services across rural and urban Wales — a Rural Health Compass placement project.

## Project Overview
This project evaluates access to GP surgeries, hospitals and everyday services
— pharmacies, supermarkets and leisure centres — across rural and urban Wales,
to assess whether NHS Wales's *Community by Design* model of "care closer to
home" is achievable in rural settings. Accessibility is measured using travel
times and distances to the nearest facilities and compared against the Access
to Services domain of WIMD 2025, applying health data science skills including
geocoding, integration of geographic datasets, statistical analysis and
mapping. It was produced during a 10-week professional placement with Rural
Health Compass.

## Placement Details
- **Student:** Ruthikssha Elangovan
- **Organisation:** Rural Health Compass (RHC)
- **Supervisor:** Dr Veronika Rasic
- **University:** University of Aberdeen — MSc Health Data Science
- **Period:** June – August 2026

## My Focus
My individual contribution within the three-person team focuses on **access to
primary and secondary care** across rural and urban Wales. I calculate the
average distance and travel time from rural and urban areas to their nearest
primary care and secondary care facilities, compare the two settings to show
how access differs and how people have to travel to reach care, and compare
these measures against the Access to Services domain of WIMD 2025.

If time permits, I will extend the analysis to everyday services such as
pharmacies, supermarkets and other local amenities.

## Repository Structure
- `scripts/` — R scripts (cleaning, analysis, mapping)
- `data/raw/` — raw source downloads (not tracked; see Data Sources)
- `data/processed/` — cleaned / derived data
- `outputs/` — figures, maps and tables

## Data Sources
Raw datasets are **not redistributed in this repository** — download each from
its source using the links below. (Use WIMD 2025.)

| Dataset | Provider | Licence | Link |
|---|---|---|---|
| [WIMD 2025 — Access to Services domain] | [Welsh Government] | [OGL v3.0] | [URL] |
| [LSOA boundaries] | [ONS] | [OGL v3.0] | [URL] |
| [Rural–urban classification] | [ONS] | [OGL v3.0] | [URL] |
| [Primary / secondary care facility locations] | [NHS Wales / StatsWales] | [check licence] | [URL] |

## Reproducing the Analysis
1. Clone this repository.
2. Download the datasets above into `data/raw/`.
3. Open the `.Rproj` file in RStudio.
4. Run the scripts in `scripts/` in order.

[Add your R version and key packages once known, e.g. R 4.x; sf, dplyr, tmap.]

## Licence
- **Code** (everything in `scripts/`) — MIT Licence, see `LICENSE-CODE`.
- **Data, figures and written outputs** — CC-BY-4.0, see `LICENSE`.

To reuse, please cite:
Elangovan, R. (2026), *Mapping Access to Care in Rural Wales*, [repository URL].
