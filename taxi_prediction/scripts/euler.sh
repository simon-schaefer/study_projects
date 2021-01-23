#!/bin/sh

# Path EULER (Target). 
readonly EULER=sischaef@euler.ethz.ch
readonly PROJECT=taxi_prediction

# Copy to euler. 
sh scripts/copy_euler.sh $EULER $PROJECT

# Building. 
sh scripts/build_euler.sh $EULER $PROJECT

# Run. 
ssh $EULER "cd $PROJECT/map_prediction/build; ./map_prediction"
