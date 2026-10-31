# claude-plugins

A Claude Code plugin marketplace with general-purpose skills.

## Plugins

| Plugin | What it does |
|---|---|
| [mermaid-diagrams](plugins/mermaid-diagrams) | Chooses the Mermaid diagram type that fits the information, writes it from the current official syntax page and checks that it renders. |
| [github-workflow](plugins/github-workflow) | Pull requests from commit to merge, review-comment replies, commit messages, issues and releases with `gh`, following the repository's own rules. |
| [go](plugins/go) | Go errors, doc comments, package layout, tests and benchmarks, pgx and connect-go v2, checked against the Go version in `go.mod` and `go doc`. |
| [protobuf](plugins/protobuf) | Protocol Buffers API design along Google's AIPs, safe schema changes, protovalidate rules and the buf toolchain. |
| [web-frontend](plugins/web-frontend) | Aurelia 2, CUBE CSS, modern CSS with Baseline checks, semantic HTML and accessibility, and PWAs. |
| [postgres](plugins/postgres) | PostgreSQL schema design and migrations that do not lock out a running application. |

## Install

In Claude Code:

```bash
claude plugin marketplace add pannpers/claude-plugins
claude plugin install <plugin>@pannpers-plugins   # e.g. go@pannpers-plugins
```

On claude.ai: **Customize > Plugins > Add > Add marketplace**, then enter `pannpers/claude-plugins`.
