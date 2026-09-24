-- ===========================================================================
-- CHALLENGE 2 - Safe Data for Analysts
-- The same challenge for every team.
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 2
--
-- THE SITUATION
--   The curated schema holds two clean tables, joined on the National
--   Insurance number:
--
--        curated.claimant  ----- nino ----->  curated.payment
--        (who they are)                       (what they were paid)
--
--   Analysts want this data. They must never see who anybody is.
--
--   Publish both tables into the analytics schema with the National
--   Insurance number replaced by a pseudonym - and with the join between
--   them still working. That last part is the whole challenge.
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: THREE LINES
--
-- Three lines to change. Every one is marked   <<<<<< EDIT THIS LINE
-- Search for EDIT to jump between them.
--
--   Task 1  Create the two tables      (done for you - read the columns)
--   Task 2  Pseudonymise the claimant  line  78   <- start here
--   Task 3  Pseudonymise the payment   line  102
--   Task 4  Publish a flag, not a date line  88
--   Task 5  Leave the personal columns out   (nothing to do - that is the point)
--
-- Then two bonus tasks at the bottom, once the core tests are green.
--
-- BRIEF.md explains what each task means and why it matters. The pipeline
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
-- It already runs, and every test starts red. Run ./check.sh 2 now,
-- before changing anything, so you can see where you are starting from.
-- ===========================================================================

DROP TABLE IF EXISTS analytics.payment_summary;
DROP TABLE IF EXISTS analytics.payment_anon;
DROP TABLE IF EXISTS analytics.claimant_anon;


-- TASK 1 - The shape of what you are publishing. Written for you.
-- Read the column lists and notice what is NOT there.
CREATE TABLE analytics.claimant_anon (
    person_id    TEXT PRIMARY KEY,
    sex          CHAR(1),
    age_band     TEXT,          -- stays empty until Bonus A
    is_deceased  BOOLEAN
);

CREATE TABLE analytics.payment_anon (
    payment_id      TEXT PRIMARY KEY,
    person_id       TEXT,
    payment_date    DATE,
    amount          NUMERIC(10,2),
    payment_method  TEXT
);


INSERT INTO analytics.claimant_anon
SELECT
    -- TASK 2 - Replace the person with a pseudonym       <<< START HERE
    --          This hashes the NINO, but with no salt at all.
    md5(c.nino),                                                  -- <<<<<< EDIT THIS LINE

    c.sex,

    -- age_band stays empty for now. Bonus A fills it in.
    NULL,

    -- TASK 4 - Publish the fact, not the date.
    --          curated.claimant has a date_of_death; an analyst needs to
    --          know whether somebody died, not when.
    false                                                         -- <<<<<< EDIT THIS LINE

-- TASK 5 - Notice there is no line here for the name, the email, the phone
-- or the date of birth. Not selecting them IS the suppression step.
FROM curated.claimant c;


-- TASK 3 - The payment table, and the point of the whole challenge.
--          person_id below is still the raw National Insurance number, so
--          the two published tables do not join to each other at all.
--          Use exactly the same expression as Task 2, with p.nino.
INSERT INTO analytics.payment_anon
SELECT
    p.payment_id,
    p.nino,                                                       -- <<<<<< EDIT THIS LINE
    p.payment_date,
    p.amount,
    p.payment_method
FROM curated.payment p;


-- ===========================================================================
-- BONUS - only once every core test is green.
--   A - an age band instead of a date of birth
--   B - analytics.payment_summary, built through the join
-- BRIEF.md says what they are; hints.md tells you how.
-- ===========================================================================