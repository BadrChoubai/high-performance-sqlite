# Window Functions

Window functions are a powerful feature in SQL that allow for more flexible and sophisticated data analysis by
processing rows individually while retaining the context of the overall result set. Unlike traditional aggregate
functions—such as `SUM()`, `COUNT()`, or `AVG()`—which collapse multiple rows into a single result, window functions
perform calculations across a set of rows related to the current row, but without grouping or collapsing those rows.

This unique capability makes window functions ideal for tasks like ranking, calculating running totals, comparing row
values, or accessing the first or last values within a specific partition of data. A window function essentially "
slides" over a portion of the result set (the "window") to apply its computation, providing both detail at the row level
and broader insights across partitions.

Key components of a window function include:

- **`OVER()` clause**: Defines the window or partition within which the function operates.
- **Partitioning**: Divides the result set into smaller, independent groups of rows. The function is then applied to
  each group separately.
- **Ordering**: Defines how rows should be sorted within each partition, allowing functions like `ROW_NUMBER()` or
  `RANK()` to assign values in sequence.

Common window functions include:

- **`ROW_NUMBER()`**: Assigns a unique sequential number to rows within a partition.
- **`RANK()` and `DENSE_RANK()`**: Rank rows within a partition, with or without gaps in ranking for ties.
- **`FIRST_VALUE()` and `LAST_VALUE()`**: Retrieve the first or last value in a partition, respectively.
- **`LAG()` and `LEAD()`**: Access data from preceding or following rows in a partitionm

By enabling row-by-row operations while maintaining awareness of the overall dataset, window functions provide immense
flexibility in reporting and data analysis, unlocking new ways to derive insights without altering the structure of the
query result set. We're going to start with a basic query:

```sql
SELECT *
FROM bookmarks
WHERE user_id <= 10;
```

Here, we're limiting the results to the first 10 users. Next, we introduce a window function:

```sql
SELECT *, row_number() OVER (PARTITION BY user_id) AS row_num
FROM bookmarks
WHERE user_id <= 10;
```

This gives us a sequential number (`row number`) for each row. However, the number increases for all rows in the result
set. What we're really after is the user's first and last bookmarks.

We need to add a partition. This will reset the row number for each user:

```sql
SELECT *, row_number() OVER (PARTITION BY user_id) AS row_num
FROM bookmarks
WHERE user_id <= 10;
```

Now, every time the `user_id` changes, the numbering starts over. Let’s go further and append the first bookmark for
each user:

```sql
SELECT *,
       row_number() OVER (PARTITION BY user_id)                            AS row_num,
       first_value(id) OVER (PARTITION BY user_id ORDER BY created_at ASC) AS first_value
FROM bookmarks
WHERE user_id <= 10;
```

This adds the first bookmark ID for every row. The `first_value()` function gives us the earliest bookmark per user,
ordered by `created_at`.

What about the last bookmark? We can modify the query to include this:

```sql
SELECT *,
       row_number() OVER (PARTITION BY user_id)                             AS row_num,
       first_value(id) OVER (PARTITION BY user_id ORDER BY created_at ASC)  AS first_value,
       first_value(id) OVER (PARTITION BY user_id ORDER BY created_at DESC) AS last_value
FROM bookmarks
WHERE user_id <= 10;
```

Now, `first_value()` is used again but ordered by `created_at DESC` to get the last bookmark.

Interestingly, this approach shows the first and last values side-by-side, within the same partition, even though the
partition is being sorted in two different ways.

## Expanding on Window Functions

We've touched on `row_number()`, `first_value()`, and `last_value()`. Let's start to explore some others:

1. `lead()`: This function returns the value of a column from the next row relative to the current row in the result
   set, within the partition.
    - `lead(id) OVER (w_user_asc)` is fetching the `id` of the next row (as `next_bookmark`) for each `user_id`, ordered
      by created_at ASC. If the current row is the last in the partition, lead() will return NULL since there’s no next
      row.
2. `lag()`: This function returns the value of a column from the previous row relative to the current row in the result
   set, within the partition.
    - `lag(id) OVER (w_user_asc)` is fetching the `id` of the previous row (as `prev_bookmark`) for each `user_id`,
      ordered by created_at ASC. If the current row is the first in the partition, lag() will return NULL since there’s
      no previous row.

- **Key Points:**
    - `lead()` and `lag()` provide a way to access future or past rows in the result set without requiring a self-join.
      These functions are especially useful for tasks like comparing values from consecutive rows (e.g., calculating
      time differences between records).

```sqlite
SELECT *,
       row_number() OVER (PARTITION BY user_id) AS row_num,
       first_value(id) OVER (w_user_asc)        AS first_value,
       first_value(id) OVER (w_user_desc)       AS last_value,
       lead(id) OVER (w_user_asc)               as next_bookmark,
       lag(id) OVER (w_user_asc)                as prev_bookmark
FROM bookmarks
WHERE user_id <= 10
WINDOW
-- Named Windows 
w_user_asc AS (PARTITION BY user_id ORDER BY created_at ASC),
w_user_desc AS (PARTITION BY user_id ORDER BY created_at DESC);
```

## Use Case

Say we want to retrieve both the first and last bookmark for each user. Specifically, we aim to determine what their
first
bookmark is (based on when it was created) and what their last bookmark is. To achieve this, we can use window
functions.

Window functions like first_value and last_value are powerful because they are applied across all rows in a partition.
In this case, every row has its first and last value set, meaning we don't need to look at previous or next rows — the
values are already available. So, we can encapsulate this logic in a Common Table Expression (CTE) to simplify the
query.

### Refactoring our code

We create a CTE called `ranked` where each row is assigned a `row_number` within its partition (based on `user_id`). The
`first_value` function is used to capture the earliest bookmark (`id`), and another `first_value` function with an
opposite
ordering captures the last bookmark. We define two windows, `w_user_asc` for sorting bookmarks in ascending order by
`created_at`, and `w_user_desc` for descending order.

```sqlite
with ranked as (SELECT *,
                       row_number() OVER (PARTITION BY user_id) AS row_num,
                       first_value(id) OVER (w_user_asc)        AS first_value,
                       first_value(id) OVER (w_user_desc)       AS last_value
                FROM bookmarks
                WHERE user_id <= 10
                WINDOW w_user_asc AS (PARTITION BY user_id ORDER BY created_at ASC),
                       w_user_desc AS (PARTITION BY user_id ORDER BY created_at DESC)
)

SELECT row_num, first_value, last_value
FROM ranked
WHERE row_num = 1;
```

In this query:

- `row_number()` gives each row a unique number within its partition (per `user_id`), ordered by the `created_at` field.
- `first_value(id) OVER (w_user_asc)` retrieves the first bookmark for each user (the earliest id).
- `first_value(id) OVER (w_user_desc)` retrieves the last bookmark (the latest id).

After defining the window functions, we filter the results by selecting only the rows where `row_num = 1`, which
effectively returns the first row for each user, containing both the first and last values.

This approach is not only efficient but also a great example of how window functions can simplify complex queries,
especially when you're mapping user behavior or tracking events over time. Rather than relying on traditional `GROUP BY`
logic, which wouldn't handle this case well, window functions allow us to perform row-by-row calculations across
partitions, providing more flexibility and power in SQL queries.

Window functions are often underutilized, partly because not all ORMs support them natively. However, they are extremely
powerful for tasks like this, where you need to process a result set in a way that wouldn't be possible (or would be
much more cumbersome) using aggregation alone.
