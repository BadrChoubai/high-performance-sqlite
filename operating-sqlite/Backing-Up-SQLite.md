# Backing up a SQLite Database

1. **Using `.backup`**
    - The `.backup` command is a built-in SQLite method for backing up your database. It ensures that ongoing writes to
      the database can continue, but any new writes after the backup command is issued will not be reflected in the
      backup.
    - This method does not lock the database during the backup process, making it ideal for situations where you need to
      keep the database operational while performing a backup.

   Example command:
   ```bash
   sqlite3 database.sqlite ".backup 'backup.sqlite'"
   ```

    - After running this command, you'll have an identical copy of the database at the point in time when the command
      was issued. It doesn't compress the data, meaning free pages from deleted entries are included.

2. **Compressing the Database During Backup with `VACUUM`**
    - When data is deleted in SQLite, it is not immediately removed but marked as free space, which can make the
      database larger than it needs to be. The `VACUUM` command reclaims this space, compressing the database as it
      backs it up.
    - Unlike `.backup`, `VACUUM` into another file is more CPU-intensive, but it results in a smaller, more compact
      database file. This method can be useful if you want to remove free pages and avoid carrying over deleted data in
      your backup.

   Example command:
   ```bash
   sqlite3 database.sqlite "vacuum into 'vacuumed.sqlite'"
   ```

    - After running this command, you'll notice the backup file is smaller. However, like `.backup`, it does not block
      writes to the database.

3. **Caution When Copying SQLite Files**
    - SQLite databases are generally single-file systems, but you may encounter scenarios where the database is split
      across two or more files (e.g., a database file and a WAL file). If you try copying these files manually while the
      database is being written to, you risk corrupting your backup.
    - It's recommended to use the built-in methods (`.backup` or `VACUUM`) instead of copying files directly unless
      you're absolutely certain no one is writing to the database. Manually copying the files during a write operation
      can be risky.

4. **Third-Party Tools for Backups**
    - If you're not using hosted services like Terso that handle backups automatically, there are third-party tools like
      **Lightstream** that can help with streaming backups. These tools operate by streaming the WAL file to external
      storage like S3, ensuring data consistency during writes.
    - Although they require some setup, these tools can provide a more robust solution for automatic backups, especially
      in scenarios where continuous backup streams are needed.

   However, the best first approach is to stick to the `.backup` or `VACUUM` methods, as they are reliable and built
   into SQLite itself.
