# Team 4 — The Money Problem

**Challenge 1 · 60 minutes · 8 core tests + 3 bonus**

---

## The situation

You have joined the data engineering team at a government agency. Your first ticket is waiting.

Your tables decide what lands in a pensioner's bank account. Around twelve
million people receive the State Pension, and for many of them it is most of
their income.

Payment records reach us from three systems that have never properly talked
to each other, and every one of them writes money differently.

## Why it matters

> Pay somebody twice and the money is gone — recovering an overpayment from a
> pensioner is slow, distressing and often written off. Miss a payment and
> somebody does not eat that week.

Which is why most of your tests are **totals**. It is not enough for the data
to look tidy. You have to be able to prove the numbers add up.

## What makes it hard

**Money is stored as text, and every system decorates it differently:**

```
185.15        £185.15       '  185.15 '      185.15 GBP
1,234.56      £1,234.56     (185.15)
```

A `NUMERIC` column will not accept any of those except the first.

**Those brackets are not decoration.** In accounting, `(185.15)` means
*minus* £185.15 — money going back the other way.

**Some payments were entered twice**, by two offices, on the same day, for
the same amount. One real payment, two rows.

**Not every record is real money.** `FAILED` payments were rejected by the
bank. `PENDING` ones have not happened. Counting them would overstate what
the agency has paid out by hundreds of thousands of pounds.

---

## The trap

Read this bit twice. It is the point of your challenge.

A **reversal** is a real transaction: a payment that was made and then taken
back. It has the same claim, the same date and the same value as the payment
it cancels — but the **opposite sign**.

So if you decide two payments are duplicates by comparing *how big* they are
and ignoring the sign, you will delete 120 genuine reversals and your totals
will be wrong.

One of your tests checks that all 120 survived. It is not there by accident.

---

## Your tasks

Open `challenges/challenge-1/team-4/solution.sql`. Everything is in there,
with the guidance next to the code.

| # | Task | Tests it turns green |
|---|---|---|
| 1 | Strip the pound signs off the weekly amounts | C4.01, C4.02, C4.03 |
| 2 | Strip the spaces and the `GBP` | C4.01, C4.02, C4.03 |
| 3 | Do the same for payments, plus the commas and brackets | *(feeds 4–6)* |
| 4 | Make bracketed amounts negative | C4.06, C4.08 |
| 5 | Keep only money that actually moved | C4.04, C4.07 |
| 6 | Remove double-entered payments — **without killing the reversals** | C4.05, C4.06 |

### Bonus, once all eight core tests are green

Finance want a statement per claim: how many payments went out against it,
and what they came to. Build `clean.claim_payment_summary`.

- **A** — One row per claim, with `payment_count` and `total_paid`
- **B** — A claim with **no** payments must still appear showing zero. A plain
  `JOIN` makes those vanish — and a pensioner who has been missed is exactly
  the case you most need to see. Use a `LEFT JOIN`, and `coalesce` so it
  reads `0.00` rather than blank
- **C** — Your totals should come to the **net** figure, because reversals
  pull it down

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
./start.sh 4        # once, at the beginning
./check.sh 1        # after every change — this is your feedback loop
```

Browse the data in TablePlus (`localhost:55432`), or from the terminal:

```bash
./explore.sh values raw.claim weekly_amount
```

**Look at the data before you write any SQL.** You cannot clean something you
have not seen, and `./explore.sh` is how you look. (If you open `hints.md`,
every task there starts with a suggested LOOK FIRST query.)

Made a mess? `./reset.sh` gives you a fresh database in twenty seconds. It is
not cheating and nobody is counting.

### Order matters

Parse the amounts, **then** filter out the failed payments, **then**
de-duplicate. Do it in a different order and you will get a different — wrong
— answer. Your file is already laid out in the right order; follow it.

---

## The one thing to take away

With money, "looks about right" is not good enough. Anyone can write a query
that produces a plausible number. The job is producing a number you can
**defend** — which is why you reconcile to an expected total, and why you
think hard before deleting a row that merely resembles another one.
