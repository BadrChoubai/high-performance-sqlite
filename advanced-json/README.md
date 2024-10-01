# Advanced JSON

In this chapter, we'll dive into advanced concepts of one of the most widely used data interchange formats: JSON. JSON
has become essential for modern data communication, and many developers consider it their go-to format. If you're not
among them, you may simply have other priorities like friends, hobbies, or life outside of coding—which is perfectly
fine! However, in this chapter, we're going to take a close look at JSON, particularly in the context of databases like
SQLite.

While storing JSON in databases is common, it's important to consider how you're using it. If your JSON objects have
well-defined schemas and you're frequently querying or updating them, it might be more efficient to break those values
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

**Sections**:

- [JSON vs. JSONB](#json-vs-jsonb-in-sqlite-key-differences)
- [Valid JSON](#valid-json)
- [Creating JSON Objects + Arrays](#creating-json-objects--arrays)

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

### Validating JSON with `json_valid`

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

## Creating JSON Objects + Arrays

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

> **JSON-B Variants**:
>- Similar to `json` and `json_array`, you can use the **binary** versions for faster storage and retrieval:
>  - `jsonb()`: Returns a binary representation of JSON text.
>  - `jsonb_array()`: Returns a binary representation of a JSON array.
>  - `jsonb_object()`: Returns a binary representation of a JSON object.
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
