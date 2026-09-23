-- ---------------------------------------------------------------------------
-- 07 - The scoring harness
--
-- You do not need to understand this file, but you are very welcome to.
--
-- The important idea: each test is one small question with one known right
-- answer. If your SQL produces the right answer, the test passes.
--
-- Every test runs inside its own safety net. If one of your queries has a
-- mistake in it, that single test reports the error and the rest still run.
-- One broken query never hides your progress on everything else.
--
-- The scorecard is sorted by TASK, not by test number, so it reads like a
-- to-do list: the task you are working on now is near the top.
-- ---------------------------------------------------------------------------

CREATE TABLE test.result (
    seq         SERIAL,
    id          TEXT PRIMARY KEY,
    kind        TEXT NOT NULL CHECK (kind IN ('core', 'bonus')),
    task        TEXT,               -- which task in your file this belongs to
    name        TEXT NOT NULL,
    expected    TEXT,
    actual      TEXT,
    status      TEXT,
    hint        TEXT
);

-- ---------------------------------------------------------------------------
-- test.check(...) runs one query and records whether it gave the expected
-- answer. The query must return a single value.
--
-- p_task is the task number in the student's file. It is also what the
-- scorecard sorts by, and the hint is prefixed with it automatically - so
-- the number shown, the number sorted on and the number in the hint can
-- never disagree with each other.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION test.check(
    p_id        TEXT,
    p_kind      TEXT,
    p_task      TEXT,
    p_name      TEXT,
    p_expected  TEXT,
    p_sql       TEXT,
    p_hint      TEXT DEFAULT NULL
) RETURNS void AS $$
DECLARE
    v_actual TEXT;
    v_status TEXT;
    v_hint   TEXT;
BEGIN
    BEGIN
        EXECUTE p_sql INTO v_actual;
        v_actual := COALESCE(btrim(v_actual), '<no rows>');

        IF v_actual = btrim(p_expected) THEN
            v_status := 'PASS';
        ELSE
            v_status := 'FAIL';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        -- Most often: the table does not exist yet, or a column name is
        -- misspelled. Report it against this one test and carry on.
        v_actual := 'ERROR: ' || left(SQLERRM, 60);
        v_status := 'FAIL';
    END;

    v_hint := COALESCE(p_hint, '');
    IF p_task IS NOT NULL AND p_task <> '' THEN
        v_hint := CASE WHEN p_task ~ 'and' THEN 'Tasks ' ELSE 'Task ' END
                  || p_task || '. ' || v_hint;
    END IF;

    INSERT INTO test.result (id, kind, task, name, expected, actual, status, hint)
    VALUES (p_id, p_kind, p_task, p_name, p_expected, v_actual, v_status, v_hint)
    ON CONFLICT (id) DO UPDATE
        SET task     = EXCLUDED.task,
            expected = EXCLUDED.expected,
            actual   = EXCLUDED.actual,
            status   = EXCLUDED.status,
            hint     = EXCLUDED.hint;
END;
$$ LANGUAGE plpgsql;

-- Clear previous results so each run starts fresh.
CREATE OR REPLACE FUNCTION test.reset() RETURNS void AS $$
BEGIN
    DELETE FROM test.result;
    ALTER SEQUENCE test.result_seq_seq RESTART WITH 1;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- The scorecard. Sorted by task, so your current work is at the top and
-- tasks you have not started yet are further down.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW test.report AS
SELECT
    COALESCE(task, '-')                       AS "task",
    id                                        AS "#",
    kind                                      AS "type",
    name                                      AS "test",
    expected                                  AS "expected",
    actual                                    AS "you got",
    CASE WHEN status = 'PASS' THEN 'PASS' ELSE 'FAIL' END AS "result",
    CASE WHEN status = 'PASS' THEN '' ELSE COALESCE(hint, '') END AS "where to look"
FROM test.result
ORDER BY kind DESC,
         COALESCE(substring(task from '\d+')::int, 99),
         seq;

COMMENT ON VIEW test.report IS 'Your scorecard, in task order. Run: SELECT * FROM test.report;';

-- A one-line summary.
CREATE OR REPLACE VIEW test.score AS
SELECT
    count(*) FILTER (WHERE kind = 'core'  AND status = 'PASS') AS core_passed,
    count(*) FILTER (WHERE kind = 'core')                      AS core_total,
    count(*) FILTER (WHERE kind = 'bonus' AND status = 'PASS') AS bonus_passed,
    count(*) FILTER (WHERE kind = 'bonus')                     AS bonus_total
FROM test.result;

-- The first thing still to do, in task order. check.sh shows this when you
-- are not yet finished, so there is always an obvious next step.
CREATE OR REPLACE VIEW test.next_up AS
SELECT task, id, name, expected, actual, hint
FROM test.result
WHERE status <> 'PASS' AND kind = 'core'
ORDER BY COALESCE(substring(task from '\d+')::int, 99), seq
LIMIT 1;
