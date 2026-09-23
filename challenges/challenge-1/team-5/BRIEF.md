# Team 5 — The Code Chaos

**Challenge 1 · 60 minutes · 9 core tests + 3 bonus**

---

## The situation

You have joined the data engineering team at a government agency. Your first ticket is waiting.

Somebody has asked what should be a five-second question:

> **How many people are currently being paid a State Pension?**

Nobody can answer it. Three systems have been recording the same fact in
different words for thirty years, and no one ever agreed a standard.

## Why it matters

Look at what "this claim is being paid" looks like in our data:

```
ACTIVE     Active     active     A     LIVE     In Payment     INPAY
```

Five systems, five vocabularies, one meaning. Count them separately and you
get five different answers to the question above — and the agency reports that
number to Parliament.

> A count is only as trustworthy as the agreement behind it. Until everybody
> uses the same word for the same thing, "how many?" has no answer at all.

## What makes it hard

**Four different columns, each with its own sprawl:**

| Column | Some of what is in there | Should become |
|---|---|---|
| `claim_status` | `A`, `LIVE`, `In Payment`, `Ceased`, `SUSP` | `ACTIVE` / `SUSPENDED` / `CLOSED` |
| `pension_type` | `nSP`, `Single Tier`, `Category A`, `CAT B` | `NEW_STATE_PENSION` / `BASIC_STATE_PENSION` |
| `payment_frequency` | `W`, `WKLY`, `1`, `4W`, `13`, `QTR` | `WEEKLY` / `FOUR_WEEKLY` / `QUARTERLY` |
| `deferral_indicator` | `Y`, `yes`, `TRUE`, `T`, `1`, `0`, `''` | a real `true` / `false` |

**`pension_type` needs thought, not just typing.** There are two different
naming schemes in that one column, from two different eras. `Category A` and
`Category B` are old legal categories — and they are both forms of the *old*
pension, so both become `BASIC_STATE_PENSION`. Get that wrong and the counts
will tell you.

**Some records point at things that do not exist.** Thirty claims quote a
National Insurance number that is not in the claimant table. Forty-five
payments quote a claim reference that is not in the claim table. A claim with
no claimant cannot be paid and must not be counted.

---

## The trap

There is a lookup table, `ref.code_mapping`, that maps messy values onto
standard ones. Use it.

**But it is incomplete.** Another team maintains it and they have not kept up
with every spelling the source systems produce.

When you hit a value that is not in the mapping, you have a choice:

- **Drop the row.** Now your payment totals are wrong and nobody knows why.
- **Leave it blank.** Now "we could not map this" is indistinguishable from
  "there was nothing here".
- **Mark it `UNKNOWN`.** The row survives, the totals stay right, and the gap
  stays visible so somebody can fix the mapping next week.

Only one of those is right. One of your tests checks you chose it.

---

## Your tasks

Open `challenges/challenge-1/team-5/solution.sql`. Everything is in there,
with the guidance next to the code.

| # | Task | Tests it turns green |
|---|---|---|
| 1 | `claim_status` — **written for you**, already passing. This is your pattern. | C5.02 |
| 2 | `pension_type` — two schemes, one answer | C5.05, C5.06 |
| 3 | `deferral_indicator` — eleven spellings, one boolean | C5.07 |
| 4 | `payment_frequency` | *(bonus B)* |
| 5 | Drop claims for people who do not exist | C5.01, C5.03, C5.04 |
| 6 | Payment methods via the lookup — and cope with the gaps | C5.09 |
| 7 | Drop payments for claims that do not exist | C5.08 |

**Task 1 is finished and its test already passes.** Read it before you write
anything — Tasks 2 and 4 are exactly the same shape.

### Bonus, once all nine core tests are green

- **A** — How many claims are `SUSPENDED`?
- **B** — How many are paid four-weekly?
- **C** — Make sure no payment method came out `NULL`

---

## How to work

```bash
./start.sh 5        # once, at the beginning
./check.sh 1        # after every change — this is your feedback loop
```

The single most useful command for this challenge:

```bash
./explore.sh values raw.claim claim_status
```

It lists every distinct value with a count, in brackets so you can see the
stray spaces. Run it on each column *before* you write its `CASE`. If you
miss one spelling, your counts will be quietly wrong.

Made a mess? `./reset.sh` gives you a fresh database in twenty seconds. It is
not cheating and nobody is counting.

---

## The one thing to take away

This is the least glamorous job in data engineering and one of the most
valuable. Standardising vocabularies is what turns four systems into one
answer. Every dashboard, every statistic and every ministerial briefing rests
on somebody having sat down and decided that `A`, `LIVE` and `In Payment`
mean the same thing.
