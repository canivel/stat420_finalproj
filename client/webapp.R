library(shiny)
library(jsonlite)
library(xgboost)
library(lubridate)
# Define UI for dataset viewer app ----
ui = fluidPage(
  #key,pickup_datetime,pickup_longitude,pickup_latitude,
  #dropoff_longitude,dropoff_latitude,passenger_count
  
  # App title ----
  titlePanel("Taxi Price Prediction Test"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      textInput("pickup_datetime", "Pickup Datetime:", value = "2019-01-01 00:00:00 UTC" ),
      textInput("pickup_address", "Pickup Address:", value = "10025"),
      textInput("dropoff_address", "Dropoff Address:", value = "Central Park New York"),
      
      numericInput(inputId = "passenger_count",
                   label = "Number of passengers:",
                   value = 1),
      
      actionButton("do", "Predict")
      
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      # Output: Formatted text for caption ----
      h3(textOutput("pickup_datetime", container = span)),
      h3(textOutput("passenger_count", container = span)),
      
      h3(textOutput("Pickup Address Lat and Long")),
      h5(textOutput("f_pickup_address", container = span)),
      h5(textOutput("f_pickup_address_lng", container = span)),
      h5(textOutput("f_pickup_address_lat", container = span)),
      
      h3(textOutput("Dropoff Address Lat and Long")),
      h5(textOutput("f_dropoff_address", container = span)),
      h5(textOutput("f_dropoff_address_lng", container = span)),
      h5(textOutput("f_dropoff_address_lat", container = span)),
      
      h1(textOutput("predict_price", container = span))
    )
  )
)

# Define server logic to summarize and view selected dataset ----

earth_radius = 6371 #in kms

sphere_dist = function(pickup_lat, pickup_lon, dropoff_lat, dropoff_lon)
{
  #Compute distances along lat, lon dimensions
  dlat = dropoff_lat - pickup_lat
  dlon = dropoff_lon - pickup_lon
  
  #Compute  distance
  a = sin(dlat/2.0)**2 + cos(pickup_lat) * cos(dropoff_lat) * sin(dlon/2.0)**2
  
  return (2 * earth_radius * asin(sqrt(a)))
  
} 

features_eng = function(data, istrain=TRUE){
  
  if(istrain == TRUE){
    data = data[complete.cases(data),]
    # Remove Negative Fare and No Passenger and some places that does not exist
    data = data[(data$fare_amount > 0 & data$fare_amount <= 500),]
    data = data[(data$pickup_longitude > -80 && data$pickup_longitude < -70),]
    data = data[(data$pickup_latitude > 35 && data$pickup_latitude < 45),]
    data = data[(data$dropoff_longitude > -80 && data$dropoff_longitude < -70),]
    data = data[(data$dropoff_latitude > 35 && data$dropoff_latitude < 45),]
    #only if passengers are between 1 and 9
    data = data[(data$passenger_count > 0 && data$passenger_count < 10),]
  }
  
  # Convert to datetime obj
  data$pickup_datetime = as_datetime(data$pickup_datetime, tz="UTC")
  
  # factorization
  data$year = as.factor(year(data$pickup_datetime))
  data$month = as.factor(month(data$pickup_datetime))
  data$day = as.factor(day(data$pickup_datetime))
  data$weekday = as.factor(weekdays(data$pickup_datetime))
  
  #factor time of the day
  hour = hour(data$pickup_datetime)
  data$time = as.factor(ifelse(hour < 7, "Overnight", 
                               ifelse(hour < 11, "Morning", 
                                      ifelse(hour < 16, "Noon",
                                             ifelse(hour < 20, "Evening",
                                                    ifelse(hour < 23, "night", "overnight")
                                             )))))
  # convert to radius position
  data$pickup_latitude = (data$pickup_latitude * pi)/180
  data$dropoff_latitude = (data$dropoff_latitude * pi)/180
  data$dropoff_longitude = (data$dropoff_longitude * pi)/180
  data$pickup_longitude = (data$pickup_longitude * pi)/180 
  data$dropoff_longitude = ifelse(is.na(data$dropoff_longitude) == TRUE, 0,data$dropoff_longitude)
  data$pickup_longitude = ifelse(is.na(data$pickup_longitude) == TRUE, 0,data$pickup_longitude)
  data$pickup_latitude = ifelse(is.na(data$pickup_latitude) == TRUE, 0,data$pickup_latitude)
  data$dropoff_latitude = ifelse(is.na(data$dropoff_latitude) == TRUE, 0,data$dropoff_latitude)
  
  # compare locations
  data$dlat = data$dropoff_latitude - data$pickup_latitude
  data$dlon = data$dropoff_longitude - data$pickup_longitude 
  
  #Compute haversine distance
  
  data$hav = sin(data$dlat/2.0)**2 + cos(data$pickup_latitude) * cos(data$dropoff_latitude) * sin(data$dlon/2.0)**2
  data$haversine = round(x = 2 * earth_radius * asin(sqrt(data$hav)), digits = 4)
  print(dim(data))
  
  #Compute Bearing distance
  data$dlon = data$pickup_longitude - data$dropoff_longitude
  data$bearing = atan2(sin(data$dlon * cos(data$dropoff_latitude)), cos(data$pickup_latitude) * sin(data$dropoff_latitude) - sin(data$pickup_latitude) * cos(data$dropoff_latitude) * cos(data$dlon))
  
  #Some point of interest where people most use taxis in NYC
  jfk_coord_lat = (40.639722 * pi)/180
  jfk_coord_long = (-73.778889 * pi)/180
  ewr_coord_lat = (40.6925 * pi)/180
  ewr_coord_long = (-74.168611 * pi)/180
  lga_coord_lat = (40.77725 * pi)/180
  lga_coord_long = (-73.872611 * pi)/180
  liberty_statue_lat = (40.6892 * pi)/180
  liberty_statue_long = (-74.0445 * pi)/180
  nyc_lat = (40.7141667 * pi)/180
  nyc_long = (-74.0063889 * pi)/180
  
  #calculate distances radius for the POI
  data$JFK_dist = sphere_dist(data$pickup_latitude, data$pickup_longitude, jfk_coord_lat, jfk_coord_long) + sphere_dist(jfk_coord_lat, jfk_coord_long, data$dropoff_latitude, data$dropoff_longitude)
  data$EWR_dist = sphere_dist(data$pickup_latitude, data$pickup_longitude, ewr_coord_lat, ewr_coord_long) +  sphere_dist(ewr_coord_lat, ewr_coord_long, data$dropoff_latitude, data$dropoff_longitude)
  data$lga_dist = sphere_dist(data$pickup_latitude, data$pickup_longitude, lga_coord_lat, lga_coord_long) + sphere_dist(lga_coord_lat, lga_coord_long, data$dropoff_latitude, data$dropoff_longitude) 
  data$sol_dist = sphere_dist(data$pickup_latitude, data$pickup_longitude, liberty_statue_lat, liberty_statue_long) + sphere_dist(liberty_statue_lat, liberty_statue_long, data$dropoff_latitude, data$dropoff_longitude)
  data$nyc_dist = sphere_dist(data$pickup_latitude, data$pickup_longitude, nyc_lat, nyc_long) + sphere_dist(nyc_lat, nyc_long, data$dropoff_latitude, data$dropoff_longitude)
  
  #remove some columns
  #drops <- c("pickup_datetime")
  #data = data[, !(names(data) %in% drops)]
  #print(dim(data))
  return (data)
  
}

server = function(input, output) {
  
  m_xgb = xgb.load("m_xgb_2.model")
  
  observeEvent(input$do, {
    
    if(is.null(input$dropoff_address)){
      return ("Dropoff Address is empty")
    }else if(is.null(input$pickup_address)){
      return ("Pickup Address is empty")
    }else if(is.null(input$pickup_datetime)){
      return ("Pickup Datetime is empty")
    } else if(is.null(input$passenger_count)){
      return ("Passenger Count is empty")
    }else{
    
      pa = gsub(" ", "+", input$pickup_address)
      gkey = "AIzaSyCdUgYHnqrxRM3BBjWJ6VUZbaIlkemU85E"
      url_pa = URLencode(sprintf("https://maps.googleapis.com/maps/api/geocode/json?address=%s&key=%s", pa, gkey))
      pa_res = fromJSON(url_pa)
      f_pickup_address = pa_res$results$formatted_address[1]
      f_pickup_address_lng = pa_res$results$geometry$location$lng[1]
      f_pickup_address_lat = pa_res$results$geometry$location$lat[1]
      
      da = gsub(" ", "+", input$dropoff_address)
      url_da = URLencode(sprintf("https://maps.googleapis.com/maps/api/geocode/json?address=%s&key=%s", da, gkey))
      da_res = fromJSON(url_da)
      f_dropoff_address = da_res$results$formatted_address[1]
      f_dropoff_address_lng = da_res$results$geometry$location$lng[1]
      f_dropoff_address_lat = da_res$results$geometry$location$lat[1]
      
      test_data = data.frame(pickup_datetime = input$pickup_datetime,
                        pickup_longitude = f_pickup_address_lng,
                        pickup_latitude = f_pickup_address_lat,
                        dropoff_longitude = f_dropoff_address_lng,
                        dropoff_latitude = f_dropoff_address_lat,
                        passenger_count = input$passenger_count)
  
      output$f_pickup_address = renderText({
        f_pickup_address
      })
      
      output$f_pickup_address_lng = renderText({
        f_pickup_address_lng
      })
      
      output$f_pickup_address_lat = renderText({
        f_pickup_address_lat
      })
      
      output$f_dropoff_address = renderText({
        f_dropoff_address
      })
      
      output$f_dropoff_address_lng = renderText({
        f_dropoff_address_lng
      })
      
      output$f_dropoff_address_lat = renderText({
        f_dropoff_address_lat
      })
      
      output$pickup_datetime = renderText({
        input$pickup_datetime
      }) 
      
      output$passenger_count = renderText({
        input$passenger_count
      }) 
      
      output$predict_price = renderText({
        X_test = features_eng(test_data, FALSE)
        yhat = predict(m_xgb, data.matrix(X_test))
        print(yhat)
        yhat
      }) 
    }
  })
  
}

# Create Shiny app ----
shinyApp(ui, server)