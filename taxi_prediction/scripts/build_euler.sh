#!/bin/sh

# Check input arguments. 
if [ -z "$1" ] && [ -z "$2" ]
then 
	echo "Please input target path !"
	exit 1
fi 

# Change to target directory and create build folder. 
ssh $1 "
if [ -d $2/map_prediction/build ]; 
then
   	rm -r $2/map_prediction/build
fi" 
ssh $1 "mkdir $2/map_prediction/build"; 

# Building project. 
ssh $1 "cd $2/map_prediction/build; ls; cmake ..; make; "
