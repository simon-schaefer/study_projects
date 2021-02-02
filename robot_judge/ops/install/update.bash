#!/bin/bash

# Update github repository.
echo $'\nUpdating GitHub repository ...'
cd $BRJ_PROJECT_PROJECT_HOME/
git stash -a
git fetch
git pull --rebase
git status
