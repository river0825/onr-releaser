#!/bin/bash

# Initialize a variable to store directories with changes
changed_dirs=()

# Iterate over all subdirectories in the current directory
for dir in */; do
  # Check if the subdirectory is a Git repository
  if [ -d "$dir/.git" ]; then
    echo "Processing directory: $dir"
    cd "$dir" || { echo "Failed to enter directory $dir"; continue; }

    # Check out the master branch and pull the latest changes
    echo "Switching to master branch..."
    git checkout master 2>/dev/null || { echo "Error: Unable to checkout master branch in $dir"; cd ..; continue; }
    echo "Pulling latest changes from master..."
    git pull origin master || { echo "Error: Unable to pull latest changes in $dir"; }
    git fetch --all

    # Check for new code or changes
    echo "Checking for new code or changes..."
    if git status --porcelain | grep -q .; then
      echo "New or modified files found in $dir:"
      git status --porcelain
      # Add the directory to the list of changed directories
      changed_dirs+=("$dir")
    else
      echo "No new or modified files in $dir."
    fi

    # Return to the parent directory
    cd ..
  else
    echo "Skipping $dir (not a Git repository)"
  fi
done

# Print the summary of directories with changes
echo
echo "Summary of directories with changes:"
if [ ${#changed_dirs[@]} -eq 0 ]; then
  echo "No directories have new or modified files."
else
  for changed_dir in "${changed_dirs[@]}"; do
    echo "- $changed_dir"
  done
fi

echo "Done!"
