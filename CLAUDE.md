# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
