-- ===========================================================================
-- CHALLENGE 1 - TEAM 5 - The Code Chaos
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
--   Task 1  Claim status          (done for you - READ IT, it is the pattern)
--   Task 2  Pension type                        line 139   <- start here
--   Task 3  The deferral yes/no flag            line 167
--   Task 4  How often they get paid             line 183
--   Task 5  Claims for people who do not exist  line 206
--   Task 6  Payment methods, via the lookup     line 243
--   Task 7  Payments for claims that are gone   line 265
--
-- The tasks appear below in that order. Do them in that order.
--
-- It already runs, and Task 1 is already passing. Run ./check.sh 1 now,
-- before changing anything, so you can see where you are starting from.
--
-- THE BIG IDEA: nobody can count anything until everyone agrees on the
-- words. 'ACTIVE', 'A', 'LIVE', 'In Payment' and 'INPAY' are five ways of
-- saying one thing. Until that is fixed, "how many people are being paid?"
-- has five different answers - and the agency reports that number to Parliament.
-- ===========================================================================

TRUNCATE clean.payment;
TRUNCATE clean.claim;
TRUNCATE clean.claimant;


-- ---------------------------------------------------------------------------
-- Load the people. Written for you: leave it alone.
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


INSERT INTO clean.claim (claim_ref, nino, claim_status, pension_type,
                         claim_start_date, qualifying_years, weekly_amount,
                         deferral_indicator, payment_frequency)
SELECT
    c.claim_ref,
    upper(btrim(c.claimant_ref)),

    ----------------------------------------------------------------
    -- TASK 1 - READ THIS ONE. It is the pattern for everything else.
    --
    -- LOOK FIRST:
    --   ./explore.sh values raw.claim claim_status
    --
    -- Thirteen spellings, three actual meanings. upper(btrim(x)) goes
    -- on the front so you only list each spelling once, instead of
    -- worrying about capitals and stray spaces separately.
    --
    -- Anything NOT listed comes out NULL. That is deliberate: a NULL
    -- is visible and countable, so you can find what you missed.
    --
    -- This one is finished and its test already passes. Study it -
    -- Tasks 2 and 4 are exactly the same shape.
    ----------------------------------------------------------------
    CASE upper(btrim(c.claim_status))
        WHEN 'ACTIVE'     THEN 'ACTIVE'
        WHEN 'A'          THEN 'ACTIVE'
        WHEN 'LIVE'       THEN 'ACTIVE'
        WHEN 'IN PAYMENT' THEN 'ACTIVE'
        WHEN 'INPAY'      THEN 'ACTIVE'
        WHEN 'SUSPENDED'  THEN 'SUSPENDED'
        WHEN 'SUSP'       THEN 'SUSPENDED'
        WHEN 'S'          THEN 'SUSPENDED'
        WHEN 'ON HOLD'    THEN 'SUSPENDED'
        WHEN 'CLOSED'     THEN 'CLOSED'
        WHEN 'C'          THEN 'CLOSED'
        WHEN 'CEASED'     THEN 'CLOSED'
        WHEN 'TERMINATED' THEN 'CLOSED'
    END,

    ----------------------------------------------------------------
    -- TASK 2 - Pension type: two schemes, one answer  <<< START HERE
    --
    -- LOOK FIRST:
    --   ./explore.sh values raw.claim pension_type
    --
    -- Fourteen spellings. This one needs you to THINK, not just type,
    -- because there are TWO different naming schemes in one column,
    -- from two different eras:
    --
    --   the modern names   'New State Pension', 'nSP', 'Single Tier'
    --   the old categories 'Category A', 'CAT A', 'Category B', 'CAT B'
    --
    -- Category A and Category B are legal categories of the OLD
    -- pension, so BOTH become BASIC_STATE_PENSION. Getting that wrong
    -- is easy, and the counts will tell you.
    --
    -- Allowed answers: NEW_STATE_PENSION, BASIC_STATE_PENSION
    --
    -- HOW TO CHECK YOUR OWN WORK - this is the important bit.
    -- Miss one spelling and it silently becomes NULL. Rather than
    -- comparing fourteen values against your CASE by eye, ask the
    -- database which ones you failed to handle. After running this
    -- file, run:
    --
    --   ./explore.sh sql "SELECT DISTINCT r.pension_type AS i_missed_this
    --                     FROM raw.claim r
    --                     JOIN clean.claim c ON c.claim_ref = r.claim_ref
    --                     WHERE c.pension_type IS NULL"
    --
    -- It names exactly the spellings your CASE did not cover. That
    -- trick - an unmapped-value report - is a real data engineering
    -- technique, and it works for Tasks 4 and 6 too.
    --
    -- TODO: replace the line below with a CASE, same shape as Task 1.
    ----------------------------------------------------------------
    upper(btrim(c.pension_type)),                                     -- <<<<<< EDIT THIS LINE

    util.to_date(c.claim_start_date, 'YYYY-MM-DD'),
    util.to_number(c.qualifying_years)::int,
    util.to_number(c.weekly_amount),

    ----------------------------------------------------------------
    -- TASK 3 - A yes/no flag with eleven spellings
    --
    -- LOOK FIRST:
    --   ./explore.sh values raw.claim deferral_indicator
    --
    --   'Y' 'y' 'YES' 'Yes' 'TRUE' 'T' '1'   all mean yes
    --   'N' 'NO' 'FALSE' 'F' '0' and empty   all mean no
    --
    -- The column in clean.claim is a real BOOLEAN, so it needs
    -- true/false, not text. You do NOT need a CASE here - in SQL a
    -- comparison is already true or false:
    --
    --     upper(btrim(x)) IN ('Y','YES','TRUE','T','1')
    --
    -- is itself a true/false value. Watch the empty ones though:
    -- coalesce(x, 'N') turns a missing value into a no.
    --
    -- TODO: replace  false  below with that comparison:
    --
    --   upper(btrim(coalesce(c.deferral_indicator,'N'))) IN ('Y','YES','TRUE','T','1')
    ----------------------------------------------------------------
    false,                                                            -- <<<<<< EDIT THIS LINE

    ----------------------------------------------------------------
    -- TASK 4 - How often they get paid
    --
    -- LOOK FIRST:
    --   ./explore.sh values raw.claim payment_frequency
    --
    -- Allowed answers: WEEKLY, FOUR_WEEKLY, QUARTERLY
    --
    -- Careful: '1', '4' and '13' are in there too. They are the number
    -- of WEEKS BETWEEN payments, not a count of anything.
    --
    -- TODO: replace the line below with a CASE, same shape as Task 1.
    --       Use the unmapped-value query from Task 2 to check yourself.
    ----------------------------------------------------------------
    upper(btrim(c.payment_frequency))                                 -- <<<<<< EDIT THIS LINE

FROM raw.claim c
----------------------------------------------------------------
-- TASK 5 - Claims for people who do not exist
--
-- LOOK FIRST:
--   ./explore.sh sql "SELECT count(*) FROM raw.claim c
--                     WHERE NOT EXISTS (SELECT 1 FROM raw.claimant p
--                     WHERE upper(btrim(p.nino)) = upper(btrim(c.claimant_ref)))"
--
-- Thirty claims quote a National Insurance number that is not in the
-- claimant table at all. They came from a system that was switched off
-- and nobody migrated the people. A claim with no claimant cannot be
-- paid, cannot be reported on, and must not be counted.
--
-- The line below keeps everything. TODO: replace it with
--
--   WHERE EXISTS (SELECT 1 FROM clean.claimant cc
--                 WHERE cc.nino = upper(btrim(c.claimant_ref)))
--
-- "Keep this claim only if a matching person exists."
----------------------------------------------------------------
WHERE c.claim_ref IS NOT NULL                                         -- <<<<<< EDIT THIS LINE
;


INSERT INTO clean.payment (payment_id, claim_ref, payment_date, amount,
                           payment_method, payment_status)
SELECT
    p.payment_id,
    p.claim_ref,
    util.to_date(p.payment_date, 'YYYY-MM-DD'),
    util.to_number(p.amount),

    ----------------------------------------------------------------
    -- TASK 6 - Use the lookup table, and cope when it lets you down
    --
    -- LOOK FIRST - the mapping table:
    --   ./explore.sh sql "SELECT * FROM ref.code_mapping WHERE domain='payment_method'"
    --
    -- LOOK FIRST - what is actually in the data:
    --   ./explore.sh values raw.payment payment_method
    --
    -- Compare the two lists. The mapping table is maintained by another
    -- team and they have not kept up - some spellings in the data are
    -- simply not in it.
    --
    -- The LEFT JOIN at the bottom already brings the mapping in. A
    -- LEFT JOIN keeps every payment even when nothing matches; for
    -- those rows m.standard_value is NULL.
    --
    -- Do NOT drop those rows. A payment you cannot categorise is still
    -- a payment, and losing it makes the totals wrong. Do not leave it
    -- NULL either - then "could not map this" looks identical to
    -- "nothing was here". Mark it UNKNOWN so it stays visible and
    -- somebody can fix the mapping next week.
    --
    -- TODO: wrap the line below in  coalesce( ... , 'UNKNOWN')
    ----------------------------------------------------------------
    m.standard_value,                                                 -- <<<<<< EDIT THIS LINE

    CASE WHEN upper(btrim(p.payment_status)) IN ('SETTLED', 'S') THEN 'SETTLED'
         ELSE 'REVERSED' END
FROM raw.payment p
LEFT JOIN ref.code_mapping m
       ON m.domain = 'payment_method'
      AND m.raw_value = p.payment_method
----------------------------------------------------------------
-- TASK 7 - Payments for claims that are not there
--
-- The same problem one level down. Some payments quote a claim
-- reference that is not in clean.claim.
--
-- Note it must be checked against YOUR cleaned claims, not the raw
-- ones: a payment belonging to one of the orphan claims you removed in
-- Task 5 has just become an orphan itself.
--
-- The line below keeps everything. TODO: replace it with
--
--   WHERE EXISTS (SELECT 1 FROM clean.claim c WHERE c.claim_ref = p.claim_ref)
----------------------------------------------------------------
WHERE p.payment_id IS NOT NULL                                        -- <<<<<< EDIT THIS LINE
;


-- ===========================================================================
-- BONUS - only once every core test is green
-- ===========================================================================
--
-- BONUS A - How many claims are SUSPENDED? If your Task 1 reading was
--   right this should already be correct - a free check that you did not
--   miss a spelling.
--
-- BONUS B - How many claims are paid four-weekly?
--
-- BONUS C - Make sure no payment_method came out NULL. "Not in the
--   mapping table" and "missing" are different things, and only one of
--   them is acceptable.
-- ===========================================================================
