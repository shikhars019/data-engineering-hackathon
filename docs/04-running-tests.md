# Running the tests and reading your score

## The one command

```bash
./check.sh 1      # Challenge 1
./check.sh 2      # Challenge 2
```

It does two things, in order:

1. Runs **your** file — `challenges/challenge-1/team-3/solution.sql`
2. Runs the tests and prints your score

Nothing is hidden. You can run both by hand in TablePlus if you prefer.

---

## Reading the scorecard

```
 task | #      | type  | test                                  | expected | you got | result
------+--------+-------+---------------------------------------+----------+---------+--------
 1    | C1.05  | core  | Names have no leading or trailing ...  | 0        | 836     | FAIL
 2    | C1.07  | core  | Placeholder text like N/A is gone      | 0        | 341     | FAIL
 3    | C1.04  | core  | Every NINO is 2 letters, 6 digits...   | 0        | 326     | FAIL
 5    | C1.01  | core  | clean.claimant has one row per person  | 1200     | 1317    | FAIL

  CORE 0/9   BONUS 0/3

  Next thing to fix:  Task 1   Names have no leading or trailing spaces
                      Task 1. Use btrim() (also called trim).
```

**The scorecard is sorted by task, not by test number.** It reads like a
to-do list: the task you are working on is near the top, and tasks you have
not started yet are further down. Work down it from the top.

The **task** column tells you which numbered task in your `solution.sql` a
test belongs to, so you never have to guess where to look.

- **expected** — the right answer
- **you got** — what your SQL produced
- **where to look** — which task this test belongs to

The gap between the two numbers is usually the clue. `expected 0, you got
326` means 326 rows still have something wrong with them — and you can go
and look at them:

```sql
SELECT * FROM clean.claimant WHERE nino !~ '^[A-Z]{2}[0-9]{6}[A-Z]$' LIMIT 20;
```

**Aim for all the core tests.** Every team can get there. Bonus tests are
what separates the teams at the end.

---

## Why you get the tests at the start

Because guessing what "done" means is not the interesting part of the job.

Real data teams write tests like these and run them on every load, forever.
They are how you find out that an upstream system changed its date format at
2am, rather than finding out from a headline. Handing you the tests first is
not making it easy — it is the actual practice.

---

## When your SQL will not run

If your file has an error, nothing is scored and you see the Postgres message
instead:

```
FAIL Your SQL did not run. Postgres said:

    ERROR:  syntax error at or near "FROM"
    LINE 42:     FROM raw.claimant
```

Go to that line number in your file. The real mistake is very often on the
line **above** the one reported — a missing comma or an unclosed bracket.

### The common ones

| Message | What to do |
|---|---|
| `relation "claimant" does not exist` | Add the schema: `raw.claimant`, not `claimant` |
| `syntax error at or near` | Look at the line above. Missing comma or bracket. |
| `column "x" does not exist` | Typo, or you are in the wrong table |
| `invalid input syntax for type numeric` | Wrap it in `util.to_number(...)` |
| `duplicate key value violates unique constraint` | You are inserting the same key twice — duplicates survived |
| `INSERT has more expressions than target columns` | Your `SELECT` list is longer than your column list |

---

## When one test says ERROR

```
 C1.03  | core  | 1500 raw records became 1200 people | 1500 -> 1200 | ERROR: relation ... | FAIL
```

That test could not run, but **the others still did**. This is deliberate:
one broken query never hides your progress on everything else.

It usually means a table you have not created yet, or a misspelled column.

---

## Digging into one test

```sql
SELECT * FROM test.result WHERE id = 'C1.04';
SELECT * FROM test.report;                          -- the whole scorecard
SELECT * FROM test.result WHERE status = 'FAIL';    -- just the failures
```

---

## Things worth knowing

**Run it constantly.** After every change. It takes seconds. A mistake you
catch immediately is much easier than one you find with ten minutes left.

**Stuck on one test?** Your team folder has a `hints.md` with a walkthrough
for every task. Using it is completely fine. Skipping it makes for a harder
run — and you can open it for a single task without reading the rest.

**Tests can go backwards.** If something that was passing starts failing, the
change you just made broke it. That is useful information, not a disaster.

**Your file starts over every time.** Each starter begins with `TRUNCATE`, so
running it twice does not pile up duplicate rows. Run it as often as you like.

**`./reset.sh` if things get strange.** A fresh database in about twenty
seconds. Your `.sql` files are never touched — only the database is rebuilt.

---

## Reporting your score

When your core tests are green, tell an organiser. Screenshot the scorecard
if you like.

Then go after the bonus tests. Or better: go and read another team's brief
and see whether their problem would have been harder than yours.
