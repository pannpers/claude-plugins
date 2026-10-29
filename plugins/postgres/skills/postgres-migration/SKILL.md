---
name: postgres-migration
description: Writing PostgreSQL migrations that do not lock out a running application or lose data. Use it whenever you write or review a migration file, or generate one with a tool such as Atlas, golang-migrate, Flyway, Prisma, Alembic or Rails, that adds, drops, renames or retypes a column or table, adds a NOT NULL, unique, foreign-key or check constraint, creates or drops an index, or backfills data, and whenever a migration must run against a table that has traffic.
---

# PostgreSQL migrations

The PostgreSQL docs say which lock each statement takes. This skill is about writing migrations that keep the running application working, and about checking that before they reach production.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md) and its migration workflow (where the desired schema lives, how files are generated and hashed, how they are deployed), and follow it. When a tool generates the migration, review the generated SQL with the rules below; tools often choose the blocking form.

## Read the docs for the server's version

```bash
curl -sL https://www.postgresql.org/docs/<major>/sql-altertable.html      # each form, which ones rewrite or scan the table
curl -sL https://www.postgresql.org/docs/<major>/explicit-locking.html    # which lock each statement takes and what it blocks
```

For Atlas, `https://atlasgo.io/llms.txt` lists every page. `atlas migrate lint` reports destructive and backward-incompatible changes in the free version; its lock checks for PostgreSQL (missing `CONCURRENTLY`, constraint locks) need Atlas Pro, so do not assume a clean lint means the migration does not block.

## Decisions

- **Every migration runs while the old application version is still serving.** Make each step compatible with both versions. A rename or a type change becomes expand and contract: add the new column, write to both, backfill, switch reads, then drop the old one in a later release.
- **Bound the wait for locks.** Start the migration with `SET lock_timeout = '5s'` (or the tool's equivalent). A statement waiting for an `ACCESS EXCLUSIVE` lock blocks every query behind it; failing fast and retrying is safer than a queue.
- **Indexes**: `CREATE INDEX CONCURRENTLY` and `DROP INDEX CONCURRENTLY` on tables with traffic. They cannot run inside a transaction, so the file must not be wrapped in one (Atlas: `-- atlas:txmode none` at the top). A failed concurrent build leaves an `INVALID` index; drop it and retry.
- **Unique and primary keys** on an existing table: build the unique index concurrently, then `ADD CONSTRAINT ... UNIQUE USING INDEX` (or `PRIMARY KEY USING INDEX`).
- **Foreign keys and CHECK constraints**: add them `NOT VALID` (fast, and enforced for new rows), then `VALIDATE CONSTRAINT` in a separate step, which takes a lighter lock while it scans.
- **NOT NULL on an existing column**: add `CHECK (col IS NOT NULL) NOT VALID`, validate it, then `SET NOT NULL`, which skips the scan because the valid check proves it (PostgreSQL 18 also accepts a not-null constraint `NOT VALID` directly). Backfill the NULLs first.
- **Adding a column**: a constant default is stored in the catalog and does not rewrite the table; a volatile default (`clock_timestamp()`, `gen_random_uuid()`), a stored generated column or an identity column rewrites the whole table under an exclusive lock.
- **Changing a column type** usually rewrites the table. Exceptions such as raising a `varchar` limit or `varchar` to `text` are listed in the docs; check before assuming.
- **Backfills** run in batches (by primary key range) in their own transactions, not in one `UPDATE` of the whole table, so that locks and WAL stay small. Keep data changes out of the schema migration when they are large.
- **Dropping** a column or table: first stop the application from reading and writing it and deploy that; only then drop it.

## Verify before you hand over

1. Apply the migrations from an empty database and from a copy of the current schema to a real PostgreSQL of the same major version, using the repository's workflow (for example `atlas migrate apply`, then its validate or drift check).
2. Run the repository's migration lint (`atlas migrate lint`, `squawk`, or its own script) and read every finding.
3. For each statement on a table with data, name the lock it takes and whether it rewrites or scans the table, from the docs page above, and say so in your report.

Report what ran and its result; if no database was available, say that the migration was not executed.
