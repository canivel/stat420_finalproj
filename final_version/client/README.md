# stat420_finalproj

Client for the project built with Shiny

## requirements

    - install.packages(lubridate)
    - install.packages(shiny)
    - install.packages(jsonlite)
    - install.packages(xgboost)

## requirements API

    - Create a Google API KEY for Geocode and add the key to the file webapp.R at gkey = "XXXXXXXXXXXX"

## usage
    - you can use any address, zip code or name of the place in New York to the pickup and dropoff, the script will look at the latitudes and longitudes and perform the inference
