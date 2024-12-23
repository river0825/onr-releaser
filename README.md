# GitHub Release Management Action

Automate your release process with this reusable GitHub Action. It handles Release Candidates (RC), Minor RCs, and Production releases based on your Git repository's state.

## Features

- **Automatic Release Type Detection**: Determines whether to create a new RC, Minor RC, or Production release based on git history and branch conditions.
- **Version Incrementing**: Automatically increments version numbers for RC releases.
- **GitHub Release Creation**: Utilizes GitHub CLI to create and publish releases.
- **Reusable Workflow**: Easily integrate into multiple repositories or workflows.

## Prerequisites

- **GitHub Repository**: Ensure you have a GitHub repository where you want to implement the release workflow.
- **GitHub Actions**: Familiarity with GitHub Actions workflows.
- **GitHub CLI (`gh`)**: Pre-installed on GitHub Actions runners.

## Installation

1. **Add the Action to Your Repository**

   Place the reusable action in your repository under `.github/actions/release/action.yml`.

2. **Create the Release Script**

   Add your `release.sh` script under `.github/actions/release/scripts/release.sh` with the necessary release logic.

3. **Setup Permissions**

   Ensure your workflow has the necessary permissions by configuring the `GITHUB_TOKEN` in your repository secrets.

## Usage

Integrate the Release Management Action into your GitHub Actions workflow.

```yaml
name: Release Workflow

on:
  workflow_dispatch:
    inputs:
      sprint_number:
        description: 'Sprint number for this release'
        required: true
      major:
        description: 'Major version number'
        required: false
        default: 'v2'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Release Action
        uses: ./.github/actions/release
        with:
          sprint_number: ${{ github.event.inputs.sprint_number }}
          major: ${{ github.event.inputs.major }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

## Example Workflow

```yaml
name: Trigger Release

on:
  push:
    branches:
      - main

jobs:
  trigger-release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Release Action
        uses: ./.github/actions/release
        with:
          sprint_number: '5'
          github_token: ${{ secrets.GITHUB_TOKEN }}
```
