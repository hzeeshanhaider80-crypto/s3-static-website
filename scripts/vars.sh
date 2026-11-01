#!/usr/bin/env bash
# Your project settings. Load them in every new Git Bash window with:
#   source scripts/vars.sh
# None of these values are secret, so this file can be committed to Git.

# Bucket names are GLOBAL across all AWS customers: make yours unique.
export BUCKET="zeeshan-portfolio-site-2026"

# Region for everything in this project.
export AWS_REGION="us-east-1"

# Your 12-digit AWS account ID, looked up automatically from the CLI login.
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

# Filled in after Step 3 (CloudFront). Leave it empty until then.
export DISTRIBUTION_ID="E1KYFOJUEI60IA"

# Filled in before Step 6 (GitHub Actions).
export GITHUB_USER="hzeeshanhaider80-crypto"
export REPO_NAME="s3-static-website"

# Print the settings so you can see they loawded.
echo "BUCKET=$BUCKET | REGION=$AWS_REGION | ACCOUNT=$ACCOUNT_ID | DIST=${DISTRIBUTION_ID:-<not set yet>}"
