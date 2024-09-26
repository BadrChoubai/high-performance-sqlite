# Row Value Syntax

Row value syntax allows you to compare multiple values as a group (a row) to another set of values. While a single value
comparison is called a scalar comparison, row value syntax provides the flexibility to compare multiple values at once.
Though it can seem a bit complex at first, it offers powerful capabilities.

### Basic Example

To use row value syntax, you enclose the values in parentheses, separated by commas. For example:

```sqlite
SELECT (1, 2, 3) = (1, 2, 3)
```

| \(1, 2, 3\) = \(1, 2, 3\) |
|:--------------------------|
| 1                         |

Here, the expression evaluates to `true` because all values in both rows match.

Now, let's change one of the values:

```sqlite
SELECT (1, 2, 3) = (1, NULL, 3)
```

| \(1, 2, 3\) = \(1, NULL, 3\) |
|:-----------------------------|
| null                         |

This time, we get `null` because `NULL` introduces uncertainty. The presence of `NULL` makes the comparison unknown.

Further modifying it:

```sqlite
SELECT (1, 2, 3) = (1, NULL, 4)
```

| \(1, 2, 3\) = \(1, NULL, 4\) |
|:-----------------------------|
| 0                            |

Here, it evaluates to `false`. The `NULL` still creates uncertainty, but the mismatch between the last value (3 vs. 4)
results in a definitive `false`.

## Applying Row Value Syntax

### Cursor-Based Pagination

Cursor-based pagination offers a distinct approach compared to offset-based pagination. Instead of jumping to a specific
page by skipping a fixed number of records, the client consuming the data sends the **last record** they saw to the
server. The server then responds with the record **directly following** that last record.

In contrast, offset-based pagination involves fixed positions, where records are retrieved by offsetting from the first
row (e.g., skipping the first 10 rows to show records 11–20).

Example of cursor-based pagination in action:

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

- **Consistency:** Cursor-based pagination ensures that records don’t shift even when new ones are added or old ones
  deleted. The system always provides the very next record after the last one seen.

#### Trade-offs

- **No Addressable Pages:** You lose the concept of numbered pages (like page 2, page 3). Since the data revolves around
  the cursor, clients can't directly jump to a specific page—they can only move forward or backward from the current
  position.

### Dates Stored as Separate Parts

Row value syntax is also helpful when dealing with dates stored as separate `year`, `month`, and `day` columns. Although
it's generally recommended to store dates in a single column, there are cases where separating them might be necessary.

Let’s walk through a use case where we generate a range of dates and break them into individual components:

First, we generate all dates for the year 2024 using a **recursive CTE**:

```sqlite
WITH RECURSIVE all_dates AS (SELECT date('2024-01-01') AS date
                             UNION ALL
                             SELECT date(date, '+1 day')
                             FROM all_dates
                             WHERE date < '2024-12-31')
```

This generates all dates from January 1, 2024, to December 31, 2024. Next, we extract the `year`, `month`, and `day`
from each date:

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

Using `strftime`, we extract and convert the `year`, `month`, and `day` to integers, making them easier to work with.

Finally, we apply **row value syntax** to select a range of dates, such as the first week of 2024:

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
WHERE (year, month, day) BETWEEN (2024, 1, 1) and (2024, 1, 7);
```

This query efficiently fetches all rows from the first week of January 2024.

### Why Row Value Syntax?

Row value syntax shines in scenarios where you're working with multi-part values like `year`, `month`, and `day`.
Instead of manually constructing comparisons for each part, row value syntax allows you to treat these parts as a tuple,
simplifying queries that span across months or years.

Without row value syntax, querying a date range across months could involve complex conditions. Row value syntax keeps
it simple by letting you compare tuples directly, eliminating the need for cumbersome logic.
