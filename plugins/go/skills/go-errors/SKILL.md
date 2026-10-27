---
name: go-errors
description: Go error handling judgement the docs leave open. Use it whenever you write or edit a .go file and the change creates, wraps, returns or checks errors (fmt.Errorf with %w, errors.Is / errors.As / errors.AsType, sentinel errors, custom error types, errors.Join). Not for tests (go-testing), SQL with pgx (go-postgres) or Connect handlers (go-connect-rpc).
---

# Errors

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md, CONTRIBUTING.md) and the linter configuration (`.golangci.yml`) before you write code; where they disagree with this skill, follow the repository.

The `errors` and `fmt` docs explain the API; this file is about choosing between the options. For the API itself, run `go doc errors` and `go doc fmt.Errorf` inside the module (see "Check the Go version" in SKILL.md).

## Choose how a caller can recognize the error

| The caller needs to... | Use | Why |
|---|---|---|
| Only know that it failed | `fmt.Errorf("load config: %w", err)` or a plain `errors.New` | Nothing to match on, so nothing to export |
| Branch on one known condition (not found, closed) | An exported sentinel: `var ErrNotFound = errors.New("...")`, checked with `errors.Is` | Cheap to compare; part of the package's API, so name it and document it |
| Read details (which field, which status code) | An exported error type, checked with `errors.AsType[*T](err)` (Go 1.26+) or `errors.As` | Carries data a sentinel cannot |
| Report several independent failures | `errors.Join` | `errors.Is` and `errors.As` still see every joined error |

A sentinel or error type that you export becomes a promise: callers will match on it. Export one only when a caller has a reason to branch.

## Wrap with `%w`, but decide where the chain stops

- Add context once per layer, saying what this layer was doing: `fmt.Errorf("fetch user %d: %w", id, err)`. Do not repeat what the inner error already says.
- `%w` makes the inner error part of your API, because callers can `errors.Is` it. At a boundary where callers should not depend on an implementation detail (a driver error, an HTTP client error), translate it into your own error, or format with `%v` to keep the message but cut the chain.
- Wrap the error value, not a pointer to it. Since Go 1.27, `go vet` reports `fmt.Errorf("...: %w", p)` when `p` is `*E` and `E` already implements `error`, because `errors.Is` and type assertions then fail.

## Compare with `errors.Is` and `errors.AsType`

- `err == ErrX` and `err.(*T)` miss wrapped errors. Use `errors.Is(err, ErrX)` and `errors.AsType[*T](err)`.
- `errors.AsType` (Go 1.26+) is the type-safe, faster form of `errors.As`. Use `errors.As` only when the module's `go` line is older than 1.26.

## Handle an error once

Either return it or log it and recover, not both. Logging and returning makes every layer above log the same failure again, and the log fills with duplicates of one event.

## Check before you finish

- `go vet ./...` catches `%w` misuse, and printf format errors.
- Search the diff for `== Err`, `.(*` on errors, and `%v` on an error you meant to wrap.

Sources: https://raw.githubusercontent.com/golang/website/master/_content/blog/go1.13-errors.md, and the release notes at `https://raw.githubusercontent.com/golang/website/master/_content/doc/go1.NN.md`.

## Check the Go version

Read the `go` line in `go.mod`. A feature is available only from that version on, for example `errors.AsType` from Go 1.26, `testing/synctest` from 1.25 and `T.Context` from 1.24.

Run `go doc` from inside the module directory. There, the toolchain that `go.mod` names answers; outside the module, the Go installed on the machine answers, and it may not know newer symbols (`go doc errors.AsType` fails on Go 1.25). Release notes, for checking what a version added: `https://raw.githubusercontent.com/golang/website/master/_content/doc/go1.NN.md`.

## Verify before you hand over

Run the repository's own checks if it defines them (a `make lint` or `make check` target, the commands in AGENTS.md or CI). Otherwise run:

```bash
gofmt -l .
go vet ./...
golangci-lint run   # if the repository configures it
go test ./...
```

Report which of these you ran and their result. If one could not run, say so instead of implying it passed.
