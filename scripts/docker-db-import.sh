#!/usr/bin/env bash
set -euo pipefail

# docker-db-import.sh
# Import a SQL dump into a DB running inside a Docker container.

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --engine [mysql|mariadb|postgres]   Database engine (default: mariadb)
  --container NAME                    Container name (required)
  --db NAME                           Target database name (required)
  --user USER                         Database user (default depends on engine)
  --password PASS                     Database password (if omitted, read from DB_PASSWORD or prompt)
  --dump PATH                         Path to .sql or .sql.gz dump (required)
  --host HOST                         Host (optional; usually not needed when using docker exec)
  --port PORT                         Port (optional)
  --pv                                Use pv for progress if available
  --no-confirm                        Do not prompt for confirmation
  --dry-run                           Print the command and exit
  -h, --help                          Show this help

Examples:
  $0 --container mariadb-local --engine mariadb \
     --db mydb --user root --dump ~/dump.sql

  $0 --engine postgres --container pg-local \
     --db mydb --user postgres --dump ~/dump.sql.gz
USAGE
}

confirm=yes
engine=mariadb
container=""
db=""
user=""
password="${DB_PASSWORD:-}"
dump_path=""
host=""
port=""
use_pv=no
dry_run=no

prompt_password() {
  if [[ -z "$password" ]]; then
    read -r -s -p "DB Password: " password
    echo
  fi
}

need() { command -v "$1" >/dev/null 2>&1 || { echo "Error: required command '$1' not found" >&2; exit 1; }; }

redact() { sed -E "s/(-p|--password(=| )?)[^ ]+/\1***** /g"; }

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine) engine="$2"; shift 2;;
    --container) container="$2"; shift 2;;
    --db) db="$2"; shift 2;;
    --user) user="$2"; shift 2;;
    --password) password="$2"; shift 2;;
    --dump) dump_path="$2"; shift 2;;
    --host) host="$2"; shift 2;;
    --port) port="$2"; shift 2;;
    --pv) use_pv=yes; shift;;
    --no-confirm) confirm=no; shift;;
    --dry-run) dry_run=yes; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2;;
  esac
done

# Defaults
case "$engine" in
  mariadb|mysql) :;;
  postgres|postgresql) engine=postgres;;
  *) echo "Unsupported engine: $engine" >&2; exit 2;;
esac
if [[ -z "$user" ]]; then
  if [[ "$engine" == "postgres" ]]; then user=postgres; else user=root; fi
fi

# Validations
[[ -n "$container" ]] || { echo "--container is required" >&2; exit 2; }
[[ -n "$db" ]] || { echo "--db is required" >&2; exit 2; }
[[ -n "$dump_path" ]] || { echo "--dump is required" >&2; exit 2; }
[[ -r "$dump_path" ]] || { echo "Dump file not found or unreadable: $dump_path" >&2; exit 2; }

need docker
if [[ "$use_pv" == "yes" ]]; then command -v pv >/dev/null 2>&1 || { echo "Warning: pv not found, continuing without progress" >&2; use_pv=no; }; fi

# Check container running
if ! docker ps --format '{{.Names}}' | grep -Fxq "$container"; then
  echo "Error: container '$container' is not running" >&2
  exit 3
fi

# Compose import command depending on engine and dump compression
dump_cmd="cat"
if [[ "$dump_path" == *.gz ]]; then
  need gunzip
  dump_cmd="gunzip -c"
fi

case "$engine" in
  mariadb|mysql)
    client_cmd=(docker exec -i "$container" sh -c "exec mysql -u$user ${password:+-p$password} ${db}")
    ;;
  postgres)
    client_cmd=(docker exec -i "$container" sh -c "exec psql -U $user -d $db -f -")
    ;;
esac

# Summary
echo "Engine     : $engine"
echo "Container  : $container"
echo "Database   : $db"
echo "User       : $user"
echo "Dump       : $dump_path"
[[ -n "$host" ]] && echo "Host       : $host"
[[ -n "$port" ]] && echo "Port       : $port"
[[ "$use_pv" == "yes" ]] && echo "Progress   : pv"

# Build pipeline
set -o pipefail
if [[ "$use_pv" == "yes" ]]; then
  pipeline=(bash -c "$dump_cmd \"$dump_path\" | pv | ${client_cmd[*]}")
else
  pipeline=(bash -c "$dump_cmd \"$dump_path\" | ${client_cmd[*]}")
fi

# Dry-run output (redact password)
if [[ "$dry_run" == "yes" ]]; then
  printf "Dry-run command:\n"
  printf "%q " "${pipeline[@]}" | redact
  echo
  exit 0
fi

if [[ "$confirm" == "yes" ]]; then
  echo "About to import into '$db' on container '$container'. This may overwrite data."
  read -r -p "Proceed? [y/N] " ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# Prompt for password if needed (mysql/mariadb only)
if [[ "$engine" != "postgres" ]]; then
  prompt_password
fi

# Execute
set +e
if [[ "$use_pv" == "yes" ]]; then
  eval "$dump_cmd \"$dump_path\"" | pv | "${client_cmd[@]}"
else
  eval "$dump_cmd \"$dump_path\"" | "${client_cmd[@]}"
fi
status=$?
set -e

if [[ $status -ne 0 ]]; then
  echo "Import failed with status $status" >&2
  exit $status
fi

echo "Import completed successfully."
