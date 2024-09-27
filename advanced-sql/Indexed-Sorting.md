# Indexed Sorting in SQLite

## Key Concept:

Using indexes to assist with sorting is significantly faster than having SQLite scan all rows and sort them afterward.
Ideally, we want to leverage existing indexes to return ordered data more efficiently.

### Example 1: Listing Indexes for the Users Table

```sqlite
PRAGMA INDEX_LIST(users);
```

Output: Lists the indexes for the `users` table, showing the available indexes but not the columns they apply to.

- To get more details about the columns in the index:

```sqlite
PRAGMA INDEX_INFO(index_name);
```

In this example, we have compound indexes (e.g., `first_name, last_name`) and single-column indexes (e.g., `email`,
`birthday`).

### Example 2: Sorting with Indexes

Let's start by selecting from `users` ordered by indexed columns:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
ORDER BY first_name, last_name
LIMIT 10;
```

Result:

| Detail                      |
|:----------------------------|
| SCAN users USING INDEX name |

SQLite uses the index on `first_name, last_name` to optimize the ordering process.

### Example 3: Sorting by a Non-Indexed Column

Sorting by a column without an index, like `created_at`, requires SQLite to scan the whole table and create a temporary
B-tree for sorting:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
ORDER BY created_at
LIMIT 10;
```

Result:

| Detail                       |
|:-----------------------------|
| SCAN users                   |
| USE TEMP B-TREE FOR ORDER BY |

### Example 4: Mixing Indexed and Non-Indexed Columns

When you mix indexed and non-indexed columns in the `ORDER BY` clause, SQLite performs a hybrid operation:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
ORDER BY first_name, created_at
LIMIT 10;
```

Result:

| Detail                                     |
|:-------------------------------------------|
| SCAN users USING INDEX name                |
| USE TEMP B-TREE FOR RIGHT PART OF ORDER BY |

SQLite first orders by `first_name` (using the index), then sorts the results by `created_at` using a temporary B-tree.

### Example 5: Sorting by `rowid`

Without any `ORDER BY` clause, the default ordering is by `rowid`. Explicitly sorting by `rowid` results in no changes
in the query plan:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
ORDER BY rowid
LIMIT 10;
```

This is the default ordering SQLite uses when no index is specified.

### Example 6: Compound Index with Extra Column

Even though `created_at` is not part of the index, the index on `first_name, last_name` can still help partially:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
ORDER BY first_name, last_name, created_at
LIMIT 10;
```

Result:

| Detail                                     |
|:-------------------------------------------|
| SCAN users USING INDEX name                |
| USE TEMP B-TREE FOR RIGHT PART OF ORDER BY |

SQLite uses the index for `first_name, last_name`, but resorts to a temporary B-tree for sorting by `created_at`.

### Example 7: Adding `id` for Disambiguation

Appending `id` to the `ORDER BY` clause ensures deterministic sorting when multiple rows have the same `first_name` and
`last_name`:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
ORDER BY first_name, last_name, id
LIMIT 10;
```

Result:

| Detail                      |
|:----------------------------|
| SCAN users USING INDEX name |

Adding `id` at the end helps SQLite uniquely identify rows with the same `first_name` and `last_name`, using the
inherent row pointer stored in the index.
