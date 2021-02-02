#!/bin/bash
export BRJ_PROJECT_NAME="robot_judge"

# Parsing input arguments.
usage()
{
    echo "usage: source setup.bash [[[-b]] | [-h]]"
}
SHOULD_BUILD=false; SHOULD_UPDATE=false; SHOULD_CHECK=false;
while [[ "$1" != "" ]]; do
    case $1 in
        -b | --build )          SHOULD_BUILD=true
                                shift;;
        -h | --help )           usage;;
        * )                     usage
    esac
    shift
done

# Set environment variables.
export BRJ_PROJECT_HOME="/cluster/work/lawecon/Work/sischaef"
export BRJ_PROJECT_PROJECT_HOME="${BRJ_PROJECT_HOME}/${BRJ_PROJECT_NAME}"
source "${BRJ_PROJECT_PROJECT_HOME}/ops/install/set_variables.bash"

# Source environment (create env. variables).
source "${BRJ_PROJECT_OPS_PATH}/install/header.bash"
module load python_cpu/3.6.4

# Update github repository (stashing !)
bash ${BRJ_PROJECT_OPS_PATH}/install/update.bash

# Build files (install requirements).
if [[ "$SHOULD_BUILD" = true ]] ; then
    bash ${BRJ_PROJECT_OPS_PATH}/install/build.bash
fi

cd ${BRJ_PROJECT_PROJECT_HOME}
echo $'\nSuccessfully set up project !'
