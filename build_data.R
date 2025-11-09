library(tidyverse)

# Clean data ----

## Met Office Hadley Centre - HadCRUT5 ----
# Anomalies based on 1961-1990 average as reference
# https://www.metoffice.gov.uk/hadobs/hadcrut5/
#
# This is what the original warming stripes used: https://showyourstripes.info/
#
# HadCRUT.5.1.0.0 - https://www.metoffice.gov.uk/hadobs/hadcrut5/data/HadCRUT.5.1.0.0/download.html
# Annual: https://www.metoffice.gov.uk/hadobs/hadcrut5/data/HadCRUT.5.1.0.0/analysis/diagnostics/HadCRUT.5.1.0.0.analysis.summary_series.global.annual.csv

hadcrut <- read_csv(
  "data-original/HadCRUT.5.1.0.0.analysis.summary_series.global.annual.csv"
) |>
  rename(
    year = Time,
    anomaly = `Anomaly (deg C)`,
    conf_low = `Lower confidence limit (2.5%)`,
    conf_high = `Upper confidence limit (97.5%)`
  )


## Berkeley Earth ----
# Global Monthly Averages (1850 – Recent), annual summary
# Anomalies based on 1850-1900 average as reference
# https://berkeleyearth.org/data/

# Load data
# This is annoying because it's in a weird format and has a bunch of comments at
# the beginning and is missing good column names
best <- read_table(
  "data-original/Land_and_Ocean_summary.txt",
  comment = "%",
  na = "NaN",
  skip = 58,
  col_names = c(
    "year",
    "anom1y",
    "uncert1y",
    "anom5y",
    "uncert5y",
    "anom1y_below",
    "uncert1y_below",
    "anom5y_below",
    "uncert5y_below"
  )
)

## NOAA Global Monitoring Laboratory at Mauna Loa, Hawai'i ----
# https://gml.noaa.gov/ccgg/trends/data.html
# CO2 (CO₂) levels (ppm)

mlo_daily <- read_csv(
  "data-original/co2_daily_mlo.csv",
  col_names = c("year", "month", "day", "decimal", "ppm"),
  skip = 32
) |> 
  mutate(date = make_date(year, month, day), .after = day)

mlo_monthly <- read_csv("data-original/co2_mm_mlo.csv", skip = 40) |>
  rename(decimal = `decimal date`) |>
  janitor::clean_names() |>
  mutate(
    across(c(ndays, sdev, unc), 
    \(x) ifelse(x < 0, NA, x))
  ) |>
  mutate(date = make_date(year, month), .after = month)

mlo_weekly <- read_csv("data-original/co2_weekly_mlo.csv", skip = 35) |>
  janitor::clean_names() |>
  mutate(across(
    c(average, x1_year_ago, x10_years_ago, increase_since_1800),
    \(x) ifelse(x < 0, NA, x)
  )) |>
  mutate(date = make_date(year, month, day), .after = day)


## Our World In Data ----
# https://ourworldindata.org/grapher/co-emissions-per-capita

owid <- read_csv("data-original/co-emissions-per-capita.csv") |> 
  janitor::clean_names()


# Save all the data ----
write_csv(hadcrut, "data/hadcrut.csv")
write_csv(best, "data/berkeley_earth.csv")
write_csv(mlo_daily, "data/mlo_daily.csv")
write_csv(mlo_weekly, "data/mlo_weekly.csv")
write_csv(mlo_monthly, "data/mlo_monthly.csv")
write_csv(owid, "data/emissions_per_capita.csv")


# Build answer key so that the plots to recreate exist in images/ ----
quarto::quarto_render(
  "answers.qmd",
  output_format = c("html", "typst")
)
