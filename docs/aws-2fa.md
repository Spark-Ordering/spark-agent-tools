# aws-2fa.sh — one Stage AWS command, approved by Carlos from his phone (ENG-2927)

```bash
~/Code/spark-agent-tools/aws-2fa.sh "<why>" -- <command...>
# e.g.
aws-2fa.sh "restart Stage2 after the ENG-2915 deploy" -- aws elasticbeanstalk restart-app-server --environment-name Stage2
```

1. Starts an IAM Identity Center device-code login for profile `sparkpos-ops` (the same
   mechanism the prod build uses for `sparkpos-release`).
2. The Claude bot DMs Carlos: the reason, the exact command, the code and the approve URL.
3. Carlos signs in as Identity Center user `carlos` with the S22 authenticator's AWS SSO entry and
   approves (codes expire in about 10 minutes). The S22 entry `mfa-aws.sh` uses belongs to IAM user
   `carlos-cli`; Identity Center rejects its codes.
4. The command runs with `AWS_PROFILE=sparkpos-ops`, then the session is logged out.
   One approval = one command.

Exit codes: the command's own; 2 usage; 3 profile not set up; 4 login not approved or expired.
Every request and result is appended to `~/.aws-2fa/history.tsv`.

## What the profile can do

Permission set `StageOps` (account 716429146716, `aws-ops/stage-ops-policy.json`):
- read Elastic Beanstalk, CloudFormation, EC2, Auto Scaling, ELB, CloudWatch and logs;
- update / restart / rebuild only environments named `Stage*`; create application versions;
  read and write the `elasticbeanstalk-us-east-2-716429146716` bucket;
- CloudFormation, Auto Scaling, EC2 and ELB writes only on resources tagged
  `elasticbeanstalk:environment-name` = `Stage*`;
- create / terminate only `Stage-agent` and the old `spark-backend-e2e` environment (ENG-2975), with the
  create-time EC2 / Auto Scaling / ELB / CloudFormation actions EB needs and delete actions only on
  resources tagged with those two environment names;
- read, rename and re-policy only IAM users `stage-agent-deployer` and `spark-backend-e2e-deployer`.

Stage-agent environment job (no YubiKey; preview with `--dry-run`, which only reads):

```bash
cd ~/Code/spark-agent-tools && bash aws-2fa.sh "ENG-2975 create Stage-agent, terminate spark-backend-e2e" -- bash aws-ops/stage-agent-env.sh
```

Production environments are not writable with it. A Stage operation that comes back
`AccessDenied`: add the action to the policy and rerun setup (it updates the permission set in place).

## One-time setup (Carlos, at the Mac, YubiKey)

```bash
cd ~/Code/spark-agent-tools && ~/Code/awui/mfa-aws.sh bash aws-ops/setup.sh
```

Idempotent: creates or updates the permission set and its policy, assigns it to Identity
Center user `carlos`, provisions it, and writes the `sparkpos-ops` profile
(`sso_session sparkpos`, role `StageOps`, region us-east-2). If the Identity Center home
region is not us-east-2, prefix `SSO_REGION=<region>`.

The logout at the end revokes the shared `sparkpos` SSO session, so a `sparkpos-release`
login that is active at the same time ends too.

Self-check: `bash aws-2fa.test.sh` (fake aws CLI and Slack).
