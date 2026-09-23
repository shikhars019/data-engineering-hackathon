-- ---------------------------------------------------------------------------
-- 06 - Configuration for Challenge 2
--
-- The analytics schema starts empty. You will create the tables in it
-- yourself - that is Challenge 2.
--
-- The one thing provided for you is the salt.
-- ---------------------------------------------------------------------------

CREATE TABLE meta.etl_config (
    setting TEXT PRIMARY KEY,
    value   TEXT NOT NULL,
    note    TEXT
);

INSERT INTO meta.etl_config (setting, value, note) VALUES
('pseudonymisation_salt',
 'pension-hackathon-2026-a7f3c91e',
 'Secret text mixed into the hash so nobody can reverse a pseudonym by guessing NINOs. Lives here in meta, NOT in analytics, so it is never published.'),
('k_anonymity_threshold',
 '5',
 'No published group may describe fewer than this many people.'),
('small_number_threshold',
 '5',
 'Counts below this must be suppressed in published aggregate tables.');

COMMENT ON TABLE meta.etl_config IS
'Settings for the Challenge 2 pipeline. Read from here rather than typing the salt into your SQL.';

-- ---------------------------------------------------------------------------
-- Why the salt matters
--
-- md5('QQ123456C') always gives the same answer. Anyone can work through
-- every possible NINO in a few seconds, hash each one, and match them
-- against your "anonymous" data. That is called a dictionary attack, and it
-- un-anonymises your whole dataset.
--
-- md5(salt || 'QQ123456C') cannot be attacked that way unless the attacker
-- also has the salt - and the salt never leaves this schema.
--
-- One of the tests checks for this. An unsalted hash will fail it.
-- ---------------------------------------------------------------------------
