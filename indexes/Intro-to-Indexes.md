# How to Use Indexes in SQLite

When designing your database schema, start by analyzing your data and deriving the schema from it. When designing your
indexes, consider the following questions: What queries are you running? How are you accessing the data? Answering these
questions will help guide the design of your indexes.

- [Indexed Sorting](../advanced-sql/Indexed-Sorting.md)

## Our Users Table

I've imported a partial version of the full size course database containing users.

```sqlite
SELECT COUNT(*)
FROM users;
SELECT *
FROM users
LIMIT 1;
```

| id | first_name | last_name | email                       | birthday   |
|:---|:-----------|:----------|:----------------------------|:-----------|
| 1  | Ladarius   | Dibbert   | ladarius.dibbert@maggio.com | 2005-03-08 |

```sqlite
EXPLAIN QUERY PLAN
SELECT COUNT(*)
FROM users;
```

### Creating an Index

Let's create an index around this very important date: `1989-02-14`, we have 103 users with that birthday.

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
where birthday = '1989-02-14'
```

| id | parent | notused | detail     |
|:---|:-------|:--------|:-----------|
| 2  | 0      | 0       | SCAN users |

Running the above query we see that SQLite is scanning the entire database looking for users with the specified birthday
in order to satisfy the `WHERE` clause. So it's not doing any B Tree traversal it is just scanning the entire table.

Let's add an index to the birthday and see where it can be used:

1. Create the index

```sqlite
CREATE INDEX idx_bday on users (birthday);
PRAGMA INDEX_INFO('bday');
PRAGMA INDEX_LIST(users);
```

Now if we run the query again, we will see that the index we created: 'bday' is used by SQLite.

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
where birthday = '1989-02-14'
```

| id | parent | notused | detail                                           |
|:---|:-------|:--------|:-------------------------------------------------|
| 3  | 0      | 0       | SEARCH users USING INDEX idx_bday \(birthday=?\) |

A few more queries you can run to see how the index we created is being used:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
WHERE birthday < '1989-01-01';

EXPLAIN QUERY PLAN
SELECT *
FROM users
WHERE birthday BETWEEN '1989-01-01' AND '1989-12-31';
```

So we've got strict equality, unbounded range, and bounded range. Those are three places that the index has helped us
so far, but let's consider the entire query. Let's look at ordering.

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
ORDER BY birthday DESC;
-- SCAN users USING INDEX bday
-- create_at has not had an index created for it
EXPLAIN QUERY PLAN
SELECT *
FROM users
ORDER BY created_at DESC; -- SCAN users; USE TEMP B-TREE FOR ORDER BY
```

---

## Index Selectivity and Cardinality

In SQLite, cardinality and selectivity are crucial concepts for understanding how effective an index will be in
optimizing queries.

**Cardinality** refers to the number of unique values in a column. A column with high cardinality has many distinct
values,
making it a better candidate for indexing. For example, a primary key (like an ID) has very high cardinality because
each value is unique.

**Selectivity** is the ratio of distinct values to the total number of rows. It gives an idea of how "selective" a
column
is. A column with high selectivity (closer to 1.0) is more useful for narrowing down query results.

If a column has low cardinality and low selectivity, such as a boolean column (e.g., a yes/no field with only two
distinct values), indexing may not be useful unless you're searching for the less frequent value (like admins in a user
table). In cases where the vast majority of rows share the same value, SQLite might ignore the index and perform a full
table scan instead.

To decide which index to use, SQLite looks for the index that narrows down the results most efficiently. In a scenario
where you have indexes on two columns (e.g., birthday and deleted_at), SQLite may choose the more selective column
(birthday if it filters out more rows) to reduce the result set before applying further filters.

The general rule is to put indexes on columns with high cardinality and high selectivity, as these are more likely to
speed up queries by reducing the number of rows that need to be scanned.

--- 

## Composite Indexes

In this section, we're delving into the use of composite indexes in SQLite and explaining the performance benefits and
behavior of such indexes based on specific queries. The focus is on constructing an index that combines multiple
columns, testing queries against that index, and understanding the rules for how SQLite uses the index.

### Creating and Examining a Composite Index

The first step in our example involves creating a composite index on the `users` table:

```sqlite
CREATE INDEX idx_multi ON users (first_name, last_name, birthday);
PRAGMA INDEX_INFO(idx_multi);
```

| seqno | cid | name       |
|:------|:----|:-----------|
| 0     | 1   | first_name |
| 1     | 2   | last_name  |
| 2     | 4   | birthday   |

Here, we’ve created an index that includes three columns: `first_name`, `last_name`, and `birthday`. The
`PRAGMA INDEX_INFO` command shows the order of the columns in the index, confirming that `first_name` is the first
column, followed by `last_name` and `birthday`.

## Querying the Database and Checking Index Usage

We run a query that uses the first column of the composite index:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
WHERE first_name = 'Tatyana';
```

| id | parent | notused | detail                                          |
|:---|:-------|:--------|:------------------------------------------------|
| 3  | 0      | 0       | SEARCH users USING INDEX multi \(first_name=?\) |

Here, SQLite successfully uses the composite index to search for `Tatyana` in the `first_name` column because it is the
leftmost column of the index. The query plan shows that it’s using the `multi` index based on the first column.

However, if we try to search using only the `last_name`, the index is not used:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
WHERE last_name = 'Francis';
```

| id | parent | notused | detail     |
|:---|:-------|:--------|:-----------|
| 2  | 0      | 0       | SCAN users |

In this case, the query results in a full table scan, because SQLite cannot skip over the `first_name` column in the
index to directly access the `last_name` column. This demonstrates that the order of columns in a composite index
matters: you must access columns from left to right, without skipping any columns.

Next, we run a query that uses both `first_name` and `last_name`:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
WHERE first_name = 'Aaron'
  AND last_name = 'Francis';
```

| id | parent | notused | detail                                                          |
|:---|:-------|:--------|:----------------------------------------------------------------|
| 3  | 0      | 0       | SEARCH users USING INDEX multi \(first_name=? AND last_name=?\) |

In this case, SQLite can use both the `first_name` and `last_name` columns from the composite index, as we are following
the rule of left-to-right usage without skipping any columns.

### Rules for Using Composite Indexes

1. **Left-to-right, no skipping**: The database must use the index in the order it was created. In our example, if a
   query includes `first_name`, SQLite can use the index, but it cannot skip `first_name` and directly use `last_name`
   or `birthday`.

2. **Stops at the first range condition**: When a range condition (e.g., `<`, `>`, `<=`, `>=`) is encountered in the
   query, SQLite stops using the index after that column.

Let’s examine a query with a range condition on `last_name`:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
WHERE first_name = 'Aaron'
  AND last_name < 'Francis'
  AND birthday = '1989-02-14';
```

| id | parent | notused | detail                                                          |
|:---|:-------|:--------|:----------------------------------------------------------------|
| 3  | 0      | 0       | SEARCH users USING INDEX multi \(first_name=? AND last_name<?\) |

Since the query includes a range condition (`last_name < 'Francis'`), SQLite stops using the index after `last_name`,
ignoring the `birthday` column, even though it is part of the composite index. This is a key limitation: when the first
range condition is encountered, the index cannot be used for subsequent columns.

### Optimizing Query Performance with Composite Indexes

> **Common equality conditions should be at the beginning of a composite index**,
while **range conditions should be at the end**.
 
This strategy allows the index to satisfy as many equality conditions
as possible before encountering a range condition that halts further index usage.

For example, in our composite index `multi(first_name, last_name, birthday)`, if most of your queries filter by
`first_name` and `last_name`, placing those columns at the beginning of the index is optimal. If you frequently perform
range scans on `birthday`, it should come last in the index.

## Index Obfuscation

One of the most important rules for writing good, performant queries is to _use the indexes you've created_. This may
seem obvious, but you can still unknowingly _obfuscate_ an index, which makes SQLite unable to use it. This happens when
you hide your indexed column under a transformation that SQLite can’t recognize, essentially making the index invisible.

For example, consider the query:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
WHERE strftime('%Y', birthday) = '1989'
LIMIT 20;
```

The query executes correctly, but you might see the result:

| detail     |
|:-----------|
| SCAN users |

Despite having an index on `birthday`, this query performs a full table scan. Why? Because the index is on `birthday`,
but the query is comparing a transformed version of it (`strftime('%Y', birthday)`), which isn’t indexed. SQLite sees
this as a completely new expression and doesn’t know how to use the existing index.

To _un-obfuscate_ the index, you need to rewrite the query so that the indexed column remains intact:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
WHERE birthday BETWEEN '1989-01-01' AND '1989-12-31'
LIMIT 20;
```

Now, the query output shows:

| detail                                                            |
|:------------------------------------------------------------------|
| SEARCH users USING INDEX bday \(birthday&gt;? AND birthday&lt;?\) |

This is what you want! The query is now using the index on `birthday` called `bday`.

The key takeaway here is to avoid hiding your indexed columns behind transformations like date math, concatenations, or
other operations. Instead, move these operations to the other side of the operand, ensuring that the indexed column
remains untouched.

In summary, **rule number one** for writing good queries: _Use your indexes by not obfuscating them_!## Joins

#### Conclusion

Using composite indexes effectively can dramatically improve query performance in SQLite. However, it’s crucial to
understand the rules governing how SQLite uses indexes: queries must access columns from left to right, and range
conditions halt further index use. By following these guidelines, you can design indexes that serve multiple queries and
avoid unnecessary full table scans.

##### Cleanup Created Indexes

```sqlite
PRAGMA INDEX_LIST(users);
-- Cleanup indexes for this lesson
DROP INDEX IF EXISTS idx_multi;
DROP INDEX IF EXISTS idx_pro_emails;
DROP INDEX IF EXISTS idx_email_domain;
DROP INDEX IF EXISTS idx_email_is_pro;
DROP INDEX IF EXISTS idx_active_emails;
```
