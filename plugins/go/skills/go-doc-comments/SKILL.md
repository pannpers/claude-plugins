---
name: go-doc-comments
description: Writing Go doc comments that render correctly. Use it whenever you write or fix doc comments in a .go file: package comments, comments on exported identifiers, lists, headings, code blocks, doc links and Deprecated notes.
---

# Doc comments

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md, CONTRIBUTING.md) and the linter configuration (`.golangci.yml`) before you write code; where they disagree with this skill, follow the repository.

The syntax is defined at https://go.dev/doc/comment. Fetch its source when you need a detail this file leaves out:

```bash
curl -sL https://raw.githubusercontent.com/golang/website/master/_content/doc/comment.md
```

## What to write

- Start with the name of the thing and a full sentence: `// ParseDate parses ...`. The first sentence is the summary that `go doc` and pkg.go.dev show in lists.
- Say what it does and why a caller would use it, including the cases a caller must handle (what it returns on failure, whether it is safe for concurrent use, what it blocks on). Leave out how it works unless the caller needs to know.
- A package comment goes on one file per package, as `// Package name ...`.
- Mark replaced API with a paragraph that starts `Deprecated: ` and names the replacement. Tools warn on uses of it.
- Refer to other identifiers with doc links, `[Name]` or `[pkg.Name]`, so that they render as links.

## Syntax mistakes that render wrong

These look fine in the source and break on pkg.go.dev. gofmt does not fix them.

| You want | Write | Not |
|---|---|---|
| A list | Indent the item lines: `//   - item` | `// - item` at the left margin, which renders as an ordinary paragraph |
| A heading | `// # Heading`, unindented, on its own line, with a blank comment line before and after | `// #Heading` (no space), an indented `# Heading`, or a heading with no following text |
| A code block | Indent every line of the block | Unindented lines, which become paragraphs |

## Check before you finish

- `go doc <pkg>.<Name>` inside the module shows the rendered text. A list or heading that did not render shows up as run-together text.
- Many repositories enforce doc comments on exported names with a linter (revive `exported`, golangci-lint). Run the repository's lint.

## Check the Go version

Read the `go` line in `go.mod`. A feature is available only from that version on; the doc comment syntax this skill relies on (links, lists, headings) is rendered from Go 1.19.

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
