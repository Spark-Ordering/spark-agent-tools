#!/bin/bash
# aws-ops/setup.sh — one-time (idempotent) setup for aws-2fa.sh (ENG-2927).
# Creates/updates the Identity Center permission set StageOps with stage-ops-policy.json,
# assigns it to Identity Center user `carlos` on account 716429146716, provisions it, and
# writes the local `sparkpos-ops` profile. Needs sso-admin rights, so Carlos runs it once:
#   cd ~/Code/spark-agent-tools && ~/Code/awui/mfa-aws.sh bash aws-ops/setup.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ACCOUNT=716429146716
REGION=us-east-2
SET_NAME=StageOps
USER_NAME=carlos
PROFILE=sparkpos-ops
POLICY="$HERE/stage-ops-policy.json"

SSO_REGION="${SSO_REGION:-us-east-2}" # the Identity Center home region (the sso-session's sso_region)

jq -e . "$POLICY" >/dev/null
read -r instance_arn store_id < <(aws sso-admin list-instances --region "$SSO_REGION" \
  --query 'Instances[0].[InstanceArn,IdentityStoreId]' --output text)
case "$instance_arn" in
  arn:aws:sso:::instance/*) echo "instance: $instance_arn" ;;
  *) echo "no Identity Center instance in $SSO_REGION; rerun with SSO_REGION=<sso_region of sso-session sparkpos>" >&2; exit 1 ;;
esac

set_arn=""
for arn in $(aws sso-admin list-permission-sets --region "$SSO_REGION" --instance-arn "$instance_arn" \
  --query 'PermissionSets[]' --output text); do
  name="$(aws sso-admin describe-permission-set --region "$SSO_REGION" --instance-arn "$instance_arn" \
    --permission-set-arn "$arn" --query 'PermissionSet.Name' --output text)"
  [ "$name" = "$SET_NAME" ] && set_arn="$arn" && break
done
if [ -z "$set_arn" ]; then
  set_arn="$(aws sso-admin create-permission-set --region "$SSO_REGION" --instance-arn "$instance_arn" \
    --name "$SET_NAME" --session-duration PT1H \
    --description "Stage-only Elastic Beanstalk ops for aws-2fa.sh (ENG-2927)" \
    --query 'PermissionSet.PermissionSetArn' --output text)"
  echo "created permission set $set_arn"
fi
aws sso-admin put-inline-policy-to-permission-set --region "$SSO_REGION" --instance-arn "$instance_arn" \
  --permission-set-arn "$set_arn" --inline-policy "file://$POLICY"
echo "inline policy set"

user_id="$(aws identitystore list-users --region "$SSO_REGION" --identity-store-id "$store_id" \
  --filters "AttributePath=UserName,AttributeValue=$USER_NAME" --query 'Users[0].UserId' --output text)"
assigned="$(aws sso-admin list-account-assignments --region "$SSO_REGION" --instance-arn "$instance_arn" \
  --account-id "$ACCOUNT" --permission-set-arn "$set_arn" \
  --query "AccountAssignments[?PrincipalId=='$user_id'] | length(@)" --output text)"
if [ "$assigned" = "0" ]; then
  aws sso-admin create-account-assignment --region "$SSO_REGION" --instance-arn "$instance_arn" \
    --target-id "$ACCOUNT" --target-type AWS_ACCOUNT --permission-set-arn "$set_arn" \
    --principal-type USER --principal-id "$user_id" >/dev/null
  echo "assigned $SET_NAME to $USER_NAME"
fi
aws sso-admin provision-permission-set --region "$SSO_REGION" --instance-arn "$instance_arn" \
  --permission-set-arn "$set_arn" --target-type ALL_PROVISIONED_ACCOUNTS >/dev/null
echo "provisioning started (takes a few seconds)"

aws configure set sso_session sparkpos --profile "$PROFILE"
aws configure set sso_account_id "$ACCOUNT" --profile "$PROFILE"
aws configure set sso_role_name "$SET_NAME" --profile "$PROFILE"
aws configure set region "$REGION" --profile "$PROFILE"
echo "profile $PROFILE written (sso_session sparkpos, role $SET_NAME)"
echo "DONE. Test: aws-2fa.sh \"setup check\" -- aws elasticbeanstalk describe-environments --query 'Environments[].EnvironmentName'"
