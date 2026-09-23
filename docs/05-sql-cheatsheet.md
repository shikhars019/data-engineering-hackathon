# SQL cheat sheet

Everything you need today, and not much else. Keep this open in a tab.

---

## Looking at data

```sql
SELECT * FROM raw.claimant LIMIT 10;          -- first 10 rows, all columns
SELECT nino, first_name FROM raw.claimant;     -- just these columns
SELECT * FROM raw.claimant WHERE sex = 'F';    -- only matching rows
SELECT count(*) FROM raw.claimant;             -- how many rows?
```

`raw.claimant` means **schema** `raw`, **table** `claimant`. You always need
both parts.

### The most useful query of the day

```sql
SELECT claim_status, count(*)
FROM raw.claim
GROUP BY claim_status
ORDER BY count(*) DESC;
```

"Show me every different value in this column, and how often each appears."
This is how you find the mess. Run it on a column before you try to clean it.

Or from the Terminal, which also shows you stray spaces:

```bash
./explore.sh values raw.claim claim_status
```

---

## Tidying text

| Function | What it does | Example |
|---|---|---|
| `btrim(x)` | Removes spaces from both ends | `btrim('  John ')` → `'John'` |
| `upper(x)` | MAKES IT SHOUT | `upper('john')` → `'JOHN'` |
| `lower(x)` | makes it quiet | `lower('JOHN')` → `'john'` |
| `initcap(x)` | Makes It Look Like This | `initcap('JOHN')` → `'John'` |
| `replace(x, a, b)` | Swaps every `a` for `b` | `replace('a b','  ','')` |
| `length(x)` | How many characters | `length('John')` → `4` |
| `left(x, n)` | First n characters | `left('SW1A1AA', 4)` → `'SW1A'` |
| `right(x, n)` | Last n characters | `right('SW1A1AA', 3)` → `'1AA'` |
| `a \|\| b` | Glues text together | `'SW1A' \|\| ' ' \|\| '1AA'` |

**Removing every space:** `replace(x, ' ', '')`

**Nesting:** functions go inside each other, innermost first.

```sql
initcap(btrim('  JOHN '))     -- btrim runs first, then initcap  ->  'John'
```

---

## Missing values

`NULL` means "we do not know". It is not the same as an empty string `''`,
and it is definitely not the same as the text `'N/A'`.

```sql
WHERE email IS NULL              -- correct
WHERE email = NULL               -- WRONG, never works
```

**`coalesce(a, b)`** returns `a`, unless `a` is NULL, in which case `b`.

```sql
coalesce(email, 'no email given')
```

**Turning junk into NULL** — the pattern you will use today:

```sql
CASE WHEN btrim(coalesce(email, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', '-')
     THEN NULL
     ELSE lower(btrim(email))
END
```

---

## CASE — "if this, then that"

```sql
CASE
    WHEN weekly_amount < 100 THEN 'low'
    WHEN weekly_amount < 200 THEN 'medium'
    ELSE 'high'
END
```

When you are comparing one thing against many values, the short form is
tidier:

```sql
CASE upper(btrim(claim_status))
    WHEN 'ACTIVE' THEN 'ACTIVE'
    WHEN 'A'      THEN 'ACTIVE'
    WHEN 'LIVE'   THEN 'ACTIVE'
    WHEN 'CLOSED' THEN 'CLOSED'
END
```

Anything not listed comes out `NULL`. That is often what you want — a `NULL`
is visible, and you can go and find out what you missed.

---

## Converting types

The `clean` tables use real types, so text has to be converted first.

```sql
util.to_number('185.15')                    -- 185.15
util.to_number('£185.15')                   -- NULL: strip the £ first
util.to_date('2026-04-06', 'YYYY-MM-DD')    -- a real date
util.to_date('06/05/1955', 'DD/MM/YYYY')    -- 6 May 1955
util.to_date('12-Jul-1948', 'DD-Mon-YYYY')  -- 12 July 1948
util.to_date('N/A', 'YYYY-MM-DD')           -- NULL
```

These give you `NULL` instead of stopping your whole script with an error.
So if a column comes out empty, your input needs more cleaning — that is the
tool telling you something useful, not a crash.

**Date format letters:** `YYYY` 4-digit year · `MM` month number · `DD` day ·
`Mon` short month name (`Jan`, `Feb`, `Mar`)

---

## Counting and grouping

```sql
SELECT town, count(*) AS people
FROM clean.address
GROUP BY town
ORDER BY people DESC;
```

**`HAVING`** filters *after* grouping — this is how you find duplicates:

```sql
SELECT nino, count(*)
FROM raw.claimant
GROUP BY nino
HAVING count(*) > 1;
```

Other useful ones: `sum(x)`, `min(x)`, `max(x)`, `count(DISTINCT x)`.

---

## Joining tables

```sql
SELECT c.first_name, a.postcode
FROM clean.claimant c
JOIN clean.address a ON a.nino = c.nino;
```

- **`JOIN`** keeps only rows that match on both sides. Handy: joining to
  `clean.claimant` quietly drops anything pointing at a person who does not
  exist.
- **`LEFT JOIN`** keeps everything on the left, filling the right with
  `NULL` where nothing matched.

**Finding orphans** — rows pointing at something that is not there:

```sql
SELECT a.*
FROM raw.address a
LEFT JOIN raw.claimant c ON c.nino = a.claimant_ref
WHERE c.nino IS NULL;
```

**`EXISTS`** does the same job and often reads better:

```sql
WHERE EXISTS (SELECT 1 FROM clean.claimant cc WHERE cc.nino = c.claimant_ref)
```

---

## WITH — naming a step

Long queries get unreadable. `WITH` lets you name each stage and build up.

```sql
WITH tidied AS (
    SELECT upper(btrim(nino)) AS nino, initcap(first_name) AS first_name
    FROM raw.claimant
)
SELECT * FROM tidied WHERE first_name = 'John';
```

You can chain as many as you like, separated by commas. Each can use the ones
before it. Your starter file is built this way.

---

## ROW_NUMBER — picking one row per group

The trick behind de-duplication.

```sql
ROW_NUMBER() OVER (PARTITION BY nino ORDER BY ingested_at DESC)
```

Read it as: *"number the rows within each person, newest first."* The newest
record gets 1, the next gets 2, and so on. Keep only `rn = 1` and you have
exactly one row per person.

**The `ORDER BY` is the whole decision.** It is what decides which record
survives. Change it and you keep a different one.

```sql
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY nino
                                 ORDER BY ingested_at DESC) AS rn
    FROM raw.claimant
)
SELECT * FROM ranked WHERE rn = 1;
```

---

## Writing your results

```sql
INSERT INTO clean.claimant (nino, first_name)
SELECT upper(btrim(nino)), initcap(btrim(first_name))
FROM raw.claimant;
```

The columns in your `SELECT` must be **in the same order** as the ones listed
after `INSERT INTO`. Names do not matter; position does.

**`TRUNCATE clean.claimant;`** empties a table. Every starter file begins
with this so you can run it as many times as you like without piling up
duplicates.

---

## Patterns (already written for you)

You will never have to write one of these today, but you will use them.

```sql
postcode ~ '^[A-Z]{1,2}[0-9][A-Z0-9]? [0-9][A-Z]{2}$'   -- is a UK postcode
nino ~ '^[A-Z]{2}[0-9]{6}[A-Z]$'                         -- is a NINO
```

`~` means "matches this pattern". `!~` means "does not match".

---

## Errors you will probably see

| Message | What it means |
|---|---|
| `relation "claimant" does not exist` | Missing schema — use `raw.claimant` |
| `syntax error at or near ...` | Usually a missing comma or bracket just before |
| `column "x" does not exist` | Typo, or the column is in another table |
| `invalid input syntax for type numeric` | Text that is not a number — use `util.to_number` |
| `duplicate key value violates unique constraint` | Inserting the same key twice — you still have duplicates |
| `INSERT has more expressions than target columns` | Your `SELECT` list is longer than your column list |

---

## Two habits worth keeping

**Run it often.** After every change. `./check.sh 1` takes seconds, and a
mistake you catch immediately is far easier than one you find at the end.

**Look before you clean.** Run the `GROUP BY` query on a column before you
write any `CASE` for it. Data always contains something you did not expect.
