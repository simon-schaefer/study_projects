# Check assumption that the trajectory length is largely independent on the timestamp and taxi ID, by computing trajectory length. 
rm(list=ls())

data.train <- read.csv("../data/train_data.csv")

library(lubridate)
times <- ymd_hms(data.train$TIMESTAMP)
data.train['WEEKDAY']   <- as.numeric(as.factor(weekdays(times)))
data.train['DAYTIME']   <- hour(times)
data.train$TIMESTAMP <- NULL

data.train$X_TRAJECTORY <- NULL
data.train$Y_TRAJECTORY <- NULL

names(data.train) <- c("ID", "TAXI_ID", "DUR", "X_ST", "Y_ST", 
                       "X_END", "Y_END", "TRAJ", "DAY", "HOUR")

library(corrplot)
M <- cor(data.train)
corrplot.mixed(M, tl.srt = 40, tl.cex = 0.7, bg = "black")

