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

## Architecture

Both scripts follow the same pattern:
1. **Auto-discover repository location:** Searches within 3 levels of `$HOME` for git repositories matching the target remote URL suffix (`spark_backend.git` or `SparkPos.git`)
2. **Validate credentials exist:** Only uses repositories that have a `.env.local` file present
3. **Load environment variables:** Sources the discovered `.env.local` file
4. **Execute query:** Runs the SQL query passed as the first argument
5. **Return results:** Outputs results to stdout

**Key Design:** Scripts are location-agnostic - they dynamically find the correct repository by matching git remote URL suffix, making them portable across different development environments and directory structures.
