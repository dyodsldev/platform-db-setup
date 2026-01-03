# DYODSL Database Migrations

## Prerequisites

Install `just` command runner:

```bash
# macOS
brew install just
```

## Quick Start

```bash
# 1. Clone the repo
git clone <your-repo>
cd platform-db-setup

# 2. Setup environment files
just setup

# 3. Edit your environment files with credentials
nano .env.dev

# 4. Run migrations
just migrate
```

## Available Commands

Run `just --list` to see all available commands, or check the `justfile`.

## Common Tasks

```bash
just migrate              # Run pending migrations
just info                 # Check migration status
just new-migration "name" # Create new migration
just backup               # Backup database
just switch-env prod      # Switch to production
```
