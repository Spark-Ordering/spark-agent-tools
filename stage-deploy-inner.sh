#!/bin/bash
# stage-deploy-inner.sh <zip> <bucket> <label> <env...> — the AWS half of stage-deploy.sh, run inside
# one aws-2fa.sh login. Uploads, creates the version, deploys every env, waits, verifies the label.
set -euo pipefail
zip="$1" bucket="$2" label="$3"
shift 3
envs=("$@")

app="$(aws elasticbeanstalk describe-environments --environment-names "${envs[0]}" \
  --query 'Environments[0].ApplicationName' --output text)"
key="$app/$label/Version.zip"
aws s3 cp --only-show-errors "$zip" "s3://$bucket/$key"
aws elasticbeanstalk create-application-version --application-name "$app" --version-label "$label" \
  --source-bundle "S3Bucket=$bucket,S3Key=$key" >/dev/null
for env in "${envs[@]}"; do
  aws elasticbeanstalk update-environment --environment-name "$env" --version-label "$label" >/dev/null
done
aws elasticbeanstalk wait environment-updated --environment-names "${envs[@]}"

rc=0
for env in "${envs[@]}"; do
  row="$(aws elasticbeanstalk describe-environments --environment-names "$env" \
    --query 'Environments[0].[VersionLabel,Status,Health]' --output text)"
  echo "$env $row"
  [ "${row%%[[:space:]]*}" = "$label" ] || { echo "$env is not on $label" >&2; rc=1; }
done
exit "$rc"
