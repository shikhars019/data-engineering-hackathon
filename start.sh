#!/usr/bin/env bash
# Start the hackathon database and load your team's data.
#
#   ./start.sh 3      first time - tells it you are team 3
#   ./start.sh        afterwards - just brings it back up
#
set -uo pipefail
cd "$(dirname "$0")"
source scripts/_lib.sh

head1 "State Pension Hackathon - starting your database"

ensure_docker || exit 1
detect_compose || exit 1
ok "Docker is available ($COMPOSE)"

TEAM_ARG="${1:-}"
EXISTING_TEAM="$(current_team)"

if [ -n "$TEAM_ARG" ]; then
  if ! printf '%s' "$TEAM_ARG" | grep -Eq '^[1-5]$'; then
    err "Team number must be 1, 2, 3, 4 or 5 - you gave '$TEAM_ARG'."
    exit 1
  fi
  TEAM="$TEAM_ARG"
elif [ -n "$EXISTING_TEAM" ]; then
  TEAM="$EXISTING_TEAM"
else
  err "Which team are you?"
  say "  Run:  ./start.sh <your team number>     for example  ./start.sh 3"
  exit 1
fi

# Switching team needs a rebuild, because data only loads on first boot.
if [ -n "$EXISTING_TEAM" ] && [ "$EXISTING_TEAM" != "$TEAM" ]; then
  warn "You were set up as team $EXISTING_TEAM and are now asking for team $TEAM."
  warn "That needs a fresh database. Work saved in the clean schema will be lost."
  printf 'Continue? [y/N] '
  read -r reply
  case "$reply" in
    [yY]*) ;;
    *) say "Cancelled - nothing changed."; exit 0 ;;
  esac
  TEAM="$TEAM" dc down -v >/dev/null 2>&1
fi

printf '%s' "$TEAM" > .team

say ""
say "Team ${BOLD}${TEAM}${NC} - bringing the database up..."

if ! TEAM="$TEAM" dc up -d 2>&1 | sed 's/^/  /'; then
  show_db_logs_on_failure
  exit 1
fi

printf '  waiting for the database to be ready'
if ! wait_for_db 60; then
  printf '\n'
  show_db_logs_on_failure
  exit 1
fi
printf '\n'
ok "Database is ready"

# The container exits if an init script fails, so also confirm the data landed.
LOADED="$(psql_value "SELECT count(*) FROM raw.claimant;")"
if [ -z "$LOADED" ] || [ "$LOADED" = "0" ]; then
  err "The database is up but no data was loaded."
  show_db_logs_on_failure
  exit 1
fi

LOADED_TEAM="$(psql_value "SELECT team FROM meta.dataset_info LIMIT 1;")"
ok "Loaded team ${LOADED_TEAM} dataset (${LOADED} raw claimant records)"

if [ -n "$LOADED_TEAM" ] && [ "$LOADED_TEAM" != "$TEAM" ]; then
  warn "The database actually holds team ${LOADED_TEAM} data, not team ${TEAM}."
  warn "Run ./reset.sh ${TEAM} to rebuild it."
fi

cat <<BANNER

${GREEN}${BOLD}  You are ready to go.${NC}

  ${BOLD}Connect your SQL client (TablePlus / DBeaver) with:${NC}

      Host:      localhost
      Port:      ${BOLD}55432${NC}        <- not the usual 5432
      Database:  pension
      User:      hackathon
      Password:  hackathon

  ${BOLD}Your working file:${NC}
      challenges/challenge-1/team-${TEAM}/solution.sql

  ${BOLD}Useful commands:${NC}
      ./check.sh 1     run your Challenge 1 SQL and score it
      ./check.sh 2     run your Challenge 2 SQL and score it
      ./explore.sh     look at the raw data from the terminal
      ./reset.sh       wipe everything and start again
      ./stop.sh        shut the database down (your work is kept)

BANNER
