#!/usr/bin/env bash
# Fallback scoring for machines where Docker will not work.
#
#   ./scripts/check-without-docker.sh 1
#   ./scripts/check-without-docker.sh 2
#
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/_lib.sh

CHALLENGE="${1:-}"
if ! printf '%s' "$CHALLENGE" | grep -Eq '^[12]$'; then
  err "Which challenge?   ./scripts/check-without-docker.sh 1   or   ... 2"
  exit 1
fi

if ! psql -d pension -c 'SELECT 1' >/dev/null 2>&1; then
  err "Cannot reach the 'pension' database."
  say "  Open Postgres.app, then run ./scripts/setup-without-docker.sh <team>"
  exit 1
fi

TEAM="$(current_team)"
if [ -z "$TEAM" ]; then
  err "I do not know which team you are."
  say "  Run:  ./scripts/setup-without-docker.sh <team number>"
  exit 1
fi

if [ "$CHALLENGE" = "1" ]; then
  SOLUTION="challenges/challenge-1/team-${TEAM}/solution.sql"
  TESTS="tests/challenge1_team${TEAM}_tests.sql"
  TITLE="Challenge 1 - Team ${TEAM}"
else
  SOLUTION="challenges/challenge-2/solution.sql"
  TESTS="tests/challenge2_tests.sql"
  TITLE="Challenge 2 - Safe Data for Analysts"
fi

head1 "$TITLE"
say ""
say "${BOLD}1. Running your SQL${NC}  (${SOLUTION})"
say "-------------------------------------------------------------"

SQL_OUT="$(psql -v ON_ERROR_STOP=1 -q -d pension -f "$SOLUTION" 2>&1)"
if [ $? -ne 0 ]; then
  err "Your SQL did not run. Postgres said:"
  say ""
  printf '%s\n' "$SQL_OUT" | sed 's/^/    /'
  say ""
  say "Nothing was scored. Fix the error and try again."
  exit 1
fi
printf '%s\n' "$SQL_OUT" | grep -v '^$' | sed 's/^/    /'
ok "Your SQL ran without errors"

say ""
say "${BOLD}2. Scoring${NC}"
say "-------------------------------------------------------------"
psql -v ON_ERROR_STOP=1 -q -d pension -f "$TESTS" >/dev/null
psql -d pension -c 'SELECT * FROM test.report;'

CORE_PASS="$(psql -tAq -d pension -c "SELECT count(*) FROM test.result WHERE kind='core' AND status='PASS'" | tr -d '[:space:]')"
CORE_TOTAL="$(psql -tAq -d pension -c "SELECT count(*) FROM test.result WHERE kind='core'" | tr -d '[:space:]')"
BONUS_PASS="$(psql -tAq -d pension -c "SELECT count(*) FROM test.result WHERE kind='bonus' AND status='PASS'" | tr -d '[:space:]')"
BONUS_TOTAL="$(psql -tAq -d pension -c "SELECT count(*) FROM test.result WHERE kind='bonus'" | tr -d '[:space:]')"

say ""
if [ "$CORE_PASS" = "$CORE_TOTAL" ]; then
  printf '%s%s  CORE %s/%s - all core tests passing!  BONUS %s/%s%s\n\n' \
    "$GREEN" "$BOLD" "$CORE_PASS" "$CORE_TOTAL" "$BONUS_PASS" "$BONUS_TOTAL" "$NC"
else
  printf '%s%s  CORE %s/%s   BONUS %s/%s%s\n\n' \
    "$YELLOW" "$BOLD" "$CORE_PASS" "$CORE_TOTAL" "$BONUS_PASS" "$BONUS_TOTAL" "$NC"
  NEXT="$(psql -tAq -d pension -c "SELECT 'Task ' || coalesce(task,'?') || '   ' || name FROM test.next_up")"
  if [ -n "$NEXT" ]; then
    say "  ${BOLD}Next thing to fix:${NC}  ${NEXT}"
    say ""
  fi
  say "  The scorecard above is in ${BOLD}task order${NC}, so work down it from the top."
fi
