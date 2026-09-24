-- ===========================================================================
-- CHALLENGE 1 - TEAM 2 - The Date Disaster
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 1
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: SIX LINES
--
-- Six lines to change. Every one is marked   <<<<<< EDIT THIS LINE
-- Search for EDIT to jump between them.
--
--   Task 1  Read CIS dates                     (done for you - read it)
--   Task 2  Read LEGACY_CSV dates              line  50   <- start here
--   Task 3  Read DIGITAL dates                 line  51
--   Task 4  Read the dates of death            lines 57 and 58
--   Task 5  Throw out impossible deaths        line  81
--   Task 6  Leave out what cannot be rescued   line  89
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
-- It already runs, and Task 1 is already passing. Run ./check.sh 1 now,
-- before changing anything, so you can see where you are starting from.
-- ===========================================================================

TRUNCATE clean.claim;
TRUNCATE clean.claimant;


INSERT INTO clean.claimant (nino, title, first_name, last_name, date_of_birth,
                            sex, marital_status, date_of_death, email, phone)
WITH parsed AS (
    SELECT

        -- TASKS 1, 2 and 3 - Read each system's dates        <<< START HERE
        -- Task 1 (CIS) is done and its test passes. Change only the text
        -- inside the quotes on the other two.
        CASE source_system
            WHEN 'CIS'        THEN util.to_date(date_of_birth, 'YYYY-MM-DD')
            WHEN 'LEGACY_CSV' THEN util.to_date(date_of_birth, 'YYYY-MM-DD')  -- <<<<<< EDIT THIS LINE
            WHEN 'DIGITAL'    THEN util.to_date(date_of_birth, 'YYYY-MM-DD')  -- <<<<<< EDIT THIS LINE
        END                                                    AS dob,

        -- TASK 4 - Dates of death, written the same three ways
        CASE source_system
            WHEN 'CIS'        THEN util.to_date(date_of_death, 'YYYY-MM-DD')
            WHEN 'LEGACY_CSV' THEN util.to_date(date_of_death, 'YYYY-MM-DD')  -- <<<<<< EDIT THIS LINE
            WHEN 'DIGITAL'    THEN util.to_date(date_of_death, 'YYYY-MM-DD')  -- <<<<<< EDIT THIS LINE
        END                                                    AS dod,

        -- Nothing to do on these. They are already fine.
        upper(btrim(nino))                                     AS nino,
        replace(initcap(btrim(title)), '.', '')                AS title,
        initcap(btrim(first_name))                             AS first_name,
        initcap(btrim(last_name))                              AS last_name,
        upper(btrim(sex))                                      AS sex,
        CASE WHEN btrim(coalesce(marital_status, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')
             THEN NULL ELSE initcap(btrim(marital_status)) END AS marital_status,
        CASE WHEN btrim(coalesce(email, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')
             THEN NULL ELSE lower(btrim(email)) END            AS email,
        CASE WHEN btrim(coalesce(phone, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')
             THEN NULL ELSE replace(btrim(phone), ' ', '') END AS phone

    FROM raw.claimant
)
SELECT
    nino, title, first_name, last_name, dob, sex, marital_status,

    -- TASK 5 - Impossible deaths. Some are before the birth date, some
    --          are in 2029. Both are errors, not deaths.
    dod,                                                          -- <<<<<< EDIT THIS LINE

    email, phone
FROM parsed

-- TASK 6 - Leave out the birth dates that cannot be rescued.
--          This keeps every row that produced a date at all, which is
--          not enough: 1900-01-01 is a valid date but not a birthday.
WHERE dob IS NOT NULL                                             -- <<<<<< EDIT THIS LINE
;


-- ===========================================================================
-- BONUS - only once every core test is green.
-- Two of them. BRIEF.md lists what they are; hints.md tells you how.
-- ===========================================================================