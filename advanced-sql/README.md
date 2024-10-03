[Next Chapter](../operating-sqlite/README.md)

---

# Advanced SQL

## The `EXPLAIN` and `EXPLAIN QUERY PLAN` SQL Commands

The `EXPLAIN` and `EXPLAIN QUERY PLAN` statements in SQL, particularly in databases like SQLite, are valuable tools for
understanding and optimizing query performance.

### 1. `EXPLAIN` Statement:

- The `EXPLAIN` statement provides detailed information about how SQLite executes a query, offering a low-level view of
  each operation the database engine performs.
- It breaks down a query into steps, showing the instructions executed by the virtual machine (VM) that runs SQL code.
- Example of usage:
  ```sql
  EXPLAIN
  SELECT *
  FROM users
  WHERE birthday BETWEEN '1989-01-01' AND '1989-12-31'
  LIMIT 20;
  ```
- **Output:** It will return a list of opcodes (operations) that describe the sequence of actions SQLite performs
  internally to execute the query.

- **Use Cases:**
    - Debugging SQL queries.
    - Understanding the internals of query execution.
    - Gaining insight into how the database processes different components of the query, including joins, filters, and
      index usage.

### 2. `EXPLAIN QUERY PLAN` Statement:

- `EXPLAIN QUERY PLAN` offers a more abstract and higher-level overview of how the database will execute a query,
  focusing on the query execution strategy.
- It provides details such as whether an index will be used, whether a full table scan will occur, and which joins will
  be employed.
- Example of usage:
  ```sql
  EXPLAIN QUERY PLAN
  SELECT *
  FROM users
  WHERE birthday BETWEEN '1989-01-01' AND '1989-12-31'
  LIMIT 20;
  ```
- **Output:** The output describes the execution plan, such as which indexes are utilized and whether the database will
  perform a table scan or an index search.

- **Use Cases:**
    - Query performance optimization.
    - Checking whether indexes are being used effectively.
    - Analyzing whether certain operations, such as table scans or joins, can be optimized.

### Key Differences:

- **`EXPLAIN`** gives a detailed, low-level breakdown of the execution steps.
- **`EXPLAIN QUERY PLAN`** provides a more user-friendly overview, focusing on the query execution strategy.

These tools are essential for database performance tuning, particularly for identifying potential bottlenecks in complex
queries.

---

## Joins

- SQLite supports multiple types of joins, including inner joins and left joins.
- The `INNER JOIN` syntax is preferred for clarity over the comma syntax (`users, bookmarks`) because it explicitly
  shows how tables are related. While `users, bookmarks` is valid and performs an inner join, it can lead to confusion
  when you don’t define the matching columns (`users.id = bookmarks.user_id`). For example:

  ```sqlite
  EXPLAIN QUERY PLAN
  SELECT users.email, url
  FROM users -- left
           INNER JOIN bookmarks -- right
                      ON bookmarks.user_id = users.id
  LIMIT 10;
  ```

  | detail                                             |
        |:---------------------------------------------------|
  | SCAN bookmarks                                     |
  | SEARCH users USING INTEGER PRIMARY KEY \(rowid=?\) |

  > The `EXPLAIN QUERY PLAN` output above shows that SQLite scans the `bookmarks` table first and then searches the
  > `users` table using its primary key (indexed by `rowid`).

### Inner Join Behavior:

- An inner join returns only rows where there is a match in both the left (`users`) and right (`bookmarks`) tables.
  Users without bookmarks or bookmarks without matching users will not appear in the result set.

### Left Join Behavior:

- If you want all rows from the left table (`users`), even when there is no matching entry in the right table
  (`bookmarks`), use a `LEFT JOIN`. This will return all users, even those without any associated bookmarks.

### Right Join Behavior:

- A `RIGHT JOIN` is the mirror opposite of a `LEFT JOIN`. It returns all rows from the right table (bookmarks), even if
  there are no matching entries in the left table (users).
  Note: SQLite does not natively support the RIGHT JOIN syntax, but you can achieve the same effect by swapping the
  table order and using a LEFT JOIN.

### Use Case for Right Joins: Finding Orphaned Records

A common use case for a RIGHT JOIN is to identify orphaned records—records in the right table that do not have a
corresponding match in the left table. Since SQLite doesn’t support a native RIGHT JOIN, you can reverse the order of
the tables and use a LEFT JOIN instead. This approach is particularly useful for tracking incomplete or broken
relationships between tables, such as finding bookmarks that are not associated with any users.
Example: Finding Orphaned Bookmarks

Let’s say we have two tables: `users` (left table) and `bookmarks` (right table). A LEFT JOIN with the tables reversed
allows you to retrieve all bookmarks, even if they have no matching user. To narrow this down and find only the orphaned
bookmarks, you can check for NULL values in the users table.
Query to Find Orphaned Bookmarks:

```sqlite
SELECT bookmarks.url, users.email
FROM bookmarks
         LEFT JOIN users
                   ON users.id = bookmarks.user_id
WHERE users.id IS NULL;
```

> This query returns all bookmarks where there is no corresponding user, indicating that the bookmark is orphaned.
> The condition `WHERE users.id IS NULL` filters out the rows where a match in the users table exists, leaving only the
> records that are missing a user association.

### How It Works:

The `LEFT JOIN` ensures that all records from the `bookmarks` table are included in the result set.
If there is no matching entry in the users table, the columns from users will contain NULL values.
By filtering on `users.id IS NULL`, you get a list of bookmarks that are not tied to any user, effectively identifying
orphaned records.

### Practical Uses:

- **Data integrity checks**: If your system should always have a user associated with each bookmark, finding orphaned
  bookmarks allows you to identify data issues.
- **Cleaning up unused records**: In some scenarios, orphaned records like these might indicate data that should be
  deleted or reassigned.

Using a join to find orphaned records is often more efficient than using a subquery and can be clearer for others
reading your query. While you could use a subquery to achieve similar results, the join approach tends to be more
intuitive when dealing with relational data.

## Subqueries

A subquery is a powerful tool that allows you to filter data in one table based on related data from another table.
Instead of joining two tables and filtering the combined data, a subquery can be used to extract only the relevant data,
avoiding issues like cartesian multiplication, which can occur when using joins.

For example, if you want to find users with more than 15 bookmarks, you might initially try something like:

```sqlite
-- Users that have more than 15 bookmarks
SELECT *
FROM users
         LEFT JOIN bookmarks
                   ON users.id = bookmarks.user_id
GROUP BY users.id
HAVING COUNT(*) > 15;
```

However, this approach brings along unnecessary data, such as all the bookmarks, which you don’t actually need. Instead,
you can use a subquery to make the process more efficient.

### Using a Subquery

A subquery helps you select only the user IDs that meet your criteria (e.g., users with more than 16 bookmarks) and then
use that to filter your primary query. Here's an example using a subquery:

```sqlite
-- Fetch users with more than 16 bookmarks
SELECT users.id, users.first_name, users.last_name, users.email
FROM users
WHERE id IN (SELECT bookmarks.user_id
             FROM bookmarks
             GROUP BY user_id
             HAVING count(*) > 16);
```

This method avoids unnecessary data retrieval by only bringing in the relevant user IDs, thus improving performance.

### Joining Data Using a Subquery

If you need to retrieve more information (e.g., bookmark counts) along with user data, you can use a subquery within a
join. This approach allows you to combine the two sets of data while still benefiting from the performance improvements
of subqueries:

```sqlite
-- Join users with bookmark counts greater than 16
SELECT users.id, users.first_name, users.last_name, users.email, ct
FROM users
         INNER JOIN (SELECT *, COUNT(*) as ct
                     FROM bookmarks
                     GROUP BY user_id
                     HAVING ct > 16) as tmp ON users.id = tmp.user_id;
```

This query combines user data with a count of their bookmarks, ensuring that only users with more than 16 bookmarks are
included.

### Performance Considerations and Mistakes

When using subqueries, it's essential to avoid correlated subqueries, which can negatively impact performance. A
correlated subquery is evaluated for each row of the outer query, which can lead to inefficient execution.

For example, here's how you could accidentally create a correlated subquery:

```sqlite
-- Example of a correlated subquery
EXPLAIN QUERY PLAN
SELECT users.id, users.first_name, users.last_name, users.email
FROM users
WHERE EXISTS (SELECT *
              FROM bookmarks
              GROUP BY user_id
              HAVING count(*) > 16
                 AND user_id = users.id);
```

This approach can lead to slow performance because the subquery is dependent on each row from the `users` table. The
query plan might show a "CORRELATED SCALAR SUBQUERY," which is a red flag for potential inefficiency. Here's an example
of what the query plan might reveal:

| Detail                             |
|:-----------------------------------|
| SCAN users                         |
| CORRELATED SCALAR SUBQUERY 1       |
| SCAN bookmarks USING INDEX user_id |

To optimize performance, it’s better to avoid correlated subqueries whenever possible and use subqueries that generate
intermediate results efficiently. Here's a query plan for a non-correlated subquery:

```sqlite
EXPLAIN QUERY PLAN
SELECT users.id, users.first_name, users.last_name, users.email, ct
FROM users
         INNER JOIN (SELECT *, COUNT(*) as ct
                     FROM bookmarks
                     GROUP BY user_id
                     HAVING ct > 16) as tmp on users.id = tmp.user_id;
```

In this case, the query plan is more optimized and avoids correlated subqueries:

| Detail                                             |
|:---------------------------------------------------|
| CO-ROUTINE tmp                                     |
| SCAN bookmarks USING INDEX user_id                 |
| SCAN tmp                                           |
| SEARCH users USING INTEGER PRIMARY KEY \(rowid=?\) |

---

## Unions

We've explored joins, where data from two different tables is combined side by side, and subqueries, which allow
you to filter or join data using results derived from another table. Now, we're moving on to unions, a different kind of
operation. Unions allow you to take two or more result sets—whether from tables or custom queries—and stack them
vertically into a single result set. Instead of expanding the data horizontally (as with joins), unions make the result
set longer by combining rows from different sources.

### The Most Basic Union

A basic union looks like this:

```sqlite
SELECT 1
UNION
SELECT 2;
```

When you run this, it takes both result sets and merges them into a single output. However, by default, unions eliminate
duplicates, meaning if we were to select several twos, like this:

```sqlite
SELECT 1
UNION
SELECT 2
UNION
SELECT 2
UNION
SELECT 2;
```

We would only see one `2` in the result, even though it appears multiple times in the queries. This is because SQLite
removes duplicate rows in the result set by default. If you want to include all duplicates, you can use the `UNION ALL`
keyword:

```sqlite
SELECT 1
UNION ALL
SELECT 2
UNION ALL
SELECT 2
UNION ALL
SELECT 2;
```

This returns all rows, including the duplicates.

### When to Use `UNION ALL`

If you're certain that your result sets don't contain duplicates or you don't care about duplicate values, it's better
to use `UNION ALL`. It speeds up the query because SQLite doesn't need to check for duplicates. This is especially
helpful when working with large result sets, as checking for duplicates involves comparing the entire row, which can be
computationally expensive.

### Column Alignment and Aliases

Another important thing to note with unions is that the number of columns in each query must be the same. If your
queries return different numbers of columns, SQLite won't be able to combine them and will throw an error. However, you
still need to be careful about column order. Consider this example:

```sqlite
SELECT 1 as N, 'a' as char
UNION ALL
SELECT 'b', 2
UNION ALL
SELECT 3, 'c';
```

Here, the first query selects `1` as `N` and `'a'` as `char`. In the second query, the order is reversed, so `'b'` and
`2` are swapped. Though SQLite can handle this query because the column counts match, it’s your responsibility to ensure
that you're selecting data in the right order to avoid confusing results.

### Setting Up a Practical Use Case

Let's create a table containing archived users:

```sqlite
CREATE TABLE users_archive
AS
SELECT *
FROM users
WHERE deleted_at IS NOT null;
```

And let's also clean up the `users` table to remove the archived users so that they don't exist
in both places:

```sqlite
DELETE
FROM users
WHERE deleted_at IS NOT null;
```

So, now in our `users` table we should have only active users and in our `users_archive` table we have only archived
users.

### Managing Archived Users with Unions

In certain applications, you might find the need to manage archived data while keeping your active dataset as small as
possible. For instance, you may want to archive user records to comply with regulations such as GDPR, while still
retaining the ability to search for these users if necessary. This situation often arises when users are marked as
deleted but still need to be accessible for audit or compliance purposes.

To illustrate this, let’s say you need to search for a user whose data has been moved to an archive table. Here’s how
you can do that:

```sqlite
SELECT *
FROM users
WHERE email = 'aaron.francis@example.com'
UNION ALL
SELECT *
FROM users_archive
WHERE email = 'aaron.francis@example.com';
```

In this query, you’re retrieving user records based on an email address from both the `users` table and the
`users_archive` table. The result set combines entries from both sources, allowing you to see whether the user exists in
either table.

Next, you can refine the results further. Suppose you want to find all records where the first name is "Aaron":

```sqlite
SELECT *
FROM (SELECT *
      FROM users
      WHERE email = 'aaron.francis@example.com'
      UNION ALL
      SELECT *
      FROM users_archive
      WHERE email = 'aaron.francis@example.com') AS tmp
WHERE first_name = 'Aaron';
```

This query provides a simple yet effective way to search for archived users while maintaining a clear distinction
between active and inactive records. Though this approach may not be the most performant for regular operations, it
serves as a useful one-off solution when you need to access archived data.

---

## Common Table Expressions in SQLite

Common Table Expressions (CTEs) are a powerful way to logically and structurally organize your SQL queries. They can
improve readability and maintainability, and they might also provide performance benefits.

> Notes on [Recursive CTEs](./Recursive-CTEs.md)

### Example Query Using `UNION ALL`:

```sqlite
SELECT *
FROM (SELECT *
      FROM users
      WHERE email = 'aaron.francis@example.com'
      UNION ALL
      SELECT *
      FROM users_archive
      WHERE email = 'aaron.francis@example.com') as tmp;
```

This query combines results from two tables: `users` and `users_archive`. While this works, it can become unwieldy with
more complex queries.

### Refactored as a CTE:

```sqlite
WITH users_all AS (SELECT *
                   FROM users
                   UNION
                   SELECT *
                   FROM users_archive)
SELECT *
FROM users_all
WHERE email = 'aaron.francis@example.com';
```

In the refactored version, we create a CTE named `users_all` that combines both user queries. This allows us to treat
the result set as a single table, simplifying the final selection.

### Benefits of Using CTEs

1. **Logical Organization:** CTEs help structure complex queries, making them easier to read and understand.
2. **Reusability:** You can define multiple CTEs in a single query, and they can reference each other.
3. **Cleaner Syntax:** Instead of repeating the same subquery, you can define it once and use it throughout your main
   query.

### Practical Usage

As you work with your data, whether filtering, joining, or organizing, getting comfortable with CTEs can significantly
streamline your query-writing process. For instance, you might expand your CTEs further:

```sqlite
WITH users_all AS (SELECT *
                   FROM users
                   UNION
                   SELECT *
                   FROM users_archive),
     users_aaron AS (SELECT *
                     FROM users_all
                     WHERE email = 'aaron.francis@example.com')
SELECT *
FROM users_aaron;
```

In this example, `users_aaron` is another CTE that filters the results from `users_all`.

Overall, CTEs are an excellent way to simplify and clean up complex queries, making them a valuable tool for SQL
developers, especially when working with Object-Relational Mappers (ORMs).

---
