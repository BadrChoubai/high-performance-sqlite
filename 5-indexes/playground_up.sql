PRAGMA journal_mode = WAL;
PRAGMA busy_timeout = 5000;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = 2000;
PRAGMA temp_store = memory;
PRAGMA foreign_keys = true;

CREATE TABLE cities
(
    id   int primary key,
    name text
) STRICT, WITHOUT ROWID;

BEGIN TRANSACTION;

INSERT INTO cities (id, name)
VALUES (1, 'aurora'),
       (2, 'boulder'),
       (3, 'denver'),
       (4, 'fort collins'),
       (5, 'golden'),
       (6, 'hudson'),
       (7, 'lyons'),
       (8, 'ouray'),
       (9, 'sterling');

COMMIT;
