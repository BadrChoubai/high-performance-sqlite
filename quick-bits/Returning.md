# The `RETURNING` clause

The `RETURNING` clause is incredibly powerful in SQLite for getting back modified rows without issuing a second query.
It's useful for inserts, updates, and deletes when you need immediate feedback on what has changed.

## 1. Basic UPSERT with `RETURNING`

When using an `UPSERT` operation, you can get the newly updated or inserted row back using `RETURNING`.

```sqlite
-- Upsert with RETURNING clause
INSERT INTO kv (k, v)
VALUES ('tCP8u7Ic', 'New York')
ON CONFLICT (k)
    DO UPDATE SET v = excluded.v
RETURNING *;

-- Returns the updated row with 'New York' as the new value
```

You can also return specific columns:

```sqlite
-- Return only the 'v' column after the upsert
INSERT INTO kv (k, v)
VALUES ('tCP8u7Ic', 'New York')
ON CONFLICT (k)
    DO UPDATE SET v = excluded.v
RETURNING v AS new_value;
```

## 2. Using `RETURNING` with DELETE

You can delete a row and retrieve the deleted data using the `RETURNING` clause.

```sqlite
-- Delete a row and return the deleted row's data
DELETE
FROM kv
WHERE k = 'tCP8u7Ic'
RETURNING *;

-- Returns the deleted row
```

## 3. Speculative DELETE with `RETURNING`

In some scenarios, you may want to issue a speculative delete and see the results immediately.

```sqlite
-- Speculative delete to view the deleted row
DELETE
FROM kv
WHERE k = '00000000'
RETURNING *;

-- Returns the row that was deleted (if it existed)
```

## 4. Using `RETURNING` with INSERT

`RETURNING` is helpful when you want to capture auto-generated values (e.g., auto-incrementing IDs) or values generated
by SQLite functions like `random()` or `datetime()`.

```sqlite
-- Inserting a new row and getting the inserted value back
INSERT INTO kv (k, v)
VALUES ('random_key', random())
RETURNING *;

-- Returns the row with the random value generated for 'v'
```

## 5. Update with `RETURNING`

Similar to inserts, `RETURNING` can be used to retrieve the updated row's new values after an update.

```sqlite
-- Update a row and return the updated value
UPDATE kv
SET v = 'UpdatedValue'
WHERE k = 'xLajfS7m'
RETURNING k, v;

-- Returns the key and updated value
```

## 6. `RETURNING` with Multiple Changes

If you're updating or inserting multiple rows at once, the `RETURNING` clause can return the rows in any order. You
should not rely on the order in which the rows are returned.

```sqlite
-- Insert multiple rows and return the inserted data
INSERT INTO kv (k, v)
VALUES ('A1', 'ValueA1'),
       ('B1', 'ValueB1')
ON CONFLICT (k)
    DO UPDATE SET v = excluded.v
RETURNING *;

-- May return the rows in an arbitrary order
```

