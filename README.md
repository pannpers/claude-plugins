# claude-plugins

A Claude Code plugin marketplace with general-purpose skills.

## Plugins

| Plugin | What it does |
|---|---|
| [mermaid-diagrams](plugins/mermaid-diagrams) | Chooses the Mermaid diagram type that fits the information, writes it from the current official syntax page and checks that it renders. |

## Install

In Claude Code:

```bash
claude plugin marketplace add pannpers/claude-plugins
claude plugin install mermaid-diagrams@pannpers-plugins
```

On claude.ai: **Customize > Plugins > Add > Add marketplace**, then enter `pannpers/claude-plugins`.
