#!/bin/bash

# Define the parent directory containing the folders
PARENT_DIR="./"

# ANSI color codes
GREEN='\033[0;32m'
NC='\033[0m' # No color

# Iterate through each folder in the parent directory
for folder in "${PARENT_DIR}"*; do
    if [ -d "$folder" ]; then  # Check if it's a directory
        echo "------------------------------------------- ${GREEN}${folder}${NC} -------------------------------------------"
        git -C "$folder" checkout master 2>/dev/null || { echo "Error: Unable to pull latest changes in $dir"; }
        git -C "$folder" pull  2>/dev/null || { echo "Error: Unable to pull latest changes in $dir"; }
        git -C "$folder" fetch --all 2>/dev/null || { echo "Error: Unable to pull latest changes in $dir"; }

        # Execute the Git log command in the current folder
        git --no-pager -C "$folder" log --merges --oneline --graph -n10

        # Add a separator for clarity
        echo ""
    fi
done
