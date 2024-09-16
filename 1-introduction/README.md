# Introduction to SQLite

A SQLite database is only a file on disk. Unlike a technology like Postgres or
MySQL, which are ran on a server. This comes with great guarantees for backwards
compatibility and robustness.

## Running SQLite

Many OSes come with SQLite already installed, but you may choose to use a version
installed by your package manager. To check if it is installed run the following
command: `which sqlite3`.

- [Install on Ubuntu](#Installing-SQLite-on-Ubuntu)


## Good uses for SQLite

1. Embedded Applications
2. Web Applications
3. Making application data portable
4. As a file format for application data


## Limitations of SQLite

1. Concurrent writers (Best to use a technology with a server-client architecture)
2. Shared database across multiple machines
3. Size of database
4. Lack of fine-grained access control

### Installing SQLite on Ubuntu

To install SQLite on Ubuntu run the following commands:

1. Update your package list with `sudo apt update`
2. Install `sqlite3` with `sudo apt install sqlite3`
3. Verify your install with `sqlite3 --version` or `which sqlite3`

### Resources

[SQLite Documentation](https://www.sqlite.org/docs.html)
