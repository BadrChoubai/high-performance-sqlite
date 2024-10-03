[Next Chapter](../README.md)

---

# Advanced JSON

In this chapter, we'll dive into advanced concepts of one of the most widely used data interchange formats: JSON. JSON
has become essential for modern data communication, and many developers consider it their go-to format. If you're not
among them, you may simply have other priorities like friends, hobbies, or life outside of coding—which is perfectly
fine! However, in this chapter, we're going to take a close look at JSON, particularly in the context of databases like
SQLite.

While storing JSON in databases is common, it's important to consider how you're using it. If your JSON objects have
well-defined schemas, and you're frequently querying or updating them, it might be more efficient to break those values
into top-level columns in your database. Although databases like SQLite support JSON, using native columns for querying
and indexing is often a better choice for performance and ease of use.

This chapter will introduce not only general JSON concepts but also specialized JSON functions that SQLite offers. We'll
explore JSON's evolution in SQLite, including the new `JSONB` functions introduced in version 3.45. These functions are
modeled after Postgres and offer a binary structure to avoid continuous reparsing—an advanced feature for those
handling larger datasets.

Additionally, we'll cover three types of JSON functions: scalar, aggregate, and table functions. These tools enable a
wide range of operations, from retrieving single values to generating entire tables from JSON data, giving you a
powerful toolkit to process and manipulate JSON within your database.

**Chapters in this Lesson**:

- [Argument Types](./Argument-Types.md)
- [JSON Functions](./JSON-Functions.md)
    - [Validating JSON](./JSON-Functions.md#validating-json-with-json_valid)
    - [JSON Extraction](./JSON-Functions.md#json-extraction-functions)
    - [Updating JSON](./JSON-Functions.md#updating-json)
    - [JSON Aggregation](./JSON-Functions.md#json-aggregation-functions)
    - [JSON Table Functions](./JSON-Functions.md#json-table-functions)

**Sections**:

- [JSON vs. JSONB](#json-vs-jsonb-in-sqlite-key-differences)
- [Valid JSON](#valid-json)
- [Creating JSON Objects + Arrays](#creating-and-inspecting-json-objects--arrays)
- [Indexing JSON](#indexing-json)

---

## JSON vs. JSONB in SQLite: Key Differences

- **No Native JSON Column**: SQLite does not have a dedicated JSON column type. JSON data must be stored in a `TEXT` or
  `BLOB` column. While SQLite allows flexibility in data storage, it's recommended to use `TEXT` or `BLOB` for JSON data
  to ensure efficient handling.

- **JSON in JavaScript**: In JavaScript, JSON is typically received as a string over the wire (e.g., from a server or
  local storage). To work with it, developers:
    - Parse it into an in-memory object using `JSON.parse`.
    - Convert it back to a string using `JSON.stringify`.

  This concept is central to understanding JSON vs. JSONB.

- **How JSON Functions Work**:
    - **JSON Functions** in SQLite operate on JSON **strings** (i.e., text). When performing operations on JSON data:
        - The string is parsed into a binary structure (similar to `JSON.parse`).
        - The operation is executed.
        - The result is converted back into a string (text).

    - **JSONB Functions**, on the other hand, work directly with the binary representation of JSON. This avoids the need
      for parsing and converting back to text, making operations faster since the data is already in binary format.

### Key Differences:

- **JSON Functions**:
    - Operate on text (strings).
    - Convert the string into binary, perform the operation, and return the result as text.

- **JSONB Functions**:
    - Skip the parsing step and work directly on the binary representation of JSON.
    - Return binary results instead of text, which can be faster when performing multiple operations or writing data
      back to disk.

### Example:

- Running `JSON extract` on a JSON object:
    - The JSON string is parsed into a binary object.
    - The key is extracted.
    - The result is returned as text.

- Running `JSONB extract` on the same object:
    - The JSON string is converted to binary.
    - The key is extracted, but the result is returned in **binary format** (not human-readable).
    - This binary output is useful for internal operations but not for direct consumption.

### Use Cases:

- **When to Use JSON**:
    - Use JSON functions when you need human-readable text as output.
    - This is ideal for consuming JSON data in applications that expect a string format.

- **When to Use JSONB**:
    - Use JSONB functions when working with JSON internally within SQLite.
    - JSONB is faster for storage and repeated operations, as it skips the parsing and conversion steps.
    - Recommended for cases where JSON data is being processed extensively within SQLite before being written back to
      disk.

#### Summary:

- Both JSON and JSONB can be used interchangeably in terms of input, but the key difference lies in the output format:
  JSON returns text, and JSONB returns binary.
- If your application consumes the data, stick with JSON for ease of readability. If you're optimizing for database
  operations or storage efficiency, JSONB is the faster option.

---

## Valid JSON

**Supporting Chapter**:

- [JSON Functions: Validating JSON](./JSON-Functions.md#validating-json-with-json_valid)

- SQLite provides several JSON-related functions, including `json`, `jsonb`, and `json_valid`, which work with **valid
  JSON** and **JSON5** formats.
- **JSON5** is a human-friendly version of JSON that allows for comments, unquoted keys, extra whitespace, and more.
- **JSON Handling in SQLite**:
    - **`json` Function**:
        - Accepts **valid JSON** or **JSON5** and converts it to **standard JSON text**.
        - You can pass simple values (e.g., `1`, `true`, or an object) to it, and it returns the JSON representation as
          a string.
        - Useful for applications that need JSON formatted as text.
    - **`jsonb` Function**:
        - Similar to `json`, but instead of returning text, it returns a **binary representation (JSON-B)**.
        - **Opaque to the user**: You can't inspect it or manipulate it directly.
        - It should only be used to store or pass JSON to other SQLite functions to improve performance by avoiding
          repeated
          parsing.
- If invalid JSON is passed to `json` or `jsonb`, SQLite raises a **runtime error** without crashing. This ensures the
  database remains stable even if it encounters malformed JSON.
- Example of invalid JSON:
  ```sql
  SELECT json('{"key": value}');
  -- [1] [SQLITE_ERROR] SQL error or missing database (malformed JSON)
  ```

## Creating and Inspecting JSON Objects + Arrays

SQLite provides multiple ways to **create JSON objects** and **arrays**. The most basic method is to pass values into
the `json` function.

```sql
SELECT json('
{
    "foo": 1, 
    "bar": "baz", 
    "baz": [1, 2, 3]
}');
-- Returns: {"foo":1,"bar":"baz","baz":[1,2,3]}
```

### Other  Methods for Creating JSON:

1. **`json_object()`**:
    - Used to create **JSON objects** with key-value pairs.
    - **Key (Label)** and **Value** are passed as arguments. The first argument is the key, and the second is the value.
    - Example:
      ```sql
      SELECT json_object('key', 'value');
      -- Returns: '{"key": "value"}'
      ```

2. **`json_array()`**:
    - Used to create **JSON arrays** by passing multiple arguments (variadic).
    - Example:
      ```sql
      SELECT json_array(1, 2, 3);
      -- Returns: '[1, 2, 3]'
      ```

---

> ### JSONB Variants:
>
>   - Similar to `json` and `json_array`, you can use the **binary** versions for faster storage and retrieval:
      >

- `jsonb()`: Returns a binary representation of JSON text.

>     - `jsonb_array()`: Returns a binary representation of a JSON array.
>     - `jsonb_object()`: Returns a binary representation of a JSON object.
>
> These binary representations are faster to use when working with large datasets.

### Inspecting Arrays

- `json_array_length()`:
    - This function returns the **number of elements** in a JSON array.
    - It works with both **standalone arrays** and **arrays embedded within JSON objects**.
    - To inspect an array inside a JSON object, use the **JSON Path** syntax (`$`) to specify the location of the array
      within the object.
    - Examples:
        - Standalone array:
          ```sql
          SELECT json_array_length('[1, 2, 3, 4, 5]');
          -- Returns: 5
          ```
        - Array inside a JSON object:
          ```sql
          SELECT json_array_length('{"foo": [1, 2, 3, 4, 5]}', '$.foo');
          -- Returns: 5
          ```

#### Summary:

- **Creating JSON**: You can create JSON using the `json`, `json_object`, and `json_array` functions.
- **Array Inspection**: Use `json_array_length` to find out the size of arrays, even when embedded in objects.
- **Binary vs. Text**: For better performance, use `jsonb`, `jsonb_array`, and `jsonb_object` when handling JSON data
  frequently.

---

## Indexing JSON

**In SQLite**, there are two methods which may used to index JSON data:

1. **[Generated Column with an Index](#generated-column-with-an-index)**
2. **[Functional Index](#functional-index)**

### Generated Column with an Index

**Purpose**: This method creates a new, derived column from the JSON blob and indexes it. The generated column can be
accessed as a top-level column and makes queries more readable.

- **Steps**:
    1. **Create a Generated Column**: This column is derived from the JSON data using `json_extract()`, but it’s not
       physically stored in the database (declared as `VIRTUAL`).
       ```sql
       ALTER TABLE users ADD COLUMN name 
       GENERATED ALWAYS AS (json_extract(data, '$.name')) VIRTUAL;
       ```
    2. **Create an Index on the Generated Column**: Once the generated column is in place, we can add a traditional
       index to it:
       ```sql
       CREATE INDEX idx_name ON users (name);
       ```
    3. **Querying**: Now you can query the indexed JSON data just as you would with any normal column:
       ```sql
       SELECT * FROM users WHERE name = 'Alice';
       ```

- **Advantages**:
    - The derived column is available at the top level of the table, making it easier to query.
    - You can hide the complexity of the JSON blob behind the generated column.
    - Useful if the application or users frequently query the same key (e.g., `name` in this example).

- **Drawbacks**:
    - You store the same data in three places: the original JSON blob, the generated column (though virtual), and the
      index.

### Functional Index

**Purpose**: This method skips the generated column and directly indexes the result of the `json_extract()` function.
The JSON key is indexed, but you have to reference the extraction function in queries.

- **Steps**:
    1. **Create a Functional Index**: Directly index the JSON extraction without creating an additional column:
       ```sql
       CREATE INDEX idx_age ON users (json_extract(data, '$.age'));
       ```
    2. **Querying**: Since the index is built on the `json_extract()` function, you must use the same function in your
       query:
       ```sql
       SELECT * FROM users WHERE json_extract(data, '$.age') = 30;
       ```

- **Advantages**:
    - Skips the middle step of generating a column.
    - Reduces the clutter of additional columns in the database schema.
    - Saves space by not duplicating data across multiple columns.

- **Drawbacks**:
    - You must remember to use the `json_extract()` function when querying, which can make queries more cumbersome and
      harder to read.
    - The function-based query has to exactly match the indexed expression for SQLite to use the index.

### Summary

SQLite offers two primary ways to index JSON data:

1. **Generated Column with Index**: Great for making a part of the JSON easily accessible and queryable as a top-level
   column.
2. **Functional Index**: Efficient when you want to skip creating a new column and only need to optimize query
   performance for specific JSON keys.

Both methods work well depending on the use case, and it's essential to understand the trade-offs in terms of query
complexity, storage overhead, and application needs.

#### Differences Between the Two Methods

| Aspect                | Generated Column with Index                                             | Functional Index                                                      |
|-----------------------|-------------------------------------------------------------------------|-----------------------------------------------------------------------|
| **Column Visibility** | The derived column is accessible as a top-level column.                 | There’s no new column; only the function is indexed.                  |
| **Query Simplicity**  | Easier to query, as the column name can be directly used.               | Queries must include the `json_extract()` function.                   |
| **Storage Overhead**  | Slightly higher storage overhead (data stored in index).                | Less storage overhead, no additional column.                          |
| **Application Use**   | Useful if the application needs to interact with the column frequently. | Ideal when you don't need a top-level column, just index performance. |

#### Important Considerations:

- **Access Patterns**: Ensure your queries match the indexed expression. SQLite requires precise matches for the query
  to use the index.
- **Explain Query Plan**: Always check your queries using `EXPLAIN QUERY PLAN` to verify that the index is being used:
  ```sql
  EXPLAIN QUERY PLAN SELECT * FROM users WHERE name = 'Alice';
  ```
  If the query doesn't match the indexed expression exactly, SQLite may not use the index.

---
