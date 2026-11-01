#!/usr/bin/env bash
# Create CloudFront (with OAC) for the S3 website, save the ID, and apply the bucket policy.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/vars.sh > /dev/null

log() { echo "[$(date '+%T')] $*"; }

ORIGIN_DOMAIN="$BUCKET.s3.$AWS_REGION.amazonaws.com"

log "1/5 Creating Origin Access Control (OAC)"
OAC_ID=$(aws cloudfront create-origin-access-control \
  --origin-access-control-config "Name=$BUCKET-oac,Description=OAC for $BUCKET,SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3" \
  --query 'OriginAccessControl.Id' --output text)
log "    OAC ID: $OAC_ID"

log "2/5 Writing distribution config"
mkdir -p build
cat > build/distribution-config.json <<JSON
{
  "CallerReference": "$BUCKET-$(date +%s)",
  "Comment": "Portfolio site for $BUCKET",
  "Enabled": true,
  "DefaultRootObject": "index.html",
  "PriceClass": "PriceClass_100",
  "HttpVersion": "http2",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "s3-$BUCKET",
        "DomainName": "$ORIGIN_DOMAIN",
        "OriginAccessControlId": "$OAC_ID",
        "S3OriginConfig": { "OriginAccessIdentity": "" }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "s3-$BUCKET",
    "ViewerProtocolPolicy": "redirect-to-https",
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    "Compress": true,
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": { "Quantity": 2, "Items": ["GET", "HEAD"] }
    }
  },
  "CustomErrorResponses": {
    "Quantity": 2,
    "Items": [
      { "ErrorCode": 403, "ResponsePagePath": "/404.html", "ResponseCode": "404", "ErrorCachingMinTTL": 10 },
      { "ErrorCode": 404, "ResponsePagePath": "/404.html", "ResponseCode": "404", "ErrorCachingMinTTL": 10 }
    ]
  }
}
JSON

log "3/5 Creating CloudFront distribution (this call returns quickly; deploying takes 5-10 min)"
read -r DIST_ID DIST_DOMAIN < <(aws cloudfront create-distribution \
  --distribution-config file://build/distribution-config.json \
  --query '[Distribution.Id, Distribution.DomainName]' --output text)
log "    Distribution ID: $DIST_ID"
log "    Website address: https://$DIST_DOMAIN"

log "4/5 Saving the Distribution ID into scripts/vars.sh"
sed -i "s/^export DISTRIBUTION_ID=.*/export DISTRIBUTION_ID=\"$DIST_ID\"/" scripts/vars.sh

log "5/5 Building and applying the bucket policy"
bash scripts/render-policies.sh
aws s3api put-bucket-policy --bucket "$BUCKET" --policy file://build/bucket-policy.json

log "✅ Done! Wait 5-10 minutes, then open: https://$DIST_DOMAIN"
