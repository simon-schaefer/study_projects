#!/bin/bash

cd /cluster/work/lawecon/Work/sischaef/robot_judge
source commands/setup.bash --build
python3 scripts/extract.py

# bsub -W 20:00 -R "rusage[mem=4096]" < ops/jobs/extract.sh
