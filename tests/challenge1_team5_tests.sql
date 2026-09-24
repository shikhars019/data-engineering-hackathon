-- ---------------------------------------------------------------------------
-- CHALLENGE 1 - TEAM 5 - The Code Chaos
-- Goal: one agreed code for each thing, and no orphan records.
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

SELECT test.check('C5.01', 'core', '5', $n$clean.claim excludes claims for people who do not exist$n$, $e$1200$e$,
    $q$SELECT count(*)::text FROM clean.claim$q$,
    $h$30 of the 1230 raw claims are orphans.$h$);
SELECT test.check('C5.02', 'core', '5 and 7', $n$No orphans left: every claim has a person, every payment has a claim$n$, $e$0$e$,
    $q$SELECT ((SELECT count(*) FROM clean.claim c LEFT JOIN clean.claimant p ON p.nino = c.nino WHERE p.nino IS NULL) + (SELECT count(*) FROM clean.payment pm LEFT JOIN clean.claim c ON c.claim_ref = pm.claim_ref WHERE c.claim_ref IS NULL))::text$q$,
    $h$A claim with no claimant cannot be paid, and a payment with no claim cannot be explained.$h$);
SELECT test.check('C5.03', 'core', '5', $n$978 claims are ACTIVE$n$, $e$978$e$,
    $q$SELECT count(*)::text FROM clean.claim WHERE claim_status = 'ACTIVE'$q$,
    $h$Task 1 already maps 'A', 'LIVE' and 'In Payment'. If the number is too high, the orphan claims are still in there.$h$);
SELECT test.check('C5.04', 'core', '5', $n$153 claims are CLOSED$n$, $e$153$e$,
    $q$SELECT count(*)::text FROM clean.claim WHERE claim_status = 'CLOSED'$q$,
    $h$Task 1 already maps 'C', 'Ceased' and 'Terminated'. Anything over the target is an orphan claim that has not been dropped yet.$h$);
SELECT test.check('C5.05', 'core', '2', $n$Every claim uses one of the two standard pension types$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claim WHERE pension_type IS NULL OR pension_type NOT IN ('NEW_STATE_PENSION','BASIC_STATE_PENSION')$q$,
    $h$Category A and Category B are both BASIC_STATE_PENSION.$h$);
SELECT test.check('C5.06', 'core', '2 and 5', $n$642 claims are New State Pension$n$, $e$642$e$,
    $q$SELECT count(*)::text FROM clean.claim WHERE pension_type = 'NEW_STATE_PENSION'$q$,
    $h$'nSP', 'NEW' and 'Single Tier' all mean the same thing. The orphan claims count towards this too until Task 5 removes them.$h$);
SELECT test.check('C5.07', 'core', '3', $n$143 claims are marked as deferred$n$, $e$143$e$,
    $q$SELECT count(*)::text FROM clean.claim WHERE deferral_indicator IS TRUE$q$,
    $h$'Y', 'YES', 'TRUE', 'T' and '1' all mean yes.$h$);
SELECT test.check('C5.08', 'core', '7', $n$clean.payment excludes payments for claims that do not exist$n$, $e$8204$e$,
    $q$SELECT count(*)::text FROM clean.payment$q$,
    $h$45 payments point at a claim that is not there.$h$);
SELECT test.check('C5.09', 'core', '6', $n$Methods missing from ref.code_mapping became UNKNOWN$n$, $e$1637$e$,
    $q$SELECT count(*)::text FROM clean.payment WHERE payment_method = 'UNKNOWN'$q$,
    $h$ref.code_mapping is incomplete. Do not lose those rows.$h$);
SELECT test.check('C5.B1', 'bonus', NULL, $n$69 claims are SUSPENDED$n$, $e$69$e$,
    $q$SELECT count(*)::text FROM clean.claim WHERE claim_status = 'SUSPENDED'$q$,
    $h$Bonus A. Task 1 maps the spellings; Task 5 removes the orphans that are padding the number out.$h$);
SELECT test.check('C5.B2', 'bonus', NULL, $n$713 claims are paid four-weekly$n$, $e$713$e$,
    $q$SELECT count(*)::text FROM clean.claim WHERE payment_frequency = 'FOUR_WEEKLY'$q$,
    $h$Bonus B. '4W', '4', 'FOUR WEEKLY' and '4-Weekly' are the same - and Task 5 has to have removed the orphans.$h$);
SELECT test.check('C5.B3', 'bonus', NULL, $n$No payment method was left empty$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.payment WHERE payment_method IS NULL$q$,
    $h$Bonus C. Unmapped is not the same as missing - use UNKNOWN.$h$);
