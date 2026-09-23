#!/usr/bin/env bash
# Shared helpers for the hackathon scripts. You do not need to read this file.
set -uo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
BOLD=$'\033[1m'; NC=$'\033[0m'

say()  { printf '%s\n' "$*"; }
ok()   { printf '%s  OK  %s %s\n' "$GREEN" "$NC" "$*"; }
warn() { printf '%s WARN %s %s\n' "$YELLOW" "$NC" "$*"; }
err()  { printf '%s FAIL %s %s\n' "$RED" "$NC" "$*" >&2; }
head1(){ printf '\n%s%s%s\n' "$BOLD" "$*" "$NC"; }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# Compose: Homebrew installs the plugin somewhere `docker compose` may not
# look, so support both spellings transparently.
# ---------------------------------------------------------------------------
detect_compose() {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
  else
    err "Docker Compose is not installed."
    say ""
    say "  Install it with:   brew install docker docker-compose"
    say ""
    say "  If 'docker-compose' works but 'docker compose' does not, link it:"
    say "    mkdir -p ~/.docker/cli-plugins"
    say "    ln -sfn \"\$(brew --prefix)/opt/docker-compose/bin/docker-compose\" ~/.docker/cli-plugins/docker-compose"
    return 1
  fi
  return 0
}

dc() { ( cd "$PROJECT_ROOT" && $COMPOSE "$@" ); }

# ---------------------------------------------------------------------------
# The Docker daemon. On macOS this is Colima, not Docker Desktop.
# ---------------------------------------------------------------------------
ensure_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    err "The 'docker' command was not found."
    say ""
    say "  Install it with:   brew install colima docker docker-compose"
    return 1
  fi

  if docker info >/dev/null 2>&1; then
    return 0
  fi

  if command -v colima >/dev/null 2>&1; then
    warn "Docker is not responding. Starting Colima (this can take a minute)..."
    if colima start; then
      sleep 2
      if docker info >/dev/null 2>&1; then
        ok "Colima is running."
        return 0
      fi
    fi
    err "Colima started but Docker is still not responding."
    say "  Try:  colima delete && colima start"
    return 1
  fi

  err "Cannot connect to the Docker daemon, and Colima is not installed."
  say ""
  say "  macOS cannot run containers on its own - it needs a small Linux VM."
  say "  Install one with:   brew install colima && colima start"
  return 1
}

# ---------------------------------------------------------------------------
# Talking to the database
# ---------------------------------------------------------------------------
PSQL_BASE="psql -v ON_ERROR_STOP=1 -U hackathon -d pension"

db_ready() {
  dc exec -T db pg_isready -U hackathon -d pension >/dev/null 2>&1
}

wait_for_db() {
  local tries="${1:-40}"
  local i=0
  while [ "$i" -lt "$tries" ]; do
    if db_ready; then return 0; fi
    sleep 1
    i=$((i + 1))
  done
  return 1
}

# Run a .sql file from the project. Path is relative to the project root.
psql_file() {
  local rel="$1"
  if [ ! -f "$PROJECT_ROOT/$rel" ]; then
    err "File not found: $rel"
    return 1
  fi
  dc exec -T db $PSQL_BASE -q -f - < "$PROJECT_ROOT/$rel"
}

# Run one query, return a bare value.
psql_value() {
  dc exec -T db $PSQL_BASE -tAq -c "$1" 2>/dev/null | tr -d '\r'
}

# Run a query and pretty-print the result.
psql_show() {
  dc exec -T db $PSQL_BASE -c "$1"
}

show_db_logs_on_failure() {
  err "The database did not start correctly."
  say ""
  say "${BOLD}Last 40 lines of the database log:${NC}"
  say "-------------------------------------------------------------"
  dc logs --tail=40 db 2>&1 | sed 's/^/  /'
  say "-------------------------------------------------------------"
  say ""
  say "Most problems are fixed by a clean restart:   ./reset.sh"
}

current_team() {
  if [ -f "$PROJECT_ROOT/.team" ]; then
    tr -dc '0-9' < "$PROJECT_ROOT/.team"
  fi
}
