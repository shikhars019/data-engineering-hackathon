# Team 3 — The Address Mess

**Challenge 1 · 60 minutes · 8 core tests + 3 bonus**

---

## The situation

You have joined the data engineering team at a government agency. Your first ticket is waiting.

Where a pensioner lives decides which regional office looks after them, which
statistics they appear in, and — if they need a home visit — where somebody
actually drives to.

Addresses reach us from three systems that have never properly talked to each
other, and nobody has ever validated a postcode on the way in.

## Why it matters

> A postcode is how the agency works out which region a pensioner lives in.
> `sw1a1aa`, `SW1A  1AA` and `SW1A 1AA` are the same place — but only the
> last one will join to anything. The other two silently drop out of every
> regional report, and nobody notices, because a missing row does not
> announce itself.

## What makes it hard

**The postcodes are written every possible way:**

```
SW1A 1AA     sw1a1aa      SW1A  1AA      ' sw1a 1aa '     SW1A1AA
```

**And some are not postcodes at all:**

```
N/A     TBC     NOT KNOWN     12345     ZZ99 9ZZZ     ''
```

**Some addresses belong to people who are not in our database** — they came
from a system that was switched off, and the people were never migrated.

**And the "is this where they live now?" flag cannot be trusted.** It was
filled in by hand and nobody maintained it. You will find people with two
addresses both marked current, and people with none marked at all.

What you *can* trust is `valid_from`. The address somebody moved to most
recently is the one they live at now.

---

## Your tasks

Open `challenges/challenge-1/team-3/solution.sql`. Everything is in there,
with the guidance next to the code.

| # | Task | Tests it turns green |
|---|---|---|
| 1 | Load the people — **written for you** | *(none — leave it alone)* |
| 2 | Tidy the town names and address lines | C3.01, C3.07 |
| 3 | Squash the postcode flat, then put one space back | C3.03, C3.08 |
| 4 | Throw out the postcodes that are not postcodes | C3.02 |
| 5 | Throw out addresses for people who do not exist | C3.04 |
| 6 | Work out which address each person actually lives at | C3.05, C3.06 |

**You do not have to write the postcode pattern.** One is written out for you
in [docs/05-sql-cheatsheet.md](../../../docs/05-sql-cheatsheet.md), under
*Patterns*. Copy it. Your job is to use it, not invent it.

**Nothing on the scorecard is free.** Every test starts red, and each one goes
green because of something you did.

### Bonus, once all eight core tests are green

Build a summary table, `clean.address_summary`, answering a question nobody
can currently answer: **how many pensioners live in each region?**

- **A** — One row per region, joined through `ref.postcode_area`
- **B** — Get London right
- **C** — Count each person once — use only their current address, or movers
  will be counted twice and the totals will not add up to every claimant

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
./start.sh 3        # once, at the beginning
./check.sh 1        # after every change — this is your feedback loop
```

Browse the data in TablePlus (`localhost:55432`), or from the terminal:

```bash
./explore.sh values raw.address postcode
```

That command wraps every value in brackets, so `[ sw1a 1aa ]` shows you the
stray spaces you would never spot otherwise.

**Look at the data before you write any SQL.** You cannot clean something you
have not seen, and `./explore.sh` is how you look. (If you open `hints.md`,
every task there starts with a suggested LOOK FIRST query.)

Made a mess? `./reset.sh` gives you a fresh database in twenty seconds. It is
not cheating and nobody is counting.

### One trap worth knowing about

Be careful what you delete. Some people have two addresses and one of them is
rubbish; some have only one. If you throw out every bad row without looking,
you can leave a real pensioner with no address at all — and one of your tests
checks for exactly that.

---

## The one thing to take away

"Clean" does not just mean tidy. It means **in a form that will join to
something else.** A beautifully formatted postcode that does not match your
region lookup is no more useful than a blank one — and considerably more
misleading, because it looks fine.
