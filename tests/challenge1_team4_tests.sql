-- ---------------------------------------------------------------------------
-- CHALLENGE 1 - TEAM 4 - The Money Problem
-- Goal: money stored as numbers, and every payment counted once.
--
-- YOU DO NOT NEED TO READ THIS FILE.
--
-- It is the machinery that marks your work, and it is written for the
-- database rather than for a person. The readable version is the
-- scorecard it produces:
--
--     ./check.sh 1
--
-- That prints every check in plain English, what the right answer is,
-- what your SQL produced, and which task to look at. That scorecard is
-- your specification - you were given it at the start on purpose. If you
-- can make it all say PASS, you have done the job.
--
-- Reading a failure:
--   'expected' is the right answer. 'you got' is what your SQL produced.
--   'ERROR: ...' means that one check could not run - usually a table
--   that does not exist yet, or a misspelled column. The others still ran.
--
-- (Curious how it works? Read on. Nothing here is a secret. But nothing
--  here is required either.)
-- ---------------------------------------------------------------------------

SELECT test.reset();

SELECT test.check('C4.01', 'core', '1 and 2', $n$Every claim came through, each with a readable weekly amount$n$, $e$1200$e$,
    $q$SELECT count(*)::text FROM clean.claim WHERE weekly_amount IS NOT NULL$q$,
    $h$Every claim should make it through, and every one needs a number.$h$);
SELECT test.check('C4.02', 'core', '1 and 2', $n$Weekly amounts are sensible numbers$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claim WHERE weekly_amount IS NULL OR weekly_amount <= 0 OR weekly_amount > 300$q$,
    $h$A stray comma turns 185.15 into something odd.$h$);
SELECT test.check('C4.03', 'core', '1 and 2', $n$The weekly amounts add up to 167245.75$n$, $e$167245.75$e$,
    $q$SELECT to_char(sum(weekly_amount), 'FM99999999990.00') FROM clean.claim$q$,
    $h$If this is out, a pound sign or comma got through.$h$);
SELECT test.check('C4.04', 'core', '5 and 6', $n$Failed and pending payments were left out$n$, $e$8445$e$,
    $q$SELECT count(*)::text FROM clean.payment$q$,
    $h$260 FAILED and 90 PENDING must go, and 200 double-postings.$h$);
SELECT test.check('C4.05', 'core', '6', $n$No payment was entered twice$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM ( SELECT claim_ref, payment_date, amount FROM clean.payment GROUP BY 1, 2, 3 HAVING count(*) > 1 ) d$q$,
    $h$Same claim, same date, same amount = entered twice.$h$);
SELECT test.check('C4.06', 'core', '6', $n$Reversals were KEPT, not deleted (120 of them)$n$, $e$120$e$,
    $q$SELECT count(*)::text FROM clean.payment WHERE amount < 0$q$,
    $h$A reversal is a real payment. Do not remove it as a duplicate.$h$);
SELECT test.check('C4.07', 'core', '3', $n$Total value paid out is 4612417.76$n$, $e$4612417.76$e$,
    $q$SELECT to_char(sum(amount), 'FM99999999990.00') FROM clean.payment WHERE amount > 0$q$,
    $h$Parse the amounts before adding them up.$h$);
SELECT test.check('C4.08', 'core', '6', $n$Net total after reversals is 4547528.85$n$, $e$4547528.85$e$,
    $q$SELECT to_char(sum(amount), 'FM99999999990.00') FROM clean.payment$q$,
    $h$Should be the total paid out minus the reversals.$h$);
SELECT test.check('C4.B1', 'bonus', NULL, $n$clean.claim_payment_summary has one row per claim$n$, $e$1200$e$,
    $q$SELECT count(*)::text FROM clean.claim_payment_summary$q$,
    $h$Bonus. Build the table first - see the bottom of your file.$h$);
SELECT test.check('C4.B2', 'bonus', NULL, $n$The summary accounts for all 8445 payments$n$, $e$8445$e$,
    $q$SELECT coalesce(sum(payment_count)::text, '0') FROM clean.claim_payment_summary$q$,
    $h$Bonus. Every payment belongs to exactly one claim.$h$);
SELECT test.check('C4.B3', 'bonus', NULL, $n$The summary totals to 4547528.85, the net figure$n$, $e$4547528.85$e$,
    $q$SELECT to_char(sum(total_paid), 'FM99999999990.00') FROM clean.claim_payment_summary$q$,
    $h$Bonus. Reversals are negative, so they pull the total down.$h$);
