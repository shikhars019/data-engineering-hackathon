-- ---------------------------------------------------------------------------
-- CHALLENGE 1 - TEAM 2 - The Date Disaster
-- Goal: every date in clean.claimant is a real, believable date.
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

SELECT test.check('C2.01', 'core', '6', $n$clean.claimant holds only people with a usable date of birth$n$, $e$1116$e$,
    $q$SELECT count(*)::text FROM clean.claimant$q$,
    $h$Records with an unusable date of birth are left out.$h$);
SELECT test.check('C2.02', 'core', '6', $n$1200 raw records became 1116 usable people$n$, $e$1200 -> 1116$e$,
    $q$SELECT (SELECT count(*) FROM raw.claimant)::text || ' -> ' || (SELECT count(*) FROM clean.claimant)::text$q$,
    $h$84 records cannot be saved and must be excluded.$h$);
SELECT test.check('C2.03', 'core', '6', $n$Every date of birth is believable for a pensioner$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claimant WHERE date_of_birth < DATE '1930-01-01' OR date_of_birth > DATE '1961-12-31'$q$,
    $h$1900-01-01 and 9999-12-31 are not real birthdays.$h$);
SELECT test.check('C2.04', 'core', '2', $n$LEGACY_CSV dates read as day/month (06/05/1955 is 1955-05-06)$n$, $e$1955-05-06$e$,
    $q$SELECT coalesce(to_char(date_of_birth, 'YYYY-MM-DD'), '<missing>') FROM clean.claimant WHERE nino = 'QQ543160C'$q$,
    $h$LEGACY_CSV writes DD/MM/YYYY, not MM/DD/YYYY.$h$);
SELECT test.check('C2.05', 'core', '3', $n$DIGITAL dates like 12-Jul-1948 parsed correctly$n$, $e$1948-07-12$e$,
    $q$SELECT coalesce(to_char(date_of_birth, 'YYYY-MM-DD'), '<missing>') FROM clean.claimant WHERE nino = 'QQ267483D'$q$,
    $h$The format string for 12-Jul-1948 is DD-Mon-YYYY.$h$);
SELECT test.check('C2.06', 'core', '1', $n$CIS dates parsed correctly$n$, $e$1955-08-31$e$,
    $q$SELECT coalesce(to_char(date_of_birth, 'YYYY-MM-DD'), '<missing>') FROM clean.claimant WHERE nino = 'QQ270018B'$q$,
    $h$CIS writes YYYY-MM-DD.$h$);
SELECT test.check('C2.07', 'core', '5', $n$Exactly 81 people have really died$n$, $e$81$e$,
    $q$SELECT count(*)::text FROM clean.claimant WHERE date_of_death IS NOT NULL$q$,
    $h$A death before birth, or in 2029, is an error - not a death.$h$);
SELECT test.check('C2.08', 'core', '6', $n$The oldest person was born 1934-04-09$n$, $e$1934-04-09$e$,
    $q$SELECT coalesce(to_char(min(date_of_birth),'YYYY-MM-DD'),'<none>') FROM clean.claimant$q$,
    $h$If this is 1900 you have kept a placeholder date.$h$);
SELECT test.check('C2.B1', 'bonus', NULL, $n$clean.claim is populated with converted start dates$n$, $e$1116$e$,
    $q$SELECT count(*)::text FROM clean.claim$q$,
    $h$Bonus A. Same CASE pattern, applied to raw.claim.$h$);
SELECT test.check('C2.B2', 'bonus', NULL, $n$Claim start dates parsed correctly$n$, $e$2021-05-06$e$,
    $q$SELECT coalesce(to_char(claim_start_date,'YYYY-MM-DD'),'<missing>') FROM clean.claim WHERE claim_ref = 'SP3200003'$q$,
    $h$Bonus A. Join to raw.claimant to find the source system.$h$);
SELECT test.check('C2.B3', 'bonus', NULL, $n$Nobody claimed their pension before turning 66$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claim c JOIN clean.claimant p ON p.nino = c.nino WHERE c.claim_start_date < (p.date_of_birth + INTERVAL '66 years')$q$,
    $h$Bonus B. Needs Bonus A finished first.$h$);
