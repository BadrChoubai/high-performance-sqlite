# Recursive CTEs

Now that we've learned about Common Table Expressions (CTEs), we get to explore recursive CTEs.
Recursive CTEs are like standard CTEs, but they reference themselves repeatedly as they build up the
table. This powerful feature allows us to work with hierarchical or sequential data more effectively. This page shows a
few very basic examples, and then a larger one that is probably useful for many of the domains you work in.

With numbers, we can create a recursive Common Table Expression (CTE). This is how we define our CTE:

```sqlite
WITH RECURSIVE numbers AS (SELECT 1 AS N
                           UNION ALL
                           SELECT N + 1
                           FROM numbers
                           WHERE N < 10)

SELECT *
FROM numbers;
```

We start with `SELECT 1 AS N`, which is our initial condition. In a recursive CTE, it’s important to use `UNION ALL`
because if you don't, it has to track every row generated to avoid duplicates. By using `UNION ALL`, it simplifies the
process.

If we run this, we generate ten numbers from the initial value of 1 up to 10. Remember to always include a limit
condition; otherwise, it could run indefinitely. You could do something like `LIMIT 10` or set a condition such as
`WHERE N < 10`.

This concept isn’t limited to numbers. For instance, we can generate a series of dates:

```sqlite
WITH RECURSIVE dates AS (SELECT DATE('2024-01-01') AS d
                         UNION ALL
                         SELECT DATE(d, '+1 day')
                         FROM dates
                         WHERE d < DATE('2024-12-31'))

SELECT *
FROM dates;
```

In this case, we define `2024-01-01` as our starting date. Using `UNION ALL`, we increment the date by one day until we
reach the end of the year.

The utility of these techniques comes into play when you want to run reports that require complete data sets. For
example, if you have a report grouped by dates and you notice missing entries (perhaps no purchases on certain days),
you can use a complete date series and perform a left join with your actual data:

```sqlite
SELECT *
FROM dates
         LEFT JOIN your_data ON dates.d = your_data.purchase_date;
```

Now, you'll have every date represented in your report, even if there were no corresponding entries in your data.

### Working with Our Own Data

```sqlite
SELECT *
FROM categories;
```

This table contains our categories, with some having parent-child relationships. We can start from the root node (where
`parent_id IS NULL`) and build out our tree:

```sqlite
WITH RECURSIVE all_categories AS (SELECT id, name, 1 AS depth, id AS path
                                  FROM categories
                                  WHERE parent_id IS NULL

                                  UNION ALL

                                  SELECT categories.id, categories.name, depth + 1, CONCAT(path, '->', categories.id)
                                  FROM all_categories
                                           INNER JOIN categories ON all_categories.id = categories.parent_id)

SELECT *
FROM all_categories;
```

Here, we define `all_categories` as our recursive CTE. The initial condition fetches all categories where `parent_id` is
`NULL`, representing the top level of our hierarchy. The recursive condition joins back to the categories table to find
children, incrementing the depth and constructing a path representation using `CONCAT`.

When we run this, the result looks something like this:

| name          | depth | path          |
|:--------------|:------|:--------------|
| Electronics   | 1     | 1             |
| Televisions   | 2     | 1->2          |
| Computers     | 2     | 1->5          |
| Phones        | 2     | 1->8          |
| Video Gear    | 2     | 1->11         |
| OLED          | 3     | 1->2->3       |
| LCD           | 3     | 1->2->4       |
| Laptops       | 3     | 1->5->6       |
| Desktops      | 3     | 1->5->7       |
| Android       | 3     | 1->8->9       |
| Apple         | 3     | 1->8->10      |
| Cameras       | 3     | 1->11->12     |
| Capture Cards | 3     | 1->11->15     |
| Canon         | 4     | 1->11->12->13 |
| Sony          | 4     | 1->11->12->14 |

This structure allows us to visualize the hierarchy and see how categories are interconnected, from parent to child.

