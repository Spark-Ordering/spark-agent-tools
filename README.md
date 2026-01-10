# Spark Agent Tools

Developer utilities for working with the Spark platform codebase.

## Tools

### sparkr - Build and Run Spark Services

Quick command to build and run Spark backend services from source with auto-restart.

```bash
./sparkr.sh spb    # Build and run spark_backend
./sparkr.sh rq     # Build and run RequestManager
```

**Features:**
- Automatically finds repositories anywhere within 3 levels of your home directory
- Kills previous instances before starting
- Builds from source (gems/assets for Rails, Maven for Java)
- Auto-restarts on crash (RequestManager)
- Runs worker and server together (spark_backend)

**Requirements:**
- Repositories must have `.env.local` file with credentials
- Git remote URL must end with `spark_backend.git` or `RequestManager.git`

### Database Query Tools

Convenient wrappers for querying Spark databases.

```bash
./mysql-query.sh "SELECT * FROM restaurants LIMIT 5"
./postgres-query.sh "SELECT * FROM orders LIMIT 5"
```

**Features:**
- Auto-discovers repositories by git remote URL
- Loads credentials from `.env.local` automatically
- Works from any directory

## Installation

```bash
git clone https://github.com/Spark-Ordering/spark-agent-tools.git
cd spark-agent-tools
```

Make sure your Spark repositories are checked out somewhere within 3 directory levels of your home directory and have `.env.local` files configured.

## How It Works

All tools use a shared repository finder (`repo-finder.sh`) that:
1. Searches for git repositories by matching remote URL suffix
2. Validates that `.env.local` exists
3. Returns the repository path for use by the tools

This makes the tools portable across different development environments and directory structures.
