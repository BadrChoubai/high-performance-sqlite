# High Performance SQLite Course Notes

This project contains source code, artifacts, and written notes created while learning the foundations of SQL and
SQLite.

## Setting up our Database

The course has a downloadable sqlite database to use and run alongside the lessons.

1. I've created a separate repository that contains a zip archive of the database:
    - [https://github.com/BadrChoubai/demo-database](https://github.com/BadrChoubai/demo-database)
2. You can clone the database with `git clone https://github.com/BadrChoubai/demo-database`
3. Then you can run `unzip` the contents of the archive into this project
   ```bash
   unzip ~/git/demo-database/database.zip .
   ```

## Chapters

1. [SQLite Internals](./sqlite-internals/README.md)
2. [Schema](./schema/README.md)
3. [Optimizing SQLite](./optimizing-sqlite/README.md)
4. [Indexes](./indexes/README.md)
    - [Creating and Using Indexes](./indexes/Intro-to-Indexes)
    - [Other Types of Indexes](./indexes/Other-types-of-Indexes.md)
5. [Advanced SQL](./advanced-sql/README.md)
   - [Recursive CTEs](./advanced-sql/Recursive-CTEs.md)
   - [Window Functions](./advanced-sql/Window-Functions.md)
   - [Row Value Syntax](./advanced-sql/Row-Value-Syntax.md)
   - [Indexed Sorting](./advanced-sql/Indexed-Sorting.md)
   - [Upserts](./advanced-sql/Upserts.md)
   - [Aggregates](./advanced-sql/Aggregates.md)
6. [Operating SQLite](./operating-sqlite/README.md)
   - [Altering Schema](./operating-sqlite/Altering-Schema.md)
   - [Backing up SQLite](./operating-sqlite/Backing-Up-SQLite.md)
   - [Exporting SQLite](./operating-sqlite/Exporting-SQLite.md)
   - [How _not_ to Corrupt SQLite](./operating-sqlite/How-to-not-corrupt-SQLite.md)
   - [Multi-Tenancy](./operating-sqlite/Multi-Tenancy.md)
7. [Advanced JSON](./advanced-json/README.md)
   - [Argument Types](./advanced-json/Argument-Types.md)
   - [JSON Functions](./advanced-json/JSON-Functions.md)

### Quick Bits

- [Dealing with `NULL`](./quick-bits/NULL.md)
- [The `RETURNING` Clause](./quick-bits/Returning.md)
- [Triggers](./quick-bits/Triggers.md)
- [Operating SQLite: Multi-Database Approach](./quick-bits/Multi-Database.md)
- [JSON5 Support in SQLite](./quick-bits/JSON5.md)

---

## Introduction to SQLite

SQLite is a lightweight, serverless, self-contained database management system.
Unlike most databases (e.g., Postgres, MySQL), SQLite doesn’t require a separate server; it’s an embedded database
that stores everything in a single file.

### Features of SQLite:

- **Serverless**: No need for a separate server process. The database is just a file that your application accesses
  directly.
  Zero Configuration: No installation or setup is required. You just include the SQLite library in your project and
  start
  working.
- **Lightweight**: It's small, fast to set up, and designed for small to medium applications like mobile apps or
  embedded systems.

### Use Cases:

- **Single-user applications**: Ideal for desktop or mobile apps where there’s only one user or minimal data.
  Embedded systems: Great for small devices or applications with limited resources.
- **Prototyping**: Excellent for quick prototypes or proof-of-concept projects due to its ease of setup.

### Limitations:

- **Limited concurrency**: Only one write operation can happen at a time, making it less suitable for high-traffic,
  multi-user
  applications.
- **Not built for large-scale, high-performance systems**: It’s perfect for smaller projects but not for
  enterprise-level applications that require robust transaction handling and scalability.

  > ### SQLite Security Considerations:
  >
  > - **No Built-In User Authentication**: Unlike larger database systems like PostgreSQL or MySQL, SQLite doesn’t have
      a
      concept of users or roles with specific permissions. There’s no fine-grained access control—anyone with access to
      the database file can read and write to it.
  > - **File-Based Security**: Since SQLite stores data in a single file, securing the database depends largely on the
      file system permissions. You should ensure that only trusted users or processes can read or modify the database
      file.
  > - **Encryption**: SQLite doesn’t provide encryption by default, but you can use external libraries, like SQLite
      Encryption Extension (SEE) or SQLCipher, to encrypt the database file. This is critical if the file might be
      stored
      on untrusted devices or environments (e.g., in mobile apps).
  > - **Data Integrity**: Even though it doesn’t have fine-grained access controls, SQLite still provides security for
      data integrity with ACID-compliant transactions and journaling to prevent corruption.

### Comparison to other Technologies:

- SQLite is file-based and serverless, while Postgres is a more complex, full-featured, client-server database
  designed
  for larger, scalable applications.
- SQLite is simpler but has limitations in handling concurrency and large-scale workloads, while PostgreSQL excels in
  those areas.

[Wikipedia Page for Further Reading](https://en.wikipedia.org/wiki/SQLite)

## Running SQLite

Many OSes come with SQLite already installed, but you may choose to use a version
installed by your package manager. To check if it is installed run the following
command: `which sqlite3`

- [Install on Ubuntu](#Installing-SQLite-on-Ubuntu)

### Installing SQLite on Ubuntu

To install SQLite on Ubuntu run the following commands:

1. Update your package list

   ```bash
   sudo apt update
   ```

2. Install the `sqlite3` package

   ```bash
   sudo apt install sqlite3 
   ```

3. Verify your install with `sqlite3 --version`

   ```bash
   sqlite3 --version
   ```

#### Resources

- [High Performance SQLite](https://highperformancesqlite.com/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
