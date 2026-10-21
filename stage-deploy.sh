#!/bin/bash
# stage-deploy.sh <branch|PR#> [Stage1|Stage2] — build a spark_backend branch and deploy it to a Stage
# web + worker EB env pair with ONE phone-approved aws-2fa.sh login (ENG-2929). No awui, no YubiKey.
# Builds from a throwaway worktree of origin/<branch>, never from the ~/Code/spark_backend checkout.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPB_DIR="${SPB_DIR:-$HOME/Code/spark_backend}"
AWS_2FA="${AWS_2FA:-$SCRIPT_DIR/aws-2fa.sh}"
BUCKET=elasticbeanstalk-us-east-2-716429146716
GH_REPO=Spark-Ordering/spark_backend

ref="${1:-}"
stage="${2:-Stage1}"
[ -n "$ref" ] || { echo "usage: stage-deploy.sh <branch|PR#> [Stage1|Stage2]" >&2; exit 2; }
case "$stage" in
  Stage1 | Stage2) ;;
  *) echo "stage must be Stage1 or Stage2, got: $stage" >&2; exit 2 ;;
esac

branch="$ref"
if [[ "$ref" =~ ^[0-9]+$ ]]; then
  branch="$(gh pr view "$ref" --repo "$GH_REPO" --json headRefName --jq .headRefName)"
fi

remote="$(git -C "$SPB_DIR" remote -v | grep -m1 'Spark-Ordering/spark_backend' | cut -f1)"
git -C "$SPB_DIR" fetch -q "$remote" "$branch"
sha="$(git -C "$SPB_DIR" rev-parse FETCH_HEAD)"

build_dir="$(mktemp -d)/spark_backend"
cleanup() { git -C "$SPB_DIR" worktree remove --force "$build_dir" >/dev/null 2>&1 || true; }
trap cleanup EXIT
git -C "$SPB_DIR" worktree add -q --detach "$build_dir" "$sha"
# config/secrets.yml is gitignored but the app needs it; every awui build shipped it from the checkout.
cp "$SPB_DIR/config/secrets.yml" "$build_dir/config/secrets.yml"
(cd "$build_dir" && mkdir -p builds && sh build.sh >/dev/null)

tail="${branch##*/}"
label="${tail:0:80}-${sha:0:8}"
echo "Built $branch @ ${sha:0:8} -> label $label; deploying to $stage-2 + $stage-Worker2" >&2

AWS_REGION=us-east-2 "$AWS_2FA" "deploy spark_backend $branch @ ${sha:0:8} to $stage" -- \
  bash "$SCRIPT_DIR/stage-deploy-inner.sh" "$build_dir/builds/Version.zip" "$BUCKET" "$label" "$stage-2" "$stage-Worker2"
