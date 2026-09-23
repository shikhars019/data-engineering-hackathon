# Team 1 — The Duplicate Claimants

**Challenge 1 · 60 minutes · 9 core tests + 3 bonus**

---

## The situation

You have joined the data engineering team at a government agency. Your first ticket is waiting.

State Pension records reach us from three systems that have never properly
talked to each other:

| System | What it is |
|---|---|
| `CIS` | The old mainframe. Decades of records. Shouts in capitals. |
| `LEGACY_CSV` | Spreadsheets emailed in by regional offices. Anything goes. |
| `DIGITAL` | The modern online service. Tidiest, but not perfect. |

When somebody moves house, reports a death, or rings the helpline, whichever
system they touched creates a record. Nobody ever joined them up.

So **the same pensioner is in our database more than once.**

## Why it matters

> Last month a review found that a small number of pensioners were being
> counted twice in departmental statistics. Nobody was paid twice — but the
> published figures were wrong, and correcting them in public is expensive
> and embarrassing.

Your job: turn 1,500 muddled records into **one row per real person**.

## What makes it hard

The National Insurance number should identify a person. Look at how it is
written:

```
QQ123456C        qq123456c        QQ 12 34 56 C
QQ-12-34-56-C      QQ123456C        Qq123456c
```

Six spellings. One person. Until you agree on a single way of writing it,
the database cannot tell they are the same.

And when you have found the duplicates, you have to decide **which record to
keep** — because they disagree with each other. Different email addresses,
different phone numbers, some fields blank. There is no "correct" answer in
the data. Someone has to make a rule.

**The rule the agency uses: the most recently ingested record wins.**

---

## Your tasks

Open `challenges/challenge-1/team-1/solution.sql`. Everything is in there,
with the guidance next to the code.

| # | Task | Tests it turns green |
|---|---|---|
| 1 | Tidy the names — trim the spaces, fix the capitals | C1.05, C1.06 |
| 2 | Turn `'N/A'`, `'UNKNOWN'` and `''` into real `NULL`s | C1.07 |
| 3 | Agree one spelling for the National Insurance number | C1.04 |
| 4 | Look at the duplicates before deleting anything | *(investigation)* |
| 5 | Decide which record survives | C1.01, C1.02, C1.03, C1.08, C1.09 |

**Start with Task 1.** It is about three minutes' work and turns two tests
green straight away, which proves your setup works.

### Bonus, once all nine core tests are green

- **A** — Tidy the titles to exactly `Mr`, `Mrs`, `Ms`, `Miss`
- **B** — Recover the best available email, not just the newest one
- **C** — Store phone numbers as 11 digits with no spaces

---

## How to work

```bash
./start.sh 1        # once, at the beginning
./check.sh 1        # after every change — this is your feedback loop
```

Browse the data in TablePlus (`localhost:55432`), or from the terminal:

```bash
./explore.sh values raw.claimant first_name
```

**Look at the data before you write any SQL.** Every task in your file starts
with a LOOK FIRST query for exactly this reason. You cannot clean something
you have not seen.

Made a mess? `./reset.sh` gives you a fresh database in twenty seconds. It is
not cheating and nobody is counting.

---

## The one thing to take away

De-duplication is never really a SQL problem. The hard part is deciding
**which version of the truth wins** — and that is a decision about the
business, not about the database. Your `ORDER BY` is where that decision
gets written down.
