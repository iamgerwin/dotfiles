# Docker DB Import Script

A reusable script to import a local SQL dump into a database running in a Docker container.

## Usage

```
scripts/docker-db-import.sh \
  --container mariadb-local \
  --engine mariadb \
  --db mydb \
  --user root \
  --dump ~/path/to/dump.sql
```

### Flags
- `--engine [mysql|mariadb|postgres]` (default: `mariadb`)
- `--container <name>` (required)
- `--db <database>` (required)
- `--user <username>` (default: `root` for MySQL/MariaDB, `postgres` for Postgres)
- `--password <password>` or `DB_PASSWORD` env; will prompt if missing
- `--dump <path>` Path to `.sql` or `.sql.gz` (required)
- `--pv` Use `pv` for progress if available
- `--no-confirm` Skip confirmation prompt
- `--dry-run` Print the command that would run (password redacted)

### Examples
- MariaDB/MySQL:
```
scripts/docker-db-import.sh \
  --container mariadb-local \
  --engine mariadb \
  --db bhg-develop-stg \
  --user root \
  --dump /Users/gerwin/Documents/bhg-develop-0911.sql
```

- PostgreSQL with gzip dump:
```
scripts/docker-db-import.sh \
  --engine postgres \
  --container pg-local \
  --db appdb \
  --user postgres \
  --dump ~/dump.sql.gz
```

## Notes
- Requires `docker` and the relevant client (`mysql`/`mariadb` or `psql`) inside the container.
- For gzip dumps, `gunzip` is required on the host.
- Optionally uses `pv` for progress.
