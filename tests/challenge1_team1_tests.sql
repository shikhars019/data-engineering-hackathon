-- ---------------------------------------------------------------------------
-- CHALLENGE 1 - TEAM 1 - The Duplicate Claimants
-- Goal: one row per real person in clean.claimant.
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

SELECT test.check('C1.01', 'core', '5', $n$clean.claimant has one row for each real person$n$, $e$1200$e$,
    $q$SELECT count(*)::text FROM clean.claimant$q$,
    $h$Are you inserting anything at all?$h$);
SELECT test.check('C1.02', 'core', '5', $n$Nobody was lost - everyone in raw is in clean$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM ( SELECT DISTINCT upper(replace(replace(btrim(nino), ' ', ''), '-', '')) AS n FROM raw.claimant ) r LEFT JOIN clean.claimant c ON c.nino = r.n WHERE c.nino IS NULL$q$,
    $h$De-duplicating must not throw whole people away.$h$);
SELECT test.check('C1.03', 'core', '5', $n$1500 raw records became 1200 people$n$, $e$1500 -> 1200$e$,
    $q$SELECT (SELECT count(*) FROM raw.claimant)::text || ' -> ' || (SELECT count(*) FROM clean.claimant)::text$q$,
    $h$Too many rows means duplicates survived.$h$);
SELECT test.check('C1.04', 'core', '3', $n$Every NINO is 2 letters, 6 digits and 1 letter$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claimant WHERE nino !~ '^[A-Z]{2}[0-9]{6}[A-Z]$'$q$,
    $h$'qq 12 34 56 c' and 'QQ-12-34-56-C' are the same person.$h$);
SELECT test.check('C1.05', 'core', '1', $n$Names have no leading or trailing spaces$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claimant WHERE first_name <> btrim(first_name) OR last_name <> btrim(last_name)$q$,
    $h$Use btrim() (also called trim).$h$);
SELECT test.check('C1.06', 'core', '1', $n$Names are Title Case, not SHOUTING or lower case$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claimant WHERE first_name <> initcap(first_name) OR last_name <> initcap(last_name)$q$,
    $h$Use initcap() after trimming.$h$);
SELECT test.check('C1.07', 'core', '2', $n$Placeholder text like N/A and UNKNOWN is gone$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claimant WHERE btrim(coalesce(email,'x')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-') OR btrim(coalesce(phone,'x')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-') OR btrim(coalesce(marital_status,'x')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')$q$,
    $h$'N/A' is not a value - it should be NULL.$h$);
SELECT test.check('C1.08', 'core', '5', $n$Survivorship: the newest record won (person A)$n$, $e$derek469@webmail.invalid$e$,
    $q$SELECT coalesce(lower(email), '<no email>') FROM clean.claimant WHERE nino = 'QQ209469B'$q$,
    $h$QQ209469B has 3 records, each with a different email.$h$);
SELECT test.check('C1.09', 'core', '5', $n$Survivorship: the newest record won (person B)$n$, $e$colin534@webmail.invalid$e$,
    $q$SELECT coalesce(lower(email), '<no email>') FROM clean.claimant WHERE nino = 'QQ124534B'$q$,
    $h$Order by ingested_at, newest first.$h$);
SELECT test.check('C1.B1', 'bonus', NULL, $n$Titles tidied to Mr / Mrs / Ms / Miss$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claimant WHERE title IS NULL OR title NOT IN ('Mr','Mrs','Ms','Miss')$q$,
    $h$Bonus A. Watch out for 'MR.' and 'mr'.$h$);
SELECT test.check('C1.B2', 'bonus', NULL, $n$Best available email recovered from all of a person's records$n$, $e$105$e$,
    $q$SELECT count(*)::text FROM clean.claimant WHERE email IS NULL$q$,
    $h$Bonus B. If the newest record has no email, look at the older ones.$h$);
SELECT test.check('C1.B3', 'bonus', NULL, $n$Phone numbers stored as 11 digits, no spaces$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claimant WHERE phone IS NOT NULL AND phone !~ '^0[0-9]{10}$'$q$,
    $h$Bonus C. Strip the spaces out of the phone number.$h$);
