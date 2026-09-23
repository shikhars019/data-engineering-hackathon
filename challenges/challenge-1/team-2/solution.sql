-- ===========================================================================
-- CHALLENGE 1 - TEAM 2 - The Date Disaster
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
--   Task 1  Read CIS dates                     (done for you - read it)
--   Task 2  Read LEGACY_CSV dates              line  76   <- start here
--   Task 3  Read DIGITAL dates                 line  77
--   Task 4  Read the dates of death            lines 92 and 93
--   Task 5  Throw out impossible deaths        line  142
--   Task 6  Leave out what cannot be rescued   line  171
--
-- The tasks appear below in that order. Do them in that order.
--
-- It already runs, and Task 1 is already passing. Run ./check.sh 1 now,
-- before changing anything, so you can see where you are starting from.
--
-- THE BIG IDEA: three source systems write dates three different ways.
-- '06/05/1955' is the 6th of May to a British system and the 5th of June
-- to an American one. You cannot guess - you have to know which system
-- sent the row. That is what the source_system column is for.
-- ===========================================================================

TRUNCATE clean.claim;
TRUNCATE clean.claimant;


INSERT INTO clean.claimant (nino, title, first_name, last_name, date_of_birth,
                            sex, marital_status, date_of_death, email, phone)
WITH parsed AS (
    SELECT

        ----------------------------------------------------------------
        -- TASKS 1, 2 and 3 - Read each system's dates    <<< START HERE
        --
        -- LOOK FIRST:
        --   ./explore.sh sql "SELECT DISTINCT ON (source_system)
        --                            source_system, date_of_birth, date_of_death
        --                     FROM raw.claimant ORDER BY source_system, random()"
        --
        --   DISTINCT ON gives you one example row per system, which is
        --   exactly what you need. (A plain LIMIT 30 would show you thirty
        --   rows from whichever system sorts first, and you would never
        --   discover the other two formats.)
        --
        -- You should see three completely different styles:
        --   CIS         1955-08-31     year, month, day
        --   LEGACY_CSV  06/05/1955     day/month/year   (British order!)
        --   DIGITAL     12-Jul-1948    day-monthname-year
        --
        -- util.to_date(text, format) turns text into a real date. If the
        -- text does not match the format you give it, you get NULL rather
        -- than an error - so a wrong format shows up as a missing date,
        -- not a crash. An empty column means your format is wrong.
        --
        -- Format letters:  YYYY = 4-digit year   MM = month number
        --                  DD   = day            Mon = Jan, Feb, Mar ...
        --
        -- Task 1 (CIS) is done, and its test already passes. Copy the
        -- shape of it. You are changing ONLY the text inside the quotes.
        ----------------------------------------------------------------
        CASE source_system
            WHEN 'CIS'        THEN util.to_date(date_of_birth, 'YYYY-MM-DD')
            WHEN 'LEGACY_CSV' THEN util.to_date(date_of_birth, 'YYYY-MM-DD')  -- <<<<<< EDIT THIS LINE
            WHEN 'DIGITAL'    THEN util.to_date(date_of_birth, 'YYYY-MM-DD')  -- <<<<<< EDIT THIS LINE
        END                                                    AS dob,


        ----------------------------------------------------------------
        -- TASK 4 - Dates of death, written the same three ways
        --
        -- Exactly the same problem, same three formats. Once Tasks 2 and
        -- 3 work, put the same two format strings here.
        --
        -- Most people are alive, so most of these are blank. That is
        -- fine - util.to_date gives NULL for a blank.
        ----------------------------------------------------------------
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

    ----------------------------------------------------------------
    -- TASK 5 - Impossible deaths
    --
    -- LOOK FIRST:
    --   ./explore.sh sql "SELECT nino, date_of_birth, date_of_death, source_system
    --                     FROM raw.claimant WHERE date_of_death LIKE '%2029%' LIMIT 10"
    --
    -- Some records say the person died BEFORE they were born. Others say
    -- they died in 2029, which has not happened yet. Both are data entry
    -- errors, not deaths.
    --
    -- A wrong date is worse than a missing one. A missing date is
    -- obviously missing. A wrong one gets used.
    --
    -- Today, for this whole exercise, is always DATE '2026-04-06'.
    --
    -- TODO: replace  dod  below with a CASE that gives NULL when
    --         - dod is on or before dob, or
    --         - dod is after 2026-04-06
    --       and otherwise gives dod. Like this:
    --
    --         CASE WHEN dod IS NULL             THEN NULL
    --              WHEN dod <= dob              THEN NULL
    --              WHEN dod > DATE '2026-04-06' THEN NULL
    --              ELSE dod
    --         END
    ----------------------------------------------------------------
    dod,                                                          -- <<<<<< EDIT THIS LINE

    email, phone
FROM parsed

----------------------------------------------------------------
-- TASK 6 - Leave out what cannot be rescued
--
-- LOOK FIRST - how many are beyond saving?
--   ./explore.sh values raw.claimant date_of_birth
--   (read the summary line at the top, not the list)
--
-- Three kinds of unusable birth date:
--   '1900-01-01'  a placeholder the old systems used for "no idea"
--   '9999-12-31'  another placeholder, meaning "never" or "unknown"
--   '' 'N/A'      blank, and a date in 2031 where somebody mistyped
--
-- None can be repaired, and a guess would be worse than nothing. Leave
-- them out. A State Pension claimant in 2026 was born between about
-- 1930 and 1961; anything outside that is wrong.
--
-- The line below keeps every row that produced a date at all. That is
-- not enough - 1900-01-01 is a perfectly valid date, it is just not a
-- real birthday.
--
-- TODO: add the two range conditions:
--         AND dob >= DATE '1930-01-01'
--         AND dob <= DATE '2026-04-06'
----------------------------------------------------------------
WHERE dob IS NOT NULL                                             -- <<<<<< EDIT THIS LINE
;


-- ===========================================================================
-- BONUS - only once every core test is green
-- ===========================================================================
--
-- BONUS A - clean.claim has exactly the same problem: claim start dates
--   in the same three styles. The twist is that raw.claim has no
--   source_system column, so you have to join back to raw.claimant to
--   find out which system the person came from.
--
--   Uncomment and finish this:
--
-- INSERT INTO clean.claim (claim_ref, nino, claim_status, pension_type,
--                          claim_start_date, qualifying_years, weekly_amount,
--                          deferral_indicator, payment_frequency)
-- SELECT c.claim_ref,
--        c.claimant_ref,
--        c.claim_status,
--        c.pension_type,
--        CASE r.source_system
--            WHEN 'CIS' THEN util.to_date(c.claim_start_date, 'YYYY-MM-DD')
--            -- TODO the other two
--        END,
--        util.to_number(c.qualifying_years)::int,
--        util.to_number(c.weekly_amount),
--        upper(btrim(c.deferral_indicator)) IN ('Y','YES','TRUE','T','1'),
--        c.payment_frequency
-- FROM raw.claim c
-- JOIN raw.claimant   r  ON upper(btrim(r.nino)) = upper(btrim(c.claimant_ref))
-- JOIN clean.claimant cc ON cc.nino              = upper(btrim(c.claimant_ref));
--
-- BONUS B - Nobody can claim a State Pension before they turn 66. Once
--   Bonus A works, the last test checks that no claim starts too early.
-- ===========================================================================
