#!/usr/bin/env bash
# Run YOUR solution file, then score it against the tests.
#
#   ./check.sh 1     Challenge 1
#   ./check.sh 2     Challenge 2
#
# Nothing here is magic: it runs your .sql file, then runs the test file,
# then prints the results. You can run both by hand in your SQL client too.
#
set -uo pipefail
cd "$(dirname "$0")"
source scripts/_lib.sh

CHALLENGE="${1:-}"
if ! printf '%s' "$CHALLENGE" | grep -Eq '^[12]$'; then
  err "Which challenge?   Run:  ./check.sh 1    or    ./check.sh 2"
  exit 1
fi

ensure_docker || exit 1
detect_compose || exit 1

if ! db_ready; then
  err "The database is not running. Start it with:  ./start.sh"
  exit 1
fi

TEAM="$(current_team)"
if [ -z "$TEAM" ]; then
  err "I do not know which team you are.   Run:  ./start.sh <team number>"
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

head1 "${TITLE}"

# -- Step 1: run the student's SQL ------------------------------------------
say ""
say "${BOLD}1. Running your SQL${NC}  (${SOLUTION})"
say "-------------------------------------------------------------"

SQL_OUT="$(psql_file "$SOLUTION" 2>&1)"
SQL_RC=$?

if [ $SQL_RC -ne 0 ]; then
  err "Your SQL did not run. Postgres said:"
  say ""
  printf '%s\n' "$SQL_OUT" | sed 's/^/    /'
  say ""
  say "${BOLD}How to read that:${NC}"
  say "  - Look for the line number, then check that line in your file."
  say "  - 'syntax error at or near' usually means a missing comma or bracket."
  say "  - 'relation ... does not exist' means a table name is wrong or"
  say "    you are missing the schema prefix, e.g. raw.claimant not claimant."
  say ""
  say "Nothing was scored. Fix the error and run ./check.sh ${CHALLENGE} again."
  exit 1
fi

printf '%s\n' "$SQL_OUT" | grep -v '^$' | sed 's/^/    /'
ok "Your SQL ran without errors"

# -- Step 2: run the tests ---------------------------------------------------
say ""
say "${BOLD}2. Scoring${NC}"
say "-------------------------------------------------------------"

if ! psql_file "$TESTS" > /dev/null 2>&1; then
  err "The test harness itself failed to run. Tell an organiser."
  psql_file "$TESTS" 2>&1 | tail -20 | sed 's/^/    /'
  exit 1
fi

psql_show "SELECT * FROM test.report;"

CORE_PASS="$(psql_value "SELECT count(*) FROM test.result WHERE kind='core' AND status='PASS';")"
CORE_TOTAL="$(psql_value "SELECT count(*) FROM test.result WHERE kind='core';")"
BONUS_PASS="$(psql_value "SELECT count(*) FROM test.result WHERE kind='bonus' AND status='PASS';")"
BONUS_TOTAL="$(psql_value "SELECT count(*) FROM test.result WHERE kind='bonus';")"

say ""
if [ "$CORE_PASS" = "$CORE_TOTAL" ]; then
  printf '%s%s  CORE %s/%s - all core tests passing!  BONUS %s/%s%s\n' \
    "$GREEN" "$BOLD" "$CORE_PASS" "$CORE_TOTAL" "$BONUS_PASS" "$BONUS_TOTAL" "$NC"
  say ""
  say "  Report your score to the organisers, then try the bonus tasks."
else
  printf '%s%s  CORE %s/%s   BONUS %s/%s%s\n' \
    "$YELLOW" "$BOLD" "$CORE_PASS" "$CORE_TOTAL" "$BONUS_PASS" "$BONUS_TOTAL" "$NC"
  say ""

  # The scorecard is in task order, so the first core failure is the
  # earliest unfinished task. Say so plainly - there is always one
  # obvious next thing to do.
  NEXT="$(psql_value "SELECT 'Task ' || coalesce(task,'?') || '   ' || name FROM test.next_up;")"
  NEXT_HINT="$(psql_value "SELECT coalesce(hint,'') FROM test.next_up;")"
  if [ -n "$NEXT" ]; then
    say "  ${BOLD}Next thing to fix:${NC}  ${NEXT}"
    [ -n "$NEXT_HINT" ] && say "                     ${NEXT_HINT}"
    say ""
  fi

  say "  The scorecard above is in ${BOLD}task order${NC}, so work down it from the top."
  say "  To see the detail of one test:"
  say "      SELECT * FROM test.result WHERE id = 'C1.03';"
fi
say ""
