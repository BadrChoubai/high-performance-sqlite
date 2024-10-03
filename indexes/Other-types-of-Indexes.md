# Other Types of Indexes

Indexes in SQLite are powerful tools for optimizing queries. Beyond standard indexes, there are several specialized
types that can be particularly useful:

- **Covering Indexes**: These indexes contain all the columns needed to satisfy a query, allowing SQLite to retrieve
  results directly from the index without additional table lookups. This can greatly improve performance for specific
  queries.
- **Partial Indexes**: These are indexes created on a subset of rows in a table, reducing the index size and enhancing
  query efficiency, especially for frequently queried subsets like active or premium users.
- **Indexes on Expressions**: SQLite allows indexing on the result of expressions or functions applied to columns, such
  as extracting the domain part of an email. This flexibility optimizes queries that rely on transformed data, like
  specific parts of JSON objects.
- **Duplicate Indexes**: Avoid creating redundant indexes that share the same leftmost prefix, as they consume
  unnecessary space without adding value. However, there are cases where simpler indexes may be beneficial for sorting
  purposes.

Each of these index types offers unique benefits for optimizing database performance while minimizing overhead.

## Covering Indexes

A covering index is a normal index that happens to cover the entire query’s needs, making it more efficient by avoiding
additional table lookups. This is not a discrete index type, but rather an index that in certain situations allows
SQLite to retrieve all necessary data for a query directly from the index itself.

### How a Covering Index Works:

- **Definition**: A covering index is when an index contains all the columns required to satisfy a query. This
  eliminates the need for SQLite to access the table separately for additional data.
- **Behavior**: The same index may or may not be covering depending on the query. For example, if you query using only
  columns in the index, it acts as a covering index. However, if the query requires columns outside of the index, SQLite
  will need to refer back to the table for that missing data.
- **Example**: Consider an index that includes `first_name`, `last_name`, and `birthday`. If you query using
  `first_name` or any combination of columns included in the index, SQLite uses the index to satisfy the query without
  accessing the table, making it a covering index for that specific query.

### Benefits:

- **Performance**: A covering index allows SQLite to skip secondary lookups in the table, reducing the number of disk
  I/O operations. This can be especially useful in performance-critical paths where efficiency is paramount.
- **Index and Row ID**: Even if the query includes columns like `rowid` (or an alias like `id`), which is implicitly
  included in every index, SQLite can still use the index to return results, making it a covering index in these cases.

### Limitations:

- **Strict Requirements**: The index must fully cover the query. If even one column in the query is not in the index,
  SQLite will have to go back to the table, and the index will no longer act as a covering index.
- **No Skipping for Filtering**: While the index must be traversed in left-to-right order for filtering purposes (e.g.,
  searching for a value), when selecting columns, SQLite can "skip" over certain columns in the index if they are not
  needed for filtering.

### Practical Considerations:

- **Query Design**: Covering indexes are not commonly designed for in advance, but they can significantly improve
  performance when discovered. If you have a hot query path requiring high performance, designing an index that covers
  the query can be beneficial.
- **Select Only What You Need**: Following the common advice of selecting only the columns you need may increase the
  likelihood of hitting a covering index, especially in SQLite where network overhead is minimal.

In summary, a covering index is a regular index that fully satisfies a query's needs, allowing SQLite to retrieve all
the necessary data without a table lookup, thus speeding up the query execution.

---

## Partial Indexes

> This feature is unique to SQLite and isn't available in some other databases like MySQL.

A partial index in SQLite is an index created on a subset of rows in a table, rather than indexing an entire column for
every row. This allows for efficient indexing by focusing on the most relevant data, reducing the index size and
improving performance, especially when the full column doesn't need to be indexed.

Partial indexes are useful in situations where:

- The index would be too large if applied to the whole table.
- You want to enforce uniqueness or optimize queries for specific subsets of data.

```sqlite
EXPLAIN QUERY PLAN
SELECT COUNT(*)
FROM users
WHERE is_pro = 1; -- Currently, there is no partial index which exists 
```

Let's jump into creating a partial index for our table of users:

```sqlite
SELECT email
FROM users
WHERE is_pro = 1;

CREATE INDEX idx_pro_emails ON users (email) WHERE is_pro = 1;
PRAGMA INDEX_INFO(idx_pro_emails);

EXPLAIN QUERY PLAN
SELECT email
FROM users
WHERE is_pro = 1;
```

Partial indexes allow you to put an index over a subset of rows. Typically, we've been putting indexes on entire
columns—every row in that column, from top to bottom. However, with partial indexes, you can index just a subset of
rows, which is incredibly helpful when the index would otherwise be too large, or you want to enforce uniqueness across
a smaller subset of rows.

We’ll explore two examples, but first, let's see how it's done. This is our table structure:

```sqlite
SELECT id, first_name, last_name, is_pro, deleted_at, created_at
FROM users
LIMIT 5;
```

The users table has columns like ID, first_name, last_name, and is_pro, among others. To get a sense of scale, let’s
check the count of pro users:

```sqlite
SELECT COUNT(*)
FROM users
WHERE is_pro = 0;
```

We should have a lot of pro users and a lot of free users. If we were frequently querying the pro members, we could
create an index like
this:

```sqlite
CREATE INDEX idx_email_is_pro ON users (email);
```

But that would index all the users, which is unnecessary for our needs. A more efficient solution is to create a partial
index:

```sqlite
CREATE INDEX idx_pro_emails ON users (email) WHERE is_pro = 1;
PRAGMA INDEX_INFO(idx_pro_emails);
```

By creating this partial index, we ensure only pro users’ emails are indexed. Let's test its effectiveness by querying
the users table:

```sqlite
SELECT email
FROM users
WHERE email LIKE 'AA%'
  AND is_pro = 1
LIMIT 4;
```

SQLite uses the idx_idx_pro_emails index for this query. If we were to remove the condition on is_pro, the query would
take
longer because it would scan the entire table. By using a partial index, queries on pro users are much faster.

One thing to note is that partial indexes only work when the query matches the WHERE condition in the index definition.
If you query with is_pro = 0, the index won’t be used.

### Example of enforcing uniqueness

Partial indexes can also be useful for enforcing unique constraints across a subset of rows. Suppose you want to allow
users to delete their accounts but only permit one active account per email. Here's an example where I’ve added myself
twice to the dataset:

```sqlite
SELECT *
FROM users
WHERE email = 'aaron.francis@example.com';
```

To enforce uniqueness on active users only, we can create a partial unique index:

```sqlite
CREATE UNIQUE INDEX active_emails ON users (email) WHERE deleted_at IS NULL;
```

If there are duplicate active users, this will fail. For example, let’s soft delete one user:

```sqlite
UPDATE users
SET deleted_at = datetime('now')
WHERE id = 208;
```

Now, we can successfully create the unique index:

```sqlite
CREATE UNIQUE INDEX idx_active_emails ON users (email) WHERE deleted_at IS NULL;
```

This index enforces email uniqueness only for active users, allowing multiple deleted accounts with the same email.
Benefits of Partial Indexes

> ### Partial indexes allow you to:
> - Create smaller, faster, and more efficient indexes for frequently used queries.
> - Enforce uniqueness over a subset of rows.
> - Optimize queries for specific subsets of data, like pro users or active accounts, without indexing the entire table.

This technique is a fantastic way to reduce index size and optimize performance for your most common use cases, while
still being flexible enough to handle less frequent queries without an index.

---

## Indexes on Expressions in SQLite

So far, we’ve been placing indexes on columns, which is the standard approach. But what’s really powerful about SQLite
is the ability to create **indexes on expressions** as well. This means we’re not limited to indexing raw column data —
we can index the result of a function or an expression applied to the column.

### Example: Indexing the Domain Part of an Email

Let’s take an example of indexing the **domain part** of email addresses. This is particularly useful if you frequently
run queries on specific email domains (e.g., users with emails from `gmail.com` or `apple.com`). Here’s how we can do
it:

```sqlite
SELECT id, email
FROM users
LIMIT 5;
```

Let’s begin by constructing the expression we want to index — in this case, extracting the domain part of the email
after the "@" symbol. We can use SQLite’s `instr()` function to locate the "@" symbol, and the `substr()` function to
extract the domain part:

```sqlite
SELECT SUBSTR(email, INSTR(email, '@') + 1)
FROM users
LIMIT 5;
```

This expression gives us the domain of each email address. Now, instead of creating a new column (e.g., a generated
column), we can directly index this expression.

### Creating an Index on the Expression

Once we have our expression, we can create an index on it just as we would for any other column. Here's the query:

```sqlite
CREATE INDEX idx_email_domain ON users (SUBSTR(email, INSTR(email, '@') + 1));
PRAGMA INDEX_INFO(idx_email_domain);
```

This creates an index on the domain part of the email. Let's test the performance by running a query that searches for
users with the domain "green.info":

```sqlite
SELECT *
FROM users
WHERE SUBSTR(email, INSTR(email, '@') + 1) = 'green.info'
LIMIT 3;
```

Without an index, this query would be slower, especially on large datasets. However, by indexing the expression, SQLite
optimizes this query, making it significantly faster.

### Verifying the Index Usage

We can check whether SQLite is using the new index for our query by using the `EXPLAIN QUERY PLAN`:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
WHERE SUBSTR(email, INSTR(email, '@') + 1) = 'green.info'
LIMIT 3;
```

The result should indicate that SQLite is using the `idx_email_domain` index:

```plaintext
SEARCH users USING INDEX idx_email_domain (<expr>=?)
```

This shows that our index on the email domain is being utilized effectively to speed up the query.

#### Use Cases for Indexes on Expressions

Indexes on expressions are incredibly useful in scenarios where you need to frequently filter or query on a *
*transformed version** of a column. In the case of emails, querying based on the domain part is one common example.
Another powerful use case is when working with **JSON data**.

Though SQLite doesn’t support indexing an entire JSON object like PostgreSQL’s `GIN` indexes, you can still index
specific fields within a JSON blob by extracting them with expressions. For example, if you frequently query for a
specific key in a JSON object, you could extract that key using `json_extract()` and index it:

```text
CREATE INDEX json_key_index ON table_name (json_extract(json_column, '$.key'));
```

This allows you to optimize queries that involve searching or filtering on specific parts of JSON data.

> ### Benefits of Indexing Expressions
> - **Optimization for complex queries**: You can optimize queries that rely on computed values (like email domains or
    JSON fields) without needing to store additional columns.
> - **Flexibility**: Expressions allow you to create indexes based on any transformation or manipulation of your data.
> - **Smaller indexes**: You can avoid indexing entire columns, instead focusing on specific computed values that are
    queried frequently.

**Key takeaway**: Indexes on expressions provide flexibility and efficiency for optimizing queries on computed values,
making SQLite a powerful tool even in scenarios where traditional indexing might fall short. Whether you're querying
based on email domains or specific JSON keys, expression indexes can significantly improve performance.

---

## Understanding Duplicate Indexes in SQLite

When creating indexes in SQLite, there are some important performance and efficiency considerations related to how
indexes are used. The basic rule for indexes is: **left to right, no skipping, stops at the first range condition**.
This rule also implies a potential for **duplicate indexes**, where indexes share a common **leftmost prefix**. Let’s
break this down.

### Left to Right: How Indexes Work

Indexes in SQLite are used by moving from left to right across the columns in the index. If SQLite encounters a **range
condition** (such as `>`, `<`, or `BETWEEN`), it stops looking for any further conditions. Here’s how this works in
practice:

1. SQLite starts scanning an index from the leftmost column.
2. It moves to the right, but stops when it encounters a range condition, meaning it won’t continue to use other columns
   in that index.

This also means that when indexes share a common **leftmost prefix**, they can often be **duplicative**, and having
multiple indexes with the same leftmost prefix could be redundant.

### Example of Duplicate Indexes

Let’s say we create the following indexes on the `users` table:

```sqlite
CREATE INDEX idx_email ON users (email);
CREATE INDEX idx_email_is_pro ON users (email, is_pro);
```

These two indexes share the leftmost prefix `email`. The second index (`idx_email_is_pro`) is a **composite index**
that starts with `email` and adds `is_pro` as a second column. Since SQLite starts with the leftmost column (`email`),
the second index can perform the same role as the first, making the first index (`idx_email`) redundant.

> ### Why Duplicate Indexes Matter
>
> When you have two indexes with the same leftmost prefix, SQLite’s query planner can use either index to run a query
> based on the leftmost column (in this case, `email`). The index with more columns can still serve queries that only
> involve `email`. For instance:
>
> ```sqlite
> SELECT *
> FROM users
> WHERE email = 'aaron.francis@example.com';
> ```

Even if the simpler index (`idx_email`) is dropped, SQLite will use the more complex composite index (
`idx_email_is_pro`) to perform the query, since it starts with the same leftmost prefix. Therefore, the single-column
index is unnecessary.

### Identifying and Removing Duplicate Indexes

When reviewing your indexes, it’s a good idea to check if any share a leftmost prefix. If they do, you can typically
remove the one with fewer columns, since the one with more columns can handle the queries just as well, and this will
save disk space and potentially reduce confusion for the query planner.

Here’s an example of checking for duplicates:

```sqlite
PRAGMA INDEX_LIST(users);
```

| seq | name             | unique | origin | partial |
|:----|:-----------------|:-------|:-------|:--------|
| 0   | email\_domain    | 0      | c      | 0       |
| 1   | pro\_user\_email | 0      | c      | 1       |
| 2   | multi            | 0      | c      | 0       |
| 3   | bday             | 0      | c      | 0       |

This will show you all the indexes on the `users` table. You can then assess whether any share a leftmost prefix and
decide which ones to drop.

Now, SQLite can still efficiently query `email` using the `pro_user_email` index.

### The Caveat: Hidden Row IDs and Sorting

There’s a small caveat to this: when you create an index on a single column, SQLite actually adds the **row ID** (or
`id` if it’s defined explicitly) to the index. This means that a simple index on `email` is actually stored as
`email, row_id`. Similarly, the composite index `idx_email_is_pro` is stored as `email, is_pro, row_id`.

This can matter in some cases. For example, if you run a query that involves sorting by the `id`:

```sqlite
EXPLAIN QUERY PLAN
SELECT *
FROM users
WHERE email = 'aaron.francis@example.com'
ORDER BY id DESC;
```

If the index includes `id` implicitly (as is the case with a single-column index on `email`), it can be used both for
filtering by `email` and for sorting by `id`. However, if you are using the `idx_email_is_pro_index`, the `is_pro`
column
gets in the way, and SQLite can’t use the implicit `id` for sorting. This forces SQLite to create a temporary B-tree for
the sorting operation, which is slower:

| id | parent | notused | detail                       |
|:---|:-------|:--------|:-----------------------------|
| 3  | 0      | 0       | SCAN users                   |
| 19 | 0      | 0       | USE TEMP B-TREE FOR ORDER BY |

To avoid this, you might decide to keep the simpler `email_index` for cases where sorting by `id` is required.

> ### Practical Implications
> The key takeaway is that you should avoid accumulating unnecessary indexes that share the same leftmost columns. They
> don’t provide any additional query optimization and only consume extra disk space. However, you may want to keep an
> index if you rely on the hidden row ID for sorting, as discussed.

#### Summary:

- **Duplicate Indexes**: Indexes that share the same leftmost prefix (e.g., `email` in both `idx_email` and
  `idx_email_is_pro`) are typically redundant, and you can usually remove the one with fewer columns.
- **Row IDs and Sorting**: Be mindful of the hidden row ID when creating indexes. If you frequently sort by `id`, a
  single-column index (like `idx_email`) may still be useful, even if it seems redundant.
- **Query Optimization**: Removing redundant indexes can reduce storage overhead and prevent confusion in the query
  planner, ensuring your database operates more efficiently.
