# Dealing with `NULL` values

In your data, you'll often encounter missing values, represented as `NULL`. While we know that `NULL` values signify
missing information, we need to address how to compare `NULL` values to non-null values and how `NULL` values are sorted
alongside non-null values.

## Comparing `NULL` Values to Non-Null Values

If you perform a simple comparison like:

```sqlite
SELECT 1 = NULL;
```

You’ll get `NULL` as the result. This indicates uncertainty: it's not known whether the value is true or false. In other
words, it’s an unknown result because `NULL` signifies "not there" or "missing."

However, instead of comparing values using `=`, SQLite provides a null-safe comparison operator: `IS` and `IS NOT`.

For example:

```sqlite
SELECT 1 IS 0;
SELECT 1 IS 1;
SELECT 1 IS NULL;
```

Using `IS` or `IS NOT`, you can compare values and receive a definite `TRUE` or `FALSE` instead of an unknown result.
This is SQLite's version of a null-safe comparison, which avoids ambiguity when dealing with `NULL` values.

## Sorting with `NULL` Values

When it comes to sorting, `NULL` values are considered small in SQLite. This means that they will typically appear at
the beginning of a sorted list, unless explicitly handled otherwise.

For example, executing the following query:

```sqlite
SELECT *
FROM categories
ORDER BY parent_id;
```

This will show rows sorted in ascending order, placing `NULL` values first.

If you want to sort in descending order, you can do so easily:

```sqlite
SELECT *
FROM categories
ORDER BY parent_id DESC;
```

In this case, the largest numbers will come first, and `NULL` values will be placed at the very end of the list,
confirming that `NULL` is smaller than every other value.

### Controlling the Position of `NULL` Values

SQLite allows you to control the position of `NULL` values in the result set, which is a feature not universally
supported in all databases.

To place `NULL` values at the top of the list while keeping the order ascending, you can use:

```sqlite
SELECT *
FROM categories
ORDER BY parent_id NULLS FIRST;
```

Conversely, if you want to keep the ascending order but place `NULL` values at the bottom, you can do:

```sqlite
SELECT *
FROM categories
ORDER BY parent_id NULLS LAST;
```

This flexibility can be really helpful when you need specific ordering of your data.

### Indexing Limitations

However, it's important to note that while you can control the order of `NULL` values in your query results, you cannot
create an index that incorporates `NULLS FIRST` or `NULLS LAST`. For example:

```sqlite
CREATE INDEX pid ON categories (parent_id ASC);
DROP INDEX pid;
```

You can create ascending or descending indexes, but if you attempt to include `NULLS LAST`, SQLite will return an error:

```sqlite
CREATE INDEX pid ON categories (parent_id DESC NULLS LAST);
-- [1] [SQLITE_ERROR] SQL error or missing database (unsupported use of NULLS LAST)
```

Despite the error, you may notice that the index created still optimizes queries even if it doesn't support `NULL`
positioning. This behavior can be a bit confusing, but it's useful to know that controlling the display of `NULL` values
in your result set is a powerful feature, allowing you to use `NULLS FIRST` or `NULLS LAST` in your queries.

## Handling `NULL` - Row Value Syntax

- [Row Value Syntax Notes](../advanced-sql/Row-Value-Syntax.md)

### Basic Example

To use row value syntax, you enclose the values in parentheses, separated by commas. For example:

```sqlite
SELECT (1, 2, 3) = (1, 2, 3);
```

| \(1, 2, 3\) = \(1, 2, 3\) |
|:--------------------------|
| 1                         |

Here, the expression evaluates to `TRUE` because all values in both rows match.

### Handling `NULL` Values

However, when `NULL` values are introduced, the comparison behaves differently. As seen before, comparing a value to
`NULL` results in an unknown (`NULL`), and this extends to row value syntax as well.

For instance, consider the following:

```sqlite
SELECT (1, 2, 3) = (1, NULL, 3);
```

| \(1, 2, 3\) = \(1, NULL, 3\) |
|:-----------------------------|
| NULL                         |

In this case, the comparison returns `NULL` because of the presence of a `NULL` in one of the values. Since `NULL`
introduces uncertainty, it causes the entire row comparison to be indeterminate.

#### Further Example with `NULL`

Even if there are mismatches in the other values, the presence of a `NULL` still affects the result. For example:

```sqlite
SELECT (1, 2, 3) = (1, NULL, 4);
```

| \(1, 2, 3\) = \(1, NULL, 4\) |
|:-----------------------------|
| 0                            |

Here, the comparison evaluates to `FALSE`. Despite the uncertainty introduced by the `NULL`, the final result is
determined by the mismatch between the last two values (3 and 4), which clearly do not match. Thus, the overall
comparison returns `FALSE`.

#### Practical Use Cases

Row value syntax with `NULL` handling can be useful in scenarios where you want to compare multiple columns
simultaneously. However, it's important to be aware of how `NULL` values can affect the outcome of these comparisons,
potentially making them uncertain or `FALSE` depending on the context.

To avoid issues with `NULL` in row comparisons, consider using `IS` or `IS NOT` for null-safe comparisons. For example,
using the following ensures `NULL` is handled explicitly:

```sqlite
SELECT (1, 2 IS NOT NULL, 3) = (1, 1, 3);
```
