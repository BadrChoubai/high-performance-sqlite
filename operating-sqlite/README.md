# Operating SQLite

## Altering Schema

![ALTER TABLE Diagram](../docs/assets/ALTER_TABLE-railroad-diagram.png)

> This diagram shows the available commands in SQLite for altering schemas or tables.

SQLite's documentation provides a twelve-step process for altering schema, which can be simplified into four steps:

1. **Create a New Table**
2. **Copy Data from Old Table to New Table**
3. **Drop the Old Table**
4. **Rename the New Table**

```sqlite
PRAGMA FOREIGN_KEYS = off;

BEGIN TRANSACTION;
SELECT type, sql
FROM sqlite_schema
WHERE tbl_name = 'users';

CREATE TABLE users_new
(
    id         integer primary key autoincrement not null,
    first_name varchar                           not null,
    last_name  varchar                           not null,
    email      varchar                           not null,
    birthday   varchar,
    is_pro     integer                           not null default '0',
    deleted_at varchar,
    created_at datetime,
    updated_at datetime
);

CREATE INDEX idx_email ON users_new (email);
CREATE INDEX idx_name ON users_new (first_name, last_name);
CREATE INDEX idx_bday ON users_new (birthday);

INSERT INTO users_new
SELECT *
FROM users;

DROP TABLE users;

ALTER TABLE users_new
    RENAME TO users;
```

| Type    | SQL                                                                                                                                                                                                                                                                                          |
|:--------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Table   | CREATE TABLE "users" ("id" integer primary key autoincrement not null, "first_name" varchar not null, "last_name" varchar not null, "email" varchar not null, "birthday" varchar, "is_pro" integer not null default '0', "deleted_at" varchar, "created_at" datetime, "updated_at" datetime) |
| Index   | CREATE INDEX email ON users (email)                                                                                                                                                                                                                                                          |
| Index   | CREATE INDEX name ON users (first_name, last_name)                                                                                                                                                                                                                                           |
| Index   | CREATE INDEX bday ON users (birthday)                                                                                                                                                                                                                                                        |
| Trigger | CREATE TRIGGER email_updated AFTER UPDATE of email ON users <br/>BEGIN<br/>INSERT INTO email_audit (user_id, old, new) VALUES (old.id, old.email, new.email);<br/>END                                                                                                                        |

- [Documentation for Further Reading](https://sqlite.org/lang_altertable.html)

---

In the video, altering a table is discussed in detail. Four things can be done with `ALTER TABLE` in SQLite:

1. **Rename the Entire Table**: `ALTER TABLE users RENAME TO users_new`.
2. **Rename a Single Column**: `ALTER TABLE users RENAME COLUMN first_name TO first_name2`.
3. **Add a Column**: However, this new column will always be added to the end of the table.
4. **Drop a Column**: This is not supported directly in SQLite.

When compared to other databases, SQLite lacks the ability to modify a column definition (e.g., change data types or
constraints) or manage foreign keys easily through the `ALTER TABLE` command. This limitation arises from how SQLite
stores the schema: it stores the `CREATE TABLE` statement directly, prioritizing **backwards compatibility**.

### Renaming Columns

The process for renaming columns is straightforward, as demonstrated:

```sqlite
ALTER TABLE users
    RENAME COLUMN first_name TO first_name2;
SELECT *
FROM users; -- Returns first_name2 column
```

### Limitations on Adding Columns

One limitation is that when adding a new column, it is always appended to the end of the table, ensuring that SQLite
does not have to update the format of each row, preserving efficiency. If the column has constraints or is a generated
column, SQLite would need to touch each row, leading to slower operations.

### Modifying Columns (The Twelve-Step Process)

To modify columns (or do more advanced schema changes like adding foreign keys), SQLite's twelve-step process can be
simplified into four steps but expands for more complex operations. The full twelve-step process:

1. **Turn Off Foreign Keys**: `PRAGMA foreign_keys = OFF;`
2. **Begin a Transaction**: `BEGIN TRANSACTION;`
3. **Select the Current Schema**: Retrieve current schema details using
   `SELECT type, sql FROM sqlite_schema WHERE tbl_name = 'users';`.
4. **Create the New Table**: Define the new structure with changes.
5. **Copy Data**: Insert data from the old table into the new table.
6. **Drop the Old Table**: `DROP TABLE users;`
7. **Rename the New Table**: `ALTER TABLE users_new RENAME TO users;`
8. **Recreate Indexes and Triggers**.
9. **Recreate Views (if any)**.
10. **Run Foreign Key Check**: `PRAGMA foreign_key_check;`
11. **Commit the Transaction**: `COMMIT;`
12. **Re-enable Foreign Keys**: `PRAGMA foreign_keys = ON;`

This process is considered tedious and prone to error but ensures the changes you want (such as column definitions or
foreign key updates) are implemented correctly.

### Other Strategies for Altering Schema

- [Altering Schema with Tools](./Altering-Tools.md)
    - One option for working with SQLite is using the [`sqlite-utils`](https://github.com/simonw/sqlite-utils) package
      developed by Simon Willison.
    - Another options is to use an Open Source and Contribution fork of SQLite, like
      libSQL: https://github.com/tursodatabase/libsql.