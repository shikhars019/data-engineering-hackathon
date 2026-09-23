#!/usr/bin/env bash
# Look at your data without leaving the terminal.
#
#   ./explore.sh                 menu of useful things to look at
#   ./explore.sh tables          what tables exist and how big they are
#   ./explore.sh peek raw.claim  first 10 rows of any table
#   ./explore.sh values raw.claim claim_status
#                                every distinct value in a column, with counts
#   ./explore.sh sql "SELECT 1"  run any query
#
# 'values' is the one you will use most. It is how you find the mess.
#
set -uo pipefail
cd "$(dirname "$0")"
source scripts/_lib.sh

ensure_docker || exit 1
detect_compose || exit 1
if ! db_ready; then
  err "The database is not running. Start it with:  ./start.sh"
  exit 1
fi

cmd="${1:-menu}"

case "$cmd" in

  tables)
    head1 "Tables in your database"
    psql_show "
      SELECT n.nspname AS schema,
             c.relname AS table,
             to_char(c.reltuples::bigint, 'FM999,999,999') AS approx_rows
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relkind = 'r'
        AND n.nspname IN ('raw','ref','clean','curated','analytics','meta')
      ORDER BY
        array_position(ARRAY['raw','ref','curated','clean','analytics','meta'], n.nspname),
        c.relname;"
    say "  'approx_rows' is an estimate. For an exact count:"
    say "      ./explore.sh sql \"SELECT count(*) FROM raw.claimant\""
    ;;

  peek)
    tbl="${2:-}"
    if [ -z "$tbl" ]; then err "Which table?   ./explore.sh peek raw.claimant"; exit 1; fi
    head1 "First 10 rows of ${tbl}"
    psql_show "SELECT * FROM ${tbl} LIMIT 10;"
    ;;

  values)
    tbl="${2:-}"; col="${3:-}"
    if [ -z "$tbl" ] || [ -z "$col" ]; then
      err "Usage:  ./explore.sh values <table> <column>"
      say "  e.g.  ./explore.sh values raw.claim claim_status"
      exit 1
    fi
    head1 "${tbl}.${col}"

    # The summary comes FIRST. The list below is sorted by how common each
    # value is, so rare problems sink to the bottom where you will not see
    # them. These numbers do not let them hide.
    say "${BOLD}What is wrong with this column${NC}"
    psql_show "
      SELECT count(*)                                                    AS rows,
             count(DISTINCT ${col})                                      AS distinct_values,
             count(*) FILTER (WHERE ${col} IS NULL
                                 OR btrim(${col}::text) = '')            AS blank_or_null,
             count(*) FILTER (WHERE ${col}::text <> btrim(${col}::text)) AS stray_spaces,
             count(*) FILTER (WHERE btrim(${col}::text)
                                    IN ('N/A','UNKNOWN','NULL','n/a','-','TBC','NOT KNOWN')
                             )                                           AS placeholders,
             count(*) FILTER (WHERE ${col}::text
                                    <> initcap(btrim(${col}::text)))     AS not_title_case
      FROM ${tbl};"

    say "${BOLD}The values themselves${NC}  (most common first)"
    # Quoting the value makes leading and trailing spaces visible.
    psql_show "
      SELECT '[' || COALESCE(${col}::text, '<NULL>') || ']' AS value_in_brackets,
             count(*) AS rows
      FROM ${tbl}
      GROUP BY ${col}
      ORDER BY count(*) DESC, 1
      LIMIT 60;"
    say "  Brackets are added so you can see spaces. [ John ] is not [John]."
    say ""
    say "  ${BOLD}If the numbers above say there is a problem but you cannot see it${NC}"
    say "  in this list, the bad values are rare - so they are near the bottom,"
    say "  or past the 60 shown. Go looking for them directly:"
    say ""
    say "      ./explore.sh sql \"SELECT DISTINCT '['||${col}||']' FROM ${tbl}"
    say "                         WHERE ${col} <> btrim(${col}) LIMIT 20\""
    ;;

  columns)
    tbl="${2:-}"
    if [ -z "$tbl" ]; then err "Which table?   ./explore.sh columns raw.claimant"; exit 1; fi
    head1 "Columns in ${tbl}"
    psql_show "
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_schema = split_part('${tbl}', '.', 1)
        AND table_name   = split_part('${tbl}', '.', 2)
      ORDER BY ordinal_position;"
    ;;

  sql)
    q="${2:-}"
    if [ -z "$q" ]; then err "Give me a query:   ./explore.sh sql \"SELECT count(*) FROM raw.claimant\""; exit 1; fi
    psql_show "$q"
    ;;

  psql)
    say "Opening a psql prompt. Type \\q to leave."
    dc exec db psql -U hackathon -d pension
    ;;

  *)
    TEAM="$(current_team)"
    head1 "Explore your data"
    cat <<MENU

  ${BOLD}./explore.sh tables${NC}
      What tables exist and roughly how big they are.

  ${BOLD}./explore.sh columns raw.claimant${NC}
      What columns a table has.

  ${BOLD}./explore.sh peek raw.claimant${NC}
      The first 10 rows, so you can see what you are dealing with.

  ${BOLD}./explore.sh values raw.claim claim_status${NC}
      Every distinct value in a column with a count, wrapped in brackets
      so stray spaces show up. ${BOLD}This is how you find the mess.${NC}

  ${BOLD}./explore.sh sql "SELECT count(*) FROM raw.claimant"${NC}
      Run any query you like.

  ${BOLD}./explore.sh psql${NC}
      Open a full psql prompt.

  You will find it easier to browse in TablePlus or DBeaver:
      localhost : 55432 / pension / hackathon / hackathon

MENU
    if [ -n "$TEAM" ]; then
      say "  You are ${BOLD}team ${TEAM}${NC}. Your brief:"
      say "      challenges/challenge-1/team-${TEAM}/BRIEF.md"
      say ""
    fi
    ;;
esac
