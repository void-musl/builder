#!/bin/bash
git init
git remote set-url origin https://github.com/accupara/los22 -b lineage-22.1 2>/dev/null || git remote add origin https://github.com/accupara/los22 -b lineage-22.1
