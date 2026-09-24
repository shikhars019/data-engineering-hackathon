-- ===========================================================================
-- CHALLENGE 1 - TEAM 3 - The Address Mess
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 1
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: SIX LINES
--
-- Six lines to change. Every one is marked   <<<<<< EDIT THIS LINE
-- Search for EDIT to jump between them.
--
--   Task 1  Load the people                    (done for you - leave it)
--   Task 2  Tidy the address lines and town    lines 75 and 76  <- start here
--   Task 3  Put ONE space back in the postcode line  84
--   Task 4  Throw out the fake postcodes       line  97
--   Task 5  Throw out addresses with no person line  98
--   Task 6  Which address do they live at NOW  line  106
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

TRUNCATE clean.address;
TRUNCATE clean.claimant;


-- TASK 1 - Load the people. Written for you: leave it alone.
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
    -- Given to you. Every postcode with ALL its spaces removed and put into
    -- capitals, so you never have to care how many spaces there were.
    SELECT a.*,
           replace(upper(btrim(a.postcode)), ' ', '') AS pc_squashed
    FROM raw.address a
),
tidied AS (
    SELECT
        address_id,
        upper(btrim(claimant_ref))                  AS nino,

        -- TASK 2 - Tidy the address line and the town       <<< START HERE
        address_line_1                              AS line_1,       -- <<<<<< EDIT THIS LINE
        town                                        AS town,         -- <<<<<< EDIT THIS LINE

        address_line_2                              AS line_2,
        county                                      AS county,

        -- TASK 3 - Put ONE space back into the postcode.
        --          Leave the CASE around it.
        CASE WHEN length(pc_squashed) BETWEEN 5 AND 7
             THEN pc_squashed                                        -- <<<<<< EDIT THIS LINE
        END                                         AS postcode,

        util.to_date(valid_from, 'YYYY-MM-DD')      AS valid_from,
        util.to_date(valid_to,   'YYYY-MM-DD')      AS valid_to
    FROM squashed
),
usable AS (
    -- TASK 4 - Throw out the postcodes that are not postcodes  (first line)
    -- TASK 5 - Throw out addresses belonging to nobody         (second line)
    -- Both conditions below keep everything as they stand.
    SELECT t.*
    FROM tidied t
    WHERE t.postcode IS NOT NULL                                     -- <<<<<< EDIT THIS LINE
      AND t.nino IS NOT NULL                                         -- <<<<<< EDIT THIS LINE
),
ranked AS (
    -- TASK 6 - Which address does the person live at NOW?
    --          Do not trust is_current. ROW_NUMBER() numbers each
    --          person's addresses; the ORDER BY decides who gets the 1.
    SELECT u.*,
           ROW_NUMBER() OVER (PARTITION BY nino
                              ORDER BY address_id) AS rn             -- <<<<<< EDIT THIS LINE
    FROM usable u
)
SELECT address_id, nino, line_1, line_2, town, county, postcode,
       valid_from, valid_to,
       -- Exactly one row per person can be number 1, so exactly one comes
       -- out true. Already written - do not change it.
       (rn = 1) AS is_current
FROM ranked;


-- ===========================================================================
-- BONUS - only once every core test is green.
-- Build clean.address_summary. BRIEF.md says what; hints.md says how.
-- ===========================================================================