-- ---------------------------------------------------------------------------
-- State Pension Data Hackathon
-- 00 - Schemas
--
-- This runs automatically when the database is first created.
-- You do not need to run it yourself.
--
-- A "schema" is just a folder for tables. We use several so it is always
-- obvious which stage of the pipeline a table belongs to:
--
--   raw        the mess as it arrived from the source systems   (Challenge 1 input)
--   ref        small clean lookup tables you can trust
--   clean      where YOUR tidied data goes                      (Challenge 1 output)
--   curated    a clean dataset, already prepared for you        (Challenge 2 input)
--   analytics  what you publish for analysts                    (Challenge 2 output)
--   meta       information about this database
--   test       the scoring harness
-- ---------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS ref;
CREATE SCHEMA IF NOT EXISTS clean;
CREATE SCHEMA IF NOT EXISTS curated;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS meta;
CREATE SCHEMA IF NOT EXISTS test;

COMMENT ON SCHEMA raw       IS 'Data exactly as it arrived from source systems. Never edit in place.';
COMMENT ON SCHEMA ref       IS 'Trusted lookup tables.';
COMMENT ON SCHEMA clean     IS 'Challenge 1 output. Your tidied data goes here.';
COMMENT ON SCHEMA curated   IS 'Challenge 2 input. Already clean - do not modify.';
COMMENT ON SCHEMA analytics IS 'Challenge 2 output. Safe to share with analysts.';

-- ---------------------------------------------------------------------------
-- Facts about this database that both you and the tests can rely on.
-- ---------------------------------------------------------------------------
CREATE TABLE meta.dataset_info (
    team            INT,
    loaded_at       TIMESTAMP DEFAULT now(),
    -- Every age calculation in this hackathon uses this date, not today's
    -- date. That way your answers do not change depending on when you run
    -- them, and everyone gets the same result.
    reference_date  DATE DEFAULT DATE '2026-04-06'
);

COMMENT ON COLUMN meta.dataset_info.reference_date
    IS 'Use this date for all age calculations. Start of the 2026/27 tax year.';
