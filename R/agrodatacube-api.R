# Get NDVI data from AgroDataCube
# Author: Stefan Vriend
# Created: 2024/01/15
# Last updated: 2024/01/16

library(httr)
library(terra)
library(here)
library(keyring)
library(lubridate)
library(tibble)

# Function to retrieve NDVI data from AgroDataCube ------------------------

# Arguments
# - bbox: tibble or data frame specifying the x and y coordinates of bounding box for which to retrieve data. The data frame should have 5 x and y coordinates, specifying the corners of the bounding box (where the starting corner is listed twice to ensure that the polygon is closed). CRS should be Amersfoort / RD New (EPSG:28992).
# - date: date specifying the date for which to retrieve data.
# - key: character specifying a AgroDataCube V2 API key.

retrieve_adc_data <- function(bbox,
                              date,
                              key = keyring::key_get(service = "RStudio Keyring Secrets",
                                                     username = "AgroDataCube V2 API key")) {

  # Check that the bounding box has correct dimensions
  if(any(dim(bbox) != c(5, 2))) {

    stop("The bounding box does not have the correct dimensions.")

  }

  # Change date to expected format (yyyymmdd)
  formatted_date <- paste0(lubridate::year(date),
                           stringr::str_pad(lubridate::month(date), width = 2,
                                            side = "left",
                                            pad = "0"),
                           stringr::str_pad(lubridate::day(date), width = 2,
                                            side = "left",
                                            pad = "0"))

  # Call API
  adc <- httr::GET(url = paste0("https://agrodatacube.wur.nl/api/v2/rest/ndvi_image?",
                                "date=", formatted_date,
                                "&geometry=POLYGON((",
                                paste(paste(bbox$x, bbox$y, sep = "%20"), collapse = ","),
                                "))",
                                "&epsg=28992",
                                "&output_epsg=4326"),
                   httr::add_headers(token = key))

  # Error message
  if("status" %in% httr::content(adc)) {

    stop("AgroDataCube V2.0 API failed to fulfill request for the following reason:\n")
    httr::content(adc)$status

  }

  # Write raw content to temporary .tif
  writeBin(adc$content, con = here::here("data", paste0(formatted_date, ".tif")))
  on.exit(unlink(here::here("data", paste0(formatted_date, ".tif"))), add = TRUE)

  r <- terra::rast(here::here("data", paste0(formatted_date, ".tif")))

  output <- terra::as.data.frame(r, xy = TRUE) |>
    dplyr::rename("value" = rlang::sym(formatted_date)) |>
    dplyr::mutate("date" = date)

  return(output)

}

# Set bounding box using Amersfoort / RD New (EPSG:28992)
bbox_ <- tibble::tribble(~x, ~y,
                         185000, 449500,
                         185000, 451000,
                         188000, 451000,
                         188000, 449500,
                         185000, 449500)

#retrieve_adc_data(bbox = bbox, date = lubridate::make_date(2019, 11, 19))

# Set dates (from https://www.groenmonitor.nl/groenindex)
adc_dates <- c(lubridate::make_date(2017, 5, 26),
               lubridate::make_date(2018, 6, 30),
               lubridate::make_date(2019, 6, 27),
               lubridate::make_date(2020, 6, 26),
               lubridate::make_date(2021, 6, 1),
               lubridate::make_date(2022, 6, 16),
               lubridate::make_date(2023, 6, 24))

ndvi <- purrr::map(.x = adc_dates,
                   .f = ~{

                     retrieve_adc_data(bbox = bbox, date = .x)

                   }) |>
  dplyr::bind_rows()
