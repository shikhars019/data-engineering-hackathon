-- ---------------------------------------------------------------------------
-- 03 - The clean tables: where YOUR Challenge 1 answer goes
--
-- These start empty. Your job is to fill them from the raw tables.
--
-- Notice the difference from raw:
--   - real types: DATE, NUMERIC and BOOLEAN instead of everything being TEXT
--   - a PRIMARY KEY on each table, so the same record cannot land twice
--
-- The types matter. A DATE column will not accept the text '04/03/1948',
-- and a NUMERIC column will not accept '£185.15'. Converting them properly
-- is a large part of the job.
--
-- Deliberately, there are NO rules here about what counts as a sensible
-- value. The database will happily store a birthday in 1899 or a postcode
-- of 'banana'. Catching that is what the tests are for, and it is why real
-- data teams write tests rather than trusting the database to notice.
-- ---------------------------------------------------------------------------

CREATE TABLE clean.claimant (
    nino            TEXT PRIMARY KEY,   -- one row per person. The key is the point.
    title           TEXT,
    first_name      TEXT,
    last_name       TEXT,
    date_of_birth   DATE,
    sex             TEXT,
    marital_status  TEXT,
    date_of_death   DATE,
    email           TEXT,
    phone           TEXT
);

CREATE TABLE clean.address (
    address_id      TEXT PRIMARY KEY,
    nino            TEXT,
    line_1          TEXT,
    line_2          TEXT,
    town            TEXT,
    county          TEXT,
    postcode        TEXT,
    valid_from      DATE,
    valid_to        DATE,
    is_current      BOOLEAN
);

CREATE TABLE clean.claim (
    claim_ref           TEXT PRIMARY KEY,
    nino                TEXT,
    claim_status        TEXT,
    pension_type        TEXT,
    claim_start_date    DATE,
    qualifying_years    INT,
    weekly_amount       NUMERIC(10,2),
    deferral_indicator  BOOLEAN,
    payment_frequency   TEXT
);

CREATE TABLE clean.payment (
    payment_id      TEXT PRIMARY KEY,
    claim_ref       TEXT,
    payment_date    DATE,
    amount          NUMERIC(10,2),
    payment_method  TEXT,
    payment_status  TEXT
);

COMMENT ON TABLE clean.claimant IS 'Challenge 1 output: one row per real person.';
COMMENT ON TABLE clean.address  IS 'Challenge 1 output: valid addresses only.';
COMMENT ON TABLE clean.claim    IS 'Challenge 1 output: claims with standard codes.';
COMMENT ON TABLE clean.payment  IS 'Challenge 1 output: real payments only.';

-- ---------------------------------------------------------------------------
-- The standard codes your cleaned data should use.
--
--   claim_status       ACTIVE | SUSPENDED | CLOSED
--   pension_type       NEW_STATE_PENSION | BASIC_STATE_PENSION
--   payment_frequency  WEEKLY | FOUR_WEEKLY | QUARTERLY
--   payment_method     BACS | CHEQUE | POST_OFFICE | UNKNOWN
--   payment_status     SETTLED | REVERSED
--   sex                M | F
--
-- Not every team needs all of these. Your brief says which.
-- ---------------------------------------------------------------------------
