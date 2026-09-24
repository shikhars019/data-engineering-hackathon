-- ===========================================================================
-- CHALLENGE 1 - TEAM 4 - The Money Problem
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 1
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: FIVE LINES
--
-- Five lines to change. Every one is marked   <<<<<< EDIT THIS LINE
-- Search for EDIT to jump between them.
--
--   Tasks 1+2  Turn the weekly amount into a number   line 75  <- start here
--   Task 3     Payment amounts: commas and brackets   line 96
--   Task 4     Make bracketed amounts negative        line 104
--   Task 5     Keep only money that actually moved    line 111
--   Task 6     Remove payments entered twice          line 128
--
-- DO THEM IN THAT ORDER - parse, then filter, then de-duplicate. A
-- different order gives a different, wrong, answer.
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


-- TASKS 1 and 2 - Turn the weekly amount into a number   <<< START HERE
INSERT INTO clean.claim (claim_ref, nino, claim_status, pension_type,
                         claim_start_date, qualifying_years, weekly_amount,
                         deferral_indicator, payment_frequency)
SELECT
    claim_ref,
    upper(btrim(claimant_ref)),
    claim_status,
    pension_type,
    util.to_date(claim_start_date, 'YYYY-MM-DD'),
    util.to_number(qualifying_years)::int,

    util.to_number( btrim(weekly_amount) ),                                -- <<<<<< EDIT THIS LINE

    upper(btrim(deferral_indicator)) IN ('Y', 'YES', 'TRUE', 'T', '1'),
    payment_frequency
FROM raw.claim;


INSERT INTO clean.payment (payment_id, claim_ref, payment_date, amount,
                           payment_method, payment_status)
WITH stripped AS (
    SELECT
        payment_id,
        claim_ref,
        util.to_date(payment_date, 'YYYY-MM-DD') AS payment_date,
        payment_method,
        upper(btrim(payment_status))             AS payment_status,

        -- Given to you: is this amount written in brackets?
        btrim(amount) LIKE '(%'                  AS is_bracketed,

        -- TASK 3 - Payment amounts have commas and brackets too
        replace(replace(btrim(amount), 'GBP', ''), ' ', '') AS digits        -- <<<<<< EDIT THIS LINE

    FROM raw.payment
),
parsed AS (
    -- TASK 4 - Make bracketed amounts negative. is_bracketed tells you which.
    SELECT
        payment_id, claim_ref, payment_date, payment_method, payment_status,
        util.to_number(digits) AS amount                                     -- <<<<<< EDIT THIS LINE
    FROM stripped
),
kept AS (
    -- TASK 5 - Only money that actually moved.
    --          This keeps everything as it stands.
    SELECT * FROM parsed
    WHERE payment_status IS NOT NULL                                         -- <<<<<< EDIT THIS LINE
),
deduped AS (
    -- TASK 6 - The same payment entered twice.
    --
    -- *** BE CAREFUL *** A REVERSAL has the same claim, same day and same
    -- value as the payment it cancels, but the OPPOSITE SIGN. It is real
    -- and must survive. The window below groups on amount itself, not on
    -- how big it is, which is what saves them. Read it and see why.
    SELECT k.*,
           ROW_NUMBER() OVER (PARTITION BY claim_ref, payment_date, amount
                              ORDER BY payment_id) AS rn
    FROM kept k
)
SELECT payment_id, claim_ref, payment_date, amount, payment_method, payment_status
FROM deduped
-- rn >= 1 is true for every row, so nothing is removed yet.
WHERE rn >= 1;                                                               -- <<<<<< EDIT THIS LINE


-- ===========================================================================
-- BONUS - only once every core test is green.
-- Build clean.claim_payment_summary. BRIEF.md says what; hints.md says how.
-- ===========================================================================