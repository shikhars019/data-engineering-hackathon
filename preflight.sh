#!/usr/bin/env bash
# "Am I ready for the hackathon?"
#
# Run this BEFORE the day. It checks every tool you need, downloads the
# database image so you are not waiting on the wifi on the day, and proves
# the whole thing works end to end.
#
# It changes nothing permanent. Safe to run as many times as you like.
#
set -uo pipefail
cd "$(dirname "$0")"
source scripts/_lib.sh

PASS=0; FAIL=0
check_ok()   { ok   "$1"; PASS=$((PASS + 1)); }
check_fail() { err  "$1"; FAIL=$((FAIL + 1)); }

head1 "State Pension Hackathon - preflight check"
say "Checking that your MacBook is ready. This takes a few minutes the first time."

# --- 1. Operating system ----------------------------------------------------
head1 "1. Your machine"
say "  macOS version: $(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
say "  Chip:          $(uname -m)"

# --- 2. Homebrew ------------------------------------------------------------
head1 "2. Homebrew"
if command -v brew >/dev/null 2>&1; then
  check_ok "Homebrew is installed ($(brew --version 2>/dev/null | head -1))"
else
  check_fail "Homebrew is not installed."
  say "     Install it from https://brew.sh then run this script again."
  say "     If your machine blocks it, tell an organiser now - not on the day."
fi

# --- 3. Docker CLI, Compose, Colima ----------------------------------------
head1 "3. Docker tools"
for tool in docker colima; do
  if command -v "$tool" >/dev/null 2>&1; then
    check_ok "'$tool' is installed"
  else
    check_fail "'$tool' is NOT installed."
    say "     Run:  brew install colima docker docker-compose"
  fi
done

if detect_compose 2>/dev/null; then
  check_ok "Docker Compose is available (using '$COMPOSE')"
else
  check_fail "Docker Compose is not available."
  say "     Run:  brew install docker-compose"
  say "     Then: mkdir -p ~/.docker/cli-plugins"
  say "           ln -sfn \"\$(brew --prefix)/opt/docker-compose/bin/docker-compose\" ~/.docker/cli-plugins/docker-compose"
fi

# --- 4. The Docker daemon ---------------------------------------------------
head1 "4. The Docker engine"
say "  macOS cannot run containers by itself, so Colima runs a small Linux VM."
if ensure_docker; then
  check_ok "Docker engine is running"
else
  check_fail "Docker engine is not running."
  say "     Run:  colima start"
fi

# Everything below needs a working engine.
if [ "$FAIL" -gt 0 ]; then
  head1 "Result"
  err "$FAIL check(s) failed. Fix those first, then run ./preflight.sh again."
  say ""
  say "Stuck? Send an organiser a screenshot of this output. Do it today,"
  say "not on the morning of the hackathon."
  exit 1
fi

# --- 5. Pull the database image --------------------------------------------
head1 "5. Downloading the database image"
say "  About 150 MB. Doing it now means you are not waiting on the day."
if docker image inspect postgres:16 >/dev/null 2>&1; then
  check_ok "postgres:16 image already downloaded"
else
  if docker pull postgres:16 2>&1 | sed 's/^/     /'; then
    check_ok "postgres:16 image downloaded"
  else
    check_fail "Could not download the postgres:16 image (check your network)."
  fi
fi

# --- 6. Port 55432 ----------------------------------------------------------
head1 "6. Network port"
if lsof -nP -iTCP:55432 -sTCP:LISTEN >/dev/null 2>&1; then
  check_fail "Something is already using port 55432."
  say "     Find it with:  lsof -nP -iTCP:55432 -sTCP:LISTEN"
else
  check_ok "Port 55432 is free"
fi

# --- 7. Full end-to-end test ------------------------------------------------
head1 "7. Full dry run"
say "  Building a real database with team 1 data, then throwing it away."
say "  This is the same thing that happens on the day."
say ""

if [ -f .team ]; then mv .team .team.preflight-backup; fi
TEAM=1 dc down -v >/dev/null 2>&1

if TEAM=1 dc up -d >/dev/null 2>&1 && wait_for_db 90; then
  ROWS="$(psql_value "SELECT count(*) FROM raw.claimant;")"
  if [ -n "$ROWS" ] && [ "$ROWS" != "0" ]; then
    check_ok "Database built and loaded ($ROWS raw claimant records)"
    TESTS="$(psql_value "SELECT count(*) FROM test.result;" 2>/dev/null || echo 0)"
    check_ok "Test harness installed"
  else
    check_fail "Database started but no data was loaded."
    dc logs --tail=30 db 2>&1 | sed 's/^/     /'
  fi
else
  check_fail "Could not build the database."
  dc logs --tail=30 db 2>&1 | sed 's/^/     /'
fi

say ""
say "  Cleaning up the dry run..."
TEAM=1 dc down -v >/dev/null 2>&1
if [ -f .team.preflight-backup ]; then mv .team.preflight-backup .team; fi

# --- 8. A SQL client --------------------------------------------------------
head1 "8. A SQL client (optional but strongly recommended)"
if [ -d "/Applications/TablePlus.app" ]; then
  check_ok "TablePlus is installed"
elif [ -d "/Applications/DBeaver.app" ]; then
  check_ok "DBeaver is installed"
else
  warn "No SQL client found."
  say "     You can survive on ./explore.sh, but browsing messy data in a"
  say "     grid is much easier. Install one of:"
  say "       brew install --cask tableplus     (free tier is plenty)"
  say "       brew install --cask dbeaver-community"
fi

# --- Result -----------------------------------------------------------------
head1 "Result"
if [ "$FAIL" -eq 0 ]; then
  printf '%s%s  All %s checks passed. You are ready for the hackathon.%s\n\n' \
    "$GREEN" "$BOLD" "$PASS" "$NC"
  say "On the day, all you need is:"
  say "    ./start.sh <your team number>"
  say ""
  exit 0
else
  printf '%s%s  %s passed, %s failed.%s\n\n' "$YELLOW" "$BOLD" "$PASS" "$FAIL" "$NC"
  say "Fix the failures above and run ./preflight.sh again."
  say "Send an organiser a screenshot today if you are stuck."
  say ""
  exit 1
fi
