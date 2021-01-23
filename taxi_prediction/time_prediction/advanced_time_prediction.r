# PACKAGES --------------------------------------------------------------------

library(dplyr)  #for easy data manipulation 
library(data.table)  #for loading large csv files
library(Hmisc)
library(PerformanceAnalytics)
library(randomForest)
library(rpart)
library(rpart.plot)
library(corrplot)
library(ggplot2)
library(caret)
require(forcats)
library(gbm, quietly = TRUE) #Boosting
library(Metrics)
library(MLmetrics)
library(e1071)
library(xgboost)
library(plotly)
library(fitdistrplus)




# IMPORT FILE --------------------------------------------------------------------
base_directory = "/Users/gfred/Desktop/comp st4240" 
filename_train = paste(base_directory,"/train_data.csv", sep = "")
data_train = fread(filename_train)


# CLEANING AWAY OFF VALUES THAT WON'T HELP PREDICTING DURATION --------------------------------------------------------------------

FindSlowArea <- function(vector){
  temp_vector <- cbind(vector,rep(0,(length(vector)/2)))
  tracker = 1
  while (tracker < (length(vector)/2)){
    i = 1
    while(vector[tracker,1]==vector[tracker+i,1]&&vector[tracker,2]==vector[tracker+i,2]&&(tracker+i)<(1+length(vector)/2)){
      i = i+1 
    }
    temp_vector[tracker,3] = i-1
    tracker = tracker+i
  }
  if (any(temp_vector[,3]>0)){
    FindSlowArea = temp_vector[temp_vector[,3]>0]}
  else{FindSlowArea=0}
}

k=1 
temp_stack <- matrix(0,nrow(data_train)*3,4)
for (i in 1:nrow(data_train)){
  temp_line <- cbind(gsub(" ","",strsplit(data_train$X_TRAJECTORY[i],",")[[1]]),gsub(" ","",strsplit(data_train$Y_TRAJECTORY[i],",")[[1]]))
  temp_mat <- FindSlowArea(rbind(temp_line,c("0","0")))
  if(temp_mat!=0){
    temp_stack[k:(k-1+length(temp_mat)/3),] <- cbind(matrix(temp_mat,ncol=3),rep(i,nrow(temp_mat),1))
    k=k+1}
}

temp_stack <- temp_stack[!temp_stack[,3]=="0",] #Cleaning list
points_to_remove<-temp_stack[as.numeric(temp_stack[,3])>7,4] 
# Points where we singular times need to wait more than 6*7 SECONDS are assumed to be disturbing more than we gain from them
data_train <- data_train[-as.numeric(points_to_remove),]


# FEATURE ENGINEERING TIMESTAMP --------------------------------------------------------------------

# SETTING WEEKDAY
data_train <- data_train %>% mutate(DAY_OF_WEEK = wday(as.Date(data_train$TIMESTAMP, format = "%d/%m/%Y")))

# SETTING TIME OF DAY
temp_list <- rep(0,length(data_train$ID))
for (i in 1:length(data_train$ID)){
  temp_list[i] <- strsplit(data_train$TIMESTAMP[i]," ")[[1]][2]
  temp_list[i] <- as.numeric(strsplit(temp_list[i],":")[[1]][1])
}
data_train <- data_train %>% mutate(TIME_OF_DAY = sapply(temp_list,as.numeric))

# SETTING DATE
for (i in 1:length(data_train$ID)){
  temp_list[i] <- strsplit(data_train$TIMESTAMP[i]," ")[[1]][1]
}
data_train <- data_train %>% mutate(DATE = temp_list)

# SETTING MONTH
temp_list <- rep(0,nrow(data_train))
temp_list2 <- c("01","02","03","04","05","06","07","08","09","10","11","12")
for (i in 1:12){
  temp_list[grepl(paste("/",temp_list2[i],"/",sep=""),data_train$DATE)] <- i
}
data_train <- data_train %>% mutate(MONTH = temp_list)



# TRANSFORMATION OF DATASET --------------------------------------------------------------------

# Visualising distribution, conclusion: looks skewed.
# hist(data_train$TRAJ_LENGTH,breaks=100)
# hist(data_train$DURATION,breaks=100)

# Getting lambda = 0 => log transformation.
# Check all LAMBDAS
# matris <- matrix(0,800,7)
# for (i in 1:800){
#   for(j in 1:7){
#     bc <- boxcox(TRAJ_LENGTH~DURATION,data=data_train[data_train$DAY_OF_WEEK==j&data_train$TAXI_ID==i,])
#     matris[i,j] <- bc$x[which.max(bc$y)]
#   }
# }

data_train <- data_train %>% mutate(LOG_TRAJ_LENGTH = log(TRAJ_LENGTH))
data_train <- data_train %>% mutate(LOG_DURATION = log(DURATION))

# For later comparisions:
data_train <- data_train %>% mutate(LOG_AVG_SPEED = LOG_TRAJ_LENGTH/LOG_DURATION)

# Historgram over different weekdays 
# plot_ly(alpha = 0.8) %>%
#   add_histogram(x = ~data_train$LOG_AVG_SPEED[data_train$DAY_OF_WEEK==1],) %>%
#   add_histogram(x = ~data_train$LOG_AVG_SPEED[data_train$DAY_OF_WEEK==2]) %>%
#   add_histogram(x = ~data_train$LOG_AVG_SPEED[data_train$DAY_OF_WEEK==3]) %>%
#   add_histogram(x = ~data_train$LOG_AVG_SPEED[data_train$DAY_OF_WEEK==4]) %>%
#   add_histogram(x = ~data_train$LOG_AVG_SPEED[data_train$DAY_OF_WEEK==5]) %>%
#   add_histogram(x = ~data_train$LOG_AVG_SPEED[data_train$DAY_OF_WEEK==6]) %>%
#   add_histogram(x = ~data_train$LOG_AVG_SPEED[data_train$DAY_OF_WEEK==7]) %>%
#   layout(barmode = "overlay")


# FEATURE ENGINEERING TAXI_ID --------------------------------------------------------------------
# A visualisation how average speed varies dependening on taxi ID
boxplot(LOG_AVG_SPEED~TAXI_ID,data=data_train[data_train$TAXI_ID<50,])
# Obviously we need to make some sort of binning of the different taxis

box_plot <- boxplot(LOG_AVG_SPEED~TAXI_ID,data=data_train)

# How much taxis vary
hist(box_plot$stats[5,]-box_plot$stats[1,],breaks = 800) 
# Obviously they are not very consistent in their speed, not very unexpected considering the variance in start and end points

# New feature SPEED_CAT using the ACTUAL_SPEED, to differentiate fast vs slow taxis, but still keeping the avg_speed
taxi_compare <- cbind(box_plot$stats[3,],sort(unique(data_train$TAXI_ID)))
sorted_taxi_compare <- taxi_compare[order(taxi_compare[,1])]
index_to_reorder <- taxi_compare[order(taxi_compare[,1]),2]
normalized_data <- sorted_taxi_compare/mean(sorted_taxi_compare)

for_each_id <- rep(0,length(unique(data_train$TAXI_ID)))
span <- max(normalized_data)-min(normalized_data)
divide_in <- 20
MIN <- min(normalized_data)
span_divider <- span/divide_in+0.00000000000001
for (percentile in 0:divide_in){
  string <- percentile+5
  normalized_data <- replace(normalized_data,normalized_data < (as.numeric(MIN)+span_divider*percentile),string)
}
for_each_id[index_to_reorder] <- normalized_data

data_train <- data_train %>% mutate(SPEED_CAT = sapply(TAXI_ID,function(x){for_each_id[x]}))
data_train <- data_train %>% mutate(ACTUAL_TAXI_SPEED = sapply(TAXI_ID,function(x){taxi_compare[taxi_compare[,2]==x][1]}))
#Essentially 20 integer categories where lower means slower and higher means quicker. It's normalized. 

# Visualisation:
# hist(data_train$SPEED_CAT)
# hist(data_train$ACTUAL_TAXI_SPEED,breaks=40)


# FEATURE ENGINEERING ~TIMESTAMP --------------------------------------------------------------------
bplot <- boxplot(LOG_AVG_SPEED~DAY_OF_WEEK,data=data_train)
# This is decent when running it for the training set, but we can't use it in a logic sense for the test set:
# We need to take care of good and bad monday tuesdays etc.
# Three categories: S M F to benchmarking for that day
# temp_list_dates <- rep(0,nrow(data_train))
# for (i in 1:nrow(data_train)){
#   x <- as.numeric(data_train$DAY_OF_WEEK[i])
#   y <- data_train$LOG_AVG_SPEED[i]
#   if(y<bplot$stats[2,x]){temp_list_dates[i]=1}else if (y<bplot$stats[4,x]) {temp_list_dates[i]=2} else {temp_list_dates[i]=3}
# }
# 
# data_train <- data_train %>% mutate(DAY_SPEED_BENCHMARK = temp_list_dates)

# Mean AVG_SPEED aggregated over different days, "which dates are quicker?"
aggr_speed_data <- aggregate(data_train$LOG_AVG_SPEED, list(data_train$DATE), FUN=mean)

# Visualize date
# aggr_speed_data <- aggr_speed_data[order(as.Date(aggr_speed_data$Group.1, format="%d/%m/%Y")),]
# plot_ly(aggr_speed_data, y=~x,x=~Group.1,type="scatter",mode="markers")

temp_list <- rep(0,nrow(data_train))
for (i in 1:nrow(data_train)){
  temp_list[i] <- aggr_speed_data$x[aggr_speed_data$Group.1==data_train$DATE[i]]
}
data_train <- data_train %>% mutate(DATE_SPEED = temp_list)


# FEATURE ENGINEERING TRAJECTORY --------------------------------------------------------------------
# Goal is to find which areas are more and less slow
# This section is commented away because it takes very long time to run. 

# This sections if for turns, calculates angle between points in trajectory
# Have not implemented it yet. Have an idea of some type of density function, but dunno yet.
#
# findTurns <- function(vector){
#   temp_vector = rep(0,(length(vector)/2-2))
#   for(i in 1:(length(vector)/2-2)){
#     a = as.numeric(vector[i+1,])-as.numeric(vector[i,])
#     b = as.numeric(vector[i+2,])-as.numeric(vector[i+1,])
#     angle <- (acos( sum(a%*%b) / ( sqrt(sum(a%*%a)) * sqrt(sum(b%*%b))) ))
#     temp_vector[i] <- angle
#   }
#   findTurns = cbind(vector,c(0,temp_vector,0))
# }
# 
# temp_stack_turns <- matrix(0,600000,3)
# k=1
# for (i in 1:40000){
#   temp_line <- cbind(gsub(" ","",strsplit(data_train$X_TRAJECTORY[i],",")[[1]]),gsub(" ","",strsplit(data_train$Y_TRAJECTORY[i],",")[[1]]))
#   radian_turns<-findTurns(temp_line)
#   if(length(radian_turns)>1){
#     radian_turns[radian_turns=="NaN"] <- 0
#     big_turns <- radian_turns[as.numeric(as.character(radian_turns[,3]))>(pi/2),]
#     if (length(big_turns)>2){
#       temp_stack_turns[k:(k-1+length(big_turns)/3),] <- matrix(big_turns,ncol=3)
#       k = (k+length(big_turns)/3)}
#   }
# }
# temp_stack_turns <- temp_stack_turns[!temp_stack_turns[,3]=="0",] #Cleaning list
# 
# plot(temp_stack_turns[,1],temp_stack_turns[,2],cex=0.05)
# 
# df_turns <- data.frame(temp_stack_turns)
# df_turns <- df_turns %>% mutate(X1 = sapply(sapply(X1,as.character),as.numeric))
# df_turns <- df_turns %>% mutate(X2 = sapply(sapply(X2,as.character),as.numeric))
# df_turns <- df_turns %>% mutate(X3 = sapply(sapply(X3,as.character),as.numeric))
# names(df_turns) <- c("X","Y","ANGLE")
# temp_stack_turns_2 <- matrix(0,100000,3)
# k=1
# tracker = 1
# while (tracker<(length(temp_stack_turns)/3)){
#   point_x <- df_turns$X[1]
#   point_y <- df_turns$Y[1]
#   finite_rows <- (df_turns$X %in% (point_x-3):(point_x+3))&(df_turns$Y %in% (point_y-3):(point_y+3))
#   q<-df_turns[finite_rows,]
#   df_turns <- df_turns[!finite_rows,]
#   temp_stack_turns_2[k,1] <- mean(q$X)
#   temp_stack_turns_2[k,2] <- mean(q$Y)
#   temp_stack_turns_2[k,3] <- length(q$X)
#   tracker <- tracker+temp_stack_turns_2[k,3]
#   k=k+1
# }
# 
# temp_stack_turns_2 <- temp_stack_turns_2[!temp_stack_turns_2[,3]=="0",] #Cleaning list
# plot(temp_stack_turns_2[,1],temp_stack_turns_2[,2],cex=0.1)

# Uses function from beginning of code
# k=1 
# temp_stack <- matrix(0,nrow(data_train),3)
# for (i in 1:nrow(data_train)){
#   temp_line <- cbind(gsub(" ","",strsplit(data_train$X_TRAJECTORY[i],",")[[1]]),gsub(" ","",strsplit(data_train$Y_TRAJECTORY[i],",")[[1]]))
#   temp_mat <- FindSlowArea(rbind(temp_line,c("0","0")))
#   if(temp_mat!=0){
#     temp_stack[k:(k-1+length(temp_mat)/3),] <- matrix(temp_mat,ncol=3)
#     k=k+1}
# }
# 
# temp_stack <- temp_stack[!temp_stack[,3]=="0",] #Cleaning list
# 
# df <- data.frame(temp_stack)
# df <- df %>% mutate(X1 = sapply(sapply(X1,as.character),as.numeric))
# df <- df %>% mutate(X2 = sapply(sapply(X2,as.character),as.numeric))
# df <- df %>% mutate(X3 = sapply(sapply(X3,as.character),as.numeric))
# df <- df %>% mutate(X4 = paste(X1,X2))
# names(df) <- c("X","Y","TIMES","AGGR")
# 
# aggr_intersects <- aggregate(df$TIMES, list(df$X,df$Y), mean)
# names(aggr_intersects) <- c("X","Y","TIMES")
# # plot_ly(data=aggr_intersects[aggr_intersects$TIMES>3,],z = ~TIMES, x=~X,y=~Y, type = "heatmap",colorscale = "Greys")
# plot(aggr_intersects[aggr_intersects$TIMES<10,]) #indicates 60+ secs, just wont happen
# 
# speed_data_for_points <- rep(0,length(aggr_intersects))
# for(i in 1:nrow(aggr_intersects)){
#   x_value <- aggr_intersects[i,1]
#   y_value <- aggr_intersects[i,2]
#   x_range <- (x_value-5):(x_value+5)
#   y_range <- (y_value-5):(y_value+5)
#   aggr_speed_loop <- 0
#   for (each in x_range){
#     for (each in y_range){
#       aggr_speed_loop <- aggr_speed_loop + aggr_intersects[i,3]}
#   }
#   speed_data_for_points[i] <- aggr_speed_loop/121
# }
# 
# 
# combined_speed_and_point <- cbind(aggr_intersects,speed_data_for_points)
# plot_ly(data=combined_speed_and_point,x=~X,y=~Y,z)
# 
# min_x <- min(data_train$X_END,data_train$X_START)
# max_x <- max(data_train$X_END,data_train$X_START)
# min_y <- min(data_train$Y_END,data_train$Y_START)
# max_y <- max(data_train$Y_END,data_train$Y_START)
# M <- matrix(0,max_y-min_y,max_x-min_x)
# for (i in 1:nrow(M)){
#   for (j in 1:ncol(M)){
#     closest <- RANN::nn2(data = aggr_intersects[,1:2], query = matrix(c(j-432,i-420),nrow=1), k = 10)
#     M[i,j] <- mean(speed_data_for_points[closest$nn.idx[closest$nn.dists!=0]]/closest$nn.dists[closest$nn.dists!=0])
#   }
# }
# It all boils down to a big matrix that covers every possible start point. 
# Can re-run it with every point in Traj if it turns out fruitful

M_File <- paste("/Users/gfred/mymatrix.csv", sep = "")
M = fread(M_File)
M <- as.matrix(M)

temp_row_x <- data_train$X_START
temp_row_y <- data_train$Y_START
temp_row_z <- rep(0,length(temp_row_y))
for (i in 1:length(temp_row_x)){
  temp_row_z[i] <- M[temp_row_x[i]+432,temp_row_y[i]+420] # Transformation because negative values in X_START Y_START
}
data_train <- data_train %>% mutate(MEAN_START_AREA_SPEED = temp_row_z)
plot_ly(z=as.matrix(M), type = "heatmap")


# THIS SECTION IF WE WANT TO MAKE K FOLD AND TRAINING ON DATA_TRAIN SET --------------------------------------------------------------------

# For select to work with dplyr again
detach("package:plotly", unload=TRUE)
detach("package:fitdistrplus", unload=TRUE)
detach("package:MASS", unload=TRUE)

data_train_N <- data_train
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "ID")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "DATE")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "X_START")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "Y_START")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "X_END")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "Y_END")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "LOG_AVG_SPEED")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "DAY_SPEED_BENCHMARK")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "DURATION")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "X_TRAJECTORY")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "Y_TRAJECTORY")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "TIMESTAMP")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "TAXI_ID")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "TIMESTAMP")]

data_train_N <- data_train_N %>% mutate(TIME_OF_DAY = sapply(TIME_OF_DAY,as.factor))
data_train_N <- data_train_N %>% mutate(DAY_OF_WEEK = sapply(DAY_OF_WEEK,as.factor))
data_train_N <- data_train_N %>% mutate(SPEED_CAT = sapply(SPEED_CAT,as.factor))
data_train_N <- data_train_N %>% mutate(MONTH = sapply(MONTH,as.factor))

flds <- createFolds(data_train$LOG_DURATION, k = 10, list = TRUE, returnTrain = FALSE)

i = 4 # Doesn't matter

train_x <- data_train_N[-flds[[i]],] %>% select(-one_of("LOG_DURATION"))
train_y <- data_train_N[-flds[[i]],] %>% select(one_of("LOG_DURATION"))
test_x <- data_train_N[flds[[i]],] %>% select(-one_of("LOG_DURATION"))
test_y <- data_train_N[flds[[i]],] %>% select(one_of("LOG_DURATION"))

train_x <- as.matrix(sapply(train_x,as.numeric))
train_y <- as.matrix(sapply(train_y,as.numeric))
test_x <- as.matrix(sapply(test_x,as.numeric))
test_y <- as.matrix(sapply(test_y,as.numeric))

dtrain = xgb.DMatrix(train_x, label = train_y)
dtest = xgb.DMatrix(test_x, label = test_y)
watchlist = list(train=dtrain, test=dtest)

quickfit_GBM = xgb.train(data = dtrain,
                         max.depth = 60,
                         eta = 0.1,
                         nthread = 2,
                         nround = 500,
                         watchlist = watchlist,
                         objective = "reg:linear",
                         early_stopping_rounds = 50,
                         print_every_n = 10)

randomf_predict <- randomForest(LOG_DURATION~.,data=data_train_N,ntree=3)

prediction_quickfit_GBM <- predict(quickfit_GBM, dtest)

MAPE(exp(test_y),exp(prediction_quickfit_GBM))

RMSPE(exp(test_y),exp(prediction_quickfit_GBM))

these_values <- (sqrt((exp(prediction_quickfit_GBM)-exp(test_y))^2)/exp(test_y))>0.2
data_with_high_error <- data_train[these_values,]

describe(data_with_high_error)

# THIS SECTION IF WE WANT TO RUN A KAGGLE SUBMISSION --------------------------------------------------------------------
base_directory = "/Users/gfred/Desktop/comp st4240" 
filename_test = paste(base_directory,"/testSH.csv", sep = "")
data_test = fread(filename_test)
data_test <- data.frame(data_test)

data_test <- data_test %>% mutate(LOG_TRAJ_LENGTH=log(data_test$TRAJ_LENGTH))

# SETTING WEEKDAY
data_test <- data_test %>% mutate(DAY_OF_WEEK = wday(as.Date(as.character(data_test$TIMESTAMP))))

# SETTING TIME OF DAY
temp_list <- rep(0,length(data_test$ID))
for (i in 1:length(data_test$ID)){
  asd <- substr(data_test$TIMESTAMP[i],start=1,stop=10)
  temp_list[i] <- strsplit(data_test$TIMESTAMP[i],asd)[[1]][2]
  temp_list[i] <- as.numeric(strsplit(temp_list[i],":")[[1]][1])
}
data_test <- data_test %>% mutate(TIME_OF_DAY = sapply(temp_list,as.numeric))

# SETTING DATE
for (i in 1:length(data_test$ID)){
  temp_list[i] <- strftime(strsplit(data_test$TIMESTAMP[i]," ")[[1]][1],"%d/%m/%Y")
}
data_test <- data_test %>% mutate(DATE = temp_list)

# SETTING MONTH
temp_list <- rep(0,nrow(data_test))
temp_list2 <- c("01","02","03","04","05","06","07","08","09","10","11","12")
for (i in 1:12){
  temp_list[grepl(paste("/",temp_list2[i],"/",sep=""),data_test$DATE)] <- i
}
data_test <- data_test %>% mutate(MONTH = temp_list)


want_to_use_4_file <- cbind(taxi_compare[,2],taxi_compare[,1],matrix(for_each_id))
temp_list <- rep(0,nrow(data_test))
for (i in 1:nrow(data_test)){
  temp_list[i] <- want_to_use_4_file[data_test$TAXI_ID[i]==want_to_use_4_file[,1],2]
}
data_test <- data_test %>% mutate(ACTUAL_TAXI_SPEED = temp_list)

for (i in 1:nrow(data_test)){
  temp_list[i] <- want_to_use_4_file[data_test$TAXI_ID[i]==want_to_use_4_file[,1],3]
}
data_test <- data_test %>% mutate(SPEED_CAT = temp_list)


want_to_use_4_file_2 <- unique(cbind(data_train$DATE,data_train$DATE_SPEED))
temp_list <- rep(0,nrow(data_test))
for (i in 1:nrow(data_test)){
  temp_list[i] <- as.numeric(want_to_use_4_file_2[which(want_to_use_4_file_2[,1]==data_test$DATE[i]),2])
}
data_test <- data_test %>% mutate(DATE_SPEED = temp_list)

temp_row_x <- data_test$X_START
temp_row_y <- data_test$Y_START
temp_row_z <- rep(0,length(temp_row_y))
for (i in 1:length(temp_row_x)){
  temp_row_z[i] <- M[temp_row_x[i]+432,temp_row_y[i]+420]
}
data_test <- data_test %>% mutate(MEAN_START_AREA_SPEED = temp_row_z)

detach("package:plotly", unload=TRUE)
detach("package:fitdistrplus", unload=TRUE)
detach("package:MASS", unload=TRUE)

data_test_N <- data_test
data_train_N <- data_train

data_test_id <- data_test[ ,(names(data_test) %in% "ID")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "ID")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "DATE")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "X_START")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "Y_START")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "X_END")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "Y_END")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "LOG_AVG_SPEED")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "DAY_SPEED_BENCHMARK")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "DURATION")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "X_TRAJECTORY")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "Y_TRAJECTORY")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "TIMESTAMP")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "TAXI_ID")]
data_train_N <- data_train_N[ , !(names(data_train_N) %in% "TIMESTAMP")]
data_test_N <- data_test_N %>% select(one_of(names(data_train_N)))

data_test_N <- data_test_N %>% mutate(TIME_OF_DAY = sapply(TIME_OF_DAY,as.factor))
data_test_N <- data_test_N %>% mutate(DAY_OF_WEEK = sapply(DAY_OF_WEEK,as.factor))
data_test_N <- data_test_N %>% mutate(SPEED_CAT = sapply(SPEED_CAT,as.factor))
data_test_N <- data_test_N %>% mutate(MONTH = sapply(MONTH,as.factor))

data_train_N <- data_train_N %>% mutate(TIME_OF_DAY = sapply(TIME_OF_DAY,as.factor))
data_train_N <- data_train_N %>% mutate(DAY_OF_WEEK = sapply(DAY_OF_WEEK,as.factor))
data_train_N <- data_train_N %>% mutate(SPEED_CAT = sapply(SPEED_CAT,as.factor))
data_train_N <- data_train_N %>% mutate(MONTH = sapply(MONTH,as.factor))

train_x <- data_train_N %>% select(-one_of("LOG_DURATION"))
train_y <- data_train_N %>% select(one_of("LOG_DURATION"))
test_x <- data_test_N 

train_x <- as.matrix(sapply(train_x,as.numeric))
train_y <- as.matrix(sapply(train_y,as.numeric))
test_x <- as.matrix(sapply(test_x,as.numeric))


dtrain = xgb.DMatrix(train_x, label = train_y)
dtest = xgb.DMatrix(test_x)

watchlist = list(train=dtrain)#, test=dtest)

quickfit_GBM = xgb.train(data = dtrain, 
                         max.depth = 60, 
                         eta = 0.01, 
                         nthread = 2, 
                         nround = 500, 
                         watchlist = watchlist, 
                         objective = "reg:linear", 
                         early_stopping_rounds = 50,
                         print_every_n = 10)

prediction_quickfit_GBM <- predict(quickfit_GBM, dtest)


resulting_guess <- exp(prediction_quickfit_GBM)+exp(data_test$LOG_TRAJ_LENGTH)

#CREATE A SUBMISSION FILE
submission = data.frame(ID = data_test$ID,PRICE = resulting_guess)

filename = paste(base_directory,"guessuno.csv", sep = "") 
write.csv(x=submission, filename, row.names = FALSE)

