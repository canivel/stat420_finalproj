# stat420_finalproj

Stat 420 - Summer 2019 - Final Proj

## requirements

    - install.packages(lubridate)
    - install.packages(ggplot2)
    - install.packages(cluster)
    - install.packages(tidyverse)
    - install.packages(caret)
    - install.packages(magrittr)
    - install.packages(Matrix)
    - install.packages(faraway)
    - install.packages(shiny)
    - install.packages(jsonlite)
    - install.packages(xgboost)

# Introduction

This study will be conducted by the following students of Stat420 Summer 2019:

- Danilo Canivel (canivel2)
- Joel Zou (joelzou2)
- Danny Breyfogle (dwb4)

## Let's call a Taxi... Maybe not.

## Dataset

For this project we will be predicting the fare amount (inclusive of tolls) for a taxi ride in New York City given the pickup and dropoff locations.

This dataset has 6 features:

- `pickup_datetime` (datetime)
- `pickup_longitude` (numeric)
- `pickup_latitude` (numeric)
- `dropoff_longitude` (numeric)
- `dropoff_latitude` (numeric)
- `passenger counts` (numeric)

We will be predicting the numeric response `fare_amount`, fitting on a training set, and predicting on a test set.

There are about 55 million observations in the training set. This is a very large dataset, so we may need to use a subset to meet computing requirements. In order to satisfy the project requirement of at least one categorical predictor, we can transform the `pickup_datetime` feature into categorical variables that would potentially be helpful in determining the fare amount, some examples would be day of the week, morning, afternoon, evening, etc.

We are going to set a preliminary objective of trying to reach a $RMSE < 2$ but a $RMSE < 2.88$ can be considered acceptable.

The dataset can be found at: [https://www.kaggle.com/c/new-york-city-taxi-fare-prediction/data]()

# Results

** The target RMSE of 2.8 was achieved, in fact, we lower it by the range of 1.56557 - 1.55991 dollars for 500k observations trained (the total data available is 55M)**

# Discussion

We found observations in the dataset that had non-positive fare_amount and passenger_count, these are likely due to errors in data entry and would not help generalize our model to predict on new data of interest, thus we remove these observations before further usage. The continuous variables fare_amount, pickup_longitude, pickup_latitude, dropoff_longitude, dropoff_latitude in the dataset can assume to be normally distributed. Since linear regression model coefficients are sensitive to outliers, we will use the boxplot rule to remove observations that has values greater than 1.5IQR away from the medium in each of these variables.

In order to make use of the pickup time information, we will create categorical dummy variables by converting the pickup_datetime column into a timestamp object. The variables we chose to create that could be helpful in predicting the fare_amount are the year, month, day of month, day of week and time of the day of each taxi ride pickup. The construction of the first four variables are trivial, for the time dummy variable, we divided the observations into 5 bins: Morning, Noon, Evening, Night and Overnight, this is based on the intuition that there is a general pattern in types of taxi rides people take depending on the time of day, for example people might be taking taxis to go to work in the morning, go to lunch at noon, back home in the evening and to entertainment venues at night.

We conducted ANOVA f-test for each of these dummy variable to get a feel on their effect on the response. The null hypothesis of each test would be that the mean of the response variable is the same for all levels of the dummy variable, by calculating the p-value and taking an $alpha=0.05$, we found that we could reject the null for the year, month, day, weekday and time dummy variables; There are statistically significance between the different levels of each of the dummy variable and the response, therefore we used these dummy variables as predictors in the linear regression model.

Linear Regression is a very good base line for this problem, but it's not the best one for solving it. Since the amount of data and coeffients are to sparse, a better optimization process like Gradient Descendent(SGD) or Information Gain would achieve better performance and results.

Looking on this directions, we added a different approach, xgboost.Rmd, using XGboost, that clear achieve much better results on unseeing data.

A web client can be found at the client/webapp.R, it runs local, predicting the value using the XGBoost model located in the same folder.
