-- ---------------------------------------------------------------------------
-- 02a - Two safety-net functions
--
-- Postgres normally throws an error and abandons your whole script the
-- moment it meets something it cannot convert:
--
--     SELECT '£185.15'::numeric;        --> ERROR, script stops dead
--     SELECT to_date('N/A','YYYY-MM-DD');  --> ERROR, script stops dead
--
-- That is correct behaviour, but it is miserable to work with when you are
-- learning: one bad row out of ten thousand and you see nothing at all.
--
-- These two functions do the same conversions but hand back NULL instead of
-- exploding. Your script keeps running, and a NULL shows up in your results
-- where the conversion failed - which tells you exactly what still needs
-- fixing.
--
-- They do NOT do the cleaning for you. util.to_number('£185.15') is still
-- NULL, because '£185.15' is not a number. Strip the pound sign first.
-- ---------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS util;

-- Turn text into a number, or NULL if it is not one.
--     util.to_number('185.15')    ->  185.15
--     util.to_number('  185.15 ') ->  185.15
--     util.to_number('£185.15')   ->  NULL   (strip the £ first)
--     util.to_number('N/A')       ->  NULL
CREATE OR REPLACE FUNCTION util.to_number(p_text TEXT)
RETURNS NUMERIC AS $$
BEGIN
    RETURN btrim(p_text)::numeric;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Turn text into a date using the format you give it, or NULL if it will
-- not fit that format.
--     util.to_date('2026-04-06', 'YYYY-MM-DD')  ->  2026-04-06
--     util.to_date('06/05/1955', 'DD/MM/YYYY')  ->  1955-05-06
--     util.to_date('12-Jul-1948', 'DD-Mon-YYYY')->  1948-07-12
--     util.to_date('N/A',        'YYYY-MM-DD')  ->  NULL
--
-- Common format letters:  YYYY year   MM month number   DD day
--                         Mon short month name (Jan, Feb, Mar ...)
CREATE OR REPLACE FUNCTION util.to_date(p_text TEXT, p_format TEXT)
RETURNS DATE AS $$
DECLARE
    v DATE;
BEGIN
    IF p_text IS NULL OR btrim(p_text) = '' THEN
        RETURN NULL;
    END IF;
    v := to_date(btrim(p_text), p_format);
    -- to_date is very forgiving and will happily invent dates in year 20026
    -- from a typo. Anything wildly out of range is a data error, not a date.
    IF v < DATE '1800-01-01' OR v > DATE '2200-01-01' THEN
        RETURN NULL;
    END IF;
    RETURN v;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION util.to_number(TEXT) IS
'Text to number, or NULL if it will not convert. Does not clean the text for you.';
COMMENT ON FUNCTION util.to_date(TEXT, TEXT) IS
'Text to date using a format string, or NULL if it will not convert.';
