# State Pension — Data Engineering Hackathon

Welcome. For the next few hours you are a **junior data engineer at a
government agency**, working on State Pension data.

You do not need any previous SQL experience. Everything is set up for you and
every task is explained where you need it.

---

## Before the day

**Please do this in the setup session, not on the morning of the hackathon.**
It is the one part that can go wrong, and it is much easier to fix with a
week to spare.

Follow **[docs/01-setup-macos.md](docs/01-setup-macos.md)**, then run:

```bash
./preflight.sh
```

It checks every tool, downloads the database image so you are not waiting on
the wifi, builds a real database as a dry run, and then throws it away. When
it prints **"You are ready for the hackathon"**, you are done.

If it does not, send an organiser a screenshot — that day, not on the morning.

---

## On the day

Three commands. That is genuinely all.

```bash
./start.sh 3        # your team number. Once, at the beginning.
./check.sh 1        # run your SQL and score it. After every change.
./reset.sh          # wipe everything and start again. Whenever you like.
```

Then point your SQL client at:

| | |
|---|---|
| Host | `localhost` |
| Port | **`55432`** — not the usual 5432 |
| Database | `pension` |
| User | `hackathon` |
| Password | `hackathon` |

---

## The two challenges

### Challenge 1 — Clean the mess *(60 minutes)*

Data has arrived from three systems that have never talked to each other.
Your job is to turn it into something trustworthy.

**Every team has a different dataset and a different problem.**

| Team | Challenge | Your brief |
|---|---|---|
| 1 | The Duplicate Claimants | [team-1/BRIEF.md](challenges/challenge-1/team-1/BRIEF.md) |
| 2 | The Date Disaster | [team-2/BRIEF.md](challenges/challenge-1/team-2/BRIEF.md) |
| 3 | The Address Mess | [team-3/BRIEF.md](challenges/challenge-1/team-3/BRIEF.md) |
| 4 | The Money Problem | [team-4/BRIEF.md](challenges/challenge-1/team-4/BRIEF.md) |
| 5 | The Code Chaos | [team-5/BRIEF.md](challenges/challenge-1/team-5/BRIEF.md) |

### Challenge 2 — Share it safely *(60 minutes)*

Analysts and researchers need this data. They must never see who anybody is.
Replace the National Insurance number with a pseudonym in two tables — and
keep the join between them working.

**The same challenge for every team** → [challenge-2/BRIEF.md](challenges/challenge-2/BRIEF.md)

You do **not** need Challenge 1 finished to start Challenge 2. It reads a
separate, already-clean dataset.

---

## How the scoring works

**You get the tests at the start.** That is deliberate. The tests are the
specification: if you can make them pass, you have done the job. Nobody is
hiding the answer from you.

`./check.sh` prints a scorecard:

```
 task | #      | test                                   | expected | you got | result
------+--------+----------------------------------------+----------+---------+--------
 1    | C1.05  | Names have no leading or trailing ...  | 0        | 0       | PASS
 2    | C1.07  | Placeholder text like N/A is gone      | 0        | 341     | FAIL
 3    | C1.04  | Every NINO is 2 letters, 6 digits...   | 0        | 326     | FAIL

  CORE 2/9   BONUS 0/3

  Next thing to fix:  Task 2   Placeholder text like N/A and UNKNOWN is gone
```

**It is sorted by task, not by test number** — so it reads like a to-do list.
Work down it from the top, and `./check.sh` tells you the next thing to fix.

Get all the **core** tests green — every team can, and the tasks are ordered
to help you. The **bonus** tests are what separates the teams.

More detail in [docs/04-running-tests.md](docs/04-running-tests.md).

---

## How your team works

You are a team of three or four, and there is **one database and one file per
team**. That means it is very easy for one confident person to take the
keyboard and everyone else to watch. Do not let that happen - the person
typing learns the least.

Use three roles and **swap them after every task**:

| Role | What they do |
|---|---|
| **Driver** | Has the keyboard. Types, and only types. |
| **Navigator** | Has the brief open. Reads the task aloud and says what to write. Does not touch the keyboard. |
| **Checker** | Runs `./explore.sh` to look at the data, runs `./check.sh 1`, and reads out what changed. |

There are five or six tasks, so everybody drives at least once.

If you are stuck for more than five minutes, swap anyway. Explaining the
problem to somebody else is the fastest way to solve it, and it is most of
what the job is.

---

## How to work

**Look at the data before you write any SQL.** Every task in your file starts
with a LOOK FIRST query for exactly this reason. Real data engineers spend
more time reading data than writing code.

```bash
./explore.sh values raw.claim claim_status
```

That lists every distinct value in a column with a count, wrapped in brackets
so you can see stray spaces. `[ John ]` and `[John]` are different, and you
will never spot it otherwise.

**Run `./check.sh` constantly.** After every single change. It takes seconds,
and a small failure you catch immediately is much easier than a big one later.

**Break things freely.** `./reset.sh` gives you a clean database in about
twenty seconds. It is not cheating, nobody is counting, and experimenting is
how you learn what the data actually contains.

---

## At the end: two minutes per team

You will each be asked two questions. Think about them while you work -
they matter more than your score.

1. **What was your mess, and what did you decide to do about it?**
2. **What did you have to decide that the data could not tell you?**

Every team hit something the database could not answer: which duplicate to
keep, whether a wrong date is worse than a missing one, whether something
that looks like a duplicate really is one. That judgement is the job. The
SQL is the easy half.

---

## If you get stuck

1. Read the error. Postgres messages are blunt but usually accurate.
   `./check.sh` explains the common ones.
2. Check the `where to look` column on the failing test.
3. Look at the data again. The answer is usually visible.
4. Ask. There are no marks for struggling in silence.

| | |
|---|---|
| [docs/01-setup-macos.md](docs/01-setup-macos.md) | Installing everything |
| [docs/04-running-tests.md](docs/04-running-tests.md) | Reading your score, fixing common errors |
| [docs/05-sql-cheatsheet.md](docs/05-sql-cheatsheet.md) | Every SQL function you need today |
| [docs/06-glossary.md](docs/06-glossary.md) | NINO? Pseudonymisation? Explained plainly |
| [docs/99-fallback-postgres-app.md](docs/99-fallback-postgres-app.md) | If Docker will not work on your Mac |

---

## About the data

Every person in this hackathon is **invented**. No real government data is used
anywhere.

All the National Insurance numbers begin `QQ` or `ZZ`, which are prefixes
that are never issued in real life. The names are generated, the addresses
are generated, and every email address ends `.invalid`, a domain reserved by
the standards body precisely so it can never reach anybody.

The *shapes* of the problems, though, are entirely real. Every kind of mess
you are about to fix is something that genuinely happens when organisations
run the same service across several systems for forty years.
