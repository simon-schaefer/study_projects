#!/bin/sh
# Execution Path: ..
# Input arguments: Target path. 

# Check input arguments. 
if [ -z "$1" ] && [ -z "$2" ]
then 
	echo "Please input server and project name !"
	exit 1
fi 

# Copy Program code. 
ssh $1 "mkdir $2/map_prediction/"
scp -r map_prediction/CMakeLists.txt $1:$2/map_prediction
scp -r map_prediction/main.cpp       $1:$2/map_prediction

ssh $1 "mkdir $2/map_prediction/src"
for f in map_prediction/src/*
do
	scp -r $f    	     			 $1:$2/map_prediction/src
done

ssh $1 "mkdir $2/map_prediction/include"
for f in map_prediction/include/*
do
	scp -r $f 						 $1:$2/map_prediction/include
done 

#ssh $1 "mkdir $2/map_prediction/tests"
#for f in map_prediction/tests/*
#do
#	scp -r $f 						 $1:$2/map_prediction/tests
#done

# Create predictions output folder. 
#ssh $1 "mkdir $2/predictions"

# Copy ressources.
#ssh $1 "mkdir $2/data"
#scp -r data/short.csv 		$1:$2/data
#scp -r data/test.csv  		$1:$2/data
#scp -r data/train_data.csv	$1:$2/data