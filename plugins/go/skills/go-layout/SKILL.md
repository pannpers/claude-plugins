---
name: go-layout
description: Go package layout and dependency wiring. Use it whenever you add a Go package or file, decide where code or an interface lives, name a package, or wire constructors and dependencies in a .go file.
---

# Package layout and dependencies

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md, CONTRIBUTING.md) and the linter configuration (`.golangci.yml`) before you write code; where they disagree with this skill, follow the repository.

The official guide is https://go.dev/doc/modules/layout (source: `https://raw.githubusercontent.com/golang/website/master/_content/doc/modules/layout.md`). The "golang-standards/project-layout" repository is not an official standard; its own issue #117 says so.

## Where code goes

- Follow the layout the repository already has. Read its top-level directories and AGENTS.md before you add a package; a new convention in one PR leaves two conventions in the codebase.
- `cmd/<name>/main.go` for each binary; keep `main` small, building dependencies and starting the program.
- `internal/` for code that other modules must not import. The compiler enforces it, so it is the cheapest way to keep an API private.
- A package is named after what it provides (`orders`, `retry`), not after what it contains (`utils`, `common`, `models`). Callers read the package name at every call site: `orders.Cancel`, not `models.CancelOrder`.

## Interfaces and constructors

- Define an interface in the package that uses it, with only the methods that package calls. The implementing package does not need to know the interface exists.
- Constructors return concrete types (usually a pointer). Returning an interface hides methods from callers and makes adding methods a breaking change. The Go wiki says: "The implementing package should return concrete (usually pointer or struct) types".
- Do not define an interface before there is a second implementation or a test double that needs it.

## Dependencies

- Pass dependencies in through constructors or struct fields, so that tests can replace them. Avoid package-level state such as a global logger or database handle.
- Pass `context.Context` as the first parameter of functions that do I/O or may block, and do not store it in a struct.

Sources: https://raw.githubusercontent.com/golang/wiki/master/CodeReviewComments.md, https://go.dev/blog/package-names.

## Check the Go version

Read the `go` line in `go.mod`. A feature is available only from that version on, for example `tool` directives in `go.mod` from Go 1.24.

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
