#!/bin/bash
# Usage: bash comp_ground_truth.sh NET="4_1024"

# Preparation. 
source setup_gurobi.sh
TIMEFORMAT=%R

# Check input parameter (if any). 
for arg in "$@"; do
	key=$(echo $arg | cut -f1 -d=)
	value=$(echo $arg | cut -f2 -d=)
	
	case "$key" in 
		NET) 	NET=${value};;
		*)	echo "Invalid argument"
	esac 
done

# Check whether network has groundtruth and in case 
# catch according groundtruth file name. 
gt_file="none"
for filename in mnist_ground_truth/*.txt; do
    file=${filename#"mnist_ground_truth/precision_"}
    if [[ $file =~ .*"$NET".* ]]
    then
        gt_file=$file
    fi
done

# Check whether file was found. 
if [ "$gt_file" = "none" ]
then
    echo "Invalid net - No groundtruth available !"
    exit 1
fi

# Iterate through groundtruth file and compare to analysis output. 
NET="mnist_relu_$NET"
EPS=${gt_file##*_}
EPS=${EPS%".txt"}
echo "Testing groundtruth for net=$NET and eps=$EPS ..."
passed=$(expr 0)
failed=$(expr 0)
fal_pos=$(expr 0)
tru_neg=$(expr 0)
while read p; do
    IMG=$( cut -d " " -f2 <<< $p )
    flag=$( cut -d " " -f4 <<< $p )
    if [ "$flag" = "verified" ] || [ "$flag" = "failed" ]
    then
        time outs=$(python3 analyzer.py mnist_nets/$NET.txt mnist_images/img$IMG.txt $EPS)
        # Compare output and ground truth. 
        out="failed"
        if [[ $outs == *"verified"* ]]; then
            out="verified"
        fi
        if [ "$flag" = "$out" ]
        then
            passed=$((++passed))
            echo "IMG:$IMG ==> flag=$flag, out=$out"
        else
            failed=$((++failed))
            echo "IMG:$IMG ==> flag=$flag, out=$out ==>> FAILED"
        fi
        # Count analysis false positives and true negatives. 
        if [ "$out" = "verified" ] && [ "$flag" = "failed" ]; then
            tru_neg=$((++tru_neg))
        fi
        if [ "$out" = "failed" ] && [ "$flag" = "verified" ]; then
            fal_pos=$((++fal_pos))
        fi
        
    fi
done <mnist_ground_truth/precision_$gt_file

# Evaluation. 
echo "Passed tests: $passed, Failed tests: $failed"
echo "True negatives (out=v,flag=f): $tru_neg"
echo "False positives (out=f,flag=v): $fal_pos"

rm dummy
rm gurobi.log

