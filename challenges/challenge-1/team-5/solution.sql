-- ===========================================================================
-- CHALLENGE 1 - TEAM 5 - The Code Chaos
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 1
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: SIX LINES
--
-- Six lines to change. Every one is marked   <<<<<< EDIT THIS LINE
-- Search for EDIT to jump between them.
--
--   Task 1  Claim status          (done for you - READ IT, it is the pattern)
--   Task 2  Pension type                        line 90   <- start here
--   Task 3  The deferral yes/no flag            line 98
--   Task 4  How often they get paid             line 101
--   Task 5  Claims for people who do not exist  line 105
--   Task 6  Payment methods, via the lookup     line 119
--   Task 7  Payments for claims that are gone   line 128
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

TRUNCATE clean.payment;
TRUNCATE clean.claim;
TRUNCATE clean.claimant;


-- Load the people. Written for you: leave it alone.
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

    -- TASK 1 - READ THIS ONE. It is the pattern for Tasks 2 and 4.
    -- Thirteen spellings, three meanings. upper(btrim(x)) on the front so
    -- you list each spelling once. Anything unlisted comes out NULL, which
    -- is deliberate: a NULL is visible and countable.
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

    -- TASK 2 - Pension type: two schemes, one answer   <<< START HERE
    upper(btrim(c.pension_type)),                                     -- <<<<<< EDIT THIS LINE

    util.to_date(c.claim_start_date, 'YYYY-MM-DD'),
    util.to_number(c.qualifying_years)::int,
    util.to_number(c.weekly_amount),

    -- TASK 3 - A yes/no flag with eleven spellings. Needs true/false,
    --          not text. A comparison is already true or false.
    false,                                                            -- <<<<<< EDIT THIS LINE

    -- TASK 4 - How often they get paid. Same shape as Task 1.
    upper(btrim(c.payment_frequency))                                 -- <<<<<< EDIT THIS LINE

FROM raw.claim c
-- TASK 5 - Claims for people who do not exist. This keeps everything.
WHERE c.claim_ref IS NOT NULL                                         -- <<<<<< EDIT THIS LINE
;


INSERT INTO clean.payment (payment_id, claim_ref, payment_date, amount,
                           payment_method, payment_status)
SELECT
    p.payment_id,
    p.claim_ref,
    util.to_date(p.payment_date, 'YYYY-MM-DD'),
    util.to_number(p.amount),

    -- TASK 6 - Payment methods via the lookup. The LEFT JOIN below brings
    --          the mapping in; for unmatched rows it is NULL.
    m.standard_value,                                                 -- <<<<<< EDIT THIS LINE

    CASE WHEN upper(btrim(p.payment_status)) IN ('SETTLED', 'S') THEN 'SETTLED'
         ELSE 'REVERSED' END
FROM raw.payment p
LEFT JOIN ref.code_mapping m
       ON m.domain = 'payment_method'
      AND m.raw_value = p.payment_method
-- TASK 7 - Payments for claims that are not there. This keeps everything.
WHERE p.payment_id IS NOT NULL                                        -- <<<<<< EDIT THIS LINE
;


-- ===========================================================================
-- BONUS - only once every core test is green.
-- Three of them. BRIEF.md lists what they are; hints.md tells you how.
-- ===========================================================================