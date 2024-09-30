# How to _Not_ Corrupt SQLite

SQLite is a robust, well-tested system, but improper handling of its files can lead to corruption. By following these
guidelines—never deleting the `-wal` file, not interfering with active database processes, and using proper tools—you
can avoid corruption and ensure your database remains reliable.

Stay cautious when interacting with SQLite, especially in multiprocess environments, and always rely on built-in safety
mechanisms like transactions and backup methods to protect your data.

## 1. Never Delete the WAL File

- **What is the WAL file?**
    - The `-wal` file stands for Write-Ahead Log. It contains data that hasn’t yet been committed to the main `.sqlite`
      database file.
- **Why is it important?**
    - If you delete the `-wal` file, you risk losing uncommitted data. This file is an essential part of the WAL
      journaling mode, where transactions are stored before they are fully written into the database.
- **Takeaway**: Always keep the `-wal` file until SQLite automatically deletes it after the transaction is fully
  committed.

## 2. What About the SHM File?

- **What is the SHM file?**
    - The `-shm` file stands for shared memory. It is used for coordinating transactions between processes. The file
      helps different processes communicate efficiently.
- **Is it important?**
    - While not as critical as the `-wal` file, the `-shm` file should not be deleted or modified directly. However,
      this file, like the `-wal` file, will automatically disappear once all database connections are closed.
- **Takeaway**: Let SQLite manage the `-shm` file; avoid deleting or tampering with it.

## 3. Don’t Move or Copy Files While They’re in Use

- **Why is this dangerous?**
    - Moving or copying SQLite database files while they are being accessed (especially if they are being written to)
      can easily lead to corruption.
- **What to do instead?**
    - If you need to move or copy the database files, ensure no one else is accessing the database at that time. You can
      start an **immediate transaction** to block other processes from writing. This will make sure no ongoing write
      operations interfere during the file operation.
- **Better solution**: Use SQLite’s **backup methods** (e.g., `.backup` command) to safely copy or move the database
  without risking corruption.
- **Takeaway**: Avoid copying or moving SQLite files during active use. Lock the database with an immediate transaction
  or use SQLite’s backup tools.

## 4. Don’t Write Directly to the Database File

- **What’s the risk?**
    - While SQLite databases are just regular files, writing to the file directly (e.g., opening it in a text editor or
      another tool) can easily corrupt the database.
- **Proper handling**: Always use approved tools (like SQLite’s CLI or appropriate libraries) to read from and write to
  the database.
- **Takeaway**: Never manually modify the database file. Always use SQLite-approved tools for interacting with the
  database.

## 5. Beware of Poor Locking Implementations

- **The problem with bad locking:**
    - SQLite relies on locking mechanisms to manage access between multiple processes. If your file system or operating
      system has a flawed locking implementation, you could end up with two processes writing to the database
      simultaneously, which could corrupt the database.
- **Is this common?**
    - Thankfully, most modern file systems have robust locking mechanisms. However, if you are using an older or
      non-standard file system, you should verify its locking capabilities.
- **Takeaway**: Ensure your environment uses a file system with a reliable locking mechanism to avoid potential
  corruption from concurrent writes.

## 6. Key Rule: Don’t Panic if You See Extra Files

- **What extra files?**
    - If you see files like `-wal` or `-shm`, don’t panic and don’t delete them. These files are part of SQLite’s normal
      operation.
- **What happens to these files?**
    - These files will automatically disappear when the last connection to the database is closed. If they remain, it
      could indicate an issue with open connections or incomplete transactions.
- **Takeaway**: Let SQLite manage its own temporary files. They are there for a reason.
