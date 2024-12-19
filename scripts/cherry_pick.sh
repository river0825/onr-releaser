#!/usr/bin/env bash
set -e

RELEASE_BRANCH=$1
FIX_REF=$2

if [ -z "$RELEASE_BRANCH" ] || [ -z "$FIX_REF" ]; then
  echo "Usage: $0 <release_branch> <fix_commit_ref>"
  exit 1
fi

git checkout $RELEASE_BRANCH
git cherry-pick $FIX_REF || {
  echo "Conflict encountered during cherry-pick of $FIX_REF."
  echo "Please resolve conflicts manually."
  exit 1
}

echo "Cherry-pick of $FIX_REF into $RELEASE_BRANCH completed successfully."
