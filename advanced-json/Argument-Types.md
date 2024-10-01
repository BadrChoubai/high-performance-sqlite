# Path Arguments vs. Value Arguments in SQLite JSON Functions

## 1. JSON Functions Overview

- JSON functions can be categorized into:
    - **Scalar functions**: Operate on a single value (e.g., `JSON_EXTRACT`).
    - **Aggregate functions**: Perform operations across multiple values.
    - **Table-value functions**: Return table-like data.

- Understanding how SQLite handles **path arguments** and **value arguments** is crucial when working with JSON
  functions.

## 2. Path Arguments

- **Path arguments**:
    - Always start with a **dollar sign (`$`)**.
    - Followed by either a **dot** (.) and an object path or a **square bracket** (`[]`) for arrays.

- **Examples of Path Argument Syntax**:
    - **Object paths**:
        - E.g., `$.objectName.keyName`—the path starts with `$`, followed by dots to access object keys.
    - **Array paths**:
        - E.g., `$.arrayName[0]`—for zero-indexed arrays.
        - For addressing from the right side of the array, use the **pound sign (`#`)**. This allows addressing the last
          item in an array.
        - Example: For an array of length 5, `$.arrayName[#-1]` would extract the last element.

- **Using Path Arguments in JSON Functions**:
    - The `JSON_EXTRACT` function uses path arguments to extract data from a JSON object or array.
        - Example: `JSON_EXTRACT('[1, 2, 3]', '$[2]')` will return the value `3` (since arrays are zero-indexed).

## 3. Value Arguments

- **Value arguments**:
    - Represent values passed directly to a function. These can be:
        - Strings, numbers, or other JSON objects.
    - **Important distinction**:
        - If a function asks for a value and you pass a string, it treats it as a string, **not as JSON**.

- **Example with JSON_OBJECT Function**:
    - The `JSON_OBJECT` function expects a label and a value. If you pass a string as a value, it will store it **as a
      string**, even if the string looks like JSON.
    - Example:
      ```sql
      SELECT JSON_OBJECT('example', '[1, 2, 3]');
      ```
        - Output: `{"example": "[1, 2, 3]"}` (The array is treated as a string, not as JSON).

- **Handling JSON and Strings**:
    - When SQLite expects **JSON** (as in `JSON` argument), it can interpret a string as JSON:
      ```sql
      SELECT JSON('[1, 2, 3]');
      ```
        - Output: `[1, 2, 3]` (interpreted as an array).

    - When SQLite expects a **value**, passing a string results in treating it as a literal string:
      ```sql
      SELECT JSON_OBJECT('example', JSON('[1, 2, 3]'));
      ```
        - Output: `{"example": [1, 2, 3]}` (The array is correctly interpreted as JSON).

## 4. Best Practices for Passing Arguments

- **Ensure proper conversion**:
    - If you pass JSON-like strings, **explicitly convert** them to JSON using the `JSON()` function or other similar
      functions.

- **Alternatives to Work with JSON in SQLite**:
    - Use **JSON unquoting operator** (`$`) to extract or convert a string to JSON.
        - Example: `SELECT JSON_EXTRACT('[1, 2, 3]', '$')` will return the entire array.
    - Alternatively, use **native JSON functions** like `JSON_ARRAY` to directly construct JSON objects or arrays.

## 5. Common Pitfalls

- **String vs. JSON Confusion**:
    - If a function expects JSON but is passed a string, it may produce unexpected results (e.g., treating an array-like
      string as a literal string).
    - Always verify whether the function expects a **path**, **JSON**, or **value** to avoid errors in the output.

### Summary

- **Path Arguments**: Always start with a `$`, used for navigating JSON objects or arrays.
- **Value Arguments**: Direct values passed to functions, treated as strings unless explicitly converted to JSON.
- **Best Practices**: Be cautious when passing arguments—ensure that strings are converted to JSON when needed using
  functions like `JSON()`.

[JSON Functions and Operators Documentation](https://sqlite.org/json1.html)

---