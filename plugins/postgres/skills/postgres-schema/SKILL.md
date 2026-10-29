---
name: postgres-schema
description: Designing PostgreSQL schemas. Use it whenever you create or change a table, column, type, constraint, index, enum or view in PostgreSQL DDL (schema.sql, a migration, an ORM model that generates DDL), choose a primary key or ID type, decide how to store time, money, text, JSON or state, decide between an enum, a CHECK constraint and a lookup table, or review a schema design in a design document.
---

# PostgreSQL schema design

The PostgreSQL docs define the types and constraints. This skill is about the choices that are hard to change once a table holds data.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md), the schema source of truth (for example `schema.sql` or the migration directory) and any schema lint script, and follow them. They may be stricter than this skill, for example on ID types or audit columns.

## Check the version and read the docs

Find the server's major version: the database image or instance config, or `SELECT current_setting('server_version_num')`. Read the docs for that version, not the newest one; features such as `uuidv7()` (18) and virtual generated columns (18) are version-specific.

```bash
curl -sL https://www.postgresql.org/docs/<major>/datatype.html          # types; sql-createtable.html, ddl-constraints.html, indexes.html
curl -sL -A 'Mozilla/5.0' "https://wiki.postgresql.org/wiki/Don%27t_Do_This"   # the community's list of common mistakes, each with "when should you"
```

## Decisions

- **Time**: `timestamptz` for a point in time (it stores an instant and converts on display); `date` for a calendar date with no time; plain `timestamp` only for a wall-clock time with no zone, such as a recurring local opening hour.
- **Text**: `text` with a `CHECK (char_length(x) <= n)` when there is a real business limit; `varchar(n)` adds nothing and changing `n` is a migration. Never `char(n)`.
- **Money**: `numeric` with the scale the currency needs, or an integer of minor units with the currency in another column. Never `money` or `float`.
- **Primary keys**: `bigint GENERATED ALWAYS AS IDENTITY` for internal rows, or a UUID when IDs are created outside the database or must not be guessable. Prefer UUIDv7 over v4 for keys that are indexed and inserted often: time-ordered values keep the B-tree index compact. A UUIDv7 reveals its creation time. Do not use `serial`.
- **Constraints belong in the database.** `NOT NULL` unless the absence of a value means something, foreign keys for every reference, `UNIQUE` for every business key, `CHECK` for value rules. Application checks alone race under concurrency.
- **Index foreign keys** used in joins or by `ON DELETE` on the referenced table; PostgreSQL does not create these indexes for you. Add other indexes for real queries, and check them with `EXPLAIN`.
- **A closed set of states**: a `CHECK (state IN (...))` or an enum type is fine when values are only added; a lookup table when the values carry data or users manage them. Removing or renaming an enum value is hard, so do not use one for a set that will shrink.
- **JSON**: `jsonb` for data whose shape the database does not need to enforce; columns for anything you filter, join or constrain on.
- **Deletes and history**: decide whether deleted rows must stay readable. A `deleted_at` flag must then be in every query and every unique constraint (as a partial index); a history table or an append-only event table keeps the main table simple. Choose one on purpose instead of adding `updated_at` and `deleted_at` to every table by habit.
- **Names**: lower-case `snake_case` (unquoted identifiers are folded to lower case), plural or singular as the schema already does.

## Verify before you hand over

Apply the schema to a real PostgreSQL of the same major version (the repository's Docker Compose, a test container or its dev database), not only to a mock. Run the repository's schema lint and tests. For a new index or a query the change is meant to support, run `EXPLAIN (ANALYZE, BUFFERS)` on realistic data and check that the plan uses it. Report what ran; if no database was available, say that the DDL was not executed.
