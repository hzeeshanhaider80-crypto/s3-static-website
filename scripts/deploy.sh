#!/usr/bin/env bash
# Upload the website to S3 and clear the CloudFront cache.
# Local use:  source scripts/vars.sh && bash scripts/deploy.sh
# In CI, BUCKET and DISTRIBUTION_ID come from GitHub Variables.
set -euo pipefail

# ---- Settings (from environment variables) ----
# ':?' stops the script with this message if BUCKET is not set.
BUCKET="${BUCKET:?BUCKET is not set. Run: source scripts/vars.sh}"
# Optional: if empty, the cache-clearing step is skipped.
DISTRIBUTION_ID="${DISTRIBUTION_ID:-}"
# Folder that holds the website.
SITE_DIR="${SITE_DIR:-site}"

# Helper that puts a timestamp in front of every message.
log() { echo "[$(date '+%T')] $*"; }

# Run from the project root, no matter where the script was started.
cd "$(dirname "$0")/.."

# Safety check: the important files must exist before uploading anything.
[ -f "$SITE_DIR/index.html" ] || { echo "ERROR: $SITE_DIR/index.html not found"; exit 1; }
[ -f "$SITE_DIR/404.html" ]   || { echo "ERROR: $SITE_DIR/404.html not found"; exit 1; }

log "1/4 Uploading CSS, JS and images (cached for 1 day)"
# 'aws s3 sync' uploads only new or changed files (fast).
# --exclude "*.html" skips HTML here; it gets a different cache rule below.
# --cache-control: how long browsers/CloudFront may keep a copy (86400 s = 1 day).
aws s3 sync "$SITE_DIR" "s3://$BUCKET" \
  --exclude "*.html" \
  --cache-control "public, max-age=86400"

log "2/4 Uploading HTML pages (always re-checked, so changes show quickly)"
# --exclude "*" then --include "*.html" = upload ONLY .html files.
# max-age=0 + must-revalidate = browsers ask for a newer version every time.
aws s3 sync "$SITE_DIR" "s3://$BUCKET" \
  --exclude "*" --include "*.html" \
  --cache-control "public, max-age=0, must-revalidate"

log "3/4 Removing files from S3 that you deleted locally"
# --delete removes bucket files that no longer exist in site/.
# (Still recoverable for 30 days thanks to versioning.)
aws s3 sync "$SITE_DIR" "s3://$BUCKET" --delete

log "4/4 Clearing CloudFront cache"
if [ -n "$DISTRIBUTION_ID" ]; then
  # "/*" = all files. CloudFront fetches fresh copies from S3 on the next visit.
  # --query/--output print only the ID instead of a big block of JSON.
  INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' --output text)
  log "    Invalidation started: $INVALIDATION_ID (takes ~1 minute)"
else
  log "    Skipped (DISTRIBUTION_ID not set yet)"
fi

log "✅ Deploy complete"
