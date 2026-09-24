# Team 3 — Hints

**Optional.** This is the walkthrough: what to look at, what is going on, and
the SQL for every task.

Using it is completely fine — nobody is counting, and reading a hint for one
task you are stuck on is exactly what it is here for. Working without it is
harder and more satisfying. Your call, and you can change your mind per task.

Your actual file is `solution.sql`. Read `BRIEF.md` first for what the
problem is; this page is only *how*.

---

## Task 1 — Load the people

Written for you. Leave it alone — your work is the addresses.

---

## Task 2 — Tidy the address line and the town

**Look first**

```bash
./explore.sh values raw.address town
```

Read the summary line it prints **before** the list. It tells you how many
values have stray spaces and how many are not in Title Case.

**What is going on**

Same two functions as any other piece of text:

| | |
|---|---|
| `btrim(x)` | removes spaces from both ends |
| `initcap(x)` | makes it `Look Like This` |

Leave `address_line_2` alone — it is mostly empty and nothing checks it.

**What to write**

```sql
initcap(btrim(address_line_1))              AS line_1,
initcap(btrim(town))                        AS town,
```

---

## Task 3 — Put ONE space back into the postcode

**Look first**

```bash
./explore.sh values raw.address postcode
```

**What is going on**

A UK postcode is always "some characters, one space, then exactly three
characters":

```
SW1A 1AA        M14 5TG        B1 1AA
```

So **the space always goes three characters from the end**. That rule works
whatever the postcode looks like, which is exactly why the `squashed` block
flattened them all first.

| | |
|---|---|
| `left(text, n)` | the first n characters |
| `right(text, n)` | the last n characters |
| `length(text)` | how long it is |
| `a \|\| b` | glues two pieces of text together |

Leave the `CASE` around it. Some values are rubbish like `'N/A'` or `'TBC'`,
and taking three characters off something two long makes no sense. The `CASE`
keeps those out of the way for now — you deal with them properly in Task 4.

**What to write**

```sql
CASE WHEN length(pc_squashed) BETWEEN 5 AND 7
     THEN left(pc_squashed, length(pc_squashed) - 3)
          || ' ' || right(pc_squashed, 3)
END                                         AS postcode,
```

---

## Task 4 — Throw out the postcodes that are not postcodes

**Look first**

```bash
./explore.sh values raw.address postcode
```

The junk is right at the top of that list, because the same rubbish was typed
over and over: `'N/A'`, `'TBC'`, `'NOT KNOWN'`, `'12345'`, `'SW1A'`.

**Careful.** `'UNKNOWN'` and `'12345'` are both 5–7 characters long, so Task 3
happily turned them into `'UNKN OWN'` and `'12 345'`. They look like
postcodes now. They are not.

Here is a pattern that matches a real UK postcode. You do not need to
understand it, only use it. The `~` means "matches".

**What to write** — replace the first condition:

```sql
WHERE t.postcode ~ '^[A-Z]{1,2}[0-9][A-Z0-9]? [0-9][A-Z]{2}$'
```

---

## Task 5 — Throw out addresses belonging to nobody

**Look first**

```bash
./explore.sh sql "SELECT count(*) FROM raw.address a
                  WHERE NOT EXISTS (SELECT 1 FROM raw.claimant c
                  WHERE upper(btrim(c.nino)) = upper(btrim(a.claimant_ref)))"
```

**What is going on**

Some addresses quote a National Insurance number that is not in the claimant
table at all. They came from a system that was switched off and the people
were never migrated. An address with no person attached cannot be used for
anything.

**What to write** — replace the second condition:

```sql
  AND EXISTS (SELECT 1 FROM clean.claimant c WHERE c.nino = t.nino)
```

Read it as: keep this row only if a matching person exists.

> **One trap.** Some people have two addresses and one of them is rubbish;
> some have only one. If you throw out every bad row without looking, you can
> leave a real pensioner with **no address at all** — and a test checks for
> exactly that.

---

## Task 6 — Which address does the person live at NOW?

**Look first — the flag cannot be trusted**

```bash
./explore.sh sql "SELECT claimant_ref, address_id, valid_from, is_current
                  FROM raw.address WHERE claimant_ref IN (
                    SELECT claimant_ref FROM raw.address
                    GROUP BY 1 HAVING count(*) > 1)
                  ORDER BY claimant_ref, valid_from LIMIT 20"
```

You will find people with **two addresses both flagged `Y`**, and people with
none flagged at all. That column was filled in by hand and nobody ever
maintained it.

What you **can** trust is `valid_from`. The address somebody moved to most
recently is the one they live at now.

`ROW_NUMBER()` does not delete anything — it numbers each person's addresses
1, 2, 3. **The `ORDER BY` decides who gets the 1.**

**What to write**

```sql
ROW_NUMBER() OVER (PARTITION BY nino
                   ORDER BY valid_from DESC, address_id DESC) AS rn
```

The `(rn = 1) AS is_current` at the bottom is already written. It always
trusts number 1 — your `ORDER BY` decides who that is.

---

## Bonus — pensioners per region

Only once every core test is green.

An analyst has asked a simple question: **how many pensioners live in each
region?** Nobody can answer it from `clean.address`, because an address holds
a postcode, not a region. That is what `ref.postcode_area` is for.

```bash
./explore.sh sql "SELECT * FROM ref.postcode_area ORDER BY region, area_code"
```

This expression pulls the letters off the front of a postcode — use it as-is:

```sql
substring(postcode from '^[A-Z]{1,2}')
```

Three things to get right: count each person **once** (current addresses
only), one row per region, and name the columns exactly `region` and
`claimant_count`.

```sql
DROP TABLE IF EXISTS clean.address_summary;
CREATE TABLE clean.address_summary AS
SELECT r.region,
       count(*)::int AS claimant_count
FROM clean.address a
JOIN ref.postcode_area r
  ON r.area_code = substring(a.postcode from '^[A-Z]{1,2}')
WHERE a.is_current
GROUP BY r.region;
```