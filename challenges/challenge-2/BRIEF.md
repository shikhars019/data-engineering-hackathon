# Challenge 2 — Safe Data for Analysts

**60 minutes · 9 core tests + 3 bonus · the same challenge for every team**

---

## The situation

Overnight the pipeline has landed two clean tables in the `curated` schema.
Somebody else did the cleaning. It is good data.

```
   curated.claimant  ----- joined on nino ----->  curated.payment
   who they are                                   what they were paid
```

It is also **full of personal information** — names, dates of birth, email
addresses, phone numbers and National Insurance numbers.

Analysts and researchers want it: forecasting what pensions will cost next
year, checking nobody is being missed. They have good reasons. **None of
them may ever see who anybody is.**

Your job is to publish both tables into the `analytics` schema with the
National Insurance number replaced by a pseudonym — **and with the join
between them still working**.

> This is a real job with a real name: **pseudonymisation**. Anyone can
> delete a column. The skill is removing the identifier while keeping the
> data usable.

---

## The thing that makes it hard

Deleting the NINO is easy. Deleting it *and* keeping the two tables linked
is not.

If you replace it with something random, the tables stop joining and the
data is worthless. If you replace it with something predictable, you have
not really hidden anything. It has to be **the same value every time, in
both tables, and impossible to reverse**.

Your starter file already gets this wrong on purpose. When you first run
it, one table holds hashes and the other still holds raw National Insurance
numbers, so joining them returns **zero rows**. Not an error — just
nothing. That is the failure mode you are learning to avoid, and it is the
one that gets shipped in real life, because nothing looks broken.

---

## Your tasks

Open `challenges/challenge-2/solution.sql`. There are **three lines to
change**, and the file names them at the top.

| # | Task | The idea |
|---|---|---|
| 1 | Create the two tables — **written for you** | Notice what is *not* in the column list |
| 2 | Pseudonymise the claimant | Hashing, and why a **salt** matters |
| 3 | Pseudonymise the payment **the same way** | Consistency, or nothing joins |
| 4 | Publish a flag, not a date of death | Derive the fact you need |
| 5 | Leave name, email, phone and DOB out | The easiest task and the most important |

### Task 2 is worth understanding properly

`md5()` turns text into a 32-character fingerprint you cannot reverse.
Except you can, if the input is predictable — there are only about a billion
possible National Insurance numbers, and a laptop can hash every one of them
in a couple of minutes and match them against your "anonymous" data.

Mixing in a secret **salt** first makes that impossible. The salt lives in
`meta.etl_config`, which is never published.

One test deliberately checks for this. An unsalted hash fails it.

**Read the salt from the config table rather than typing it into your SQL.**
Both work today, but salts get rotated — and when yours does, you want to
change it in one place rather than hunting through every script that
hardcoded it. Secrets pasted into code also end up in version control,
where they stay forever.

### Task 3 is the point of the whole challenge

Use **exactly** the same expression as Task 2, with `p.nino` instead of
`c.nino`. Character for character.

Two tests prove it worked: one counts the payments that find their person
through the join, and one adds up the money. If your two recipes differ by
so much as a space, both come back empty.

### Bonus, once all nine core tests are green

- **A** — An age band instead of a date of birth. The `age_band` column is
  already there and empty. Ages are worked out against `DATE '2026-04-06'`,
  never today's date, so that everyone's answer matches.
- **B** — Build `analytics.payment_summary`: one row per person, how many
  payments and how much in total. It only works if Task 3 is right, so it
  doubles as proof your join survived.

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

---

## How to work

```bash
./check.sh 2        # after every change — this is your feedback loop
```

Your database is already running from this morning. You do not need to
restart anything, and **you do not need Challenge 1 finished** — this
challenge reads `curated`, which was prepared for you. The people in it are
a completely different set from your Challenge 1 data.

```bash
./explore.sh peek curated.claimant
./explore.sh sql "SELECT * FROM meta.etl_config"
```

---

## The one thing to take away

Anonymising data is not deleting columns. It is replacing the parts that
identify somebody while keeping everything that makes the data worth having.

Get that wrong in the obvious direction and you publish someone's identity.
Get it wrong in the other direction and you publish a table that joins to
nothing, reports zero, and looks perfectly fine while doing it.