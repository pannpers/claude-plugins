---
name: go-testing
description: Writing and fixing Go tests and benchmarks. Use it whenever you create or edit a _test.go file, add test cases, test code that uses time, goroutines or channels (testing/synctest), write a test helper or test double, debug a flaky or racy test, or write a benchmark and compare results with benchstat.
---

# Go tests and benchmarks

The `testing` package docs define the API. This skill is about the choices that decide whether a test catches regressions without breaking for unrelated reasons.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md, CONTRIBUTING.md) and two or three existing `_test.go` files near the code you are testing, and follow their assertion library, package naming, table shape and mocking tool. A test written in a different style from its neighbours is harder to maintain than either style alone.

## Check the Go version

Read the `go` line in `go.mod`; these depend on it:

| Since | Feature | Use it for |
|---|---|---|
| 1.24 | `t.Context()` | A context canceled when the test ends, instead of `context.Background()` |
| 1.24 | `for b.Loop() { ... }` | Benchmark loops; it keeps results alive so the compiler cannot optimize the work away |
| 1.25 | `testing/synctest` (`synctest.Test`, `synctest.Wait`) | Code that uses timers, tickers, timeouts or goroutines |
| 1.26 | `t.ArtifactDir()` | Files a test writes for later inspection (`go test -artifacts`) |
| 1.27 | `synctest.Sleep`, `httptest.NewTestServer` | Advancing the fake clock and waiting in one call; an HTTP server on the fake network inside a bubble |

Run `go doc testing`, `go doc testing/synctest` and `go doc <test library>` from inside the module directory: there, the toolchain that `go.mod` names answers, while outside it the machine's Go may not know newer symbols. Release notes: `https://raw.githubusercontent.com/golang/website/master/_content/doc/go1.NN.md`.

## Choices

- **Time and concurrency**: run the test inside `synctest.Test`. In the bubble the clock is fake: `time.Sleep` advances it instantly and `synctest.Wait` waits until every goroutine in the bubble is blocked. That makes timeouts and retries deterministic. A real `time.Sleep` outside a bubble is only right when the test needs real wall-clock time, for example to widen a race window against a real database.
- **Checking errors**: compare with `errors.Is` or `errors.As` (or the assertion library's equivalent), not with the error string. A string check breaks when someone rewords a message.
- **Parallelism**: call `t.Parallel()` only when the test shares no mutable state. Tests that set environment variables, change the working directory or touch globals must not be parallel; `t.Setenv` and `t.Chdir` panic in parallel tests for this reason.
- **Helpers**: call `t.Helper()` first, so that a failure points at the caller's line.
- **Cleanup**: use `t.Cleanup` rather than `defer` in helpers, so that cleanup runs after the test, not when the helper returns.
- **Test doubles**: replace a dependency through the interface the code under test already accepts. If the code reaches a dependency through a global, that is a design problem to fix in the code, not something to patch around in the test.

## Benchmarks

Measure before and after a change, and compare with benchstat. A single run is noise.

```bash
go test -run='^$' -bench=<Name> -count=10 ./<pkg> > old.txt
# make the change
go test -run='^$' -bench=<Name> -count=10 ./<pkg> > new.txt
go run golang.org/x/perf/cmd/benchstat@latest old.txt new.txt
```

Report the benchstat table, including the p-value; a change whose interval crosses zero did not measurably help.

## Verify before you hand over

Run the repository's own test target if it has one (Makefile, AGENTS.md, CI). Otherwise:

```bash
go vet ./...
go test -race -shuffle=on ./...
```

`-race` finds data races that pass silently without it, and `-shuffle=on` finds tests that depend on running in order. Report which commands you ran and their result; if one could not run (no database, no network), say so instead of implying it passed.
