-- ===========================================================================
-- CHALLENGE 2 - Safe Data for Analysts
-- The same challenge for every team.
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 2
--
-- THE SITUATION
--   Analysts and researchers want to study pension payments. They have good
--   reasons: forecasting spending, spotting gaps, checking nobody is missed.
--
--   They must never see who anybody is.
--
--   The curated schema holds two clean tables, joined on the National
--   Insurance number:
--
--        curated.claimant  ----- nino ----->  curated.payment
--        (who they are)                       (what they were paid)
--
--   Your job is to publish both tables into the analytics schema with the
--   National Insurance number replaced by a pseudonym - and with the join
--   between them still working.
--
--   That last part is the whole challenge. Anyone can delete a column. The
--   skill is removing the identifier while keeping the data usable.
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: THREE LINES
--
-- Most of this file is explanation. The pipeline is already written, and
-- you should leave nearly all of it alone.
--
-- There are exactly three lines to change. Every one is marked like this:
--
--        <<<<<< EDIT THIS LINE
--
-- Search for EDIT to jump between them.
--
--   Task 1  Create the two tables      (done for you - read the columns)
--   Task 2  Pseudonymise the claimant  line  120   <- start here
--   Task 3  Pseudonymise the payment   line  181
--   Task 4  Publish a flag, not a date line  142
--   Task 5  Leave the personal columns out   (nothing to do - that is the point)
--
-- Then two bonus tasks at the bottom, once the core tests are green.
--
-- It already runs. Run ./check.sh 2 now, before changing anything, so you
-- can see where you are starting from.
-- ===========================================================================

DROP TABLE IF EXISTS analytics.payment_summary;
DROP TABLE IF EXISTS analytics.payment_anon;
DROP TABLE IF EXISTS analytics.claimant_anon;


-- ---------------------------------------------------------------------------
-- TASK 1 - The shape of what you are publishing. Written for you.
--
-- Read the column lists, and notice what is NOT there: no name, no National
-- Insurance number, no date of birth, no email, no phone.
--
-- Deciding what not to publish is most of this job, and it has already been
-- decided for you here.
-- ---------------------------------------------------------------------------
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
    ----------------------------------------------------------------
    -- TASK 2 - Replace the person with a pseudonym   <<< START HERE
    --
    -- md5(text) turns any text into a 32-character fingerprint. The same
    -- input always gives the same fingerprint - which is exactly what lets
    -- the join keep working - but you cannot turn a fingerprint back into
    -- the original.
    --
    -- Except you can, if the input is predictable. There are only about a
    -- billion possible National Insurance numbers. A laptop can hash every
    -- single one of them in a couple of minutes, build a lookup table, and
    -- match your "anonymous" data straight back to real people. That is
    -- called a dictionary attack.
    --
    -- The fix is a SALT: a secret string mixed in before hashing. Without
    -- it an attacker cannot build that table. The salt lives in
    -- meta.etl_config, which is never published.
    --
    -- LOOK FIRST:
    --   ./explore.sh sql "SELECT * FROM meta.etl_config"
    --
    -- The line below hashes the NINO, but with no salt at all. One of the
    -- tests deliberately catches that.
    --
    -- TODO: mix the salt in before the NINO. The salt is
    --
    --         (SELECT value FROM meta.etl_config
    --          WHERE setting = 'pseudonymisation_salt')
    --
    --       and  ||  glues text together, so you want
    --       md5( <the salt>  ||  c.nino ).
    --
    -- READ the salt from meta.etl_config rather than typing the text
    -- into your SQL. Both give the same answer today - but a salt gets
    -- rotated, and when it does you want to change it in one place, not
    -- hunt through every script that ever hardcoded it. Secrets pasted
    -- into code also end up in version control, where they stay forever.
    ----------------------------------------------------------------
    md5(c.nino),                                                  -- <<<<<< EDIT THIS LINE

    c.sex,

    -- age_band stays empty for now. Bonus A fills it in.
    NULL,

    ----------------------------------------------------------------
    -- TASK 4 - Publish the fact, not the date
    --
    -- curated.claimant has a date_of_death. An exact date of death is
    -- personal information, and an analyst almost never needs it - what
    -- they need is whether the person has died.
    --
    -- So publish a true/false, not a date.
    --
    -- In SQL a comparison is already true or false, so you do not need a
    -- CASE here. c.date_of_death IS NOT NULL is true for somebody who has
    -- died and false for somebody who has not.
    --
    -- TODO: replace  false  with  (c.date_of_death IS NOT NULL)
    ----------------------------------------------------------------
    false                                                         -- <<<<<< EDIT THIS LINE

-- TASK 5 - Notice there is no line here for the name, the email, the phone
-- or the date of birth. Not selecting them IS the suppression step. It is
-- the easiest task of the day and the one that matters most.
FROM curated.claimant c;


-- ---------------------------------------------------------------------------
-- TASK 3 - The payment table, and the point of the whole challenge
--
-- Run this file, then look at what came out:
--
--   ./explore.sh peek analytics.payment_anon
--
-- The person_id column is still full of raw National Insurance numbers.
-- That is the exact thing you were told not to publish, and a test is
-- already failing because of it.
--
-- But there is a second, subtler problem. Try joining your two published
-- tables together:
--
--   ./explore.sh sql "SELECT count(*) FROM analytics.payment_anon p
--                     JOIN analytics.claimant_anon c ON c.person_id = p.person_id"
--
-- You get 0. Not an error - just nothing. One table holds hashes and the
-- other holds NINOs, so no row matches any other row. The data is
-- published, it looks fine, and it is completely useless.
--
-- THIS IS THE LESSON. A pseudonym has to be built the SAME WAY everywhere
-- it appears, or the tables stop joining and nobody notices until an
-- analyst quietly reports a total of zero.
--
-- TODO: use exactly the same expression you worked out in Task 2, with
--       p.nino instead of c.nino. Copy it character for character.
-- ---------------------------------------------------------------------------
INSERT INTO analytics.payment_anon
SELECT
    p.payment_id,
    p.nino,                                                       -- <<<<<< EDIT THIS LINE
    p.payment_date,
    p.amount,
    p.payment_method
FROM curated.payment p;


-- ===========================================================================
-- BONUS - only once every core test is green
-- ===========================================================================
--
-- BONUS A - An age band instead of a date of birth
--
--   An exact date of birth identifies people; an age band does not. The
--   age_band column is sitting there empty.
--
--   Work the age out against DATE '2026-04-06', never today's date, so
--   that everybody's answer matches:
--
--       date_part('year', age(DATE '2026-04-06', c.date_of_birth))
--
--   Replace the  NULL  in the claimant query above with a CASE giving
--   '65-69', '70-74', '75-79', '80-84' or '85+'. Watch your boundaries:
--   70-74 means 70, 71, 72, 73 and 74.
--
--       CASE
--           WHEN date_part('year', age(DATE '2026-04-06', c.date_of_birth)) < 70 THEN '65-69'
--           ...
--           ELSE '85+'
--       END
--
--
-- BONUS B - A summary table, built through the join
--
--   Analysts mostly want totals, not rows. Build one row per person: how
--   many payments, and how much in total. This only works if Task 3 is
--   right, so it doubles as proof that your join survived.
--
--   Uncomment and finish:
--
-- CREATE TABLE analytics.payment_summary AS
-- SELECT c.person_id,
--        count(*)::int                AS payment_count,
--        sum(p.amount)::numeric(12,2) AS total_paid
-- FROM analytics.payment_anon p
-- JOIN analytics.claimant_anon c ON ...   -- TODO: join them on person_id
-- GROUP BY ...;                           -- TODO
-- ===========================================================================