#!/bin/bash
# Idempotent: the Stage-agent EB env on SharedLB + its deploy-only IAM user; the old spark-backend-e2e env gone (ENG-2975).
# Runs under the phone-approved StageOps profile (aws-ops/stage-ops-policy.json), no YubiKey:
#   cd ~/Code/spark-agent-tools && bash aws-2fa.sh "ENG-2975 create Stage-agent, terminate spark-backend-e2e" -- bash aws-ops/stage-agent-env.sh
# --dry-run only reads and prints what a real run would do.
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-2
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

APP="Spark Ordering"
ENV_NAME=Stage-agent
OLD_ENV=spark-backend-e2e
HOST=stage-agent.us-east-2.elasticbeanstalk.com
DEPLOYER=stage-agent-deployer
OLD_DEPLOYER=spark-backend-e2e-deployer
POLICY="$(cd "$(dirname "$0")" && pwd)/stage-agent-deployer-policy.json"

env_field() {
  aws elasticbeanstalk describe-environments --application-name "$APP" --environment-names "$1" \
    --no-include-deleted --query "Environments[0].$2" --output text
}

# The CLI's EB waiters give up after ~7 min; creating an env takes longer. Terminated reads as None.
wait_status() {
  until [ "$(env_field "$1" Status)" = "$2" ]; do sleep 20; done
}

if [ "$DRY_RUN" = 1 ]; then
  if aws iam get-user --user-name "$OLD_DEPLOYER" > /dev/null 2>&1; then
    echo "[dry-run] IAM user $OLD_DEPLOYER exists: would rename to $DEPLOYER"
  fi
  echo "[dry-run] put-user-policy eb-e2e-deploy on $DEPLOYER from $POLICY"
  echo "[dry-run] $ENV_NAME status: $(env_field "$ENV_NAME" Status) (None = would be created from $OLD_ENV version $(env_field "$OLD_ENV" VersionLabel))"
  echo "[dry-run] $OLD_ENV status: $(env_field "$OLD_ENV" Status) (anything but None = would be terminated after $ENV_NAME is Ready)"
  exit 0
fi

# IAM first, so the deploy key can act on Stage-agent the moment it exists. A rename keeps the access key.
if aws iam get-user --user-name "$OLD_DEPLOYER" > /dev/null 2>&1; then
  aws iam update-user --user-name "$OLD_DEPLOYER" --new-user-name "$DEPLOYER"
  echo "[stage-agent] renamed IAM user $OLD_DEPLOYER -> $DEPLOYER"
fi
aws iam put-user-policy --user-name "$DEPLOYER" --policy-name eb-e2e-deploy --policy-document "file://$POLICY"
echo "[stage-agent] policy eb-e2e-deploy on $DEPLOYER scoped to $ENV_NAME"

if [ "$(env_field "$ENV_NAME" Status)" = None ]; then
  VERSION=$(env_field "$OLD_ENV" VersionLabel)
  # 443 rule mirrors spark-backend-e2e (priorities are relative per env on a shared ALB);
  # EB adds the port-80 rule itself, and the name "default" is reserved, so it is not set here.
  aws elasticbeanstalk create-environment --application-name "$APP" --environment-name "$ENV_NAME" \
    --cname-prefix stage-agent --template-name stage2-2-e2e --version-label "$VERSION" --option-settings \
    "Namespace=aws:elbv2:listener:443,OptionName=Rules,Value=stageagent" \
    "Namespace=aws:elbv2:listenerrule:stageagent,OptionName=HostHeaders,Value=$HOST" \
    "Namespace=aws:elbv2:listenerrule:stageagent,OptionName=PathPatterns,Value=/*" \
    "Namespace=aws:elbv2:listenerrule:stageagent,OptionName=Priority,Value=5" > /dev/null
  echo "[stage-agent] creating $ENV_NAME from version $VERSION"
fi
wait_status "$ENV_NAME" Ready
echo "[stage-agent] $ENV_NAME $(env_field "$ENV_NAME" Status) / $(env_field "$ENV_NAME" Health) at $(env_field "$ENV_NAME" CNAME)"

if [ "$(env_field "$OLD_ENV" Status)" != None ]; then
  aws elasticbeanstalk terminate-environment --environment-name "$OLD_ENV" > /dev/null
  wait_status "$OLD_ENV" None
  echo "[stage-agent] terminated $OLD_ENV"
fi
