#!/bin/bash

# Login.
ssh sischaef@login.leonhard.ethz.ch

# Data and extraction scripts directory.
/cluster/work/lawecon/Work/dhivya/
/cluster/work/lawecon/Work/sischaef/

# Setup local server access.
sshfs sischaef@login.leonhard.ethz.ch:/cluster/work/lawecon/Work/ /Users/sele/Desktop/remote

# Copy files.
scp sischaef@login.leonhard.ethz.ch:/cluster/work/lawecon/Work/sischaef/plots/* ~/Desktop/.
