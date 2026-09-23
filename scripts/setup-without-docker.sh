#!/usr/bin/env bash
# Fallback setup for machines where Docker will not work.
# Uses a local PostgreSQL (Postgres.app) instead of a container.
#
#   ./scripts/setup-without-docker.sh 3
#
# Safe to re-run: it rebuilds the database from scratch each time.
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/_lib.sh

head1 "Hackathon setup - local PostgreSQL (no Docker)"

TEAM="${1:-$(current_team)}"
if ! printf '%s' "$TEAM" | grep -Eq '^[1-5]$'; then
  err "Which team are you?   ./scripts/setup-without-docker.sh <1-5>"
  exit 1
fi

if ! command -v psql >/dev/null 2>&1; then
  err "'psql' was not found."
  say "  Install Postgres.app from https://postgresapp.com, then run:"
  say "    sudo mkdir -p /etc/paths.d && echo /Applications/Postgres.app/Contents/Versions/latest/bin | sudo tee /etc/paths.d/postgresapp"
  say "  Close Terminal, open it again, and try once more."
  exit 1
fi
ok "psql found ($(psql --version))"

if ! psql -d postgres -c 'SELECT 1' >/dev/null 2>&1; then
  err "PostgreSQL is not running."
  say "  Open Postgres.app and check for the green dot."
  exit 1
fi
ok "PostgreSQL is running"

say ""
say "Rebuilding the 'pension' database for team ${BOLD}${TEAM}${NC}..."
dropdb --if-exists pension >/dev/null 2>&1
createdb pension || { err "Could not create the database."; exit 1; }

for f in initdb/*.sql; do
  printf '  %s\n' "$(basename "$f")"
  if ! psql -v ON_ERROR_STOP=1 -q -d pension -f "$f"; then
    err "Failed while running $f"
    exit 1
  fi
done

printf '  team%s.sql\n' "$TEAM"
if ! psql -v ON_ERROR_STOP=1 -q -d pension -f "data/team${TEAM}.sql"; then
  err "Failed while loading data/team${TEAM}.sql"
  exit 1
fi

psql -q -d pension -c "INSERT INTO meta.dataset_info (team) VALUES (${TEAM}); ANALYZE;"
printf '%s' "$TEAM" > .team

ROWS="$(psql -tAq -d pension -c 'SELECT count(*) FROM raw.claimant' | tr -d '[:space:]')"
ok "Loaded team ${TEAM} dataset (${ROWS} raw claimant records)"

cat <<BANNER

${GREEN}${BOLD}  You are ready to go.${NC}

  ${BOLD}Connect your SQL client with:${NC}
      Host:      localhost
      Port:      ${BOLD}5432${NC}        <- note: 5432, not 55432
      Database:  pension
      User:      $(whoami)
      Password:  (leave blank)

  ${BOLD}Your working file:${NC}
      challenges/challenge-1/team-${TEAM}/solution.sql

  ${BOLD}To score your work:${NC}
      ./scripts/check-without-docker.sh 1

BANNER
