#!/bin/bash
# Self-check for stage-deploy.sh against fake aws / gh / aws-2fa.sh and a local spark_backend repo.
# Run: bash stage-deploy.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/stage-deploy.sh"
export FIXTURES; FIXTURES="$(mktemp -d)"
export PATH="$HERE/stage-deploy.test:$PATH" AWS_2FA="$HERE/stage-deploy.test/aws-2fa.sh"
fail() { echo "FAIL: $*"; exit 1; }
reset() { rm -f "$FIXTURES"/*.log "$FIXTURES/label" "$FIXTURES/uploaded.zip"; }

# Origin repo at a path containing Spark-Ordering/spark_backend, plus a clone like ~/Code/spark_backend.
origin="$FIXTURES/Spark-Ordering/spark_backend"
mkdir -p "$origin/config"
git -C "$origin" init -q -b development
echo 'zip -qr builds/Version.zip ./ -x ".git/*" "builds/*"' >"$origin/build.sh"
echo 'config/secrets.yml' >"$origin/.gitignore"
echo app >"$origin/app.rb"
echo config >"$origin/config/application.rb"
git -C "$origin" add -A && git -C "$origin" -c user.email=t@t -c user.name=t commit -qm init
git -C "$origin" checkout -qb cborde/ENG-2915/auth-amount-check
echo feature >"$origin/feature.rb"
git -C "$origin" add -A && git -C "$origin" -c user.email=t@t -c user.name=t commit -qm feature
sha="$(git -C "$origin" rev-parse HEAD)"
git -C "$origin" checkout -q development
export SPB_DIR="$FIXTURES/checkout"
git clone -q -o Spark-Ordering "$origin" "$SPB_DIR"
mkdir -p "$SPB_DIR/config"
echo 'secret: x' >"$SPB_DIR/config/secrets.yml"

rc=0; bash "$SCRIPT" 2>/dev/null || rc=$?
[ "$rc" = 2 ] || fail "usage exit $rc"
rc=0; bash "$SCRIPT" 773 Production 2>/dev/null || rc=$?
[ "$rc" = 2 ] || fail "non-Stage target exit $rc"
[ ! -f "$FIXTURES/aws.log" ] || fail "aws called for a non-Stage target"
echo "ok: usage; only Stage1/Stage2 accepted"

reset; out="$(bash "$SCRIPT" 773 2>&1)" || fail "happy path: $out"
grep -q "pr view 773 --repo Spark-Ordering/spark_backend" "$FIXTURES/gh.log" || fail "PR not resolved"
label="auth-amount-check-${sha:0:8}"
[ "$(cat "$FIXTURES/label")" = "$label" ] || fail "label $(cat "$FIXTURES/label")"
listing="$(unzip -l "$FIXTURES/uploaded.zip")"
grep -q "feature.rb" <<<"$listing" || fail "zip not built from the PR branch"
grep -q "config/secrets.yml" <<<"$listing" || fail "secrets.yml missing from the zip"
[ ! -f "$SPB_DIR/feature.rb" ] || fail "built in the checkout instead of a worktree"
[ "$(wc -l <"$FIXTURES/approvals.log" | tr -d ' ')" = 1 ] || fail "not exactly one approval"
grep -qF "deploy spark_backend cborde/ENG-2915/auth-amount-check @ ${sha:0:8} to Stage1" "$FIXTURES/approvals.log" \
  || fail "approval reason: $(cat "$FIXTURES/approvals.log")"
grep -q "s3://elasticbeanstalk-us-east-2-716429146716/Spark Ordering/$label/Version.zip" "$FIXTURES/aws.log" || fail "s3 key"
grep -q "update-environment --environment-name Stage1-2 --version-label $label" "$FIXTURES/aws.log" || fail "web env"
grep -q "update-environment --environment-name Stage1-Worker2 --version-label $label" "$FIXTURES/aws.log" || fail "worker env"
grep -q "wait environment-updated --environment-names Stage1-2 Stage1-Worker2" "$FIXTURES/aws.log" || fail "no wait"
grep -q "^Stage1-Worker2 $label" <<<"$out" || fail "verify output: $out"
[ "$(git -C "$SPB_DIR" worktree list | wc -l | tr -d ' ')" = 1 ] || fail "build worktree left behind"
echo "ok: PR# -> branch, zip from a throwaway worktree with secrets.yml, one approval, web + worker deployed and verified"

reset; out="$(bash "$SCRIPT" cborde/ENG-2915/auth-amount-check Stage2 2>&1)" || fail "branch arg: $out"
[ ! -f "$FIXTURES/gh.log" ] || fail "gh called for a branch name"
grep -q "update-environment --environment-name Stage2-Worker2" "$FIXTURES/aws.log" || fail "Stage2 worker"
echo "ok: branch name + Stage2"

reset; rc=0; FAKE_STUCK_ENV=Stage1-Worker2 bash "$SCRIPT" 773 >/dev/null 2>&1 || rc=$?
[ "$rc" = 1 ] || fail "env stuck on the old label exited $rc"
echo "ok: an env that did not take the new label fails the run"

mv "$SPB_DIR/config/secrets.yml" "$FIXTURES/secrets.bak"
reset; rc=0; bash "$SCRIPT" 773 >/dev/null 2>&1 || rc=$?
[ "$rc" != 0 ] || fail "deployed without secrets.yml"
[ ! -f "$FIXTURES/approvals.log" ] || fail "approval asked without secrets.yml"
echo "ok: missing secrets.yml stops before any approval"

rm -rf "$FIXTURES"
echo "ALL OK"
