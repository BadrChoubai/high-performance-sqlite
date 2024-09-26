# Row Value Syntax

Row value syntax is a way to compare multiple values to another set of multiple values. When it's just a single value,
that is called a scalar value, but when you have multiple, you can use this row value syntax, which can be really
powerful. It can be a little bit confusing, but still, really powerful. Let me show you.

The way that you do row value syntax is you open parentheses and then you put your comma-separated values inside. For
example:

```sqlite
SELECT (1, 2, 3) = (1, 2, 3)
```

| \(1, 2, 3\) = \(1, 2, 3\) |
|:--------------------------|
| 1                         |

When we run this, you'll see it evaluates to true because the row values are equal.

However, if we change one of the values, for instance:

```sqlite
SELECT (1, 2, 3) = (1, NULL, 3)
```

| \(1, 2, 3\) = \(1, NULL, 3\) |
|:-----------------------------|
| null                         |

This time, we get `null` because it evaluates to unknown. The presence of a `NULL` means that the comparison cannot be
determined as true or false—it is unknown and unknowable.

If we further modify it to:

```sqlite
SELECT (1, 2, 3) = (1, NULL, 4)
```

| \(1, 2, 3\) = \(1, NULL, 4\) |
|:-----------------------------|
| 0                            |

Here, it evaluates to false. The key takeaway is that if the `NULL` could be substituted with a value that matches or
doesn’t match, SQLite will indicate that it doesn’t know.

## Applying Row Value Syntax

### Cursor-Based Pagination

Cursor-based pagination differs from offset-based pagination in a key way. In cursor-based pagination, the client (or
user) consuming the data sends the service or database the **last record** they saw. The service then responds with the
record **directly after** that last one. This differs from offset-based pagination, where the records are ordered and
offset by a set number, like showing page 2 by skipping the first 10 records.

For example, in offset pagination, you might say, "show me page 2," and the system would skip the first 10 records and
show records 11 to 20. For page 3, it would skip the first 20 records, and so on. However, in cursor-based pagination,
the client sends the last seen record, and the server responds with the next one in sequence.

```sqlite
SELECT *
FROM users
ORDER BY first_name, last_name, id
LIMIT 10;

-- Aaliyah Bashirian 322714 = Last record seen

SELECT *
FROM users
WHERE (first_name, last_name, id) > ('Aaliyah', 'Bashirian', 322714)
ORDER BY first_name, last_name, id
LIMIT 10;
```

#### Advantages

- **Consistency:** With cursor-based pagination, records don’t shift out from under you. Even if new records are added
  or deleted, the server still shows the **very next record** after the one that the client last saw, ensuring a
  consistent view of the data.

#### Trade-offs

- **No Addressable Pages:** You lose the concept of fixed, addressable pages since pagination revolves around the
  cursor. The client can’t jump directly to "page 2" or "page 3" because everything is based on the position of the
  cursor (i.e., the last record seen).

### Dates Stored as Separate Parts

Row value syntax is also useful when you're storing dates as separate parts (e.g., year, month, and day columns).
Although storing dates in this manner isn't highly recommended, it's still a great example of where row value syntax can
simplify queries.

Let’s explore a use case where we generate a range of dates and then separate them into year, month, and day columns
using **recursive CTEs**. After that, we'll demonstrate how row value syntax can make querying ranges across these parts
easier.

First, we start by generating all the dates for 2024 using a **recursive CTE**:

```sqlite
WITH RECURSIVE all_dates AS (SELECT date('2024-01-01') AS date
                             UNION ALL
                             SELECT date(date, '+1 day')
                             FROM all_dates
                             WHERE date < '2024-12-31')
```

This creates a table of all dates for the year 2024, including the leap day for February 29. Next, we use another
**CTE** to split the generated dates into separate `year`, `month`, and `day` columns:

```sqlite
WITH RECURSIVE
    all_dates AS (SELECT date('2024-01-01') AS date
                  UNION ALL
                  SELECT date(date, '+1 day')
                  FROM all_dates
                  WHERE date < '2024-12-31'),

    dates AS (SELECT 1 * strftime('%Y', date) AS year,
                     1 * strftime('%m', date) AS month,
                     1 * strftime('%d', date) AS day
              FROM all_dates)
```

Here, we use the `strftime` function to extract the `year`, `month`, and `day` parts from each date and cast them to
integers. This ensures that our date components are in integer format, which is important for further comparisons.

Finally, we can use **row value syntax** to select a range of dates, such as the first week of 2024:

```sqlite
WITH RECURSIVE
    all_dates AS (SELECT date('2024-01-01') AS date
                  UNION ALL
                  SELECT date(date, '+1 day')
                  FROM all_dates
                  WHERE date < '2024-12-31'),

    dates AS (SELECT 1 * strftime('%Y', date) AS year,
                     1 * strftime('%m', date) AS month,
                     1 * strftime('%d', date) AS day
              FROM all_dates)

SELECT *
FROM dates
WHERE (year, month, day) BETWEEN (2024, 1, 1) and (2024, 1, 7) 
```

This query fetches all rows where the combination of `year`, `month`, and `day` falls within the first week of January
2024.

### Why Row Value Syntax?

This syntax becomes incredibly helpful when working with complex ranges across multiple date parts. Without row value
syntax, you'd need to manually handle the logic for days that span different months or years, which can get messy. For
example, querying a range that spans across months would require additional logic to ensure proper comparisons for days
in each month. Row value syntax simplifies this by allowing you to compare tuples directly.
