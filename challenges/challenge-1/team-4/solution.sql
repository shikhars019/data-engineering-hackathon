-- ===========================================================================
-- CHALLENGE 1 - TEAM 4 - The Money Problem
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 1
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: FIVE LINES
--
-- Most of this file is explanation. The query itself is already written,
-- and you should leave nearly all of it alone.
--
-- There are exactly five lines to change. Every one is marked like this:
--
--        <<<<<< EDIT THIS LINE
--
-- Search for EDIT to jump between them.
--
--   Tasks 1+2  Turn the weekly amount into a number   line 107  <- start here
--   Task 3     Payment amounts: commas and brackets   line 147
--   Task 4     Make bracketed amounts negative        line 167
--   Task 5     Keep only money that actually moved    line 190
--   Task 6     Remove payments entered twice          line 234
--
-- The tasks appear below in that order. DO THEM IN THAT ORDER - parse,
-- then filter, then de-duplicate. A different order gives a different,
-- wrong, answer.
--
-- It already runs. Run ./check.sh 1 now, before changing anything, so you
-- can see where you are starting from.
--
-- THE BIG IDEA: this data decides what lands in a pensioner's bank account.
-- Pay somebody twice and the money is gone. Miss a payment and somebody
-- does not eat. That is why most of your tests are totals: it is not
-- enough for the data to look tidy, you have to prove the numbers add up.
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


-- ---------------------------------------------------------------------------
-- TASKS 1 and 2 - Turn the weekly amount into a number   <<< START HERE
--
-- LOOK FIRST:
--   ./explore.sh values raw.claim weekly_amount
--
-- Every system decorates money differently:
--   '185.15'        fine
--   '£185.15'       currency symbol
--   '  185.15 '     spaces round it
--   '185.15 GBP'    currency spelled out
--
-- A NUMERIC column accepts none of those except the first, so you have to
-- strip the decoration off before converting.
--
--   replace(text, 'x', '')  removes every 'x'
--   util.to_number(text)    text to number, or NULL if it cannot
--
-- util.to_number never crashes your script - it just gives NULL. So if
-- this column comes out empty, there is still decoration left on it.
--
-- replace() calls nest, innermost first:
--   replace(replace(btrim(x), '£', ''), 'GBP', '')
--
-- TODO: on the marked line, strip the '£', the 'GBP', and any spaces,
--       before util.to_number sees it:
--
--         util.to_number(
--             replace(replace(replace(replace(btrim(weekly_amount),
--                 '£', ''), ',', ''), 'GBP', ''), ' ', '')
--         )
-- ---------------------------------------------------------------------------
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

        ----------------------------------------------------------------
        -- TASK 3 - Payments have commas and brackets too
        --
        -- LOOK FIRST:
        --   ./explore.sh sql "SELECT amount, payment_status FROM raw.payment
        --                     WHERE amount LIKE '(%' OR amount LIKE '%,%'
        --                     ORDER BY random() LIMIT 15"
        --
        -- Four-weekly payments run into four figures, so on top of
        -- everything in Task 1 you also get thousands separators:
        --   '1,234.56'   '£1,234.56'   '  2,054.00 '
        --
        -- And some amounts are in brackets: '(185.15)', '(£328.64)'.
        -- Look at the payment_status next to those. In accounting,
        -- brackets mean a NEGATIVE number - money going back the other
        -- way. That matters enormously in Task 6.
        --
        -- TODO: add replace() calls for  '('  ')'  ','  and 'GBP'
        --       so every amount ends up as bare digits and a dot.
        ----------------------------------------------------------------
        replace(replace(btrim(amount), '£', ''), ' ', '') AS digits          -- <<<<<< EDIT THIS LINE

    FROM raw.payment
),
parsed AS (
    ----------------------------------------------------------------
    -- TASK 4 - Make bracketed amounts negative
    --
    -- You stripped the brackets off in Task 3, so '(185.15)' is now
    -- just '185.15'. The minus sign has to be put back.
    --
    -- is_bracketed already tells you which rows those were.
    --
    -- TODO: replace the marked line with
    --
    --     CASE WHEN is_bracketed THEN -util.to_number(digits)
    --          ELSE util.to_number(digits) END AS amount
    ----------------------------------------------------------------
    SELECT
        payment_id, claim_ref, payment_date, payment_method, payment_status,
        util.to_number(digits) AS amount                                     -- <<<<<< EDIT THIS LINE
    FROM stripped
),
kept AS (
    ----------------------------------------------------------------
    -- TASK 5 - Only money that actually moved
    --
    -- LOOK FIRST:
    --   ./explore.sh values raw.payment payment_status
    --
    --   SETTLED   the money arrived
    --   REVERSED  it arrived and was then taken back - still real
    --   FAILED    the bank rejected it. No money moved.
    --   PENDING   has not happened yet.
    --
    -- Counting FAILED payments as real would overstate what the agency has
    -- paid out by hundreds of thousands of pounds.
    --
    -- TODO: replace the marked line with
    --
    --     WHERE payment_status IN ('SETTLED', 'REVERSED')
    ----------------------------------------------------------------
    SELECT * FROM parsed
    WHERE payment_status IS NOT NULL                                         -- <<<<<< EDIT THIS LINE
),
deduped AS (
    ----------------------------------------------------------------
    -- TASK 6 - The same payment entered twice
    --
    -- LOOK FIRST:
    --   ./explore.sh sql "SELECT claim_ref, payment_date, amount, count(*)
    --                     FROM raw.payment GROUP BY 1,2,3
    --                     HAVING count(*) > 1 ORDER BY 4 DESC LIMIT 10"
    --
    -- Some payments were keyed in twice by two different offices. Same
    -- claim, same day, same amount - one real payment.
    --
    -- *** BE CAREFUL HERE ***
    -- A REVERSAL also has the same claim, the same day and the same
    -- value as the payment it cancels - but the OPPOSITE SIGN. It is a
    -- real, separate transaction and it must survive. If you decide two
    -- payments are the same by ignoring the sign, you will delete 120
    -- genuine reversals and your totals will be wrong. A test checks
    -- that all 120 are still there.
    --
    -- The window below is already written and gets this right: it
    -- groups on amount itself, not on how big it is, so +185.15 and
    -- -185.15 land in different groups. Read it and make sure you see
    -- why that saves the reversals.
    ----------------------------------------------------------------
    SELECT k.*,
           ROW_NUMBER() OVER (PARTITION BY claim_ref, payment_date, amount
                              ORDER BY payment_id) AS rn
    FROM kept k
)
SELECT payment_id, claim_ref, payment_date, amount, payment_method, payment_status
FROM deduped

-- THIS is the line that actually removes the duplicates.
-- ROW_NUMBER() above only numbered the rows: 1, 2, 3 within each group
-- of identical payments. Keeping only number 1 keeps one of each and
-- discards the rest.
--
-- Right now it says rn >= 1, which is true for every row - so nothing
-- is removed at all.
--
-- TODO: change  rn >= 1  to  rn = 1
WHERE rn >= 1;                                                               -- <<<<<< EDIT THIS LINE


-- ===========================================================================
-- BONUS - only once every core test is green
--
-- Finance have asked for a statement per claim: how many payments went out
-- against it, and what they came to in total. This is the table that would
-- sit behind "why was I paid this amount?" on a helpline screen.
--
-- Two things make it harder than it looks:
--
--   1. A claim with NO payments must still appear, showing zero. If you
--      use a plain JOIN those claims vanish - and a pensioner who has been
--      missed is exactly the case you most need to see. Use a LEFT JOIN.
--
--   2. Reversals are negative, so a total is not the same as "money sent".
--      Your total should be the NET figure - what the claim actually cost.
--
-- TODO: build the summary table. Name the columns exactly:
--         claim_ref, payment_count, total_paid
--
-- Uncomment and finish:
--
-- DROP TABLE IF EXISTS clean.claim_payment_summary;
-- CREATE TABLE clean.claim_payment_summary AS
-- SELECT c.claim_ref,
--        count(p.payment_id)::int               AS payment_count,
--        coalesce(sum(p.amount), 0)::numeric(12,2) AS total_paid
-- FROM clean.claim c
-- LEFT JOIN clean.payment p ON ...   -- TODO: join them on claim_ref
-- GROUP BY ...;                      -- TODO
--
-- Why coalesce()? sum() of no rows is NULL, not 0. A claim with no
-- payments should read 0.00, not blank.
-- ===========================================================================
