# Team 1 — Hints

**Optional.** This is the walkthrough: what to look at, what is going on, and
the SQL for every task.

Using it is completely fine — nobody is counting, and reading a hint for one
task you are stuck on is exactly what it is here for. Working without it is
harder and more satisfying. Your call, and you can change your mind per task.

Your actual file is `solution.sql`. Read `BRIEF.md` first for what the
problem is; this page is only *how*.

---

## Task 1 — Tidy the names

**Look first**

```bash
./explore.sh values raw.claimant first_name
```

Read the **summary line it prints before the list of values**. It tells you
how many names have stray spaces and how many are not in Title Case. The list
underneath is sorted by how common each name is, so the messy ones are near
the bottom and easy to miss.

**What is going on**

You are looking at things like `'  John'`, `'JOHN  '`, `'john'`. All the same
name, all written differently, and to the database all different people.

Two functions fix it:

| | |
|---|---|
| `btrim(x)` | removes spaces from both ends |
| `initcap(x)` | makes it `Look Like This` |

They nest, innermost first: `initcap(btrim(first_name))`.

**What to write**

```sql
initcap(btrim(first_name))                    AS first_name,
initcap(btrim(last_name))                     AS last_name,
```

---

## Task 2 — `'N/A'` is not a value

**Look first**

```bash
./explore.sh values raw.claimant marital_status
```

**What is going on**

The old systems had no way to record "we do not know", so people typed
whatever fitted:

```
''    'N/A'    'UNKNOWN'    'NULL'    'n/a'    '-'
```

None of those are marital statuses. They all mean *no value*, and in a
database that is spelled `NULL` — a real thing meaning "nothing here", not
the four letters N-U-L-L.

`marital_status` is **already done for you** in the file. Copy that `CASE`
onto the two lines underneath it.

**One difference for email.** `marital_status` is a word, so it uses
`initcap()`. An email address is not a word — it should be all lower case.
`Derek469@Webmail.Invalid` is not an email address. For phone, `btrim(phone)`
is fine.

**What to write**

```sql
CASE WHEN btrim(coalesce(email, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')
     THEN NULL
     ELSE lower(btrim(email))
END                                           AS email,
CASE WHEN btrim(coalesce(phone, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')
     THEN NULL
     ELSE btrim(phone)
END                                           AS phone,
```

---

## Task 3 — One spelling for each National Insurance number

**Look first**

```bash
./explore.sh sql "SELECT nino FROM raw.claimant ORDER BY random() LIMIT 20"
```

**What is going on**

The same number, written five different ways:

```
'QQ123456C'    'qq123456c'    'QQ 12 34 56 C'    'QQ-12-34-56-C'    '  QQ123456C  '
```

These are all the **same person**. Until every one of them is written
identically, the database cannot tell that.

The line in your file already handles the capitals and the spaces on the
*outside*. It does not handle the spaces in the *middle*, or the dashes.

`replace(text, ' ', '')` removes every space. They nest, like `initcap` and
`btrim` did.

**What to write**

```sql
upper(replace(replace(btrim(nino), ' ', ''), '-', '')) AS nino,
```

---

## Task 4 — Look before you delete

Nothing to edit. Run these three and think about what they tell you.

**(a) How many people are in here more than once?**

```sql
SELECT count(*) FROM (
    SELECT nino FROM raw.claimant
    GROUP BY nino HAVING count(*) > 1
) x;
```

You should get **58**.

**(b) Now count the rows and think about that number**

```sql
SELECT count(*) FROM raw.claimant;
```

1500 rows. Your brief says there are about 1200 real people. That is **300
extra rows** — but query (a) only found 58 people with a duplicate.

58 duplicated people cannot produce 300 extra rows. **So where are the rest
hiding?**

Think about what `GROUP BY nino` actually compares. Is `'QQ123456C'` the same
value as `'qq123456c'`? To you, yes. To the database, no.

> This is why Task 3 exists. Once every NINO is written the same way, run
> query (a) again and watch the number change.

**(c) Now look at one person properly**

```sql
SELECT record_id, nino, email, source_system, ingested_at
FROM raw.claimant
WHERE nino IN ('QQ209469B','qq209469b','QQ-20-94-69-B')
ORDER BY ingested_at;
```

Three records. One man. **Three different email addresses.** Which one is
correct? Nothing in the data tells you. Somebody has to decide — and that is
Task 5.

---

## Task 5 — Decide which record survives

**What is going on**

`ROW_NUMBER()` does not delete anything. It walks through each person's
records and writes 1, 2, 3 into a column called `rn`. **The `ORDER BY`
decides who gets the 1.**

Right now it says `ORDER BY record_id`, which is meaningless — it keeps
whichever record happened to be typed first.

> **The rule the agency uses: the most recently ingested record wins.**

The second part of the `ORDER BY` only breaks ties, so the answer is the same
every time you run it.

**What to write**

```sql
ROW_NUMBER() OVER (PARTITION BY nino
                   ORDER BY ingested_at DESC, record_id DESC) AS rn
```

Change it, re-run, and watch Derek's email change.

**And the line below it**

```sql
WHERE rn = 1;
```

That is what actually removes the duplicates, and it is already written. It
always keeps number 1 — your `ORDER BY` decides who number 1 *is*.

---

## Bonus

Only once every core test is green.

### Bonus A — Tidy the titles to exactly `Mr`, `Mrs`, `Ms`, `Miss`

```bash
./explore.sh values raw.claimant title
```

You will find `'MR.'`, `'mr'`, `'Mr.'` and more. Two functions do it: one to
fix the capitals, one to get rid of the full stop.

```sql
replace(initcap(btrim(title)), '.', '')       AS title,
```

### Bonus B — Recover the best available email

Some people lose their email in Task 5, because the newest record happens to
have `'N/A'` in it even though an older record had a real address. Keeping
the newest record should not mean throwing away information you already had.

`max(email) OVER (PARTITION BY nino)` gives you an email from **any** of that
person's records. `coalesce()` picks the first non-NULL value.

Add to the `ranked` block:

```sql
max(email) OVER (PARTITION BY nino)           AS fallback_email
```

and in the final `SELECT`, use `coalesce(email, fallback_email)` instead of
`email`.

### Bonus C — Phone numbers as 11 digits, no spaces

`'07700 900123'` should become `'07700900123'`.

```sql
ELSE replace(btrim(phone), ' ', '')
```