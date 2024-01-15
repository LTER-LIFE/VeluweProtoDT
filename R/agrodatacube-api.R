# Get NDVI data
# Author: Stefan Vriend
# Created: 2024/01/15
# Last updated: 2024/01/15

library(httr)
library(terra)

bbox <- tibble::tribble(~x, ~y,
                        5.824436777442551, 52.032393019069225,
                        5.824436777442551, 52.046647934312794,
                        5.870356194968013, 52.046647934312794,
                        5.870356194968013, 52.032393019069225,
                        5.824436777442551, 52.032393019069225)

bbox_rd <- tibble::tribble(~x, ~y,
                           185000, 449500,
                           185000, 451000,
                           188000, 451000,
                           188000, 449500,
                           185000, 449500)

test <- httr::GET(url = paste0("https://agrodatacube.wur.nl/api/v2/rest/ndvi_image?",
                               "date=20191119",
                               "&geometry=POLYGON((",
                               paste(paste(bbox_rd$x, bbox_rd$y, sep = "%20"), collapse = ","),
                               "))",
                               "&epsg=28992",
                               "&output_epsg=4326"),
                  httr::add_headers(token = keyring::key_get(service = "RStudio Keyring Secrets",
                                                             username = "AgroDataCube V2 API key")))


bin_raster <- readBin(test$content, what = "raw", n=length(test$content))
writeBin(bin_raster, con = "raster.tif")
r <- raster::raster("raster.tif")

## CHECK THIS
# https://community.rstudio.com/t/convert-a-binary-post-request-to-a-local-raster/158656/4
###

test$content |>
  tiff::readTIFF() |>
  terra::rast()

httr::content(test, as = "text")

terra_test <- terra::rast(file.choose())

#
# headers = c(
#   'Accept' = 'application/json',
#   'Authorization' = keyring::key_get(service = "RStudio Keyring Secrets",
#                              username = "AgroDataCube V2 API key")
# )
#
# res <- httr::VERB("GET", url = paste0("https://agrodatacube.wur.nl/api/v2/rest/ndvi_image?date=20191110&geometry=POINT((",
#                                       paste(bbox_rd[1, 1], bbox_rd[1, 2], sep = ' '), "))",
#                                       "&epsg=28992&output_epsg=4326"), httr::add_headers(headers))
#
# httr::content(res)
#
#
# library(httr)
#
# res <- httr::VERB("GET", url = "https://agrodatacube.wur.nl/api/v2/rest/ndvi_image?date=20191119&geometry=POLYGON((185000%20449500,185000%20451000,188000%20451000,188000%20449500,185000%20449500))&epsg=28992&output_epsg=4326", httr::add_headers(headers))
#
# cat(content(res, 'text'))
