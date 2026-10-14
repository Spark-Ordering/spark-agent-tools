# Stage spark_backend on/off for agents (ENG-2811)

`stage-backend.sh start [--wait] | stop | status | heartbeat`

## Why agents need it

Stage spark_backend (`www.spark-stage.com`: EB envs Stage1-2, Stage1-Worker2, Stage-RequestManager,
plus the shared `stage-database` Aurora cluster) is off most of the time. `StopTestingEnvironmentsJob`
scales it to 0 instances every night at 3 AM ET unless an E2E heartbeat arrived in the last hour.

Agent work that needs it running:

- **Cypress checklists for RestWeb / spark_backend PRs.** Specs whose `baseUrl` is
  `www.spark-stage.com` cannot run against a 503. ENG-2781 (RestWeb #897, Sushi-Hut special hours)
  sat paused from 2026-10-04 to 2026-10-07 with all 4 checklist specs unrun, while the #prs thread
  asked a human three times to scale Stage1 back to 1 instance.
- **`falcon9/customer_service` calls from AI threads on dev envs** (`change_order_time`,
  `place_order`, ...; `SPARK_BACKEND_URL` = `www.spark-stage.com` in `.env.develop1`).
- **SPARK_E2E web suites** whose orchestrator already heartbeats this same API during long runs.

Before this tool the only paths were a human in the AWS console or `aws elasticbeanstalk
update-environment` from the agent, which the auto-mode classifier denies as a shared-resource change.

## How it is scoped

- Calls the existing prod control plane `https://app.sparkordering.com/falcon9/environment/start_aws_stage`
  / `stop_aws_stage` (spark_backend `Falcon9::EnvironmentController`, same API the Raycast commands and
  the SPARK_E2E orchestrator use). Production manages stage on/off because stage is off when you need it.
- The stage key `stage` and both hosts are hardcoded; the script takes no environment argument. The
  server side only knows `stage` / `stage2` groups, so the key itself cannot reach production compute.
- `start` also sends one heartbeat, so a run started near 3 AM ET is not shut down under it; long runs
  call `heartbeat` (each one buys an hour).
- No human approval: stage shuts itself down nightly, so a forgotten `start` costs at most one day of
  one instance per env (Trent, #prs 2026-10-06).

## One-time setup

`~/.config/spark/stage-control.env` with one line, `RAYCAST_API_KEY=<key>` (the value SPARK_E2E's
`cypress.config.js` calls `envControlApiKey`). The script sources it and never prints it.

## Use

```
~/Code/spark-agent-tools/stage-backend.sh start --wait   # ~10-20 min: DB first, then EB envs
~/Code/spark-agent-tools/stage-backend.sh status         # 503 = off
~/Code/spark-agent-tools/stage-backend.sh stop           # when done, if nothing else needs it today
```

Self-check: `bash stage-backend.test.sh`.
