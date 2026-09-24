# Team 4 — Hints

**Optional.** This is the walkthrough: what to look at, what is going on, and
the SQL for every task.

Using it is completely fine — nobody is counting, and reading a hint for one
task you are stuck on is exactly what it is here for. Working without it is
harder and more satisfying. Your call, and you can change your mind per task.

Your actual file is `solution.sql`. Read `BRIEF.md` first for what the
problem is; this page is only *how*.

> **Do the tasks in order.** Parse, then filter, then de-duplicate. A
> different order gives a different, wrong, answer.

---

## Tasks 1 and 2 — Turn the weekly amount into a number

**Look first**

```bash
./explore.sh values raw.claim weekly_amount
```

**What is going on**

Every system decorates money differently:

| Value | Problem |
|---|---|
| `185.15` | fine |
| `£185.15` | currency symbol |
| `'  185.15 '` | spaces round it |
| `185.15 GBP` | currency spelled out |

A `NUMERIC` column accepts none of those except the first, so you have to
strip the decoration off before converting.

| | |
|---|---|
| `replace(text, 'x', '')` | removes every `x` |
| `util.to_number(text)` | text to number, or `NULL` if it cannot |

`util.to_number` never crashes your script — it just gives `NULL`. So if this
column comes out empty, there is still decoration left on it.

`replace()` calls nest, innermost first.

**What to write**

```sql
util.to_number(
    replace(replace(replace(replace(btrim(weekly_amount),
        '£', ''), ',', ''), 'GBP', ''), ' ', '')
),
```

---

## Task 3 — Payment amounts have commas and brackets too

**Look first**

```bash
./explore.sh sql "SELECT amount, payment_status FROM raw.payment
                  WHERE amount LIKE '(%' OR amount LIKE '%,%'
                  ORDER BY random() LIMIT 15"
```

**What is going on**

Four-weekly payments run into four figures, so on top of everything in Task 1
you also get thousands separators: `1,234.56`, `£1,234.56`, `'  2,054.00 '`.

And some amounts are in brackets: `(185.15)`, `(£328.64)`. **Look at the
`payment_status` next to those.** In accounting, brackets mean a NEGATIVE
number — money going back the other way. That matters enormously in Task 6.

The line in your file strips `GBP` and spaces. It does not yet strip the
pound sign, the commas or the brackets.

**What to write**

```sql
replace(replace(replace(replace(replace(replace(btrim(amount),
    '(', ''), ')', ''), '£', ''), ',', ''), 'GBP', ''), ' ', '') AS digits
```

---

## Task 4 — Make bracketed amounts negative

You stripped the brackets off in Task 3, so `(185.15)` is now just `185.15`.
The minus sign has to be put back. `is_bracketed` already tells you which
rows those were.

**What to write**

```sql
CASE WHEN is_bracketed THEN -util.to_number(digits)
     ELSE util.to_number(digits) END AS amount
```

---

## Task 5 — Only money that actually moved

**Look first**

```bash
./explore.sh values raw.payment payment_status
```

| Status | What it means |
|---|---|
| `SETTLED` | the money arrived |
| `REVERSED` | it arrived and was then taken back — still real |
| `FAILED` | the bank rejected it. No money moved. |
| `PENDING` | has not happened yet |

Counting `FAILED` payments as real would overstate what the agency has paid
out by hundreds of thousands of pounds.

**What to write**

```sql
WHERE payment_status IN ('SETTLED', 'REVERSED')
```

---

## Task 6 — The same payment entered twice

**Look first**

```bash
./explore.sh sql "SELECT claim_ref, payment_date, amount, count(*)
                  FROM raw.payment GROUP BY 1,2,3
                  HAVING count(*) > 1 ORDER BY 4 DESC LIMIT 10"
```

Some payments were keyed in twice by two different offices. Same claim, same
day, same amount — one real payment.

> ### Be careful here
>
> A **reversal** also has the same claim, the same day and the same value as
> the payment it cancels — but the **opposite sign**. It is a real, separate
> transaction and it must survive.
>
> If you decide two payments are the same by ignoring the sign — by using
> `abs(amount)`, say — you will delete **120 genuine reversals** and your
> totals will be wrong. A test checks that all 120 are still there.

The window in your file is already right: it groups on `amount` itself, not
on how big it is, so `+185.15` and `-185.15` land in different groups.

All that is left is to keep only the first row of each group. Right now it
says `rn >= 1`, which is true for every row, so nothing is removed.

**What to write**

```sql
WHERE rn = 1;
```

---

## Bonus — a statement per claim

Only once every core test is green.

Finance want a statement per claim: how many payments went out against it,
and what they came to. This is the table that would sit behind
*"why was I paid this amount?"* on a helpline screen.

Two things make it harder than it looks:

1. **A claim with NO payments must still appear, showing zero.** With a plain
   `JOIN` those claims vanish — and a pensioner who has been missed is
   exactly the case you most need to see. Use a `LEFT JOIN`.
2. **Reversals are negative**, so a total is not the same as "money sent".
   Your total should be the NET figure — what the claim actually cost.

Why `coalesce`? `sum()` of no rows is `NULL`, not 0. A claim with no payments
should read `0.00`, not blank.

```sql
DROP TABLE IF EXISTS clean.claim_payment_summary;
CREATE TABLE clean.claim_payment_summary AS
SELECT c.claim_ref,
       count(p.payment_id)::int                  AS payment_count,
       coalesce(sum(p.amount), 0)::numeric(12,2) AS total_paid
FROM clean.claim c
LEFT JOIN clean.payment p ON p.claim_ref = c.claim_ref
GROUP BY c.claim_ref;
```
