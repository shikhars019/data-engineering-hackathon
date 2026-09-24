# Team 5 — Hints

**Optional.** This is the walkthrough: what to look at, what is going on, and
the SQL for every task.

Using it is completely fine — nobody is counting, and reading a hint for one
task you are stuck on is exactly what it is here for. Working without it is
harder and more satisfying. Your call, and you can change your mind per task.

Your actual file is `solution.sql`. Read `BRIEF.md` first for what the
problem is; this page is only *how*.

---

## Task 1 — Claim status. Read this one.

Already done, and its test already passes. It is the pattern for Tasks 2
and 4, so read it before you write anything.

```bash
./explore.sh values raw.claim claim_status
```

Thirteen spellings, three actual meanings. `upper(btrim(x))` goes on the
front so you only list each spelling once instead of worrying about capitals
and stray spaces separately.

Anything **not** listed comes out `NULL`. That is deliberate: a `NULL` is
visible and countable, so you can find what you missed.

---

## How to check your own work

This is the most useful thing on this page.

Miss one spelling and it silently becomes `NULL`. Rather than comparing
fourteen values against your `CASE` by eye, ask the database which ones you
failed to handle. **After running your file:**

```bash
./explore.sh sql "SELECT DISTINCT r.pension_type AS i_missed_this
                  FROM raw.claim r
                  JOIN clean.claim c ON c.claim_ref = r.claim_ref
                  WHERE c.pension_type IS NULL"
```

It names exactly the spellings your `CASE` did not cover. That trick — an
unmapped-value report — is a real data engineering technique, and it works
for Tasks 4 and 6 too.

---

## Task 2 — Pension type: two schemes, one answer

**Look first**

```bash
./explore.sh values raw.claim pension_type
```

**What is going on**

Fourteen spellings. This one needs you to **think**, not just type, because
there are **two different naming schemes** in one column, from two eras:

| Scheme | Spellings |
|---|---|
| the modern names | `New State Pension`, `nSP`, `NSP`, `NEW`, `Single Tier`, `ST` |
| the old categories | `Category A`, `CAT A`, `Category B`, `CAT B` |

`Category A` and `Category B` are legal categories of the **old** pension, so
**both** become `BASIC_STATE_PENSION`. Getting that wrong is easy, and the
counts will tell you.

Allowed answers: `NEW_STATE_PENSION`, `BASIC_STATE_PENSION`.

**What to write**

```sql
CASE upper(btrim(c.pension_type))
    WHEN 'NEW STATE PENSION'   THEN 'NEW_STATE_PENSION'
    WHEN 'NSP'                 THEN 'NEW_STATE_PENSION'
    WHEN 'NEW'                 THEN 'NEW_STATE_PENSION'
    WHEN 'SINGLE TIER'         THEN 'NEW_STATE_PENSION'
    WHEN 'ST'                  THEN 'NEW_STATE_PENSION'
    WHEN 'BASIC STATE PENSION' THEN 'BASIC_STATE_PENSION'
    WHEN 'BSP'                 THEN 'BASIC_STATE_PENSION'
    WHEN 'BASIC'               THEN 'BASIC_STATE_PENSION'
    WHEN 'CATEGORY A'          THEN 'BASIC_STATE_PENSION'
    WHEN 'CAT A'               THEN 'BASIC_STATE_PENSION'
    WHEN 'CATEGORY B'          THEN 'BASIC_STATE_PENSION'
    WHEN 'CAT B'               THEN 'BASIC_STATE_PENSION'
END,
```

---

## Task 3 — A yes/no flag with eleven spellings

**Look first**

```bash
./explore.sh values raw.claim deferral_indicator
```

`Y`, `y`, `YES`, `Yes`, `TRUE`, `T`, `1` all mean yes.
`N`, `NO`, `FALSE`, `F`, `0` and empty all mean no.

The column in `clean.claim` is a real `BOOLEAN`, so it needs true/false, not
text. **You do not need a `CASE` here** — in SQL a comparison is already true
or false. Watch the empty ones though: `coalesce(x, 'N')` turns a missing
value into a no.

**What to write**

```sql
upper(btrim(coalesce(c.deferral_indicator,'N'))) IN ('Y','YES','TRUE','T','1'),
```

---

## Task 4 — How often they get paid

**Look first**

```bash
./explore.sh values raw.claim payment_frequency
```

Allowed answers: `WEEKLY`, `FOUR_WEEKLY`, `QUARTERLY`.

**Careful:** `1`, `4` and `13` are in there too. They are the number of
**weeks between payments**, not a count of anything.

**What to write**

```sql
CASE upper(btrim(c.payment_frequency))
    WHEN 'WEEKLY'      THEN 'WEEKLY'
    WHEN 'W'           THEN 'WEEKLY'
    WHEN 'WKLY'        THEN 'WEEKLY'
    WHEN '1'           THEN 'WEEKLY'
    WHEN '4-WEEKLY'    THEN 'FOUR_WEEKLY'
    WHEN '4W'          THEN 'FOUR_WEEKLY'
    WHEN 'FOUR WEEKLY' THEN 'FOUR_WEEKLY'
    WHEN '4'           THEN 'FOUR_WEEKLY'
    WHEN '4 WEEKLY'    THEN 'FOUR_WEEKLY'
    WHEN 'QUARTERLY'   THEN 'QUARTERLY'
    WHEN 'Q'           THEN 'QUARTERLY'
    WHEN 'QTR'         THEN 'QUARTERLY'
    WHEN '13'          THEN 'QUARTERLY'
END
```

---

## Task 5 — Claims for people who do not exist

**Look first**

```bash
./explore.sh sql "SELECT count(*) FROM raw.claim c
                  WHERE NOT EXISTS (SELECT 1 FROM raw.claimant p
                  WHERE upper(btrim(p.nino)) = upper(btrim(c.claimant_ref)))"
```

Thirty claims quote a National Insurance number that is not in the claimant
table at all. They came from a system that was switched off and nobody
migrated the people. A claim with no claimant cannot be paid, cannot be
reported on, and must not be counted.

**What to write**

```sql
WHERE EXISTS (SELECT 1 FROM clean.claimant cc
              WHERE cc.nino = upper(btrim(c.claimant_ref)))
```

---

## Task 6 — Use the lookup, and cope when it lets you down

**Look first — the mapping table**

```bash
./explore.sh sql "SELECT * FROM ref.code_mapping WHERE domain='payment_method'"
```

**Look first — what is actually in the data**

```bash
./explore.sh values raw.payment payment_method
```

Compare the two lists. The mapping table is maintained by another team and
they have not kept up — some spellings in the data are simply not in it.

The `LEFT JOIN` in your file already brings the mapping in. A `LEFT JOIN`
keeps every payment even when nothing matches; for those rows
`m.standard_value` is `NULL`.

**Do not drop those rows.** A payment you cannot categorise is still a
payment, and losing it makes the totals wrong. **Do not leave it `NULL`
either** — then "could not map this" looks identical to "nothing was here".
Mark it `UNKNOWN` so it stays visible and somebody can fix the mapping next
week.

**What to write**

```sql
coalesce(m.standard_value, 'UNKNOWN'),
```

---

## Task 7 — Payments for claims that are not there

The same problem one level down. Some payments quote a claim reference that
is not in `clean.claim`.

Note it must be checked against **your cleaned claims**, not the raw ones: a
payment belonging to one of the orphan claims you removed in Task 5 has just
become an orphan itself.

**What to write**

```sql
WHERE EXISTS (SELECT 1 FROM clean.claim c WHERE c.claim_ref = p.claim_ref)
```

---

## Bonus

Only once every core test is green. All three should already be true if your
mappings are right — they are a free check that you did not miss a spelling.

- **A** — How many claims are `SUSPENDED`?
- **B** — How many are paid four-weekly?
- **C** — Make sure no payment method came out `NULL`. "Not in the mapping
  table" and "missing" are different things, and only one is acceptable.