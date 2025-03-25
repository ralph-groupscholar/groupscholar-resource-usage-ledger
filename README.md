# Group Scholar Resource Usage Ledger

A Dart CLI for logging how scholars use Group Scholar resources, then rolling up weekly and monthly summaries. It stores events in Postgres so the ops team can track engagement over time.

## Features
- Log resource usage sessions with minutes, staff, and notes.
- Filter recent activity by scholar or resource.
- Summarize usage by week, month, scholar, or resource.
- Initialize schema and seed data from SQL files.

## Tech Stack
- Dart 3.10
- PostgreSQL (via `postgres` package)

## Getting Started

### 1) Install dependencies
```
dart pub get
```

### 2) Configure environment
Set the database environment variables (do not commit secrets):
```
export PGHOST=your-host
export PGPORT=5432
export PGDATABASE=your-db
export PGUSER=your-user
export PGPASSWORD=your-password
export PGSSLMODE=require
```

### 3) Initialize the database
```
dart run bin/groupscholar_resource_usage_ledger.dart init-db
```

### 4) Log usage
```
dart run bin/groupscholar_resource_usage_ledger.dart log \
  --scholar "Ava Nguyen" \
  --resource "Essay Lab" \
  --type workshop \
  --minutes 45 \
  --occurred-at 2026-02-08T14:00:00Z \
  --staff "Jordan Ellis" \
  --notes "Outlined activity plan"
```

### 5) Review usage
```
dart run bin/groupscholar_resource_usage_ledger.dart list --scholar "Ava Nguyen"
```

### 6) Summarize usage
```
dart run bin/groupscholar_resource_usage_ledger.dart summary --group-by week
```

## Testing
```
dart test
```

## Database Notes
- Schema: `groupscholar_resource_usage_ledger`
- Primary table: `usage_events`
- SQL files live in `sql/`
