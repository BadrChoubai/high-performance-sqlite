# SQLite Aggregates

SQLite supports aggregate functions similar to other databases, including `COUNT`, `SUM`, `MIN`, `MAX`, and others.
However, it also has some quirks and unique features worth noting:

### 1. Selecting Non-Aggregate Columns

When executing a query that includes aggregation, SQLite allows the selection of columns not included in the aggregate
expression or the `GROUP BY` clause. This behavior can lead to unexpected results, as the values returned for these
columns are arbitrary.

**Example:**

```sql
SELECT *
FROM users
LIMIT 2;
```

This query retrieves the first two users, which are both non-pro users.

Now, if we execute the following query:

```sql
SELECT *, COUNT(*)
FROM users
GROUP BY is_pro
LIMIT 2;
```

We observe:

- ~945,000 non-pro users
- ~44,000 pro users
- The names returned (e.g., Bertie Wysoski, N. Dibbert) are arbitrary and not reliable.

### 2. Filtering Aggregate Expressions

SQLite allows filtering within aggregate expressions using the `FILTER` clause. This enables counting or summing values
based on specific conditions, providing more flexibility in querying.

**Example:**
To count users based on their pro status:

```sql
SELECT COUNT(*) FILTER (WHERE is_pro = 1)                        AS pro_users,
       COUNT(*) FILTER (WHERE is_pro = 0)                        AS non_pro_users,
       COUNT(*) FILTER (WHERE strftime('%Y', birthday) = '1989') AS born_in_1989
FROM users
LIMIT 10;
```

### Summary of Results:

| pro_users | non_pro_users | born_in_1989 |
|-----------|---------------|--------------|
| 44,382    | 945,526       | 33,098       |

This allows you to efficiently retrieve multiple aggregates in a single query, using filters to specify conditions for
each aggregate.

## Handling Aggregates with NULL Values

SQLite introduces a distinction between the `SUM` and `TOTAL` functions when dealing with NULL values.

### Difference between `SUM` and `TOTAL`

- **`SUM`**: Adheres to SQL standards and returns NULL if all aggregated values are NULL.
- **`TOTAL`**: Returns 0.0 if all values are NULL or there are no rows, which is often more practical for applications
  that need a numeric result.

#### 1. When summing values that are not NULL:

```sqlite
WITH numbers AS (SELECT 1 AS n
                 UNION ALL
                 SELECT 1)

SELECT SUM(n), TOTAL(n)
FROM numbers; -- Result: `2, 2.0`
```

#### 2. When summing values where one is NULL:

```sqlite
WITH numbers AS (SELECT NULL AS n
                 UNION ALL
                 SELECT 1)

SELECT SUM(n), TOTAL(n)
FROM numbers; -- Result: `1, 1.0`
```

#### 3. When all values are NULL:

```sqlite
WITH numbers AS (SELECT NULL AS n
                 UNION ALL
                 SELECT NULL)

SELECT SUM(n), TOTAL(n)
FROM numbers; -- Result: `NULL, 0.0`
```

## Using `GROUP_CONCAT`

SQLite offers the `GROUP_CONCAT` function, which concatenates values from a specified column into a single string, with
values separated by a specified separator (default is a comma). This function is similar to `STRING_AGG`.

### Features of `GROUP_CONCAT`

1. **Concatenation with Separator**: You can specify a custom separator to use instead of the default comma.
2. **Ordering within Concatenation**: You can specify an `ORDER BY` clause within the `GROUP_CONCAT` function, allowing
   you to control the order of concatenated values.
3. **Using DISTINCT**: You can use the `DISTINCT` keyword within `GROUP_CONCAT` to ensure that only unique values are
   included in the result.
4. **Grouping by Expressions**: You can group results by calculated expressions and concatenate values accordingly.

**Example:**
To group by birth year and concatenate first names:

```sql
SELECT strftime('%Y', birthday)                              AS birthyear,
       GROUP_CONCAT(DISTINCT first_name ORDER BY first_name) AS names
FROM users
GROUP BY strftime('%Y', birthday);
```

## Important Takeaways

- Avoid selecting columns that aren't included in the `GROUP BY` clause when you expect meaningful results.
- The `FILTER` clause provides a powerful way to perform multiple aggregations based on specific conditions in one
  query.
- The distinction between `SUM` and `TOTAL` in handling NULL values allows for more flexible and robust application
  behavior, especially when dealing with missing data.
- The `GROUP_CONCAT` function offers an easy way to concatenate values with customization options for separators and
  ordering.

