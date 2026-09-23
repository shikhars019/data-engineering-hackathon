-- ---------------------------------------------------------------------------
-- 04 - The curated tables: your Challenge 2 INPUT
--
-- This is a different set of people from the raw tables. Think of it as
-- last night's pipeline output: somebody else already did the cleaning,
-- and it is genuinely clean.
--
-- It is also full of personal information. Names, dates of birth, home
-- addresses, National Insurance numbers. Exactly the sort of thing you
-- must not hand to an analyst.
--
-- Challenge 2 is about publishing this safely. Read it, do not change it.
-- ---------------------------------------------------------------------------

CREATE TABLE curated.claimant (
    nino            CHAR(9) PRIMARY KEY,
    title           TEXT,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    date_of_birth   DATE NOT NULL,
    sex             CHAR(1),
    marital_status  TEXT,
    date_of_death   DATE,
    email           TEXT,
    phone           TEXT
);

CREATE TABLE curated.address (
    address_id  TEXT PRIMARY KEY,
    nino        CHAR(9) NOT NULL REFERENCES curated.claimant(nino),
    line_1      TEXT,
    line_2      TEXT,
    town        TEXT,
    county      TEXT,
    postcode    TEXT NOT NULL,
    valid_from  DATE,
    valid_to    DATE,
    is_current  BOOLEAN NOT NULL
);

CREATE TABLE curated.claim (
    claim_ref           TEXT PRIMARY KEY,
    nino                CHAR(9) NOT NULL REFERENCES curated.claimant(nino),
    claim_status        TEXT NOT NULL,
    pension_type        TEXT,
    claim_start_date    DATE,
    qualifying_years    INT,
    weekly_amount       NUMERIC(10,2),
    deferral_indicator  BOOLEAN,
    payment_frequency   TEXT
);

CREATE TABLE curated.payment (
    payment_id      TEXT PRIMARY KEY,
    claim_ref       TEXT NOT NULL REFERENCES curated.claim(claim_ref),
    payment_date    DATE NOT NULL,
    amount          NUMERIC(10,2) NOT NULL,
    payment_method  TEXT,
    payment_status  TEXT NOT NULL
);

COMMENT ON TABLE curated.claimant IS 'Challenge 2 input. Clean, and full of personal data.';
