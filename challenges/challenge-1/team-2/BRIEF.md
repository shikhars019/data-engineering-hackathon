# Team 2 — The Date Disaster

**Challenge 1 · 60 minutes · 8 core tests + 3 bonus**

---

## The situation

You have joined the data engineering team at a government agency. Your first ticket is waiting.

State Pension records reach us from three systems that have never properly
talked to each other:

| System | How it writes the 6th of May 1955 |
|---|---|
| `CIS` | `1955-05-06` — year, month, day |
| `LEGACY_CSV` | `06/05/1955` — day/month/year |
| `DIGITAL` | `06-May-1955` — day-month name-year |

Every one of those dates is stored as **plain text**. Nothing has ever
checked that they are dates at all.

## Why it matters

State Pension age is 66. A date of birth is not a detail — it is the thing
that decides whether somebody gets paid, and when.

> `06/05/1955` is the 6th of May to a British system and the 5th of June to
> an American one. One month of State Pension is about £960. Read the date
> wrong and you have either underpaid a pensioner or overpaid the country.

You cannot guess which format a row uses. You have to know **which system
sent it** — which is exactly what the `source_system` column is for.

## What makes it hard

Beyond the three formats, the old systems had no way to say "we do not know",
so people typed something that would fit:

```
1900-01-01      a placeholder meaning "no idea"
9999-12-31      another placeholder, meaning "never" or "unknown"
2031-06-12      somebody typed the year wrong
''  'N/A'       blank
```

And some records are simply impossible: people who died **before they were
born**, and people recorded as dying in **2029**.

A wrong date is worse than a missing date. A missing date is obviously
missing. A wrong one gets used.

---

## Your tasks

Open `challenges/challenge-1/team-2/solution.sql`. Everything is in there,
with the guidance next to the code.

| # | Task | Tests it turns green |
|---|---|---|
| 1 | Read `CIS` dates — **already written for you** | *(none — it is your worked example)* |
| 2 | Read `LEGACY_CSV` dates (day/month/year) | C2.04 |
| 3 | Read `DIGITAL` dates (`12-Jul-1948`) | C2.05 |
| 4 | Convert dates of death the same three ways | C2.06 |
| 5 | Discard impossible deaths | C2.07 |
| 6 | Leave out the birth dates that cannot be rescued | C2.01, C2.02, C2.03, C2.08 |

**Task 1 is already finished.** Read it first — it is the pattern for Tasks 2
and 3, which are one word each. Nothing scores for it: every test on the
scorecard starts red, and each one goes green because of something you did.

### Bonus, once all eight core tests are green

- **A** — `clean.claim` has the same problem. Note `raw.claim` has no
  `source_system` column, so you will need to join back to find it.
- **B** — Prove nobody claimed their pension before turning 66.

---

### Hints are there if you want them

Your folder has three files:

| File | What it is |
|---|---|
| `BRIEF.md` | this page — the problem, and why it matters |
| `solution.sql` | the file you edit |
| `hints.md` | **optional.** A full walkthrough: what to look at, what is going on, and the SQL for every task |

**Using `hints.md` is completely fine and nobody is counting.** It is there so
that being stuck never costs you the rest of the hour.

**Not using it is harder and more satisfying.** If you want the tougher run,
work from `BRIEF.md` and the failing tests alone, and open `hints.md` only
when you have genuinely run out of ideas — for one task, not the whole thing.

Either way you can change your mind at any point.

---

## How to work

```bash
./start.sh 2        # once, at the beginning
./check.sh 2        # WRONG - that runs Challenge 2
./check.sh 1        # after every change — this is your feedback loop
```

Browse the data in TablePlus (`localhost:55432`), or from the terminal:

```bash
./explore.sh sql "SELECT source_system, date_of_birth FROM raw.claimant LIMIT 30"
```

**Look at the data before you write any SQL.** You cannot clean something you
have not seen, and `./explore.sh` is how you look. (If you open `hints.md`,
every task there starts with a suggested LOOK FIRST query.)

Made a mess? `./reset.sh` gives you a fresh database in twenty seconds. It is
not cheating and nobody is counting.

### A useful habit

`util.to_date(text, format)` hands back `NULL` when the text does not match
the format, instead of stopping your whole script with an error. So if a
column comes out empty, your format string is wrong — that is the tool
telling you something, not a crash.

---

## The one thing to take away

A date in a database is not the same thing as a date written down. Text that
*looks* like a date carries no promise that it is one, and no promise about
what order the numbers are in. Somewhere, somebody has to decide — and write
that decision down in code.
