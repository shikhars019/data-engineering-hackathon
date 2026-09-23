-- ---------------------------------------------------------------------------
-- CHALLENGE 1 - TEAM 3 - The Address Mess
-- Goal: one tidy, valid, current address for every claimant.
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

SELECT test.check('C3.01', 'core', '1', $n$clean.claimant is populated (this part is written for you)$n$, $e$1200$e$,
    $q$SELECT count(*)::text FROM clean.claimant$q$,
    $h$Just run the INSERT that is already in your file.$h$);
SELECT test.check('C3.02', 'core', '4 and 5', $n$clean.address holds only usable addresses$n$, $e$1362$e$,
    $q$SELECT count(*)::text FROM clean.address$q$,
    $h$38 bad postcodes and 25 orphans must go.$h$);
SELECT test.check('C3.03', 'core', '3', $n$Every postcode is a valid UK postcode, tidily formatted$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.address WHERE postcode IS NULL OR postcode !~ '^[A-Z]{1,2}[0-9][A-Z0-9]? [0-9][A-Z]{2}$'$q$,
    $h$'sw1a1aa' should become 'SW1A 1AA'.$h$);
SELECT test.check('C3.04', 'core', '5', $n$Addresses belonging to unknown people were dropped$n$, $e$1200$e$,
    $q$SELECT count(DISTINCT nino)::text FROM clean.address$q$,
    $h$25 addresses point at people who do not exist.$h$);
SELECT test.check('C3.05', 'core', '6', $n$Each claimant has ONE current address, and it is the latest one$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM ( SELECT nino FROM clean.address GROUP BY nino HAVING count(*) FILTER (WHERE is_current) <> 1 OR max(valid_from) FILTER (WHERE is_current) IS DISTINCT FROM max(valid_from) ) bad$q$,
    $h$Do not trust is_current - the latest valid_from wins.$h$);
SELECT test.check('C3.06', 'core', '4', $n$Nobody was left without an address$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.claimant c LEFT JOIN clean.address a ON a.nino = c.nino WHERE a.nino IS NULL$q$,
    $h$Only ever drop an address the person is no longer at.$h$);
SELECT test.check('C3.07', 'core', '2', $n$Town names are tidy$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM clean.address WHERE town <> initcap(btrim(town))$q$,
    $h$btrim() then initcap().$h$);
SELECT test.check('C3.08', 'core', '6', $n$A known claimant's current postcode is correct$n$, $e$EH12 4WJ$e$,
    $q$SELECT coalesce(max(postcode), '<missing>') FROM clean.address WHERE nino = 'QQ213762A' AND is_current$q$,
    $h$Check you picked the newest address for this person.$h$);
SELECT test.check('C3.B1', 'bonus', NULL, $n$clean.address_summary has one row per region$n$, $e$12$e$,
    $q$SELECT count(*)::text FROM clean.address_summary$q$,
    $h$Bonus. Build the table first - see the bottom of your file.$h$);
SELECT test.check('C3.B2', 'bonus', NULL, $n$The summary says 94 claimants live in London$n$, $e$94$e$,
    $q$SELECT coalesce(max(claimant_count)::text, '<no row>') FROM clean.address_summary WHERE region = 'London'$q$,
    $h$Bonus. Join through ref.postcode_area to get the region.$h$);
SELECT test.check('C3.B3', 'bonus', NULL, $n$The summary accounts for all 1200 claimants$n$, $e$1200$e$,
    $q$SELECT coalesce(sum(claimant_count)::text, '0') FROM clean.address_summary$q$,
    $h$Bonus. Count current addresses only, or you will double-count movers.$h$);
