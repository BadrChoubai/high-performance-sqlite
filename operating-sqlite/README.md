# Operating SQLite

## Altering Schema

SQLite offers limited direct schema alterations through `ALTER TABLE`, supporting operations such as renaming tables or
columns and adding columns. More complex schema modifications (like changing column data types or adding foreign keys)
require a [12-step process](https://sqlite.org/lang_altertable.html), which includes:

1. Turn off foreign keys.
2. Begin a transaction.
3. Retrieve the schema.
4. Create a new table with desired changes.
5. Copy data from the old to the new table.
6. Drop the old table.
7. Rename the new table.
8. Recreate indexes, triggers, and views.
9. Perform a foreign key check.
10. Commit the transaction.
11. Re-enable foreign keys.

This process ensures backward compatibility and avoids altering the database directly.

[Chapter Notes](./Altering-Schema.md)

---

## Backing Up a SQLite Database

1. **Using `.backup`**: Safely backs up the database without locking it. Changes made after the command are not
   reflected in the backup.

   ```bash
   sqlite3 database.sqlite ".backup 'backup.sqlite'"
   ```

2. **Using `VACUUM`**: Reclaims space from deleted entries while compressing the database, resulting in a more compact
   file but is more CPU-intensive.

   ```bash
   sqlite3 database.sqlite "vacuum into 'vacuumed.sqlite'"
   ```

3. **Caution when copying files**: Directly copying SQLite files, especially when they are in use, can cause corruption.
   Use `.backup` or `VACUUM` for safer backups.

4. **Third-party tools**: Tools like **Lightstream** offer robust streaming backups but require setup.

[Chapter Notes](./Backing-Up-SQLite.md)

---

## Exporting a SQLite Database

Exporting differs from backing up as it produces a SQL script that can recreate the database in other systems:

1. **Using `.dump`**: Outputs the database schema and data as SQL statements, ideal for migrating to other systems.

   ```bash
   sqlite3 database.sqlite ".dump" > database_dump.sql
   ```

2. **Compressing with `gzip`**: Reduces the size of the SQL dump.

   ```bash
   sqlite3 database.sqlite ".dump" | gzip > gzipped.sql.gz
   ```

3. **Reimporting**: The SQL dump can be reimported into SQLite or other systems.

4. **Recovering from corruption**: Use `.recover` to salvage data from a corrupted database.

[Chapter Notes](./Exporting-SQLite.md)

---

## How to Avoid Corrupting SQLite

1. **Never delete the WAL file**: The Write-Ahead Log contains uncommitted data. Deleting it risks losing this data.

2. **Avoid moving/copying files in use**: Moving or copying database files during use can lead to corruption. Use
   SQLite’s backup tools instead.

3. **Do not modify the database file manually**: Always use SQLite-approved tools for database interactions.

4. **Ensure proper locking mechanisms**: Flawed locking on non-standard file systems can lead to corruption. Modern
   systems generally avoid this issue.

[Chapter Notes](./How-to-not-corrupt-SQLite.md)

--- 

## Multi-Tenancy

Multi-tenancy is an architectural model that enables a single application to serve multiple customers (tenants) while
ensuring data isolation and security, particularly prevalent in Software as a Service (SaaS) environments where
efficiency and scalability are paramount. By adopting multi-tenancy, businesses can streamline resource utilization,
reduce operational costs, and enhance their capacity for innovation. In the context of database systems, this model
supports efficient resource management and scalability, making it an ideal choice for SaaS applications, though it also
introduces complexities related to data access control, query management, and schema migrations.

[Chapter Notes](./Multi-Tenancy.md)
