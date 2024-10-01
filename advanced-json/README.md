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

