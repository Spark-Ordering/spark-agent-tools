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

## Services in Codespace

| Service | Port | URL |
|---------|------|-----|
| Rails (spark_backend) | 3000 | http://localhost:3000 |
| Metro (SparkPos) | 8081 | http://localhost:8081 |
| Supabase API | 54321 | http://localhost:54321 |
| Supabase Postgres | 54322 | postgresql://postgres:postgres@localhost:54322/postgres |
| Supabase Studio | 54323 | http://localhost:54323 |
| MySQL | 3306 | mysql://root:root@localhost:3306 |

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
