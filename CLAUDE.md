# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Environment Detection

To determine if running in a GitHub Codespace vs local Mac:
```bash
# Returns "codespace" or "local"
[ -d /workspaces ] && echo "codespace" || echo "local"
```

## Repository Locations

### In GitHub Codespaces
When running in a Codespace, repos are at fixed paths - **no need for repo-finder**:

| Repo | Path |
|------|------|
| spark_backend | `/workspaces/spark-agent-tools/spark_backend` |
| SparkPos | `/workspaces/spark-agent-tools/sparkpos` |
| RequestManager | `/workspaces/spark-agent-tools/RequestManager` |

### On Local Mac
Repos are typically at:
- `~/Code/spark_backend`
- `~/Code/SparkPos`
- `~/Code/RequestManager`

Or use `repo-finder.sh` to locate them dynamically.

## CRITICAL: Full Stack Runs on Codespace

**The ENTIRE backend stack runs on Codespace, NOT cloud services.** This includes:

- **Supabase** - Local instance on Codespace (NOT supabase.co cloud)
- **PowerSync** - Self-hosted on Codespace (NOT powersync.journeyapps.com cloud)
- **Metro** - React Native bundler on Codespace
- **spark_backend** - Rails server on Codespace
- **RequestManager** - Java service on Codespace

The mobile app runs on a LOCAL emulator and connects to ALL services via port forwarding from Codespace. The app's `.env.local` must point to localhost URLs (forwarded ports), NOT cloud URLs.

**If debugging shows the app trying to reach cloud URLs (*.supabase.co, *.powersync.journeyapps.com), the environment is misconfigured.**

## Services in Codespace

| Service | Port |
|---------|------|
| Rails (spark_backend) | 3000 |
| Metro (SparkPos) | 8081 |
| PowerSync | 8080 |
| Supabase API | 54321 |
| Supabase Postgres | 54322 |
| Supabase Studio | 54323 |
| MySQL | 3306 |

### Accessing Codespace Services

**IMPORTANT:** `localhost` URLs only work if port forwarding is active on the Mac. To get the GitHub forwarded URLs (which always work), use:

```bash
gh codespace ports -c <codespace-name> --json sourcePort,browseUrl
```

This returns URLs like `https://<codespace-name>-<port>.app.github.dev`. When giving the user URLs to access Codespace services, **always use these GitHub forwarded URLs**, not localhost.

## Codespace Log Locations

**Always check these paths for service logs:**

| Service | Log Path |
|---------|----------|
| RequestManager | `/tmp/requestmanager.log` |
| Edge Functions | `/tmp/edge-functions.log` |

### Starting Services with Logs

```bash
# RequestManager (logs automatically to /tmp/requestmanager.log)
cd /workspaces/spark-agent-tools/RequestManager && ./start-codespace.sh &

# Edge Functions
cd /workspaces/spark-agent-tools/sparkpos && npx supabase functions serve --env-file supabase/functions/.env > /tmp/edge-functions.log 2>&1 &
```

### Reading Logs

```bash
tail -f /tmp/requestmanager.log    # Follow RequestManager logs
tail -f /tmp/edge-functions.log    # Follow Edge Function logs
```

## Overview

This repository contains database query wrapper scripts for the Spark platform. These scripts provide convenient access to MySQL (spark_backend) and PostgreSQL (SparkPos) databases by automatically loading credentials from environment files.

## Scripts

### MySQL Query Tool
```bash
./mysql-query.sh "SELECT * FROM restaurants LIMIT 5"
```

**Purpose:** Query the spark_backend MySQL database
**Credential Source:** Parses `AWS_DATABASE_URL` environment variable (format: `mysql2://username:password@host/database`)

### PostgreSQL Query Tool
```bash
./postgres-query.sh "SELECT * FROM orders LIMIT 5"
```

**Purpose:** Query the SparkPos PostgreSQL database
**Credential Source:** Uses `DATABASE_URL_DEVELOP` environment variable

**IMPORTANT: Codespace vs Cloud Database**
- Running locally on Mac queries the **cloud database** (via DATABASE_URL_DEVELOP)
- To query the **Codespace's local Supabase**, run the script ON the Codespace:
```bash
gh codespace ssh -c <codespace-name> -- "cd /workspaces/spark-agent-tools && ./postgres-query.sh \"SELECT * FROM table\""
```
When debugging sync issues, always query the Codespace database since that's what the app connects to.

### Spark Runner Tool
```bash
./sparkr.sh spb    # Build and run spark_backend (Rails server + worker)
./sparkr.sh rq     # Build and run RequestManager (Java service)
```

**Purpose:** Build and run Spark services with auto-restart capability
**Features:**
- Kills previous instances before starting
- Loads environment from `.env.local`
- Auto-restarts on crash (RequestManager)
- Runs worker and server together (spark_backend)

### Codespace Management Scripts (mac/)

**IMPORTANT FOR CLAUDE:** Always use these scripts instead of manually writing osascript or terminal commands.

#### Spawn Environment
```bash
./mac/spawn-env.sh --sparkpos <branch>   # ALWAYS specify SparkPos branch
./mac/spawn-env.sh --sparkpos add-logout-button  # Example with current dev branch
```

**CRITICAL: ALWAYS use `--sparkpos <branch>` flag.** The SparkPos master branch often lacks fixes needed for local dev (like SSL localhost checks). Always spawn with the active development branch.

Creates a full dev environment: Codespace, port forwarding, Metro terminal, DevTools.

#### Connect to Metro
```bash
./mac/connect-metro.sh                    # Auto-detect Codespace
./mac/connect-metro.sh <codespace-name>   # Specific Codespace
```
**Use this script to open Metro in a new terminal window.** Do NOT manually write osascript commands - this script handles iTerm2, Terminal.app, and other terminals automatically.

#### Teardown Environment
```bash
./mac/teardown-env.sh              # Delete current Codespace
./mac/teardown-env.sh <name>       # Delete specific Codespace
```

## Supabase Edge Function Environment Variables

**CRITICAL: Edge functions read custom env vars from `supabase/functions/.env`, NOT from `.env.local`.**

If an edge function needs `POWERSYNC_PRIVATE_KEY` or other custom vars:

1. Create/update `supabase/functions/.env` on Codespace:
   ```bash
   gh codespace ssh -c <name> -- "grep 'POWERSYNC_PRIVATE_KEY' /workspaces/spark-agent-tools/sparkpos/.env.local > /workspaces/spark-agent-tools/sparkpos/supabase/functions/.env"
   ```

2. **Reload env vars WITHOUT full restart** (this is important!):
   ```bash
   gh codespace ssh -c <name> -- "docker restart supabase_edge_runtime_sparkpos"
   ```

**NEVER use `supabase stop && supabase start` just to reload env vars** - it triggers massive Docker image downloads (5-10+ minutes). The `docker restart` command takes 2 seconds.

## Port Forwarding

Port forwarding from Codespace to Mac drops frequently. When you see "Network request failed" errors:

```bash
./ensure-ports.sh                    # Auto-detect codespace, forward missing ports
./ensure-ports.sh <codespace-name>   # Specific codespace
```

This script:
- Checks which ports (54321, 8080, 8081) are missing
- Only forwards the missing ones (doesn't kill working ports)
- Uses `nohup` so forwarding survives shell closure

**Ports required:**
| Port | Service |
|------|---------|
| 54321 | Supabase API |
| 8080 | PowerSync |
| 8081 | Metro |

## Architecture

### Shared Repository Finder (`repo-finder.sh`)
All scripts use a shared utility function `find_repo()` that:
1. **Auto-discovers repository location:** Searches within 3 levels of `$HOME` for git repositories matching the target remote URL suffix
2. **Validates credentials exist:** Only returns repositories that have a `.env.local` file present
3. **Returns repository path:** Used by scripts to source environment variables and run commands

### Script Pattern
All scripts follow the same pattern:
1. Source the `repo-finder.sh` utility
2. Find target repository by git remote suffix (`spark_backend.git`, `SparkPos.git`, `RequestManager.git`)
3. Load environment variables from the discovered `.env.local` file
4. Execute the requested operation (query, build, run)

**Key Design:** Scripts are location-agnostic - they dynamically find the correct repository by matching git remote URL suffix, making them portable across different development environments and directory structures.
