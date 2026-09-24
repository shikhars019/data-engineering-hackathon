-- ---------------------------------------------------------------------------
-- CHALLENGE 2 - Safe Data for Analysts
-- Goal: publish the data with the National Insurance numbers replaced, and
--       the join between the two tables still working.
--
-- YOU DO NOT NEED TO READ THIS FILE.
--
-- It is the machinery that marks your work. The readable version is the
-- scorecard it produces:
--
--     ./check.sh 2
--
-- That prints every check in plain English, what the right answer is, what
-- your SQL produced, and which task to look at.
-- ---------------------------------------------------------------------------

SELECT test.reset();

-- Helper: search every text column in the analytics schema for a pattern.
-- This is how the tests check that no personal data leaked out, wherever
-- you happened to put it.
CREATE OR REPLACE FUNCTION test.scan_analytics(p_pattern TEXT)
RETURNS bigint AS $fn$
DECLARE
    r     RECORD;
    n     bigint;
    total bigint := 0;
BEGIN
    FOR r IN
        SELECT table_name, column_name
        FROM information_schema.columns
        WHERE table_schema = 'analytics'
          AND data_type IN ('text', 'character varying', 'character')
    LOOP
        BEGIN
            EXECUTE format('SELECT count(*) FROM analytics.%I WHERE %I ~ %L',
                           r.table_name, r.column_name, p_pattern)
            INTO n;
            total := total + n;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;
    END LOOP;
    RETURN total;
END;
$fn$ LANGUAGE plpgsql;

SELECT test.check('D.01', 'core', '2', $n$Every person is published, each under a different SALTED pseudonym$n$, $e$1200$e$,
    $q$SELECT count(*)::text FROM ( SELECT DISTINCT a.person_id FROM analytics.claimant_anon a WHERE a.person_id ~ '^[0-9a-f]{32}$' AND a.person_id NOT IN (SELECT md5(c.nino) FROM curated.claimant c) ) x$q$,
    $h$md5(salt || nino), with the salt read from meta.etl_config. A plain md5(nino) is crackable in minutes and does not count.$h$);
SELECT test.check('D.02', 'core', '3', $n$Every payment is published with a pseudonym in place of the NINO$n$, $e$8808$e$,
    $q$SELECT count(*)::text FROM analytics.payment_anon WHERE person_id ~ '^[0-9a-f]{32}$'$q$,
    $h$The payment table is still publishing raw National Insurance numbers.$h$);
SELECT test.check('D.03', 'core', '3 and 5', $n$Nothing in analytics is a National Insurance number, by name or by value$n$, $e$0$e$,
    $q$SELECT ((SELECT count(*) FROM information_schema.columns WHERE table_schema = 'analytics' AND column_name ~* '(nino|national_insurance|full_name|surname|first_name|last_name|email|phone|telephone|date_of_birth|^dob$)') + test.scan_analytics('[A-Z]{2}[0-9]{6}[A-Z]'))::text$q$,
    $h$No column should be called nino, and no value should look like one.$h$);
SELECT test.check('D.04', 'core', '3', $n$THE JOIN STILL WORKS: every payment finds its person$n$, $e$8808$e$,
    $q$SELECT count(*)::text FROM analytics.payment_anon p JOIN analytics.claimant_anon c ON c.person_id = p.person_id$q$,
    $h$Both tables must build the pseudonym exactly the same way, or nothing joins.$h$);
SELECT test.check('D.05', 'core', '3', $n$The joined total still comes to 8932219.75$n$, $e$8932219.75$e$,
    $q$SELECT to_char(sum(p.amount), 'FM99999999990.00') FROM analytics.payment_anon p JOIN analytics.claimant_anon c ON c.person_id = p.person_id$q$,
    $h$If this is short, some payments are not joining to a person.$h$);
SELECT test.check('D.06', 'core', '4', $n$84 people are flagged as deceased$n$, $e$84$e$,
    $q$SELECT count(*)::text FROM analytics.claimant_anon WHERE is_deceased$q$,
    $h$Publish the fact, not the date. is_deceased is true when a date of death exists.$h$);
SELECT test.check('D.B1', 'bonus', NULL, $n$Everybody has an age band$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM analytics.claimant_anon WHERE age_band IS NULL$q$,
    $h$Bonus A. Work the age out against DATE '2026-04-06', not today.$h$);
SELECT test.check('D.B2', 'bonus', NULL, $n$249 people are in the 70-74 band$n$, $e$249$e$,
    $q$SELECT count(*)::text FROM analytics.claimant_anon WHERE age_band = '70-74'$q$,
    $h$Bonus A. Check your band boundaries: 70-74 means 70, 71, 72, 73 and 74.$h$);
SELECT test.check('D.B3', 'bonus', NULL, $n$analytics.payment_summary totals to 8932219.75$n$, $e$8932219.75$e$,
    $q$SELECT to_char(sum(total_paid), 'FM99999999990.00') FROM analytics.payment_summary$q$,
    $h$Bonus B. One row per person, built through the join.$h$);
