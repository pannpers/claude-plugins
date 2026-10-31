---
name: go-postgres
description: Writing Go code that talks to PostgreSQL through pgx v5. Use it whenever you write or edit a repository or store file with SQL in it (*_repo.go, *_store.go, a repository package), or code that uses pgx, pgxpool, pgx.Rows, CollectRows, Scan, Exec, transactions (Begin, BeginTx, pgx.BeginFunc), Batch, CopyFrom, NULL columns, custom types such as enums, or that maps pgconn.PgError codes (unique or foreign-key violations) to application errors.
---

# PostgreSQL with pgx

The pgx docs cover the API. This skill is about the decisions that keep database code correct under concurrency and failure.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md) and one existing repository file, and follow how it scans rows, represents NULL, places transactions and maps errors.

## Check the versions

Read `github.com/jackc/pgx/v5` in `go.mod`. Run `go doc github.com/jackc/pgx/v5`, `go doc github.com/jackc/pgx/v5/pgxpool.Config` and `go doc github.com/jackc/pgx/v5/pgtype` from inside the module, so that the docs match the version in use. For a longer explanation, read the package doc in the module cache: `$(go list -m -f '{{.Dir}}' github.com/jackc/pgx/v5)/pgtype/doc.go`.

## Decisions

- **Queries**: pass values as placeholders (`$1`, `$2`), never by formatting them into the SQL string. A formatted value is an injection risk and defeats the prepared statement cache.
- **Columns**: name the columns you read, so that adding a column to the table does not change what your scan expects. `SELECT * FROM unnest(...)` and similar set-returning functions, whose shape you control, are fine.
- **Scanning**: `pgx.CollectRows` with `pgx.RowToStructByName` maps columns to struct fields by name; plain `rows.Scan` is explicit and fails loudly when the column order changes. Either way, check `rows.Err()` (or use a helper that does), because iteration errors surface only there.
- **NULL**: a nullable column needs a type that can hold NULL: a pointer, a `pgtype` type, or `sql.Null*`. Scanning NULL into a plain `string` or `int` fails at run time.
- **Transactions**: decide which layer owns the boundary. The boundary belongs where the business rule lives that needs several statements to succeed or fail together. Use `pgx.BeginFunc` (or `BeginTxFunc`), which commits on success and rolls back on error or panic; a hand-written `Begin`/`Commit` must check the error that `Commit` returns, because that is where a serialization failure appears.
- **Errors**: `pgx.ErrNoRows` means "not found", and callers usually need it as their own not-found error. Map constraint violations by code, not by message: `errors.AsType[*pgconn.PgError](err)` (Go 1.26+), then `pgErr.Code` against the codes in `pgerrcode` (`23505` unique violation, `23503` foreign key violation). Wrap the original error as the cause, so that the driver detail is still in the log.
- **Custom types**: PostgreSQL enums and domain types must be registered on each connection before they can be scanned: load them with `conn.LoadType` or `conn.LoadTypes` in `pgxpool.Config.AfterConnect`.
- **Bulk work**: `pgx.Batch` sends several statements in one round trip; `CopyFrom` loads many rows fastest but bypasses `ON CONFLICT`.
- **Pool**: size `pgxpool.Config.MaxConns` from what the database allows across all replicas of the service, not from the CPU count of one replica.

## Verify before you hand over

Run the repository's tests against a real PostgreSQL (its Makefile, Docker Compose or test container setup). Mocked database tests cannot catch SQL syntax errors, wrong column types or constraint behaviour. Then run `go vet ./...` and the repository's lint. Report what ran; if no database was available, say that the SQL was not executed.
