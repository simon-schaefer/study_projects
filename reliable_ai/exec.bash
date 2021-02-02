#!/bin/bash
# Usage: bash exec.sh NET="mnist_relu_3_10" IMG="img1"

# Source solver preparation file. 
source setup_gurobi.sh

# Set default arguments. 
NET=mnist_relu_3_10
IMG=img0
EPS=0.0005

# Check input parameter (if any). 
for arg in "$@"; do
	key=$(echo $arg | cut -f1 -d=)
	value=$(echo $arg | cut -f2 -d=)
	
	case "$key" in 
		NET)	NET=${value};;
		IMG) 	IMG=${value};;
		EPS) 	EPS=${value};;
		*)	echo "Invalid argument"
	esac 
done

# Execute file. 
echo "--------------------------------------"
echo "Executing analyzer with input $NET, $IMG and $EPS"
python3 analyzer.py mnist_nets/$NET.txt mnist_images/$IMG.txt $EPS

rm dummy
rm gurobi.log
