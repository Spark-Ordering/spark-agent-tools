#!/bin/bash
# Deploy a spark_backend git ref to the spark-backend-e2e EB env (ENG-2914), no YubiKey.
# Usage: deploy-spark-backend-e2e.sh [--ref <git-ref>] [--dry-run]   (default ref: HEAD)
# Uses the deployer key from Infisical via creds.sh; never prints it.
set -euo pipefail

REGION=us-east-2
APP="Spark Ordering"
ENV_NAME=spark-backend-e2e
BUCKET=elasticbeanstalk-us-east-2-716429146716
SPB_DIR="${SPB_DIR:-$HOME/Code/spark_backend}"
CREDS="$HOME/Code/SparkPos/scripts/creds.sh"
KEEP=20

REF=HEAD
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --ref) REF="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

SHA=$(git -C "$SPB_DIR" rev-parse --short=10 "$REF")
LABEL="e2e-${SHA}-$(date +%Y%m%d%H%M%S)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "[e2e-deploy] ref=$REF sha=$SHA label=$LABEL env=$ENV_NAME"

# Clean checkout of the ref, so untracked local files never ship.
git -C "$SPB_DIR" archive "$REF" | tar -x -C "$WORK"
mkdir -p "$WORK/builds" "$WORK/tmp/pids"
(cd "$WORK" && bash build.sh > /dev/null)
ZIP="$WORK/builds/Version.zip"
echo "[e2e-deploy] built $(du -h "$ZIP" | cut -f1)"

if [ "$DRY_RUN" = 1 ]; then
  echo "[e2e-deploy] dry-run: would upload s3://$BUCKET/$APP/$LABEL/Version.zip, create version $LABEL, update $ENV_NAME"
  exit 0
fi

export REGION APP ENV_NAME BUCKET LABEL ZIP KEEP
bash "$CREDS" run -- bash -c '
  set -euo pipefail
  export AWS_ACCESS_KEY_ID="$AWS_EB_E2E_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$AWS_EB_E2E_SECRET_ACCESS_KEY"
  KEY="$APP/$LABEL/Version.zip"
  aws s3 cp "$ZIP" "s3://$BUCKET/$KEY" --region "$REGION" --only-show-errors
  aws elasticbeanstalk create-application-version --region "$REGION" --application-name "$APP" \
    --version-label "$LABEL" --source-bundle "S3Bucket=$BUCKET,S3Key=$KEY" > /dev/null
  aws elasticbeanstalk update-environment --region "$REGION" --application-name "$APP" \
    --environment-name "$ENV_NAME" --version-label "$LABEL" > /dev/null
  echo "[e2e-deploy] update started: $ENV_NAME -> $LABEL"

  # Keep the newest $KEEP e2e-* versions; Version2.* release history is never touched.
  OLD=$(aws elasticbeanstalk describe-application-versions --region "$REGION" --application-name "$APP" \
    --query "reverse(sort_by(ApplicationVersions[?starts_with(VersionLabel, \`e2e-\`)], &DateCreated))[$KEEP:].VersionLabel" \
    --output text)
  for V in $OLD; do
    aws elasticbeanstalk delete-application-version --region "$REGION" --application-name "$APP" --version-label "$V"
    echo "[e2e-deploy] pruned $V"
  done
'
