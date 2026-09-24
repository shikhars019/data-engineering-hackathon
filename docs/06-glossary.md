# Glossary

Nobody is born knowing these. Ask about anything that is not here.

---

## The benefits world

**The agency** — throughout this hackathon you work for a government
agency that pays the State Pension. It is deliberately not named, because it
is not a real organisation and none of the data is real. Everything about the
*work*, though, is exactly what this job looks like.

**State Pension** — a regular payment from the government to people over
State Pension age, currently 66. It is not a benefit you apply for and lose;
you build entitlement over your working life by paying National Insurance.

**NINO** — National Insurance number. Your unique reference for tax and
benefits, in the shape `QQ123456C`: two letters, six digits, one letter. In
this hackathon every NINO starts `QQ` or `ZZ`, prefixes that are never issued
in real life, so nothing here can collide with a real person.

**Qualifying years** — how many years of National Insurance you have paid.
You need about 35 for a full State Pension; fewer means a smaller one.

**New State Pension / Basic State Pension** — the system changed in April
2016. People who reached pension age before then are on the old Basic State
Pension, sometimes recorded by its legal categories, `Category A` and
`Category B`. Everybody after is on the New State Pension, sometimes called
the Single Tier pension. Same reality, several vocabularies — which is
exactly the problem Team 5 is dealing with.

**Deferral** — choosing to delay taking your pension in exchange for a bigger
one later.

**Claimant** — the person receiving the payment.

---

## Data engineering

**Data engineer** — the person who makes sure data arrives somewhere useful,
in a usable state. Everything an analyst or a dashboard does rests on a data
engineer having got the data there first, and got it right.

**ETL** — Extract, Transform, Load. Get data out of one place, change its
shape, put it somewhere else. Most of this job is ETL.

**Pipeline** — a sequence of ETL steps that runs on a schedule. Usually
overnight, usually while nobody is watching, which is why it has to be
trustworthy.

**Schema** — a folder for tables. This hackathon has `raw`, `ref`, `clean`,
`curated`, `analytics`, `meta`. Which folder a table sits in tells you what
stage of the pipeline it belongs to, and how much you should trust it.

**Raw / landing** — data exactly as it arrived, mess and all. You never edit
it in place. If your cleaning turns out to be wrong you need to be able to go
back to what was actually sent.

**Curated** — data that has been cleaned and is safe to build on.

**Primary key** — the column that uniquely identifies a row. Two rows cannot
share one. In `clean.claimant` it is the NINO, which is why duplicates cause
an error rather than quietly doubling your counts.

**Foreign key / orphan** — a value in one table that should point at a row in
another. When the row it points at does not exist, the record is an
**orphan**: a claim with no claimant, a payment with no claim.

**De-duplication** — collapsing several records of the same real thing into
one.

**Survivorship** — the rules for which version wins when duplicates disagree.
Newest? Most complete? Most trusted source? There is no answer in the data.
Someone has to decide, and that decision is a business rule, not a technical
one.

**Golden record** — the single agreed version of a person or thing, after
de-duplication and survivorship have been applied.

**Standardisation** — agreeing that `A`, `LIVE` and `In Payment` all mean the
same thing, and writing it down once.

**Referential integrity** — every reference points at something that actually
exists.

**Idempotent** — a script you can run twice and get the same result. It
sounds academic until a pipeline fails at 3am and somebody has to decide
whether it is safe to run again.

**Reconciliation** — proving your numbers still add up after you have
transformed them. The reason Team 4's tests are totals rather than row counts.

---

## Privacy and disclosure control

**PII** — Personally Identifiable Information. Anything that identifies a
person: name, NINO, date of birth, address, phone, email.

**Disclosure control** — the discipline of publishing useful statistics
without revealing individuals. Every statistical agency in the world employs
people to do this.

**Anonymisation** — removing identity from data so nobody can be picked out.
Harder than it sounds, because identity hides in combinations.

**Pseudonymisation** — replacing a real identifier with a made-up but
consistent one. The same person always gets the same pseudonym, so your
tables still join, but the pseudonym means nothing on its own.

**Hash** — a one-way fingerprint of some text. `md5('hello')` always gives
the same 32 characters, and you cannot work backwards from the fingerprint
to the text.

**Salt** — a secret string mixed in before hashing. Without it, a hash of
something predictable is not really hidden: there are only about a billion
possible NINOs, so an attacker can hash every one of them and match the
results against your data. That is a **dictionary attack**, and a salt is
what prevents it. The salt must never be published alongside the data.

**Generalisation** — publishing something less precise so it stops
identifying anyone. An exact date of birth becomes an age band. A full
postcode becomes a region.

**Suppression** — leaving something out entirely because publishing it would
identify someone.

**Consistency** — a pseudonym is only useful if the same person gets the
same pseudonym everywhere they appear. Build it differently in two tables and
those tables stop joining — and nothing tells you, because an empty
result is not an error.

---

## SQL words

**Query** — a question you ask the database.

**Table / row / column** — a spreadsheet, a line in it, and a field.

**NULL** — "we do not know". Different from an empty string, and very
different from the text `'N/A'`.

**Join** — matching rows in one table to rows in another.

**Aggregate** — a calculation over many rows: `count`, `sum`, `min`, `max`.

**Window function** — a calculation across a set of related rows that still
gives you one answer per row. `ROW_NUMBER()` is the one you will use today.

**CTE** — the `WITH name AS (...)` bit. A named step in a longer query, so
you can build it up in readable pieces instead of one enormous statement.
