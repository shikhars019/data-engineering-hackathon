-- ===========================================================================
-- CHALLENGE 1 - TEAM 1 - The Duplicate Claimants
--
-- THIS IS YOUR FILE. Edit it, save it, then run:   ./check.sh 1
--
-- ---------------------------------------------------------------------------
-- YOUR JOB: SIX LINES
--
-- Most of this file is explanation. The query itself is already written,
-- and you should leave nearly all of it alone.
--
-- There are exactly six lines to change. Every one is marked like this:
--
--        <<<<<< EDIT THIS LINE
--
-- Search for EDIT to jump between them.
--
--   Task 1  Tidy the names                     lines 61 and 62    <- start here
--   Task 2  Turn 'N/A' and friends into NULL   lines 93 and 94
--   Task 3  One spelling for the NINO          line  119
--   Task 4  Look at the duplicates             (no edit - just look)
--   Task 5  Decide which record survives       line  197
--
-- The tasks appear below in that order. Do them in that order.
--
-- It already runs. Run ./check.sh 1 now, before changing anything, so you
-- can see where you are starting from.
-- ===========================================================================

-- Start from empty every time, so you can run this file as often as you like.
TRUNCATE clean.claimant;


INSERT INTO clean.claimant (nino, title, first_name, last_name, date_of_birth,
                            sex, marital_status, date_of_death, email, phone)
WITH tidied AS (
    SELECT

        ----------------------------------------------------------------
        -- TASK 1 - Tidy the names                      <<< START HERE
        --
        -- LOOK FIRST:
        --   ./explore.sh values raw.claimant first_name
        --
        -- Read the summary line it prints BEFORE the list of values. It
        -- will tell you how many names have stray spaces, and how many
        -- are not in Title Case. The list underneath is sorted by how
        -- common each name is, so the messy ones are near the bottom.
        --
        -- You are looking at things like '  John', 'JOHN  ', 'john'.
        -- All the same name, all written differently.
        --
        -- TWO FUNCTIONS FIX THIS:
        --   btrim(x)    removes spaces from both ends
        --   initcap(x)  makes it Look Like This
        --
        -- They nest, innermost first:  initcap(btrim(first_name))
        --
        -- TODO: do that to both lines below.
        ----------------------------------------------------------------
        first_name                                    AS first_name,   -- <<<<<< EDIT THIS LINE
        last_name                                     AS last_name,    -- <<<<<< EDIT THIS LINE


        ----------------------------------------------------------------
        -- TASK 2 - 'N/A' is not a value
        --
        -- LOOK FIRST:
        --   ./explore.sh values raw.claimant marital_status
        --
        -- The old systems had no way to record "we do not know", so
        -- people typed whatever fitted:
        --      ''    'N/A'    'UNKNOWN'    'NULL'    'n/a'    '-'
        --
        -- None of those are marital statuses. They all mean "no value",
        -- and in a database that is spelled NULL - a real thing that
        -- means "nothing here", not the four letters N-U-L-L.
        --
        -- marital_status is DONE FOR YOU below. Copy that CASE onto the
        -- two lines underneath it.
        --
        -- One difference for email. marital_status is a word, so it uses
        -- initcap(). An email address is not a word - it should be all
        -- lower case, so use lower(btrim(email)) in the ELSE.
        -- 'Derek469@Webmail.Invalid' is not an email address.
        -- For phone, btrim(phone) is fine.
        ----------------------------------------------------------------
        CASE WHEN btrim(coalesce(marital_status, '')) IN ('', 'N/A', 'UNKNOWN', 'NULL', 'n/a', '-')
             THEN NULL
             ELSE initcap(btrim(marital_status))
        END                                           AS marital_status,

        email                                         AS email,        -- <<<<<< EDIT THIS LINE
        phone                                         AS phone,        -- <<<<<< EDIT THIS LINE


        ----------------------------------------------------------------
        -- TASK 3 - One spelling for each National Insurance number
        --
        -- LOOK FIRST:
        --   ./explore.sh sql "SELECT nino FROM raw.claimant ORDER BY random() LIMIT 20"
        --
        -- The same number, written five different ways:
        --   'QQ123456C'    'qq123456c'    'QQ 12 34 56 C'
        --   'QQ-12-34-56-C'    '  QQ123456C  '
        --
        -- These are all the SAME person. Until every one of them is
        -- written identically, the database cannot tell that.
        --
        -- The line below already handles the capitals and the spaces on
        -- the OUTSIDE. It does not handle the spaces in the MIDDLE, or
        -- the dashes.
        --
        -- TODO: wrap it in replace() twice more - once to remove ' ',
        --       once to remove '-'.
        --       replace(text, ' ', '')  removes every space.
        --       Remember they nest: replace(replace(x, ...), ...)
        ----------------------------------------------------------------
        upper(btrim(nino))                            AS nino,         -- <<<<<< EDIT THIS LINE


        -- Nothing to do on these. They are already fine.
        record_id,
        ingested_at,
        title,
        util.to_date(date_of_birth, 'YYYY-MM-DD')     AS date_of_birth,
        upper(btrim(sex))                             AS sex,
        util.to_date(date_of_death, 'YYYY-MM-DD')     AS date_of_death

    FROM raw.claimant
),
ranked AS (
    SELECT
        t.*,

        ----------------------------------------------------------------
        -- TASK 4 - Look before you delete. No edit here, just run these.
        --
        -- (a) How many people are in here more than once?
        --
        --     SELECT count(*) FROM (
        --         SELECT nino FROM raw.claimant
        --         GROUP BY nino HAVING count(*) > 1
        --     ) x;
        --
        --     You should get 58.
        --
        -- (b) But hold on. Count the rows and think about that number:
        --
        --     SELECT count(*) FROM raw.claimant;
        --
        --     1500 rows. Your brief says there are about 1200 real
        --     people. That is 300 extra rows - but query (a) only found
        --     58 people with a duplicate.
        --
        --     58 duplicated people cannot produce 300 extra rows.
        --     So where are the rest hiding?
        --
        --     Think about what GROUP BY nino actually compares. Is
        --     'QQ123456C' the same value as 'qq123456c'? To you, yes.
        --     To the database, no.
        --
        --     >>> This is why Task 3 exists. Once every NINO is written
        --         the same way, run query (a) again and see what happens.
        --
        -- (c) Now look at one person properly:
        --
        --     SELECT record_id, nino, email, source_system, ingested_at
        --     FROM raw.claimant
        --     WHERE nino IN ('QQ209469B','qq209469b','QQ-20-94-69-B')
        --     ORDER BY ingested_at;
        --
        --     Three records. One man. THREE DIFFERENT EMAIL ADDRESSES.
        --     Which one is correct? Nothing in the data tells you.
        --     Somebody has to decide. That is Task 5.
        --
        ----------------------------------------------------------------
        -- TASK 5 - Decide which record survives
        --
        -- ROW_NUMBER() does not delete anything. It walks through each
        -- person's records and writes 1, 2, 3 into a new column called
        -- rn. The ORDER BY decides WHO GETS THE 1.
        --
        -- Right now it says ORDER BY record_id, which is meaningless -
        -- it keeps whichever record happened to be typed first.
        --
        -- THE RULE THE AGENCY USES: THE MOST RECENTLY INGESTED RECORD WINS.
        --
        -- TODO: change the ORDER BY so the newest ingested_at comes
        --       first, and so ties are broken the same way every time:
        --
        --           ORDER BY ingested_at DESC, record_id DESC
        --
        --       Change it, re-run, and watch Derek's email change.
        ----------------------------------------------------------------
        ROW_NUMBER() OVER (PARTITION BY nino
                           ORDER BY record_id)        AS rn             -- <<<<<< EDIT THIS LINE

    FROM tidied t
)
SELECT nino, title, first_name, last_name, date_of_birth, sex, marital_status,
       date_of_death, email, phone
FROM ranked

-- THIS is the line that actually removes the duplicates.
-- ROW_NUMBER() above only numbered the rows: 1, 2, 3 for each person.
-- Keeping only number 1 keeps one record per person and discards the
-- rest. It is already written for you - do not change it.
--
-- It always keeps number 1. Your Task 5 edit decides who number 1 is.
WHERE rn = 1;


-- ===========================================================================
-- BONUS - only once every core test is green
-- ===========================================================================
--
-- BONUS A - Tidy the titles to exactly Mr, Mrs, Ms or Miss.
--   LOOK FIRST:  ./explore.sh values raw.claimant title
--   You will find 'MR.', 'mr', 'Mr.' and more. Two functions will do it:
--   one to fix the capitals, one to get rid of the full stop.
--
-- BONUS B - Recover the best available email.
--   Some people lose their email in Task 5, because the newest record
--   happens to have 'N/A' in it - even though an older record had a real
--   address. Keeping the newest record should not mean throwing away
--   information you already had.
--   Hint: max(email) OVER (PARTITION BY nino) gives you an email from ANY
--   of that person's records. coalesce() picks the first non-NULL value.
--
-- BONUS C - Store phone numbers as 11 digits with no spaces.
--   '07700 900123' should become '07700900123'.
-- ===========================================================================
