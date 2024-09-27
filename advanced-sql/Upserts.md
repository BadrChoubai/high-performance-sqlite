# Upserts

An **upsert** in SQLite is a combination of an "insert" and an "update," allowing you to insert a new row into a table
or update an existing one if a conflict occurs, such as a violation of a unique constraint. This functionality is
particularly useful for ensuring data consistency by preventing duplicate entries while still allowing updates to
existing records in a single atomic operation.

In SQLite, upserts are handled using the `INSERT ... ON CONFLICT` syntax, allowing fine-grained control over how
conflicts are resolved (e.g., `DO UPDATE` or `DO NOTHING`). This is different from other databases like MySQL, where
`INSERT ... ON DUPLICATE KEY UPDATE` is used, or PostgreSQL, which uses `INSERT ... ON CONFLICT DO UPDATE` but allows
more flexibility with handling conflicts on specific constraints. SQLite's upsert mechanism is simpler and tightly
integrated with its minimalist design, offering straightforward conflict resolution without the need for triggers or
additional logic.

## Introduction

We start by selecting from the `kv` table ([create it](#creating-the-kv-table)) with a limit of 10:

```sqlite
SELECT *
FROM kv
LIMIT 10;
```

In this `kv` table, we have a unique index on the key column, which is crucial in a key-value store. If we try to insert
a value that already exists for the key, we will encounter an error:

```sqlite
INSERT INTO kv (k, v)
VALUES ('tCP8u7Ic', 'New York');
-- [19] [SQLITE_CONSTRAINT_PRIMARYKEY] A PRIMARY KEY constraint failed (UNIQUE constraint failed: kv.k)
```

This error is expected and desired because we don't want two key-value pairs with the same key in our store. But what if
you need to either update a value or insert it if it doesn't exist? That's where **upsert** comes in.

### Upsert with ON CONFLICT Clause

The upsert allows us to update an existing row or insert a new one. We can do this using the `ON CONFLICT` clause, which
turns an `INSERT` statement into an upsert.

```sqlite
INSERT INTO kv (k, v)
VALUES ('tCP8u7Ic', 'New York')
ON CONFLICT (k)
    DO UPDATE SET v = excluded.v;
```

- **On conflict**: Here, we declare the conflict target (the key, in this case).
- **Do update**: Instead of doing nothing, we update the value to `excluded.v`, where `excluded` refers to the
  conflicting row that was not inserted.

Now, if you select from the table again:

```sqlite
SELECT v
FROM kv
WHERE k = 'tCP8u7Ic';
-- Output: New York
```

This successfully updates the value in the key-value store.

### Using a WHERE Clause with Upsert

You may want to conditionally apply the upsert. You can use a `WHERE` clause to specify that an update should only
happen under certain conditions. For example, if the value is `NULL`, you want to update it.

```sqlite
-- Insert a new object with a NULL value
INSERT INTO kv (k, v)
VALUES ('t4UIP8c6', NULL),
       ('68UiiP4o', NULL);

-- View NULL values first
SELECT *
FROM kv
ORDER BY v NULLS FIRST;

-- Upsert with a WHERE clause
INSERT INTO kv (k, v)
VALUES ('t4UIP8c6', 'Julian')
ON CONFLICT (k)
    DO UPDATE SET v = excluded.v
WHERE kv.v IS NULL;

-- View the updated results
SELECT *
FROM kv
ORDER BY v NULLS FIRST;
```

#### Additional Features of Upsert

- **Do Nothing**: If your business logic dictates that conflicts should be ignored, you can use `DO NOTHING`, which
  suppresses the error and skips the insertion.

  ```sqlite
  INSERT INTO kv (k, v) VALUES ('wKyZVR8Eju5u9', 'Engineer')
  ON CONFLICT (k)
  DO NOTHING;
  ```

- **Chaining with Excluded**: You can use the `excluded` keyword to access the values that were conflicting. For
  example, to update a record using the excluded value:

  ```sqlite
  ON CONFLICT (k)
  DO UPDATE SET v = excluded.v;
  ```

- **Custom Conditions in WHERE**: You can access both the existing row and the excluded row in your `WHERE` clause. For
  example, if you had a `last_updated` column, you could compare timestamps and decide whether to update:

  ```sqlite
  ON CONFLICT (k)
  DO UPDATE SET v = excluded.v
  WHERE kv.last_updated < excluded.last_updated;
  ```

### Using Upsert for a Counter

Another  use case for upsert is implementing a counter. Instead of checking if a key exists, retrieving the
current value, and then updating it, you can use upsert to increment or decrement a value directly with a single query.

In the below example, we modify the `kv` table so that the values we store are numbers, and we implement a counter that
increments on each insert.

```sqlite
-- Assuming we have the kv table created as follows:
CREATE TABLE IF NOT EXISTS kv
(
    k TEXT PRIMARY KEY,
    v INTEGER
) STRICT, WITHOUT ROWID;

-- Insert the initial value for the key
INSERT INTO kv (k, v)
VALUES ('000000', 1)
ON CONFLICT (k)
    DO UPDATE SET v = kv.v + 1;

-- Check the current value
SELECT *
FROM kv
WHERE k = '000000';
-- Output: 1

-- Run the upsert again
INSERT INTO kv (k, v)
VALUES ('000000', 1)
ON CONFLICT (k)
    DO UPDATE SET v = kv.v + 1;

-- Check the updated value
SELECT *
FROM kv
WHERE k = '000000'; -- Output: 2
```

#### Explanation:

1. **First Insertion**: The first `INSERT INTO kv (k, v)` sets the value to `1`. If there’s no conflict, it inserts the
   row with the key `'000000'` and value `1`.

2. **Subsequent Insertions**: On subsequent inserts with the same key, the `ON CONFLICT` clause triggers, preventing a
   primary key violation. Instead, it updates the value using `kv.v + 1`, which increments the counter by `1`.

This method allows you to increment (or decrement) a counter without needing to run multiple queries (checking if the
key exists and then updating). Instead, a single query handles both cases — either inserting the initial value or
incrementing it.

#### Benefits:

- Simplifies logic: No need to check if the key exists and run separate queries for inserting and updating.
- Efficient: You let the database handle the conflict and apply the necessary update, saving round trips to the
  database.
- Flexible: You can adapt this pattern for other operations, like decrementing counters or updating other values.

This is a very efficient and neat way to handle counters in SQLite using upsert. Upserts allow you to throw the query
over to the database and let it take care of the rest, which simplifies your code and improves performance.

### Practicality of This Pattern

1. **Simplifies Logic for Incremental Updates**: If you ever need to track counts (e.g., page views, likes, retry
   attempts, etc.), using upsert eliminates the need for a "check-then-increment" approach, streamlining your code into
   a single query.

2. **Performance Benefits**: Upsert counters reduce database round trips, which can be important for
   performance-sensitive applications. You avoid the overhead of querying for existence before updating.

3. **Atomicity**: It provides a clean, atomic operation—avoiding race conditions that might occur with separate "check
   and update" queries, ensuring that counts are always accurate even under heavy load.

4. **Flexibility**: Even if you don't use it now, it's a pattern that can easily be adapted for future use cases
   involving other operations (like decrementing counters or tallying events).
 
--- 

## Creating the KV Table

Here’s the code to create the table and insert initial data:

```sqlite
CREATE TABLE IF NOT EXISTS kv
(
    k TEXT PRIMARY KEY,
    v TEXT
) STRICT, WITHOUT ROWID;

INSERT INTO kv (k, v)
VALUES ('G3TQ0it', 'Alice'),
       ('0gKffwa', '30'),
       ('0htoHkpO', 'Denver'),
       ('wKyZVR8Eju5u9', 'Developer'),
       ('IsebS6B', 'James'),
       ('xLajfS7m', '28'),
       ('tCP8u7Ic', 'Boston'),
       ('dHdqPHPdvUy', 'Electrician');
```

This code sets up the `kv` table and demonstrates various techniques for handling conflicts and upserts in SQLite.

[Back to Introduction](#introduction)