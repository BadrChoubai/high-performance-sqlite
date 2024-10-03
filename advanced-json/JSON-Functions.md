# SQLite JSON Functions

This page lists nearly all the built-in functions to SQLite that you can use to work
with JSON. These functions can be categorized into three types:

1. **Scalar**: Functions that return a single value from JSON.
2. **Aggregate**: Functions that return a single value by aggregating multiple values.
3. **Table**: Functions that return multiple rows and potentially multiple columns, derived from JSON arrays or objects.

**Supporting Chapters**:

- [Notes on Argument Types](./Argument-Types.md)

**Sections**:

- [Validating JSON](#validating-json-with-json_valid)
- [JSON Extraction](#json-extraction-functions)
- [Updating JSON](#updating-json)
- [JSON Aggregation](#json-aggregation-functions)
- [JSON Table Functions](#json-table-functions)

## Validating JSON with `json_valid`

- **`json_valid` Function**:
    - Used to check if the input is valid JSON before processing it further.
    - **Returns 1 (valid) or 0 (invalid)**.
    - Can validate both JSON and JSON5 inputs.
    - **Default Behavior**: If no second parameter is provided, it defaults to **Bit 1** (strict JSON validation).

- **Bit Flags in `json_valid`**:
    - You can pass a second parameter (bit flags) to fine-tune the validation process:
        1. **Bit 1 (Strict JSON Validation)**: Validates against **strict RFC 8259** JSON (standard JSON).
        2. **Bit 2 (JSON5 Validation)**: Validates **JSON5** inputs, allowing its flexible features like comments and
           unquoted keys.
        3. **Bit 3 (Blob Validation)**: Validates if the input is a **JSON-B blob** but does not perform deep
           validation.
        4. **Bit 4 (Strict Blob Validation)**: Validates if the input strictly conforms to the JSON-B standard.
    - **Default Behavior**: If no second parameter is provided, it defaults to **Bit 1** (strict JSON validation).

### Combining Bit Flags in `json_valid`

- The bit flags can be **combined** to check multiple formats at once by summing their values.
    - **Example: Bit 2 (JSON5) + Bit 3 (JSON-B)**:
      ```sql
      SELECT json_valid(input, 6);  -- Validates JSON5 and JSON-B
      ```
- **Common Bit Flag Combinations**:
    - **Bit 2 + Bit 3 (Value 6)**: Validates both **JSON5 as text** and **JSON-B blobs**.
    - **Bit 2 + Bit 4 (Value 10)**: Validates **strict JSON5** and **strict JSON-B blobs**.

#### Summary:

- SQLite provides robust support for handling JSON and JSON5 formats through its `json`, `jsonb`, and `json_valid`
  functions.
- **Performance Optimization**: Use JSON-B for faster operations and storage efficiency.
- **Validation Options**: `json_valid` offers flexibility in checking different JSON formats, ensuring your data is
  properly formatted before using it in SQLite.

**Best Practices:**

- **Use `json_valid`** to validate JSON inputs, especially if you're not certain about their format.
- **Leverage JSON-B** for performance improvements in scenarios where you need to store and query large amounts of JSON
  data.
- **Combine bit flags** in `json_valid` based on your use case:
    - Use **Bit 2 + Bit 3 (Value 6)** for most scenarios, as it covers **both JSON5 and JSON-B validation**.

**JSON-B Performance Advantages**:

- **JSON-B (Binary Representation)**:
    - Storing and querying JSON as binary (using `jsonb`) improves performance:
        - Faster queries: Avoids parsing JSON repeatedly.
        - Smaller storage footprint: Compressed binary format.
    - Ideal for scenarios where JSON is read frequently but not edited.

---

## JSON Extraction Functions

- JSON manipulation is critical when working with JSON data types in SQLite.
- This session covers methods to extract individual data pieces from JSON blobs stored in SQLite databases.

### 1. JSON Extract Function:

- **Usage:**
    - `JSON extract` takes a JSON object and a path to extract data from the JSON blob.
    - Example:
      ```sql
      SELECT JSON_EXTRACT('{"A": "foo", "B": "bar", "C": 3}', '$.A');
      ```
      This will extract the value `"foo"` associated with key `A`.

- **Path Syntax:**
    - The extraction path must begin with a dollar sign (`$`), indicating the root of the JSON object.

- **Variadic Extraction:**
    - You can extract multiple elements at once, which returns an array:
      ```sql
      SELECT JSON_EXTRACT('{"A": "foo", "B": "bar", "C": 3}', '$.A', '$.C');
      ```
      This returns an array with `A` and `C` values: `["foo", 3]`.

- **SQLite vs MySQL Behavior:**
    - **SQLite**: JSON extract returns native SQL data types (e.g., a bare `foo`).
    - **MySQL**: JSON extract always returns valid JSON, so the value would be `"foo"` in quotes.
    - In SQLite, JSON extract with a single key returns an unquoted string or a native number type, while in MySQL, the
      return is always in valid JSON format.

### 2. Arrow Extraction Operators:

- **Single Arrow (`->` Operator):**
    - Returns a valid JSON result, preserving JSON format:
      ```sql
      SELECT '{"A": "foo", "B": "bar"}' -> '$.A';
      ```
      In this case, it returns `"foo"` (as JSON).

    - Differences from `JSON extract`: This operator guarantees the return value is JSON, not a native SQL type.

- **Double Arrow (`->>` Operator):**
    - The **unquoting extraction operator** returns SQL native data types by unquoting JSON strings:
      ```sql
      SELECT '{"A": "foo", "B": "bar"}' ->> '$.A';
      ```
      Here, it returns `foo` (as a native SQL string).

- **Comparison Between Operators:**
    - The single arrow (`->`) operator extracts data in JSON format.
    - The double arrow (`->>`) operator unquotes and returns native SQL values, such as strings or numbers.

### 3. Path Argument vs Key Argument:

- **Path Argument:**
    - For `JSON extract`, the path must start with a dollar sign (`$`), explicitly referencing the JSON structure.
    - Example:
      ```sql
      SELECT JSON_EXTRACT('{"A": "foo", "B": "bar"}', '$.A');
      ```

- **Key Argument (Arrow Operators):**
    - The arrow operators (`->`, `->>`) allow you to reference JSON keys directly, without requiring the dollar sign:
      ```sql
      SELECT '{"A": "foo", "B": "bar"}' -> 'A';
      ```

### 4. Arrays and Indexing:

- **Extracting from Arrays:**
    - The arrow operators allow you to extract elements directly from arrays by specifying their index:
      ```sql
      SELECT '[1, 2, 3, 4]' ->> '$[1]';
      ```
      This will extract the second element (`2`) from the array.

- **Representation Differences:**
    - In cases of numbers, the JSON and SQL representations of values like `2` are the same, but strings might differ in
      their quoted or unquoted forms.

#### Summary:

- SQLite offers flexible methods to extract values from JSON data types.
- Depending on the desired result, you can choose:
    - `JSON extract` for native SQL data types.
    - Single arrow (`->`) for extracting values while preserving JSON format.
    - Double arrow (`->>`) for extracting unquoted SQL-native values.
- The key is understanding the differences between SQLite and other databases, like MySQL, and using the right method
  depending on whether you need valid JSON or SQL-native types.

---

## Updating JSON

- SQLite provides various functions to modify JSON objects, each tailored to different update scenarios.
- This session covers the five main functions for updating JSON in SQLite: `JSON_INSERT`, `JSON_REPLACE`, `JSON_SET`,
  `JSON_REMOVE`, and `JSON_PATCH`.

### 1. JSON Insert Function:

- **Usage:**
    - `JSON_INSERT` adds new keys to a JSON object but does not overwrite existing keys.
    - Example:
      ```sql
      SELECT JSON_INSERT('{"A": 1}', '$.B', 2);
      ```
      This adds key `B` with value `2`, resulting in `{"A": 1, "B": 2}`.

- **Behavior:**
    - It only inserts if the key does not already exist. If the key exists, the operation does nothing.

### 2. JSON Replace Function:

- **Usage:**
    - `JSON_REPLACE` updates the value of an existing key in a JSON object but will not insert new keys.
    - Example:
      ```sql
      SELECT JSON_REPLACE('{"A": 1, "B": 2}', '$.B', 3);
      ```
      This replaces the value of key `B` with `3`, resulting in `{"A": 1, "B": 3}`.

- **Behavior:**
    - It only operates on keys that already exist. If the key is not present, nothing is changed.

### 3. JSON Set Function:

- **Usage:**
    - `JSON_SET` can either insert or update keys. It combines the behaviors of both `JSON_INSERT` and `JSON_REPLACE`.
    - Example:
      ```sql
      SELECT JSON_SET('{"A": 1}', '$.B', 2);
      ```
      This inserts key `B` if it doesn't exist or updates it if it does.

- **Behavior:**
    - It inserts a new key if not present or updates an existing key, making it a more versatile option than `INSERT` or
      `REPLACE`.

### 4. JSON Remove Function:

- **Usage:**
    - `JSON_REMOVE` deletes a key from a JSON object.
    - Example:
      ```sql
      SELECT JSON_REMOVE('{"A": 1, "B": [1, 2, 3]}', '$.B[1]');
      ```
      This removes the element at index `1` from the array `B`, resulting in `{"A": 1, "B": [1, 3]}`.

- **Behavior:**
    - It can remove any key or element in an array at a specified index.

### 5. JSON Patch Function:

- **Usage:**
    - `JSON_PATCH` merges two JSON objects, where the right-hand side takes precedence if keys conflict.
    - Example:
      ```sql
      SELECT JSON_PATCH('{"A": 1}', '{"B": 2}');
      ```
      This merges the two objects, resulting in `{"A": 1, "B": 2}`.

- **Behavior:**
    - If a key exists in both objects, the value from the right-hand object replaces the left-hand value.
    - **Note**: Arrays are treated as atomic. If both objects contain arrays under the same key, the array from the
      right-hand object will fully overwrite the array on the left, without merging.

### 6. Handling Arrays and Appending Elements:

- **Appending to Arrays:**
    - You can append elements to arrays using `JSON_SET` with special path syntax:
      ```sql
      SELECT JSON_SET('{"A": [1, 2, 3]}', '$.A[#]', 4);
      ```
      This appends `4` to the array `A`, resulting in `{"A": [1, 2, 3, 4]}`.

- **Array Modification:**
    - You can also modify specific array elements by using their index in the path:
      ```sql
      SELECT JSON_SET('{"A": [1, 2, 3]}', '$.A[2]', 9);
      ```
      This updates the element at index `2` to `9`, resulting in `{"A": [1, 2, 9]}`.

### 7. JSON vs JSONB:

- **Differences Between JSON and JSONB:**
    - `JSONB` is a binary format that offers performance advantages when storing and modifying JSON data in SQLite.
    - Use `JSONB` functions (like `JSONB_SET`, `JSONB_PATCH`, etc.) for faster operations and to avoid format conversion
      overhead.
    - **Example**:
        - Storing data as `JSONB` results in faster read/write operations, especially when repeatedly updating JSON
          objects.

#### Summary:

- SQLite offers several functions for updating JSON:
    - **Insert** adds new keys without overwriting.
    - **Replace** updates existing keys without adding new ones.
    - **Set** can insert new keys or update existing ones.
    - **Remove** deletes keys or array elements.
    - **Patch** merges two objects, with the right-hand object taking precedence.
- For arrays, remember that arrays are treated as atomic, so use `JSON_SET` for precise control.
- For optimal performance, consider using `JSONB` when dealing with frequent JSON updates.

---

## JSON Aggregation Functions

- JSON aggregation functions are powerful tools in SQLite for working with JSON data types. They enable you to transform
  grouped data into structured JSON arrays or objects, rather than using typical aggregations like `SUM`, `MAX`, or
  concatenations.
- This session covers two main aggregation functions: `JSON_GROUP_ARRAY` and `JSON_GROUP_OBJECT`, along with their
  `JSONB` counterparts for JSONB storage.

### 1. JSON Group Array

- **Purpose:**
    - The `JSON_GROUP_ARRAY` function takes the result of a `GROUP BY` operation and returns the grouped values as a
      JSON array, instead of concatenating or summing them.

- **Example Usage:**
    - Suppose you have a table `products` with categories like fruits and vegetables, and you want to group product
      names by category in JSON format:
      ```sql
      SELECT category, JSON_GROUP_ARRAY(name) 
      FROM products 
      GROUP BY category;
      ```
      This query will return categories with their associated product names in a JSON array format:
      ```json
      {"category": "fruit", "names": ["apple", "banana", "orange"]}
      {"category": "vegetable", "names": ["carrot", "spinach"]}
      ```

- **Advanced Usage with JSON Objects:**
    - You can extend this by grouping more complex objects inside the array. For instance, to include both product names
      and prices in the JSON array:
      ```sql
      SELECT category, 
             JSON_GROUP_ARRAY(JSON_OBJECT('name', name, 'price', price)) 
      FROM products 
      GROUP BY category;
      ```
      This would return a JSON array where each element is an object containing both the name and price of the products.

- **Summary:**
    - `JSON_GROUP_ARRAY` is useful for returning grouped data as JSON arrays, providing more flexibility than
      traditional aggregations like concatenation.

### 2. JSON Group Object

- **Purpose:**
    - The `JSON_GROUP_OBJECT` function creates a JSON object by mapping a key-value pair for each row in the group.
      Unlike `JSON_GROUP_ARRAY`, which produces an array, this function returns a JSON object where each key is mapped
      to a specific value.

- **Example Usage:**
    - Consider a table `employees` with columns `name`, `department`, and `salary`. You can group employees by their
      department and create a JSON object where the employee name is the key, and their salary is the value:
      ```sql
      SELECT department, 
             JSON_GROUP_OBJECT(name, salary) 
      FROM employees 
      GROUP BY department;
      ```
      This would generate JSON objects for each department, where the employee names are keys, and their salaries are
      values:
      ```json
      {"department": "engineering", "employees": {"Alice": 75000, "Charlie": 80000}}
      {"department": "sales", "employees": {"Bob": 60000, "Eve": 62000}}
      ```

- **Compressing Data:**
    - Without a `GROUP BY`, the entire table can be compressed into a single JSON object. For example:
      ```sql
      SELECT JSON_GROUP_OBJECT(name, salary) 
      FROM employees;
      ```
      This results in a single JSON object for all employees:
      ```json
      {"Alice": 75000, "Bob": 60000, "Charlie": 80000, "Diana": 70000, "Eve": 62000}
      ```

- **Summary:**
    - `JSON_GROUP_OBJECT` is ideal for scenarios where you need to group data into a JSON object with defined keys and
      values, providing a more structured way of organizing data.

---

> ### JSONB Variants
>
> In addition to `JSON_GROUP_ARRAY` and `JSON_GROUP_OBJECT`, there are corresponding JSONB versions: `JSONB_GROUP_ARRAY`
> and `JSONB_GROUP_OBJECT`.
>
> The `JSONB` variants work similarly but store data in the `JSONB` format, which can provide performance advantages in
> certain scenarios, especially when dealing with large datasets or frequent updates.

#### Summary:

- `JSON_GROUP_ARRAY`: Groups rows into a JSON array.
- `JSON_GROUP_OBJECT`: Groups rows into a JSON object with key-value pairs.
- `JSONB_GROUP_ARRAY` & `JSONB_GROUP_OBJECT`: The `JSONB` versions of the above functions, optimized for `JSONB`
  storage.

---

## JSON Table Functions

JSON table functions in SQLite are powerful tools for transforming JSON data into tabular formats. These functions allow
you to work with complex JSON structures inside SQL queries without needing to do heavy post-processing in your
application code.

JSON table functions in SQLite, specifically `json_each` and `json_tree` differ from scalar and
aggregate functions because they return multiple rows and columns, making them ideal for working with structured data
stored in JSON format.

### 1. `json_each`: Shallow Iterator

**Purpose**:

- Converts a JSON array or object into a result set, producing one row per item. Each item in the JSON becomes a row,
  enabling you to work with the JSON content as if it were in a table.

**Basic Example**:

```sql
SELECT *
FROM products, json_each(products.tags);
```

- **Products Table**: Contains columns like `id`, `name`, `price`, and a JSON array column `tags`.
- **Result**: The `tags` array is exploded into individual rows using `json_each`. Each tag corresponds to a separate
  row, while other columns (like `id`, `name`, and `price`) are repeated for each tag.

**Output**:  
When using `json_each`, you get:

- Columns from the base table (`id`, `name`, etc.).
- New columns like `key`, `value`, `type`, `atom`, `id`, `parent`, `fullkey`, and `path`:
    - **Key/Value**: Represents the JSON key-value pair.
    - **Type**: Indicates the type of the value (text, array, etc.).
    - **Atom**: Represents the SQL primitive (only populated if the value can be expressed as a SQL primitive, like text
      or integer).

**Renaming Columns for Clarity**:

- You can use `AS` to rename columns:

```sql
SELECT id, name, value AS tag
FROM products, json_each(products.tags);
```

### 2. Cross Joins and `json_each`

- `json_each` can be used in an **implicit cross join** by using a comma in the query:

```sql
SELECT *
FROM products, json_each(products.tags);
```

- This form of cross join is unique because it only joins rows from the `json_each` function that correspond to the
  original row in the base table. This is not a traditional cross join, which would join every row with every other row.

You can also use an **explicit cross join**:

```sql
SELECT *
FROM products
         CROSS JOIN json_each(products.tags);
```

Both implicit and explicit cross joins behave similarly with `json_each`.

### `json_tree`: Recursive Iterator

- **Purpose**: A **recursive** version of `json_each` that digs into nested structures in JSON. Useful when working with
  deeply
  nested JSON objects or arrays.
- **Difference**: While `json_each` is limited to shallow-level iteration (first-level elements only), `json_tree` can
  traverse all levels of a deeply nested structure.
- **Example**:

    ```sql
    SELECT *
    FROM products, json_tree(products.tags);
    ```

#### Comparing `json_each` and `json_tree`

| Function    | Behavior           | Use Case                                   |
|-------------|--------------------|--------------------------------------------|
| `json_each` | Shallow iterator   | When only first-level elements are needed. |
| `json_tree` | Recursive iterator | For deeply nested JSON structures.         |

#### Practical Application

- Use these table functions to convert JSON data back into a **tabular structure** for SQL querying.
- Example Use Case: A JSON array of tags stored in a column can be "exploded" into individual rows, allowing for easier
  processing using SQL.
- **Example**:

    ```sql
    SELECT products.id, products.name, json_each.value AS tag
    FROM products, json_each(products.tags);
    ```

#### Summary

- **`json_each`** and **`json_tree`** are powerful tools for working with JSON in SQLite.
- These table functions simplify working with JSON data directly in the database, reducing the need for complex
  application logic and enabling cleaner, more efficient queries.

**Key Insights:**

- **Push processing to the database**: These functions allow SQLite to handle complex JSON manipulations, reducing the
  need to perform additional processing in the application layer.
- **Effective for Data Handling**: Whether your data is in JSON arrays or objects, these functions are effective in
  transforming JSON back into relational data that can be processed with SQL.

