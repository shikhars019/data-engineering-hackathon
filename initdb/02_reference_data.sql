-- ---------------------------------------------------------------------------
-- 02 - Reference data: small lookup tables you CAN trust.
--
-- Not everything in a data warehouse is a mess. These two tables are clean,
-- maintained by someone else, and safe to join to.
-- ---------------------------------------------------------------------------

CREATE TABLE ref.postcode_area (
    area_code TEXT PRIMARY KEY,
    region    TEXT NOT NULL
);

COMMENT ON TABLE ref.postcode_area IS
'Maps the letters at the start of a postcode to a UK region. SW -> London.';

INSERT INTO ref.postcode_area (area_code, region) VALUES
('B', 'West Midlands'),
('BN', 'South East'),
('BS', 'South West'),
('BT', 'Northern Ireland'),
('CB', 'East of England'),
('CF', 'Wales'),
('CV', 'West Midlands'),
('EH', 'Scotland'),
('EX', 'South West'),
('G', 'Scotland'),
('HU', 'Yorkshire and The Humber'),
('L', 'North West'),
('LE', 'East Midlands'),
('LS', 'Yorkshire and The Humber'),
('M', 'North West'),
('NE', 'North East'),
('NG', 'East Midlands'),
('NR', 'East of England'),
('PL', 'South West'),
('PR', 'North West'),
('RG', 'South East'),
('S', 'Yorkshire and The Humber'),
('SA', 'Wales'),
('SE', 'London'),
('SO', 'South East'),
('SR', 'North East'),
('SW', 'London');


CREATE TABLE ref.code_mapping (
    domain         TEXT NOT NULL,
    raw_value      TEXT NOT NULL,
    standard_value TEXT NOT NULL,
    PRIMARY KEY (domain, raw_value)
);

COMMENT ON TABLE ref.code_mapping IS
'Maps messy source values onto standard codes. WARNING: it is INCOMPLETE. The team that maintains it has not kept up with every spelling the source systems use. Anything missing from here is your problem to handle.';

INSERT INTO ref.code_mapping (domain, raw_value, standard_value) VALUES
('payment_method', 'BACS', 'BACS'),
('payment_method', 'bacs', 'BACS'),
('payment_method', 'Bank Transfer', 'BACS'),
('payment_method', 'BANK TRANSFER', 'BACS'),
('payment_method', 'Cheque', 'CHEQUE'),
('payment_method', 'CHQ', 'CHEQUE'),
('payment_method', 'cheque', 'CHEQUE'),
('payment_method', 'CHEQUE', 'CHEQUE'),
('payment_method', 'Post Office', 'POST_OFFICE'),
('payment_method', 'PO', 'POST_OFFICE'),
('payment_method', 'POST OFFICE', 'POST_OFFICE');
