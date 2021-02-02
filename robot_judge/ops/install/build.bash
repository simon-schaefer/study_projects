#!/bin/bash

# Install self-python-package.
echo $'\nInstalling package ...'
cd ${BRJ_PROJECT_PROJECT_HOME}
pip3 install --user -r ops/requirements.txt
pip3 install --user -e .
echo "Successfully built environment !"

# Build outs directory.
echo $'\nBuilding output, data and plots directory ...'
cd ${BRJ_PROJECT_HOME}
if [[ ! -d "data" ]]; then
    mkdir data
fi
if [[ ! -d "plots" ]]; then
    mkdir plots
fi
