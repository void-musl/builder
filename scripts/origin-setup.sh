#!/bin/env bash

sudo git config --global --add safe.directory /crave-devspaces/actions-runner/_work/builder/builder/work_dir
sudo rm -rf .git
sudo git init
sudo git remote add -t lineage-22.1 origin https://github.com/accupara/los22
