# Team 2 — Hints

**Optional.** This is the walkthrough: what to look at, what is going on, and
the SQL for every task.

Using it is completely fine — nobody is counting, and reading a hint for one
task you are stuck on is exactly what it is here for. Working without it is
harder and more satisfying. Your call, and you can change your mind per task.

Your actual file is `solution.sql`. Read `BRIEF.md` first for what the
problem is; this page is only *how*.

---

## Tasks 1, 2 and 3 — Read each system's dates

**Look first**

```bash
./explore.sh sql "SELECT DISTINCT ON (source_system)
                         source_system, date_of_birth, date_of_death
                  FROM raw.claimant ORDER BY source_system, random()"
```

`DISTINCT ON` gives you one example row per system, which is exactly what you
need here. A plain `LIMIT 30` would show you thirty rows from whichever
system sorts first, and you would never discover the other two formats.

**What is going on**

Three completely different styles:

| System | Example | Meaning |
|---|---|---|
| `CIS` | `1955-08-31` | year, month, day |
| `LEGACY_CSV` | `06/05/1955` | day/month/year — **British order** |
| `DIGITAL` | `12-Jul-1948` | day-monthname-year |

`util.to_date(text, format)` turns text into a real date. If the text does
not match the format you give it, you get `NULL` rather than an error — so a
wrong format shows up as a missing date, not a crash. **An empty column means
your format string is wrong.**

Format letters:

| | |
|---|---|
| `YYYY` | 4-digit year |
| `MM` | month number |
| `DD` | day |
| `Mon` | `Jan`, `Feb`, `Mar` … |

Task 1 (CIS) is already done and its test passes. Copy the shape of it — you
are changing **only the text inside the quotes**.

**What to write**

```sql
CASE source_system
    WHEN 'CIS'        THEN util.to_date(date_of_birth, 'YYYY-MM-DD')
    WHEN 'LEGACY_CSV' THEN util.to_date(date_of_birth, 'DD/MM/YYYY')
    WHEN 'DIGITAL'    THEN util.to_date(date_of_birth, 'DD-Mon-YYYY')
END                                                    AS dob,
```

---

## Task 4 — Dates of death, written the same three ways

Exactly the same problem, the same three formats. Once Tasks 2 and 3 work,
put the same two format strings here.

Most people are alive, so most of these are blank. That is fine —
`util.to_date` gives `NULL` for a blank.

**What to write**

```sql
CASE source_system
    WHEN 'CIS'        THEN util.to_date(date_of_death, 'YYYY-MM-DD')
    WHEN 'LEGACY_CSV' THEN util.to_date(date_of_death, 'DD/MM/YYYY')
    WHEN 'DIGITAL'    THEN util.to_date(date_of_death, 'DD-Mon-YYYY')
END                                                    AS dod,
```

---

## Task 5 — Impossible deaths

**Look first**

```bash
./explore.sh sql "SELECT nino, date_of_birth, date_of_death, source_system
                  FROM raw.claimant WHERE date_of_death LIKE '%2029%' LIMIT 10"
```

**What is going on**

Some records say the person died **before they were born**. Others say they
died in **2029**, which has not happened yet. Both are data entry errors, not
deaths.

A wrong date is worse than a missing one. A missing date is obviously
missing. A wrong one gets used.

Today, for this whole exercise, is always `DATE '2026-04-06'`.

**What to write**

Replace the bare `dod` with:

```sql
CASE WHEN dod IS NULL             THEN NULL
     WHEN dod <= dob              THEN NULL
     WHEN dod > DATE '2026-04-06' THEN NULL
     ELSE dod
END,
```

---

## Task 6 — Leave out what cannot be rescued

**Look first**

```bash
./explore.sh values raw.claimant date_of_birth
```

Read the summary line at the top, not the list.

**What is going on**

Three kinds of unusable birth date:

| Value | What it is |
|---|---|
| `1900-01-01` | a placeholder the old systems used for "no idea" |
| `9999-12-31` | another placeholder, meaning "never" or "unknown" |
| `''`, `'N/A'` | blank — and some dates in 2031 where somebody mistyped |

None can be repaired, and a guess would be worse than nothing. Leave them
out. A State Pension claimant in 2026 was born between about 1930 and 1961;
anything outside that is wrong.

The line in your file keeps every row that produced a date at all. That is
not enough — `1900-01-01` is a perfectly valid date, it is just not a real
birthday.

**What to write**

```sql
WHERE dob IS NOT NULL
  AND dob >= DATE '1930-01-01'
  AND dob <= DATE '2026-04-06'
;
```

---

## Bonus

Only once every core test is green.

### Bonus A — `clean.claim` has exactly the same problem

Claim start dates come in the same three styles. The twist: `raw.claim` has
no `source_system` column, so you have to join back to `raw.claimant` to find
out which system the person came from.

```sql
INSERT INTO clean.claim (claim_ref, nino, claim_status, pension_type,
                         claim_start_date, qualifying_years, weekly_amount,
                         deferral_indicator, payment_frequency)
SELECT c.claim_ref,
       c.claimant_ref,
       c.claim_status,
       c.pension_type,
       CASE r.source_system
           WHEN 'CIS'        THEN util.to_date(c.claim_start_date, 'YYYY-MM-DD')
           WHEN 'LEGACY_CSV' THEN util.to_date(c.claim_start_date, 'DD/MM/YYYY')
           WHEN 'DIGITAL'    THEN util.to_date(c.claim_start_date, 'DD-Mon-YYYY')
       END,
       util.to_number(c.qualifying_years)::int,
       util.to_number(c.weekly_amount),
       upper(btrim(c.deferral_indicator)) IN ('Y','YES','TRUE','T','1'),
       c.payment_frequency
FROM raw.claim c
JOIN raw.claimant   r  ON upper(btrim(r.nino)) = upper(btrim(c.claimant_ref))
JOIN clean.claimant cc ON cc.nino              = upper(btrim(c.claimant_ref));
```

### Bonus B — Nobody claims before they turn 66

Once Bonus A works, the last test checks that no claim starts before the
claimant's 66th birthday. If your date formats are right, it should already
be true.

That test reports two numbers — how many claims were too early, **and how
many it looked at**. The second one is there on purpose: an empty
`clean.claim` also has zero claims that are too early, and that is not the
same thing as a clean one.