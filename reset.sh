#!/usr/bin/env bash
# Wipe the database completely and rebuild it from scratch.
#
# Use this whenever you have made a mess and want a clean start.
# It is quick, it is safe, and it is not cheating.
#
set -uo pipefail
cd "$(dirname "$0")"
source scripts/_lib.sh

head1 "Reset the hackathon database"

ensure_docker || exit 1
detect_compose || exit 1

TEAM="${1:-$(current_team)}"
if [ -z "$TEAM" ]; then
  err "Which team are you?   Run:  ./reset.sh <team number>"
  exit 1
fi

say "This deletes ${BOLD}everything${NC} in the database and reloads team ${BOLD}${TEAM}${NC} data."
say "Anything you wrote into the clean or analytics schemas will be lost."
say "Your .sql files on disk are ${BOLD}not${NC} touched."
say ""
printf 'Are you sure? [y/N] '
read -r reply
case "$reply" in
  [yY]*) ;;
  *) say "Cancelled - nothing changed."; exit 0 ;;
esac

say ""
say "Removing the old database..."
# The -v is the important bit. It drops the storage volume, which is what
# allows the initdb scripts to run again on the next start.
TEAM="$TEAM" dc down -v 2>&1 | sed 's/^/  /'

printf '%s' "$TEAM" > .team
say ""
exec ./start.sh "$TEAM"
