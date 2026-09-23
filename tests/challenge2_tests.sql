-- ---------------------------------------------------------------------------
-- CHALLENGE 2 - Safe Data for Analysts
-- Goal: publish analytics tables that are useful but cannot identify anyone.
--
-- These tests are your specification. Run them with:   ./check.sh 2
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

SELECT test.check('D.01', 'core', '2', $n$analytics.dim_claimant_anon has one row per person$n$, $e$1468$e$,
    $q$SELECT count(*)::text FROM analytics.dim_claimant_anon$q$,
    $h$Anonymising should not lose anybody.$h$);
SELECT test.check('D.02', 'core', '5', $n$No column in analytics is named after personal data$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM information_schema.columns WHERE table_schema = 'analytics' AND column_name ~* '(nino|national_insurance|surname|first_name|last_name|email|phone|telephone|date_of_birth|^dob$|full_address|address_line|postcode$)'$q$,
    $h$If a column is called 'nino', it should not be here at all.$h$);
SELECT test.check('D.03', 'core', '5', $n$No value anywhere in analytics looks like a NINO$n$, $e$0$e$,
    $q$SELECT test.scan_analytics('[A-Z]{2}[0-9]{6}[A-Z]')::text$q$,
    $h$A renamed column is still a leak. Do not carry the value.$h$);
SELECT test.check('D.04', 'core', '4', $n$No value anywhere in analytics looks like a full postcode$n$, $e$0$e$,
    $q$SELECT test.scan_analytics('[A-Z]{1,2}[0-9][A-Z0-9]? [0-9][A-Z]{2}')::text$q$,
    $h$Publish the area (SW), never the full postcode.$h$);
SELECT test.check('D.05', 'core', '2', $n$Every person has a different pseudonym$n$, $e$1468$e$,
    $q$SELECT count(DISTINCT person_pseudo_id)::text FROM analytics.dim_claimant_anon$q$,
    $h$Two people sharing a pseudonym would corrupt every count.$h$);
SELECT test.check('D.06', 'core', '2', $n$Pseudonyms are 32-character hashes$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM analytics.dim_claimant_anon WHERE person_pseudo_id IS NULL OR person_pseudo_id !~ '^[0-9a-f]{32}$'$q$,
    $h$md5() returns 32 hex characters.$h$);
SELECT test.check('D.07', 'core', '2', $n$The pseudonym is SALTED, not a plain hash of the NINO$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM analytics.dim_claimant_anon d JOIN curated.claimant c ON d.person_pseudo_id = md5(c.nino)$q$,
    $h$Use md5(salt || nino). Read the salt from meta.etl_config.$h$);
SELECT test.check('D.08', 'core', '6', $n$Every claim links back to a person in the dimension$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM analytics.fct_claim_anon f LEFT JOIN analytics.dim_claimant_anon d ON d.person_pseudo_id = f.person_pseudo_id WHERE d.person_pseudo_id IS NULL$q$,
    $h$Pseudonymise consistently or the join breaks.$h$);
SELECT test.check('D.09', 'core', '6', $n$analytics.fct_claim_anon has one row per claim$n$, $e$1468$e$,
    $q$SELECT count(*)::text FROM analytics.fct_claim_anon$q$,
    $h$Build this from curated.claim.$h$);
SELECT test.check('D.10', 'core', '3 and 4', $n$Everyone has a region and an age band$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM analytics.dim_claimant_anon WHERE region IS NULL OR age_band IS NULL$q$,
    $h$A NULL region usually means the join missed.$h$);
SELECT test.check('D.11', 'core', '7', $n$k-anonymity: no group of age band + sex + region is smaller than 5$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM ( SELECT age_band, sex, region FROM analytics.dim_claimant_anon GROUP BY 1, 2, 3 HAVING count(*) < 5 ) too_small$q$,
    $h$Widen your age bands until every group has 5 or more people.$h$);
SELECT test.check('D.12', 'core', '8', $n$The published summary never shows a count of 1 to 4$n$, $e$0$e$,
    $q$SELECT count(*)::text FROM analytics.agg_claims_by_region WHERE claim_count BETWEEN 1 AND 4$q$,
    $h$A count of 2 leaks as badly as a group of 2. Use NULL.$h$);
SELECT test.check('D.B1', 'bonus', NULL, $n$The summary covers all 12 regions$n$, $e$12$e$,
    $q$SELECT count(DISTINCT region)::text FROM analytics.agg_claims_by_region$q$,
    $h$Bonus A. Suppressing a count is fine. Losing the row is not.$h$);
SELECT test.check('D.B2', 'bonus', NULL, $n$An analyst role exists and can read the analytics schema$n$, $e$yes$e$,
    $q$SELECT CASE WHEN has_table_privilege('analyst_ro', 'analytics.dim_claimant_anon', 'SELECT') THEN 'yes' ELSE 'no' END$q$,
    $h$Bonus B. CREATE ROLE analyst_ro; then GRANT SELECT.$h$);
SELECT test.check('D.B3', 'bonus', NULL, $n$The analyst role CANNOT read the curated schema$n$, $e$no$e$,
    $q$SELECT CASE WHEN has_table_privilege('analyst_ro', 'curated.claimant', 'SELECT') THEN 'yes' ELSE 'no' END$q$,
    $h$Bonus B. Analysts must not reach the personal data.$h$);
