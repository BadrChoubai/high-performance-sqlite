# Optimizing SQLite

## Locking

### 1. Unlocked

- **Description**: In the "Unlocked" state, no locks are held on the database. Multiple processes can read from or write
  to the database, assuming no other locks have been placed. This is the default state when no transaction is active.
- **Use Case**: When the database is idle or no transactions are currently taking place.

### 2. Shared Lock

- **Description**: A "Shared Lock" allows multiple processes to read from the database at the same time, but none of them
  can write. This lock ensures that no changes are made to the database while data is being read.
- **Use Case**: When a process starts a read operation, it acquires a shared lock to prevent writes during the read
  operation, ensuring consistency.

### 3. Reserved Lock

- **Description**: The "Reserved Lock" indicates that a process intends to write to the database but has not yet begun
  the write operation. This lock allows the process to continue reading but prevents other processes from acquiring any
  additional locks that would interfere with a future write.
- **Use Case**: When a process begins preparing to make changes but hasn't started the write yet, like in the preparation
  phase of a transaction.

### 4. Pending Lock

- **Description**: The "Pending Lock" is a transitional state. A process that wants to write must first acquire a pending
  lock before transitioning to an exclusive lock. During this phase, no new shared locks can be granted, but processes
  that already hold shared locks can continue to read.
- **Use Case**: This state occurs when a process is about to perform a write but must wait until all current readers finish.

### 5. Exclusive Lock

- **Description**: An "Exclusive Lock" grants a single process full access to the database for writing. In this state,
  no other process can read or write until the lock is released. This ensures that the changes made during the write
  operation are atomic and consistent.
- **Use Case**: When a process is actively writing to the database, it holds an exclusive lock to ensure no interference
  from other processes.

These locking stages are critical for ensuring data consistency and integrity in SQLite's concurrent read-write operations,
especially in multiprocess environments.

## Journal Modes

SQLite supports various **Journal Modes** which dictate how the Database Engine manages transactions and writes to disk.
Each mode offering different advantages in terms of performance, concurrency, and the method by which changes are logged
and applied. The Journal is the way that SQLite ensures that you can have atomic commits and rollbacks.

### 1. WAL (Write-Ahead Log) Mode

Write-Ahead Log (WAL) Mode in SQLite significantly enhances performance by allowing concurrent reads and writes, unlike
Rollback Mode. In WAL Mode, new data is written to a separate "write-ahead log" file instead of modifying the database
file directly. This enables multiple readers to access the database while a writer appends changes to the log.

Periodically, a process called a "checkpoint" occurs, merging the changes from the WAL file into the main database file.
This checkpoint is configurable and helps maintain database integrity while improving throughput, as readers don't get
blocked by writers. Readers can see the database up to the last transaction they are aware of, even if new transactions
are being written.

Overall, WAL Mode offers faster writes, higher concurrency, and is the recommended setting for performance in SQLite databases.

### 2. Rollback Mode

Rollback Mode in SQLite is one of the journal modes that ensures atomic commits and rollbacks by maintaining a separate
file (often named with a -journal suffix) during transactions. In this mode, when a page of the database is about to be
modified, the original page is first copied to the journal. Then, the changes are made directly in the database file.
Once the transaction is successfully committed, the journal becomes irrelevant and can either be deleted, truncated, or
zero-filled. If the transaction needs to be rolled back, the original page from the journal is copied back into the database,
restoring the previous state.

A key aspect of Rollback Mode is that it blocks readers during writes since the database file itself is being modified.
Although Rollback Mode is the default, many modern systems prefer Write-Ahead Logging (WAL) for better performance, which
will be discussed in the next video of the course.

## Transaction Modes

### Deferred Transaction (default):

- No intent to write is declared when the transaction starts.
- It begins without locking the database immediately, allowing reads, but will attempt to upgrade to a write lock when needed.
- If an exclusive lock is already held, the transaction fails instantly without waiting, throwing an SQLite busy error.

### Immediate Transaction:

- Declares the intent to write from the start, acquiring a reserved lock early on.
- This gives a grace period (like a 5-second timeout) when trying to upgrade to an exclusive lock. If another transaction
  holds the exclusive lock, it will wait up to 5 seconds (or whatever the busy timeout is set to) before failing.
- In Write-Ahead Logging (WAL) mode, Immediate and Exclusive transactions behave the same.

### Exclusive Transaction:

- Works similarly to Immediate in WAL mode, directly acquiring an exclusive lock from the start.
- Useful when you want to prevent any concurrent access from the moment the transaction begins.

#### Key Considerations:

- **Deferred transactions** can lead to issues when trying to upgrade to a write lock in the middle of a transaction,
  especially if the lock is already held by another process.
- **Immediate transactions** are recommended for write operations because they provide a buffer period to attempt lock
  acquisition without immediately failing.
- It’s important for applications to be configured to use Immediate transactions for writes to avoid lock contention errors
  (SQLite busy) and ensure a smoother user experience.

Different frameworks handle these transactions in various ways, so checking how to enable Immediate transactions in your
specific framework (Rails, Laravel, Django, etc.) is crucial.

## Optimizing and Analyzing Your Database

- **ANALYZE Command**: This command updates the internal statistics (stored in tables like `sqlite_stat1`) that SQLite
  uses for query planning. Running `ANALYZE` after significant changes to the schema or data ensures SQLite has up-to-date
  information for optimization.

- **PRAGMA OPTIMIZE**: This command automates the process of running `ANALYZE` and other optimizations, only analyzing
  tables and indexes that need it. You can pass a flag to see what the command will do before executing it. This makes
  it a more efficient option than running `ANALYZE` manually.

- **PRAGMA Analysis Limit**: By setting a limit (from 1 to 1000, or 0 for unlimited), you control how much of the database
  is analyzed. A recommended setting is 400, balancing performance with thoroughness.

## Suggested Pragma Statements

1. `PRAGMA journal_mode = WAL;`
2. `PRAGMA busy_timeout = 5000;`
3. `PRAGMA synchronous = NORMAL;`
4. `PRAGMA cache_size = 2000;`
5. `PRAGMA temp_store = memory;`
6. `PRAGMA foreign_keys = true;`

### Faster Inserts

1. **Setting `PRAGMA synchronous` to OFF**:

   - This approach turns off SQLite’s default synchronization behavior, which ensures data integrity in case of a crash
     or power outage. Setting `PRAGMA synchronous = OFF` increases insertion speed because SQLite skips the process of
     syncing data to disk after every transaction. However, it introduces some risk: in the event of a system failure,
     you might lose recent changes or corrupt the database.

2. **Batching Inserts into Transactions**:
   - Instead of performing each insert operation within its own transaction (which involves multiple commit operations),
     grouping multiple inserts into a single transaction speeds up the process. By batching, say, 500 or 1000 inserts at
     a time within one transaction, you reduce the overhead of committing after each insert. This method can dramatically
     improve performance, especially on slower drives like HDDs compared to SSDs.
