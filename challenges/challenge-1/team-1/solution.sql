-- ===========================================================================
-- CHALLENGE 1 - TEAM 1 - The Duplicate Claimants
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 1
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: SIX LINES
--
-- Six lines to change. Every one is marked   <<<<<< EDIT THIS LINE
-- Search for EDIT to jump between them.
--
--   Task 1  Tidy the names                     lines 45 and 46   <- start here
--   Task 2  Turn 'N/A' and friends into NULL   lines 54 and 55
--   Task 3  One spelling for the NINO          line  58
--   Task 4  Look at the duplicates             (no edit - just look)
--   Task 5  Decide which record survives       line  81
--
-- BRIEF.md explains what each task means and why it matters. The query
-- below is already written - leave anything that is not marked alone.
--
-- ---------------------------------------------------------------------------
-- STUCK? There is a full walkthrough in hints.md
--
-- It has the queries to run, the explanation for every task, and the SQL
-- you need. Using it is completely fine and nobody is counting.
--
-- Not using it makes for a harder and more satisfying hackathon. Your
-- call - and you can dip in for one task without reading the rest.
-- ---------------------------------------------------------------------------
--
-- It already runs, and every test starts red. Run ./check.sh 1 now,
-- before changing anything, so you can see where you are starting from.
-- ===========================================================================

-- Start from empty every time, so you can run this file as often as you like.
TRUNCATE clean.claimant;


INSERT INTO clean.claimant (nino, title, first_name, last_name, date_of_birth,
                            sex, marital_status, date_of_death, email, phone)
WITH tidied AS (
    SELECT

        -- TASK 1 - Tidy the names                            <<< START HERE
        first_name                                    AS first_name,   -- <<<<<< EDIT THIS LINE
        last_name                                     AS last_name,    -- <<<<<< EDIT THIS LINE

        -- TASK 2 - 'N/A' is not a value.
        -- marital_status is done for you. The other two are yours.
        CASE WHEN btrim(coalesce(marital_status, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')
             THEN NULL
             ELSE initcap(btrim(marital_status))
        END                                           AS marital_status,
        email                                         AS email,        -- <<<<<< EDIT THIS LINE
        phone                                         AS phone,        -- <<<<<< EDIT THIS LINE

        -- TASK 3 - One spelling for each National Insurance number
        upper(btrim(nino))                            AS nino,         -- <<<<<< EDIT THIS LINE

        -- Nothing to do on these. They are already fine.
        record_id,
        ingested_at,
        title,
        util.to_date(date_of_birth, 'YYYY-MM-DD')     AS date_of_birth,
        upper(btrim(sex))                             AS sex,
        util.to_date(date_of_death, 'YYYY-MM-DD')     AS date_of_death

    FROM raw.claimant
),
ranked AS (
    SELECT
        t.*,

        -- TASK 4 - Look at the duplicates before you delete anything.
        --          Nothing to edit here.
        --
        -- TASK 5 - Decide which record survives.
        --          ROW_NUMBER() numbers each person's records 1, 2, 3.
        --          The ORDER BY decides who gets the 1.
        ROW_NUMBER() OVER (PARTITION BY nino
                           ORDER BY record_id)        AS rn             -- <<<<<< EDIT THIS LINE

    FROM tidied t
)
SELECT nino, title, first_name, last_name, date_of_birth, sex, marital_status,
       date_of_death, email, phone
FROM ranked

-- This is the line that actually removes the duplicates: it keeps only
-- number 1 for each person. Already written - do not change it.
WHERE rn = 1;


-- ===========================================================================
-- BONUS - only once every core test is green.
-- Three of them. BRIEF.md lists what they are; hints.md tells you how.
-- ===========================================================================