#!/bin/bash
rm -rf .git
git init

if git remote get-url origin > /dev/null 2>&1; then
  git remote set-url origin https://github.com/accupara/los22 # Unnes code
  git remote set-branches origin lineage-22.1 # Same
  # Remove it
else
  git remote add -t lineage-22.1 origin https://github.com/accupara/los22
