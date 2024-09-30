# Altering Schema with Tools

We have touched on the base strategy in SQLite when it comes to altering tables and schemas. These notes
touch on a few tools which may be used alternatively to ease the process.

## Using `sqlite-utils`

One of the options you may choose is `sqlite-utils`, a Python package which can be installed to manipulate and work
with data in SQLite.

### Installing the package

You can install the package using `pip` or if you're using Homebrew on macOS:

```bash
# Check that you have pip installed
pip --version 
# Python >=3.11, use pipx [https://github.com/pypa/pipx]
pip install sqlite-utils

# Alternatively, on macOS
brew install sqlite-utils
```

### Using the package

```bash
# This command is a dry run of what sqlite-utils
# plans to do to our table, it is the exact same
# outcome as what we touched on in the previous lesson.

sqlite-utils transform database.sqlite users --sql
```

```text
CREATE TABLE [users_new_10b8febb8e06] (
   [id] INTEGER PRIMARY KEY NOT NULL,
   [first_name] TEXT NOT NULL,
   [last_name] TEXT NOT NULL,
   [email] TEXT NOT NULL,
   [birthday] TEXT,
   [is_pro] INTEGER NOT NULL DEFAULT '0',
   [deleted_at] TEXT,
   [created_at] FLOAT,
   [updated_at] FLOAT
);
INSERT INTO [users_new_10b8febb8e06] ([rowid], [id], [first_name], [last_name], [email], [birthday], [is_pro], [deleted_at], [created_at], [updated_at])
   SELECT [rowid], [id], [first_name], [last_name], [email], [birthday], [is_pro], [deleted_at], [created_at], [updated_at] FROM [users];
DROP TABLE [users];
ALTER TABLE [users_new_10b8febb8e06] RENAME TO [users];
```

