-- ===========================================================================
-- CHALLENGE 1 - TEAM 3 - The Address Mess
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 1
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: SIX LINES
--
-- Most of this file is explanation. The query itself is already written,
-- and you should leave nearly all of it alone.
--
-- There are exactly six lines to change. Every one is marked like this:
--
--        <<<<<< EDIT THIS LINE
--
-- Search for EDIT to jump between them.
--
--   Task 1  Load the people                    (done for you - leave it)
--   Task 2  Tidy the address lines and town    lines 97 and 98  <- start here
--   Task 3  Put ONE space back in the postcode line  134
--   Task 4  Throw out the fake postcodes       line  183
--   Task 5  Throw out addresses with no person line  184
--   Task 6  Which address do they live at NOW  line  215
--
-- The tasks appear below in that order. Do them in that order.
--
-- It already runs, and Task 1 is already passing. Run ./check.sh 1 now,
-- before changing anything, so you can see where you are starting from.
--
-- THE BIG IDEA: a postcode is how the agency works out which region a pensioner
-- lives in. 'sw1a1aa', 'SW1A  1AA' and 'SW1A 1AA' are the same place, but
-- only the last one will join to anything. The other two drop silently out
-- of every regional report, and nobody notices, because a missing row does
-- not announce itself.
-- ===========================================================================

TRUNCATE clean.address;
TRUNCATE clean.claimant;


-- ---------------------------------------------------------------------------
-- TASK 1 - Load the people. Written for you: leave it alone.
-- Your work is the addresses, below.
-- ---------------------------------------------------------------------------
INSERT INTO clean.claimant (nino, title, first_name, last_name, date_of_birth,
                            sex, marital_status, date_of_death, email, phone)
SELECT
    upper(btrim(nino)),
    replace(initcap(btrim(title)), '.', ''),
    initcap(btrim(first_name)),
    initcap(btrim(last_name)),
    util.to_date(date_of_birth, 'YYYY-MM-DD'),
    upper(btrim(sex)),
    CASE WHEN btrim(coalesce(marital_status, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')
         THEN NULL ELSE initcap(btrim(marital_status)) END,
    util.to_date(date_of_death, 'YYYY-MM-DD'),
    CASE WHEN btrim(coalesce(email, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')
         THEN NULL ELSE lower(btrim(email)) END,
    CASE WHEN btrim(coalesce(phone, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')
         THEN NULL ELSE replace(btrim(phone), ' ', '') END
FROM raw.claimant;


INSERT INTO clean.address (address_id, nino, line_1, line_2, town, county,
                           postcode, valid_from, valid_to, is_current)
WITH squashed AS (
    -- Given to you. Every postcode, with ALL its spaces removed and put
    -- into capitals. Doing that first means you never have to care how
    -- many spaces there were to begin with.
    SELECT a.*,
           replace(upper(btrim(a.postcode)), ' ', '') AS pc_squashed
    FROM raw.address a
),
tidied AS (
    SELECT
        address_id,
        upper(btrim(claimant_ref))                  AS nino,

        ----------------------------------------------------------------
        -- TASK 2 - Tidy the address line and the town   <<< START HERE
        --
        -- LOOK FIRST:
        --   ./explore.sh values raw.address town
        --
        -- Read the summary line it prints BEFORE the list. It tells you
        -- how many values have stray spaces and how many are not in
        -- Title Case.
        --
        -- Same two functions as any other piece of text:
        --   btrim(x)    removes spaces from both ends
        --   initcap(x)  makes it Look Like This
        --
        -- TODO: wrap both lines below in initcap(btrim( ... )).
        --       Leave address_line_2 alone - it is mostly empty and
        --       nothing checks it.
        ----------------------------------------------------------------
        address_line_1                              AS line_1,       -- <<<<<< EDIT THIS LINE
        town                                        AS town,         -- <<<<<< EDIT THIS LINE

        address_line_2                              AS line_2,
        county                                      AS county,

        ----------------------------------------------------------------
        -- TASK 3 - Put ONE space back into the postcode
        --
        -- LOOK FIRST:
        --   ./explore.sh values raw.address postcode
        --
        -- A UK postcode is always "some characters, one space, then
        -- exactly three characters":
        --      SW1A 1AA        M14 5TG        B1 1AA
        --
        -- So the space always goes three characters from the END. That
        -- rule works whatever the postcode looks like, which is why we
        -- squashed them all flat first.
        --
        --   left(text, n)   the first n characters
        --   right(text, n)  the last n characters
        --   length(text)    how long it is
        --   a || b          glues two pieces of text together
        --
        -- TODO: replace  pc_squashed  on the marked line with
        --
        --         left(pc_squashed, length(pc_squashed) - 3)
        --         || ' ' ||
        --         right(pc_squashed, 3)
        --
        -- Leave the CASE around it. Some values are rubbish like 'N/A'
        -- or 'TBC', and taking three characters off something two long
        -- makes no sense. The CASE keeps those out of the way for now -
        -- you deal with them properly in Task 4.
        ----------------------------------------------------------------
        CASE WHEN length(pc_squashed) BETWEEN 5 AND 7
             THEN pc_squashed                                        -- <<<<<< EDIT THIS LINE
        END                                         AS postcode,

        util.to_date(valid_from, 'YYYY-MM-DD')      AS valid_from,
        util.to_date(valid_to,   'YYYY-MM-DD')      AS valid_to
    FROM squashed
),
usable AS (
    ----------------------------------------------------------------
    -- TASK 4 - Throw out the postcodes that are not postcodes
    --
    -- LOOK FIRST:
    --   ./explore.sh values raw.address postcode
    --   The junk is right at the top of that list, because the same
    --   rubbish was typed over and over: 'N/A', 'TBC', 'NOT KNOWN',
    --   '12345', 'SW1A'.
    --
    -- Careful: 'UNKNOWN' and '12345' are both 5-7 characters long, so
    -- Task 3 happily turned them into 'UNKN OWN' and '12 345'. They
    -- look like postcodes now. They are not.
    --
    -- Here is a pattern that matches a real UK postcode. You do not
    -- need to understand it, only use it. The ~ means "matches":
    --
    --     t.postcode ~ '^[A-Z]{1,2}[0-9][A-Z0-9]? [0-9][A-Z]{2}$'
    --
    -- TODO: replace the first condition below with that.
    --
    --
    -- TASK 5 - Throw out addresses belonging to nobody
    --
    -- LOOK FIRST:
    --   ./explore.sh sql "SELECT count(*) FROM raw.address a
    --                     WHERE NOT EXISTS (SELECT 1 FROM raw.claimant c
    --                     WHERE upper(btrim(c.nino)) = upper(btrim(a.claimant_ref)))"
    --
    -- Some addresses quote a National Insurance number that is not in
    -- the claimant table at all. They came from a system that was
    -- switched off and the people were never migrated. An address with
    -- no person attached cannot be used for anything.
    --
    -- TODO: replace the second condition below with
    --
    --     EXISTS (SELECT 1 FROM clean.claimant c WHERE c.nino = t.nino)
    --
    -- "Keep this row only if a matching person exists."
    ----------------------------------------------------------------
    SELECT t.*
    FROM tidied t
    WHERE t.postcode IS NOT NULL                                     -- <<<<<< EDIT THIS LINE
      AND t.nino IS NOT NULL                                         -- <<<<<< EDIT THIS LINE
),
ranked AS (
    ----------------------------------------------------------------
    -- TASK 6 - Which address does the person live at NOW?
    --
    -- LOOK FIRST - the flag cannot be trusted:
    --   ./explore.sh sql "SELECT claimant_ref, address_id, valid_from, is_current
    --                     FROM raw.address WHERE claimant_ref IN (
    --                       SELECT claimant_ref FROM raw.address
    --                       GROUP BY 1 HAVING count(*) > 1)
    --                     ORDER BY claimant_ref, valid_from LIMIT 20"
    --
    -- You will find people with TWO addresses both flagged 'Y', and
    -- people with none flagged at all. That column was filled in by
    -- hand and nobody ever maintained it.
    --
    -- What you CAN trust is valid_from. The address somebody moved to
    -- most recently is the one they live at now.
    --
    -- ROW_NUMBER() does not delete anything. It walks through each
    -- person's addresses and writes 1, 2, 3 into a column called rn.
    -- The ORDER BY decides WHO GETS THE 1.
    --
    -- TODO: change the ORDER BY so the most recent valid_from comes
    --       first, and ties break the same way every time:
    --
    --           ORDER BY valid_from DESC, address_id DESC
    ----------------------------------------------------------------
    SELECT u.*,
           ROW_NUMBER() OVER (PARTITION BY nino
                              ORDER BY address_id) AS rn             -- <<<<<< EDIT THIS LINE
    FROM usable u
)
SELECT address_id, nino, line_1, line_2, town, county, postcode,
       valid_from, valid_to,

       -- THIS is what marks the current address, and it is written for
       -- you. (rn = 1) is a true/false question: "is this row number 1
       -- for this person?" Exactly one row per person can be number 1,
       -- so exactly one comes out true.
       --
       -- It always trusts number 1. Your Task 6 edit decides who
       -- number 1 is.
       (rn = 1) AS is_current
FROM ranked;


-- ===========================================================================
-- BONUS - only once every core test is green
--
-- An analyst has asked a simple question: how many pensioners live in each
-- region of the country? Nobody can answer it from clean.address, because
-- an address holds a postcode, not a region.
--
-- That is what ref.postcode_area is for. It maps the letters at the start
-- of a postcode to a region: SW -> London, M -> North West.
--
-- LOOK FIRST:
--   ./explore.sh sql "SELECT * FROM ref.postcode_area ORDER BY region, area_code"
--
-- This expression pulls the letters off the front of a postcode. You do
-- not have to understand it, just use it:
--
--     substring(postcode from '^[A-Z]{1,2}')
--
-- TODO: build the summary table. Three things to get right:
--         - count each person ONCE, so use only their current address
--         - one row per region
--         - name the columns exactly: region, claimant_count
--
-- Uncomment and finish:
--
-- DROP TABLE IF EXISTS clean.address_summary;
-- CREATE TABLE clean.address_summary AS
-- SELECT r.region,
--        count(*)::int AS claimant_count
-- FROM clean.address a
-- JOIN ref.postcode_area r
--   ON r.area_code = substring(a.postcode from '^[A-Z]{1,2}')
-- WHERE ...          -- TODO: current addresses only
-- GROUP BY ...;      -- TODO
-- ===========================================================================
