#!/usr/bin/env bash
# Fill your real values into the policy templates.
# Output goes to build/ (ignored by Git), ready for the AWS CLI.
set -euo pipefail

# Run from the project root and load your settings.
cd "$(dirname "$0")/.."
source scripts/vars.sh > /dev/null

# Stop with a clear message if CloudFront hasn't been created yet.
[ -n "$DISTRIBUTION_ID" ] || { echo "ERROR: set DISTRIBUTION_ID in scripts/vars.sh first (Step 3)"; exit 1; }

# Folder for the generated files.
mkdir -p build

# Loop over every template; replace each placeholder with its real value.
for file in bucket-policy github-trust-policy github-deploy-policy; do
  sed -e "s/BUCKET_NAME/$BUCKET/g" \
      -e "s/ACCOUNT_ID/$ACCOUNT_ID/g" \
      -e "s/DISTRIBUTION_ID/$DISTRIBUTION_ID/g" \
      -e "s/GITHUB_USER/$GITHUB_USER/g" \
      -e "s/REPO_NAME/$REPO_NAME/g" \
      "aws/$file.json" > "build/$file.json"
  echo "Created build/$file.json"
done
