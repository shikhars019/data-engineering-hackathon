# Challenge 2 — Safe Data for Analysts

**60 minutes · 12 core tests + 3 bonus · the same challenge for every team**

---

## The situation

It is the afternoon. Overnight, the pipeline has landed a clean, finished
dataset in the `curated` schema — 1,468 pensioners, properly typed, properly
conformed. Somebody else did the cleaning. It is good data.

It is also **full of personal information**: names, dates of birth, home
addresses, National Insurance numbers.

Three groups have asked for access:

- **The agency's own analysts** forecasting how much State Pension will cost next year
- **The Office for National Statistics** publishing regional breakdowns
- **University researchers** studying pensioner poverty

All three have good reasons. None of them may ever see who anybody is.

> This is a real job with a real name: **disclosure control**. Every
> statistical agency in the world employs people to do it, and when they get
> it wrong it makes the news.

Your job is to publish a version of `curated` into the `analytics` schema
that is **useful to an analyst and useless to someone trying to find their
neighbour**.

---

## What you must not publish

Names. National Insurance numbers. Email addresses. Phone numbers. Exact
dates of birth. Full postcodes.

The tests check for all of these — and not just by column name. One test
searches **every text value in every analytics table** for anything shaped
like a National Insurance number, and another does the same for postcodes.
Renaming a column does not hide its contents.

---

## Your tasks

Open `challenges/challenge-2/solution.sql`. Everything is in there, with the
guidance next to the code.

| # | Task | The idea |
|---|---|---|
| 1 | Create the tables — **written for you** | Notice what is *not* in the column list |
| 2 | Replace each person with a pseudonym | Hashing, and why a **salt** matters |
| 3 | Age band instead of date of birth | Generalisation |
| 4 | Region instead of postcode | Generalisation |
| 5 | Leave the personal columns out | The easiest task and the most important |
| 6 | Build the claims table | Pseudonyms must be **consistent** or nothing joins |
| 7 | **k-anonymity** | The real lesson. See below. |
| 8 | The summary table | Small counts leak too |

### Task 2 is worth understanding properly

`md5()` turns text into a 32-character fingerprint that cannot be reversed.
Except it can, if the input is predictable — there are only about a billion
possible National Insurance numbers, and a laptop can hash every one of them
in a couple of minutes and match them against your "anonymous" data.

Mixing in a secret **salt** first makes that impossible. The salt lives in
`meta.etl_config`, which is never published.

One test deliberately checks for this. An unsalted hash fails it.

### Task 7 is the point of the whole challenge

You will finish Tasks 2 to 6, run the tests, and one will still fail. Nothing
is broken — you have met the actual problem.

Every column you published is harmless on its own. Nobody is identified by
"female", or by "80-84", or by "Northern Ireland". Put all three together and
you may be describing **two people in the country** — and anybody who knows
their neighbour is an 82-year-old widow in Belfast now knows what she is paid.

**k-anonymity** is the rule that prevents this: every published combination
must describe at least *k* people. The agency uses k = 5.

Your file shows you how to see the failing groups for yourself, and how to
fix them. The fix costs you a little detail and buys you the ability to
publish at all. That trade-off is the job.

### Bonus, once all twelve core tests are green

- **A** — Check you *suppressed* the small counts rather than deleting the rows
- **B** — Create an `analyst_ro` role that can read `analytics` and nothing else
- **C** — Run `./check.sh 2` twice. Does it still pass?

---

## How to work

```bash
./check.sh 2        # after every change — this is your feedback loop
```

Your database is already running from this morning. You do not need to
restart anything, and **you do not need Challenge 1 finished** — this
challenge reads `curated`, which was prepared for you.

The people in `curated` are a completely different set from the ones in your
Challenge 1 data. Nothing you did this morning affects this.

```bash
./explore.sh peek curated.claimant
./explore.sh sql "SELECT * FROM meta.etl_config"
```

---

## The one thing to take away

Anonymisation is not a checkbox, and deleting the name column is not the end
of it. Identity hides in **combinations** — three harmless facts about
somebody can add up to one person. Protecting people means thinking about
what your data reveals together, not just field by field.

That is the difference between data that can be shared and data that cannot,
and it is why this job exists.
