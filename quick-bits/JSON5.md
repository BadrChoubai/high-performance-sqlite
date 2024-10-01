# Introduction to JSON5 in SQLite

- **SQLite's Minimalist Philosophy:** SQLite is known for being small, fast, and efficient, avoiding unnecessary
  features. However, despite this philosophy, SQLite has surprisingly added support for **JSON5**.
- **JSON5 Overview:** JSON5 is an extended version of JSON designed to be more human-readable, allowing for more
  flexibility in writing JSON, such as:
    - Unquoted keys
    - Inline comments
    - Extra whitespace
    - Trailing commas
    - Special values (e.g., `Infinity`).
- JSON5 support in SQLite provides flexibility for those working with human-friendly JSON formats but be cautious:
    - The output will always be compressed and stripped of JSON5-specific features.
    - For consistent results, it’s best to stick with standard JSON where possible.

## 1. JSON5 as Input, Real JSON as Output

- **Input Support Only:** SQLite allows **JSON5** as input, but it **does not preserve** the JSON5 format when storing
  or returning the data. Instead, it converts JSON5 into standard JSON.
- **Automatic Conversion:** When JSON5 is passed to a function in SQLite that accepts JSON:
    - It strips away any JSON5-specific features (like comments, unquoted keys, extra whitespace, trailing commas).
    - Converts it into valid JSON according to the standard (ISO or ECMA spec).

- **Example**:
  ```sql
  SELECT JSON('{
   // This is a comment
   unquoted: "Whoa",
   trailingComma: true,
  }');
  ```
  > The above JSON5 input will be converted to standard JSON, removing the comment, normalizing the keys, and
  eliminating the trailing comma.
  > The output would look like:
  >  ```json
  >  {"unquoted":"Whoa","trailingComma":true}
  >  ```

## 2. Special Values in JSON5

- **Special Cases in JSON5:** JSON5 allows some unique values that are not part of regular JSON:
    - For example, **`Infinity`** as a valid number:
      ```sql
      SELECT JSON('{"number": Infinity}');
      ```
      > SQLite will convert **`Infinity`** into a valid JSON number or throw an error depending on the context, but it
      can
      >  accept JSON5 for input.

## 3. Limitations of JSON5 in SQLite

- **Non-Preservation of JSON5 Features:** SQLite does not preserve JSON5 formatting or features such as:
    - Comments
    - Trailing commas
    - White spaces
- This means that while SQLite **accepts** JSON5 for input, it will always store and output **standard JSON**.

## 4. Best Practices When Using JSON5 in SQLite

- **Be Mindful of the Conversion:** Since SQLite converts JSON5 to standard JSON, it’s essential to:
    - Avoid relying on JSON5-specific features (e.g., comments or unquoted keys) in critical operations, as they will be
      stripped away.
    - Use JSON5 **only** for input flexibility but not for preserving human-readable formats.
- **Recommendation for Writing JSON:** Although SQLite supports JSON5, it is recommended to:
    - **Hand-write standard JSON** if you want to avoid potential errors or stripped-away features.
    - This ensures that the JSON will be stored and returned in the same format without unexpected data changes.

## 5. JSON5 and Malformed JSON Handling

- **SQLite's Promise on Malformed JSON:** SQLite guarantees that no matter how malformed the JSON is (including JSON5):
    - It **will not crash** SQLite.
    - However, errors or unexpected results may occur. If the JSON is incorrectly formatted, SQLite will throw an error
      rather than fail internally.

## 6. Use Cases for JSON5 in SQLite

- **Existing JSON5 Data:** If you are working with data that already uses JSON5 formatting, you can pass it into SQLite
  without having to manually convert it to standard JSON.
- **Flexible JSON Input:** JSON5 can be particularly helpful for **programmatically generated JSON** that might include
  extra whitespace, comments, or other features that SQLite can automatically handle.

---