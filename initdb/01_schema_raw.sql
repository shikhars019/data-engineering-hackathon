-- ---------------------------------------------------------------------------
-- 01 - The raw landing tables
--
-- Everything here is TEXT, nothing is unique, nothing is checked, and
-- nothing is joined up. That is deliberate, and it is what real landing
-- tables look like.
--
-- Three source systems feed this, and they disagree with each other:
--
--   CIS          the old mainframe. Shouts in capitals.
--   LEGACY_CSV   spreadsheets emailed in by regional offices. Anything goes.
--   DIGITAL      the modern online service. Tidiest, but not perfect.
--
-- When two records disagree, the source system is usually the clue.
-- ---------------------------------------------------------------------------

CREATE TABLE raw.claimant (
    record_id       TEXT,
    nino            TEXT,   -- National Insurance number. Should identify a person.
    title           TEXT,
    first_name      TEXT,
    last_name       TEXT,
    date_of_birth   TEXT,   -- written differently by each source system
    sex             TEXT,
    marital_status  TEXT,
    date_of_death   TEXT,   -- empty for the living
    email           TEXT,
    phone           TEXT,
    source_system   TEXT,
    ingested_at     TEXT    -- when this record landed. Useful for tie-breaks.
);

CREATE TABLE raw.address (
    address_id      TEXT,
    claimant_ref    TEXT,   -- meant to match raw.claimant.nino. Not always does.
    address_line_1  TEXT,
    address_line_2  TEXT,
    town            TEXT,
    county          TEXT,
    postcode        TEXT,
    valid_from      TEXT,
    valid_to        TEXT,   -- empty means "still lives here"
    is_current      TEXT    -- a flag you should not fully trust
);

CREATE TABLE raw.claim (
    claim_ref           TEXT,
    claimant_ref        TEXT,   -- meant to match raw.claimant.nino
    claim_status        TEXT,
    pension_type        TEXT,
    claim_start_date    TEXT,
    qualifying_years    TEXT,
    weekly_amount       TEXT,   -- money, stored as text, formatted inconsistently
    deferral_indicator  TEXT,   -- a yes/no flag with far too many spellings
    deferral_weeks      TEXT,
    payment_frequency   TEXT,
    last_updated        TEXT
);

CREATE TABLE raw.payment (
    payment_id      TEXT,
    claim_ref       TEXT,   -- meant to match raw.claim.claim_ref
    payment_date    TEXT,
    amount          TEXT,
    payment_method  TEXT,
    payment_status  TEXT,
    created_at      TEXT
);

COMMENT ON TABLE raw.claimant IS 'People. May contain the same person more than once.';
COMMENT ON TABLE raw.address  IS 'Addresses. May point at people who do not exist.';
COMMENT ON TABLE raw.claim    IS 'State Pension claims.';
COMMENT ON TABLE raw.payment  IS 'Individual payments made against a claim.';
