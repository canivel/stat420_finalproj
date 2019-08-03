library(shiny)
library(jsonlite)
library(xgboost)
# Define UI for dataset viewer app ----
ui = fluidPage(
  #key,pickup_datetime,pickup_longitude,pickup_latitude,
  #dropoff_longitude,dropoff_latitude,passenger_count
  
  # App title ----
  titlePanel("Taxi Price Prediction vs Uber Estimate"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      textInput("pickup_datetime", "Pickup Datetime:", value = "2019-01-01 00:00:00" ),
      textInput("pickup_address", "Pickup Address:"),
      textInput("dropoff_address", "Dropoff Address:"),
      
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
server = function(input, output) {
  
  m_xgb = xgb.load("m_xgb.model")
  
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
      gkey = "XXXXXXXX"
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
  
      print(test_data)
      
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
        predict(m_xgb, data.matrix(test_data))
      }) 
    }
  })
  
}

# Create Shiny app ----
shinyApp(ui, server)