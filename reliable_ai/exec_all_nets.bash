#!/bin/bash
# Usage: bash exec_all_nets.bash IMG="img1"

# Source solver preparation file. 
source setup_gurobi.sh

# Set default arguments. 
IMG=img0
EPS=0.0005

# Check input parameter (if any). 
for arg in "$@"; do
	key=$(echo $arg | cut -f1 -d=)
	value=$(echo $arg | cut -f2 -d=)
	
	case "$key" in 
		IMG) 	IMG=${value};;
		EPS) 	EPS=${value};;
		*)	echo "Invalid argument"
	esac 
done

# Iterate over all nets in mnist_nets directory. 
for filename in mnist_nets/*.txt; do
    net=${filename#"mnist_nets/"}
    net=${net%".txt"}
    bash exec.bash NET="$net" IMG="$IMG" EPS="$EPS" 
done
