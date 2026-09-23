#!/usr/bin/env bash
# Shut the database down. Your data and your work are kept.
set -uo pipefail
cd "$(dirname "$0")"
source scripts/_lib.sh
ensure_docker || exit 1
detect_compose || exit 1
dc stop
ok "Database stopped. Run ./start.sh to bring it back - your work is still there."
