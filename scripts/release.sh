#!/bin/bash

# Define the parent directory containing the folders
PARENT_DIR="./"

# ANSI color codes
GREEN='\033[0;32m'
# Additional ANSI color codes
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'

NC='\033[0m' # No color
if [[ -z "$1" ]]; then
    echo "Usage: $0 <SPRINT_NUMBER> [--dry-run] [--real-run]" 
    exit 1
fi

# Set the gh function based on the second argument
case "$2" in
    "--real-run")
        function gh() { command gh "$@"; }  # Replace with actual command execution
        ;;
    "-v"|"--verbose")
        DEBUG=true
        ;;
    *)
        function gh() { echo ">>> Mock >>> ${YELLOW}gh $@"${NC}; }
        ;;
esac

SPRINT=$1
major_version="v2.${SPRINT}"
tag_rc="${major_version}.0-rc"
release_branch="release-${major_version}"

echo "major_version: ${major_version}"
echo "tag_rc: ${tag_rc}"
echo "release_branch: ${release_branch}"

function debug() {
    if [ -z "$DEBUG" ]; then
        return
    fi
    echo "Information gathered:"
    echo "Latest commit: ${latest_commit}"
    echo "Latest tag: ${latest_tag}"
    echo "RC tag match: ${rc_tag_match}"
    echo "Production tag match: ${prod_tag_match}"
    echo "Latest commit in release branch: ${latest_commit_in_release_branch}"
    echo "Latest tag in release branch: ${tag_on_latest_commit_in_release_branch}"
    echo ""
}
# check release type, there are 3 types of release. 
# 0. No new Code
# 1. New RC release
# 2. New minor release
# 3. Production release
function check_type() {
    local folder=$1  # Accept folder as a parameter
    # if there is a rc tag match the SPRINT number, then it is a production release
    # if there is no rc tag match the SPRINT number, then it is a new RC release
    # if there is a new commit in the release branch, then it is a new minor release
    # if there is no new commit in the release branch, then there is no new code to release

    # Check if the latest commit has already been tagged
    latest_commit=$(git -C "$folder" rev-parse HEAD)
    latest_tag=$(git -C "$folder" describe --tags --exact-match "$latest_commit" 2>/dev/null)

    # Existing logic to determine release type
    rc_tag_match=$(git -C "$folder" tag | grep -E "v2\.${SPRINT}\.\d*-rc")
    prod_tag_match=$(echo ${latest_prod_version} | grep -E "v2\.${SPRINT}\.\d*$")

    ## Check if there is a new code to release to RC
    # Get the latest commit in the release branch
    latest_commit_in_release_branch=$(git -C "$folder" rev-parse --verify "${release_branch}" 2>/dev/null || echo "")

    # Check if the latest commit in the release branch is tagged
    tag_on_latest_commit_in_release_branch=$(git -C "$folder" describe --tags --exact-match "$latest_commit_in_release_branch" 2>/dev/null || echo "")
    
    debug

    if [ -n "$latest_commit_in_release_branch" ] && [ -z "$tag_on_latest_commit_in_release_branch" ]; then
        # New RC release
        echo "${latest_commit_in_release_branch} is not tagged"
        return 1  
    elif [ -n "$rc_tag_match" ] && [ -z "$prod_tag_match" ]; then
        # Production release
        return 3 
    elif [ -n "$latest_tag" ]; then
        # Indicate no new code
        return 0  
    else

        if [ -z "$latest_commit_in_release_branch" ]; then
            echo "No release branch, use the following commands to create a new release branch:"
            echo ${MAGENTA}"git -C \"$folder\" checkout -b \"${release_branch}\""${NC}
            echo ${MAGENTA}"git -C \"$folder\" push origin \"${release_branch}\""${NC}
            echo ""
        fi
        return 0  # Indicate no new code
    fi
}

function release_production() {
    local latest_rc_version=$(git -C "$folder" tag | grep -E "v2\.\d*\.\d*-rc" | sort -V | tail -n 1)
    echo "This is a ${MAGENTA}production${NC} release."
    echo "Creating production release ${new_version} from ${latest_rc_version}"
    cd $folder
    gh release create ${new_version} --target $(git rev-list -n 1 ${latest_rc_version})   -t "${new_version}" -d --latest --generate-notes
    cd ..
}

function release_rc() {
    # local tags_on_release_branch=$(git -C "$folder" tag | grep -E "v2\.${SPRINT}\.\d*")
    local latest_commit_in_release_branch=$(git -C "$folder" rev-parse --verify "${release_branch}" 2>/dev/null || echo "")
    local is_tagged_on_latest_commit=$(git -C "$folder" describe --tags --exact-match "$latest_commit" 2>/dev/null || echo "")

    
    if [ -n "$rc_tag_match" ] && [ -z "$tag_on_latest_commit_in_release_branch" ]; then
        echo "New ${MAGENTA}Minor Release${NC} detected"
        release_minor
        return 2  # Indicate minor release
    elif [ -z "$tags_on_release_branch" ]; then
        echo "This is a new ${MAGENTA}RC${NC} release."
        cd $folder
        gh release create ${tag_rc} --target ${release_branch} -t "${tag_rc}" -d -p --generate-notes
        cd ..
    fi

}

function release_minor() {
    IFS='.' read -r major minor patch <<< "${rc_tag_match#v}"  # Extract major, minor, and patch versions
    patch=${patch%%-*}  # Remove any suffix from minor version
    new_patch=$((patch + 1))  # Increment the minor version
    new_rc_version="${major}.${minor}.${new_patch}-rc"  # Construct the new RC version

    echo "Creating minor version release ${new_rc_version}"
    cd $folder
    gh release create ${new_rc_version} --target ${release_branch} -t "${new_rc_version}" -d -p --generate-notes
    cd ..
}


# Iterate through each folder in the parent directory
for folder in "${PARENT_DIR}"*; do
    if [ -d "$folder" ]; then  # Check if it's a directory
        if ! git -C "$folder" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            continue
        fi

        echo "---------------------------------------- ${GREEN}${folder}${NC} ----------------------------------------"
        # git -C "$folder" pull origin master 2>/dev/null || { echo "Error: Unable to pull latest changes in $dir"; }

        # Check if the latest commit has already been tagged
        latest_commit=$(git -C "$folder" rev-parse HEAD)
        latest_rc_version=$(git -C "$folder" tag | grep -E "v2\.\d*\.\d*-rc" | sort -V | tail -n 1)
        latest_prod_version=$(git -C "$folder" tag | grep -E "v2\.\d*\.\d*$" | sort -V | tail -n 1)
        new_version="${latest_rc_version%-rc}"  # Remove the '-rc' suffix
        echo "Latest RC Version: ${latest_rc_version}"  # Debugging line
        echo "Latest Prodution Version: ${latest_prod_version}"  # Debugging line
        echo ""


        check_type "$folder"
        type=$?
        if [[ $type == "3" ]]; then
            release_production
        elif [[ $type == "1" ]]; then
            release_rc
        else [[ $type == "0" ]];
            echo "No new code to release."
        fi
        continue

        echo ""
    fi
done
