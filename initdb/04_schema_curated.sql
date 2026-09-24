-- ---------------------------------------------------------------------------
-- 04 - The curated tables: your Challenge 2 INPUT
--
-- Two tables, and one thing joins them: the National Insurance number.
--
--        curated.claimant                curated.payment
--        ----------------                ---------------
--        nino  <-------- joined on -------> nino
--        full_name                        payment_id
--        date_of_birth                    payment_date
--        sex                              amount
--        date_of_death                    payment_method
--        email
--        phone
--
-- This is a different set of people from the raw tables. Think of it as
-- last night's pipeline output: somebody else already did the cleaning,
-- and it is genuinely clean.
--
-- It is also full of personal information. Names, dates of birth, email
-- addresses, phone numbers, National Insurance numbers. Exactly the sort
-- of thing you must not hand to an analyst.
--
-- Challenge 2 is about publishing this safely. Read it, do not change it.
-- ---------------------------------------------------------------------------

CREATE TABLE curated.claimant (
    nino            CHAR(9) PRIMARY KEY,
    full_name       TEXT NOT NULL,
    date_of_birth   DATE NOT NULL,
    sex             CHAR(1),
    date_of_death   DATE,
    email           TEXT,
    phone           TEXT
);

CREATE TABLE curated.payment (
    payment_id      TEXT PRIMARY KEY,
    nino            CHAR(9) NOT NULL REFERENCES curated.claimant(nino),
    payment_date    DATE NOT NULL,
    amount          NUMERIC(10,2) NOT NULL,
    payment_method  TEXT
);

CREATE INDEX ON curated.payment (nino);

COMMENT ON TABLE curated.claimant IS
'Challenge 2 input. Clean, and full of personal data.';
COMMENT ON TABLE curated.payment IS
'Challenge 2 input. Joined to curated.claimant on nino.';
