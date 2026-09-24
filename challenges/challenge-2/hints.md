# Challenge 2 — Hints

**Optional.** This is the walkthrough: what to look at, what is going on, and
the SQL for every task.

Using it is completely fine — nobody is counting, and reading a hint for one
task you are stuck on is exactly what it is here for. Working without it is
harder and more satisfying. Your call, and you can change your mind per task.

Your actual file is `solution.sql`. Read `BRIEF.md` first for what the
problem is; this page is only *how*.

---

## Task 1 — The shape of what you are publishing

Written for you. Read the column lists and notice what is **not** there: no
name, no National Insurance number, no date of birth, no email, no phone.

Deciding what not to publish is most of this job, and it has already been
decided for you here.

---

## Task 2 — Replace the person with a pseudonym

**Look first**

```bash
./explore.sh sql "SELECT * FROM meta.etl_config"
```

**What is going on**

`md5(text)` turns any text into a 32-character fingerprint. The same input
always gives the same fingerprint — which is exactly what lets the join keep
working — but you cannot turn a fingerprint back into the original.

**Except you can, if the input is predictable.** There are only about a
billion possible National Insurance numbers. A laptop can hash every single
one of them in a couple of minutes, build a lookup table, and match your
"anonymous" data straight back to real people. That is a **dictionary
attack**.

The fix is a **salt**: a secret string mixed in before hashing. Without it an
attacker cannot build that table. The salt lives in `meta.etl_config`, which
is never published.

The line in your file hashes the NINO with no salt at all. One of the tests
deliberately catches that.

> **Read the salt from the config table rather than typing the text into your
> SQL.** Both give the same answer today — but a salt gets rotated, and when
> it does you want to change it in one place, not hunt through every script
> that hardcoded it. Secrets pasted into code also end up in version control,
> where they stay forever.

**What to write**

```sql
md5((SELECT value FROM meta.etl_config
     WHERE setting = 'pseudonymisation_salt') || c.nino),
```

`||` glues text together, so this is "the salt, then the NINO, all hashed".

---

## Task 3 — The payment table, and the point of the whole challenge

**Look first**

Run your file, then look at what came out:

```bash
./explore.sh peek analytics.payment_anon
```

The `person_id` column is still full of raw National Insurance numbers. That
is the exact thing you were told not to publish, and a test is already
failing because of it.

**But there is a second, subtler problem.** Try joining your two published
tables together:

```bash
./explore.sh sql "SELECT count(*) FROM analytics.payment_anon p
                  JOIN analytics.claimant_anon c ON c.person_id = p.person_id"
```

You get **0**. Not an error — just nothing. One table holds hashes and the
other holds NINOs, so no row matches any other row. The data is published, it
looks fine, and it is completely useless.

> ### This is the lesson
>
> A pseudonym has to be built the **same way everywhere it appears**, or the
> tables stop joining and nobody notices until an analyst quietly reports a
> total of zero.

Two tests prove it worked: one counts the payments that find their person
through the join, and one adds up the money. If your two recipes differ by so
much as a space, both come back empty.

**What to write** — exactly the same expression as Task 2, with `p.nino`:

```sql
md5((SELECT value FROM meta.etl_config
     WHERE setting = 'pseudonymisation_salt') || p.nino),
```

---

## Task 4 — Publish the fact, not the date

`curated.claimant` has a `date_of_death`. An exact date of death is personal
information, and an analyst almost never needs it — what they need is
**whether** the person has died.

So publish a true/false, not a date.

In SQL a comparison is already true or false, so you do not need a `CASE`.
`c.date_of_death IS NOT NULL` is true for somebody who has died and false for
somebody who has not.

**What to write**

```sql
(c.date_of_death IS NOT NULL)
```

---

## Task 5 — Leave the personal columns out

Nothing to type. There is no line in the query for the name, the email, the
phone or the date of birth, and there is no column for them in the target
table either.

**Not selecting them is the suppression step.** It is the easiest task of the
day and the one that matters most.

---

## Bonus

Only once every core test is green.

### Bonus A — An age band instead of a date of birth

An exact date of birth identifies people; an age band does not. The
`age_band` column is sitting there empty.

Work the age out against `DATE '2026-04-06'`, **never today's date**, so that
everybody's answer matches:

```sql
date_part('year', age(DATE '2026-04-06', c.date_of_birth))
```

Watch your boundaries: `70-74` means 70, 71, 72, 73 **and** 74.

Replace the `NULL` in the claimant query with:

```sql
CASE
    WHEN date_part('year', age(DATE '2026-04-06', c.date_of_birth)) < 70 THEN '65-69'
    WHEN date_part('year', age(DATE '2026-04-06', c.date_of_birth)) < 75 THEN '70-74'
    WHEN date_part('year', age(DATE '2026-04-06', c.date_of_birth)) < 80 THEN '75-79'
    WHEN date_part('year', age(DATE '2026-04-06', c.date_of_birth)) < 85 THEN '80-84'
    ELSE '85+'
END,
```

### Bonus B — A summary table, built through the join

Analysts mostly want totals, not rows. Build one row per person: how many
payments, and how much in total.

This only works if Task 3 is right, so it doubles as proof that your join
survived.

Add at the end of your file:

```sql
CREATE TABLE analytics.payment_summary AS
SELECT c.person_id,
       count(*)::int                AS payment_count,
       sum(p.amount)::numeric(12,2) AS total_paid
FROM analytics.payment_anon p
JOIN analytics.claimant_anon c ON c.person_id = p.person_id
GROUP BY c.person_id;
```