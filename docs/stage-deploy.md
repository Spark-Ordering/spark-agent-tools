# stage-deploy.sh — deploy a spark_backend branch to Stage, no awui (ENG-2929)

```bash
~/Code/spark-agent-tools/stage-deploy.sh <branch|PR#> [Stage1|Stage2]   # default Stage1
# e.g.
stage-deploy.sh 773            # spark_backend PR #773 -> Stage1-2 + Stage1-Worker2
```

1. Resolves a PR number to its head branch (`Spark-Ordering/spark_backend`), fetches it.
2. Builds `builds/Version.zip` with the repo's `build.sh` in a throwaway worktree of that commit,
   so the `~/Code/spark_backend` checkout is never switched or built from. The gitignored
   `config/secrets.yml` is copied in from `~/Code/spark_backend` (every awui build shipped it).
3. ONE `aws-2fa.sh` approval (Carlos's phone, ENG-2927) runs `stage-deploy-inner.sh`: upload to
   `elasticbeanstalk-us-east-2-716429146716`, create the version `<branch tail>-<sha8>`, deploy it to
   the web and worker envs, wait, and check both envs report the new label (exit 1 if not).

Exit codes: 2 usage, 4 approval not given/expired (from aws-2fa.sh), 1 an env is not on the new label.

Stage is off most nights (ENG-2811): `stage-backend.sh start --wait` first when it returns 503.
Production envs are out of reach twice over: the script only builds `Stage1`/`Stage2` env names and
the `StageOps` role cannot write non-`Stage*` environments.

Self-check: `bash stage-deploy.test.sh` (fake aws, gh and aws-2fa).
