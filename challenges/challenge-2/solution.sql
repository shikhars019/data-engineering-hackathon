-- ===========================================================================
-- CHALLENGE 2 - Safe Data for Analysts
-- The same challenge for every team.
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 2
--
-- THE SITUATION
--   Analysts, researchers and the Office for National Statistics all want
--   to study State Pension data. They have good reasons: spotting regional
--   inequality, forecasting spending, checking nobody is being missed.
--
--   They must never see who anybody is.
--
--   The curated schema is clean, finished data - and full of names, dates
--   of birth, home addresses and National Insurance numbers. Your job is
--   to publish a version of it into the analytics schema that is useful
--   to an analyst and useless to someone trying to find their neighbour.
--
--   This is a real job. It has a name: disclosure control.
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: SEVEN LINES
--
-- Most of this file is explanation. The pipeline is already written, and
-- you should leave nearly all of it alone.
--
-- There are exactly seven lines to change. Every one is marked like this:
--
--        <<<<<< EDIT THIS LINE
--
-- Search for EDIT to jump between them.
--
--   Task 1  Create the tables            (done for you - read the columns)
--   Task 2  Pseudonymise the person      line  109   <- start here
--   Task 3  Age band instead of birthday (done for you - Task 7 revisits it)
--   Task 4  Region instead of postcode   line  147
--   Task 5  Leave the personal data out  (nothing to do - that is the point)
--   Task 6  The claims table             lines 174 and 175
--   Task 7  k-anonymity                  lines 126 and 127  (the two age bands)
--   Task 8  The summary table            line  256
--
-- It already runs, and eight tests already pass. Run ./check.sh 2 now,
-- before changing anything, so you can see where you are starting from.
-- ===========================================================================

DROP TABLE IF EXISTS analytics.agg_claims_by_region;
DROP TABLE IF EXISTS analytics.fct_claim_anon;
DROP TABLE IF EXISTS analytics.dim_claimant_anon;


-- ---------------------------------------------------------------------------
-- TASK 1 - The shape of what you are publishing. Written for you.
--
-- Read the column lists. Notice what is NOT there: no name, no NINO, no
-- date of birth, no postcode, no email, no phone. Deciding what not to
-- publish is most of this job, and it has already been decided here.
-- ---------------------------------------------------------------------------
CREATE TABLE analytics.dim_claimant_anon (
    person_pseudo_id  TEXT PRIMARY KEY,
    age_band          TEXT,
    sex               TEXT,
    region            TEXT,
    marital_status    TEXT,
    is_deceased       BOOLEAN
);

CREATE TABLE analytics.fct_claim_anon (
    claim_pseudo_id     TEXT PRIMARY KEY,
    person_pseudo_id    TEXT,
    claim_year_month    TEXT,
    claim_status        TEXT,
    pension_type        TEXT,
    weekly_amount_band  TEXT,
    payment_frequency   TEXT
);


INSERT INTO analytics.dim_claimant_anon
SELECT
    ----------------------------------------------------------------
    -- TASK 2 - Replace the person with a pseudonym   <<< START HERE
    --
    -- md5(text) turns any text into a 32-character fingerprint. The same
    -- input always gives the same fingerprint, which is what lets you
    -- still join tables together - but you cannot turn a fingerprint
    -- back into the original.
    --
    -- Except you can, if the input is predictable. There are only about
    -- a billion possible NINOs. A laptop can hash every single one of
    -- them in a couple of minutes, build a lookup table, and match your
    -- "anonymous" data straight back to real people. That is called a
    -- dictionary attack.
    --
    -- The fix is a SALT: a secret string mixed in before hashing. Without
    -- it the attacker cannot build their table. The salt lives in
    -- meta.etl_config, which is NOT published.
    --
    -- LOOK FIRST:
    --   SELECT * FROM meta.etl_config;
    --
    -- One of the tests deliberately checks for this. An unsalted hash
    -- will fail it.
    --
    -- TODO: mix the salt in before the NINO. The salt is:
    --         (SELECT value FROM meta.etl_config
    --          WHERE setting = 'pseudonymisation_salt')
    --       and  ||  glues text together.
    ----------------------------------------------------------------
    md5(c.nino),                                                  -- <<<<<< EDIT THIS LINE

    ----------------------------------------------------------------
    -- TASK 3 - Age band instead of date of birth
    --
    -- An exact date of birth identifies people. An age band does not.
    --
    -- Ages are worked out against DATE '2026-04-06', never today's date,
    -- so that everybody's answer matches.
    --
    -- This is written for you and it works. You WILL come back and
    -- change the last two bands in Task 7 - that is the point of Task 7.
    ----------------------------------------------------------------
    CASE
        WHEN date_part('year', age(DATE '2026-04-06', c.date_of_birth)) < 70 THEN '65-69'
        WHEN date_part('year', age(DATE '2026-04-06', c.date_of_birth)) < 75 THEN '70-74'
        WHEN date_part('year', age(DATE '2026-04-06', c.date_of_birth)) < 80 THEN '75-79'
        WHEN date_part('year', age(DATE '2026-04-06', c.date_of_birth)) < 85 THEN '80-84'  -- <<<<<< EDIT THIS LINE
        ELSE '85+'                                                                          -- <<<<<< EDIT THIS LINE
    END,

    c.sex,

    ----------------------------------------------------------------
    -- TASK 4 - Region instead of postcode
    --
    -- Right now this publishes the full postcode. A full UK postcode
    -- covers about fifteen houses. Combined with an age and a sex, that
    -- is a name and address.
    --
    -- What an analyst actually needs is the region.
    --
    -- The join to ref.postcode_area is already written below - it takes
    -- the letters off the front of the postcode ('SW1A 1AA' -> 'SW') and
    -- looks up which region that is.
    --
    -- TODO: publish  r.region  instead of the postcode.
    ----------------------------------------------------------------
    a.postcode,                                                   -- <<<<<< EDIT THIS LINE

    c.marital_status,
    (c.date_of_death IS NOT NULL)

-- TASK 5 - Notice there is no line here for name, email, phone or NINO.
-- Not selecting them IS the suppression step. It is the easiest task of
-- the day and the one that matters most.
FROM curated.claimant c
JOIN curated.address a
  ON a.nino = c.nino AND a.is_current
LEFT JOIN ref.postcode_area r
  ON r.area_code = substring(a.postcode from '^[A-Z]{1,2}');


-- ---------------------------------------------------------------------------
-- TASK 6 - The claims table
--
-- The important bit: person_pseudo_id must be made EXACTLY the same way
-- here as in the table above. If the recipes differ by so much as a
-- space, nothing joins and the whole warehouse is useless.
--
-- TODO: apply the same salted hash you worked out in Task 2 - in BOTH
--       places below.
-- ---------------------------------------------------------------------------
INSERT INTO analytics.fct_claim_anon
SELECT
    md5(cl.claim_ref),                                            -- <<<<<< EDIT THIS LINE
    md5(cl.nino),                                                 -- <<<<<< EDIT THIS LINE
    to_char(cl.claim_start_date, 'YYYY-MM'),
    cl.claim_status,
    cl.pension_type,
    CASE
        WHEN cl.weekly_amount < 100 THEN 'under 100'
        WHEN cl.weekly_amount < 150 THEN '100-149'
        WHEN cl.weekly_amount < 200 THEN '150-199'
        WHEN cl.weekly_amount < 250 THEN '200-249'
        ELSE '250 and over'
    END,
    cl.payment_frequency
FROM curated.claim cl;


-- ===========================================================================
-- TASK 7 - k-anonymity: the real lesson of the whole challenge
--
-- Run ./check.sh 2 now. However carefully you did Tasks 2 to 6, the
-- k-anonymity test still fails. Nothing is broken - you have just met the
-- actual problem.
--
-- Every column you published is harmless on its own. Nobody is identified
-- by "female", or by "80-84", or by "Northern Ireland". But put all three
-- together and you might be describing two people in the whole country -
-- and anyone who knows their neighbour is an 82-year-old widow in Belfast
-- now knows what she is paid.
--
-- k-anonymity is the rule that stops this: every published combination
-- must describe at least k people. The agency uses k = 5.
--
-- SEE THE PROBLEM FOR YOURSELF - run this:
--
--     SELECT age_band, sex, region, count(*) AS people
--     FROM analytics.dim_claimant_anon
--     GROUP BY 1, 2, 3
--     HAVING count(*) < 5
--     ORDER BY people;
--
-- Look at which band keeps appearing. There simply are not many people
-- aged 85 and over in any one region.
--
-- THE FIX: make the bands wider. If '80-84' and '85+' were a single
-- '80+' band, every one of those small groups would be big enough.
--
-- You lose a little detail. You gain the ability to publish at all. That
-- trade-off is the job.
--
-- TODO: go back to Task 3 and merge the last two bands into a single
--       '80+'. The two marked lines up there become one:
--
--           ELSE '80+'
--
--       Then run ./check.sh 2 again.
-- ===========================================================================


-- ===========================================================================
-- TASK 8 - The summary table, and the same trap one level up
--
-- Most analysts never touch the row-level data. They want a summary:
-- how many claims, by region and age band.
--
-- But a summary leaks in exactly the same way. A cell reading "2" tells
-- you there are two people in that region and age band - which is no
-- better than publishing the two rows themselves. Widening the age bands
-- in Task 7 protected the detailed table; it does not automatically
-- protect a count.
--
-- So the same rule applies: any count below 5 is replaced with NULL.
--
-- Note NULL, not zero, and not a deleted row. An analyst needs to be
-- able to tell "too small to publish" apart from "nobody lives here".
-- Deleting the row would quietly change the total.
--
-- TODO: finish the CASE below so counts under 5 become NULL.
-- ---------------------------------------------------------------------------
CREATE TABLE analytics.agg_claims_by_region AS
SELECT
    d.region,
    d.age_band,
    count(*) AS claim_count                                       -- <<<<<< EDIT THIS LINE
FROM analytics.fct_claim_anon f
JOIN analytics.dim_claimant_anon d
  ON d.person_pseudo_id = f.person_pseudo_id
GROUP BY d.region, d.age_band;


-- ===========================================================================
-- BONUS - only once every core test is green
-- ===========================================================================
--
-- BONUS A - Check you suppressed the counts rather than dropping the
--   rows. Every region should still appear in the summary, even if some
--   of its numbers are blank.
--
-- BONUS B - None of this helps if an analyst can just read curated
--   instead. Create a role that can read analytics and nothing else:
--
--   CREATE ROLE analyst_ro NOLOGIN;
--   GRANT USAGE ON SCHEMA analytics TO analyst_ro;
--   GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO analyst_ro;
--   REVOKE ALL ON SCHEMA curated FROM analyst_ro;
--   REVOKE ALL ON ALL TABLES IN SCHEMA curated FROM analyst_ro;
--
-- BONUS C - Run ./check.sh 2 twice in a row. Does it still pass? A
--   pipeline you cannot safely re-run is a pipeline somebody has to
--   babysit at 3am.
-- ===========================================================================
