# SQLite Schemas

This part of the course goes over a lot of what to know about working with data and
how SQLite treats data in regard to its type system.

## Types

The five built-in types supported by SQLite include: `null`, `integer`, `real`,
`text`, and `blob`.

[Flexible Typing Documentation](https://sqlite.org/flextypegood.html)

## Type Affinity

Type Affinity is how SQLite determines if it should take your input and turn it
into a different type.

### Type Affinity Rules

```sql
CREATE TABLE my_table (
    my_int INT -- -> INTEGER affinity
    my_string CHAR, CLOB, TEXT -- -> TEXT affinity
    my_variable BLOB -- -> BLOB affinity
    my_real REAL, FLOA, DOUB  -- -> REAL affinity
    my_otherwise -- -> NUMERIC affinity
)
```

## Strict Types

Using the `strict` table modifier, you can enforce types in your database.

```sqlite
create table strict_types (int integer, text text) strict;
-- .mode box if using CLI

insert into strict_types values (1, 'qwerty');
insert into strict_types values ('qwerty', 1);
--Runtime error: cannot store TEXT value in INTEGER column strict_types.int (19)
```

### Mixing types 

```sqlite
create table kv (key text, value any) strict;
insert into kv values ('name', 'buddy');
insert into kv values ('age', 25);
select key, typeof(key), value, typeof(value) from kv;

drop table kv;
```

## Dates in SQLite

There are no built-in type for `Dates`, it does have built-in functions which work 
on values stored as valid dates. 

Three ways you might store a Date value in SQLite include: TEXT (ISO 8601), 
REAL (JDN), INTEGER (UNIX TIMESTAMP). No matter which way of these three you 
choose they will work with SQLite's built-in date functions.

```sqlite3
select date(); -- YYYY-MM-DD
select datetime(); -- YYYY-MM-DD H:i:s
select unixepoch();
select strftime('%d', 'now');
select timediff(date(), date());

-- Looking for thanksgiving (using datetime modifiers)
select datetime('now', 'start of year', '+10 months', 'weekday 4', '+21 days');

select timediff('now', '1999-03-02');
```

## Booleans in SQLite

```sqlite3
select true; -- 1
select false; -- 0

create table ex (bool int);
insert into ex values (1), (true), (0), (false);
select * from ex;
```

## Floating Point in SQLite

In SQLite, REAL is the datatype that stores floating point numbers.

```sqlite
create table floats (val float);
-- 'float': based on the affinity rules means the value is stored as REAL 
insert into floats values (3.14), (-11.26), (0.0314);


-- If working with decimal values such as prices it is best to insert values in the lowest denomination
-- in USD, those are cents (convert-in, convert-out):
create table prices (cents float);
insert into prices values (3.99*100), (0.99*100), (1299.99*100);
select cents / 100 from prices;

drop table floats;
drop table prices;
```

## Row ID

In SQLite `rowid` is a "secret" primary key for your table. The way that most databases work
is that you declare a primary key and that is how data is kept track of when written to disk.
This creates a clustered index which defines how data is stored on the disk.

In SQLite the `rowid` _is_ the clustered index, so if we define a PRIMARY KEY in our table, sqlite
will still use the `rowid` when storing data on disk.

```sqlite
create table example (n integer);
insert into example values (1), (2), (3);
select rowid, * from example;

drop table example;

create table uuid_example (uuid text primary key);
insert into uuid_example values ('12345678-1234-1234-1234-123456789123');
select rowid, * from uuid_example;

insert into uuid_example values (null);
-- Now we have a null value for one of our rows
-- and sqlite has still created a rowid for it
select rowid, * from uuid_example;

drop table uuid_example;

-- You could instead create the table like this
create table uuid_example (uuid text primary key not null);
-- and now, this does not work
insert into uuid_example values (null);
select rowid, * from uuid_example;

drop table uuid_example;
```

### Aliasing `rowid`

- `rowid` tables: SQLite creates a rowid by default unless an INTEGER PRIMARY KEY column is defined.
- Alias for `rowid`: If you define an INTEGER PRIMARY KEY, that column aliases the rowid and behaves in the same way.

```sqlite
create table example_id (id integer primary key);
select rowid, * from example_id;
insert into example_id values (1), (2);
select rowid, * from example_id;

drop table example_id;
```

| id | id |
| :--- | :--- |
| 1 | 1 |
| 2 | 2 |


### WITHOUT ROWID tables

You can explicitly disable rowid with the WITHOUT ROWID clause, in which case no rowid exists at all.
This can be a performance improvement as well because SQLite no longer has to do two index lookups, one
for the `rowid`, and another for the `primary key`

```sqlite
create table example_no_rowid (id integer primary key, value any) strict, without rowid;
select rowid from example_no_rowid;
-- [1] [SQLITE_ERROR] SQL error or missing database (no such column: rowid)
insert into example_no_rowid values (1, 'apples'), (2, 'bananas');
select * from example_no_rowid;

drop table example_no_rowid;
```

## Generated Columns

There are two types of generate columns:

1. Virtual (calc. at runtime)
2. Stored (calc. once) - written to disk as if it were a regular column

**The value inside a generated column _must_ be deterministic.**

### Example of Virtual Generated Column 

```sqlite
create table people (
    id integer primary key,
    first_name text,
    last_name text,
    full_name generated always as (concat(first_name, ' ', last_name))
);

insert into people (first_name, last_name) values ('badr', 'choubai');
select * from people;

drop table people
```

| id | first\_name | last\_name | full\_name   |
|:---|:------------|:-----------|:-------------|
| 1  | badr        | choubai    | badr choubai |


### Example of Stored Generated Column 

```sqlite
create table products (
    id integer primary key,
    name text,
    price real,
    tax_rate real,
    price_after_tax real generated always as (price + (price * tax_rate)) STORED
);

insert into products (name, price, tax_rate) values ('High Performance SQLite', 179.99, 0.0);
select name, price - (price * 0.30), price_after_tax from products;

drop table products;
```

