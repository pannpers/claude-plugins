---
name: mermaid-diagrams
description: Choose the Mermaid diagram type that fits the information, then write it from the current official syntax page and check that it renders. Mermaid has 30+ diagram types (sankey, xychart, treemap, venn, ishikawa, radar, quadrantChart, packet, architecture, block, treeView, timeline, kanban, gitGraph, requirement, usecase, wardley and more), but the habit is to reach for flowchart, sequenceDiagram or stateDiagram for everything. Use this skill every time you are about to write a ```mermaid block or a <pre class="mermaid"> — in an HTML report, an Artifact page, a GitHub PR, issue, README or other Markdown file, or a design doc — and whenever the user asks for a diagram, chart, 図, 図解, フロー図 or 可視化, even if they name no diagram type.
---

# mermaid-diagrams

This skill is an index. It holds only what the official documentation does not tell you: which diagram type fits which shape of information, which renderer runs which Mermaid version, and how to check a diagram before you hand it over. For syntax, read the official page each time (step 3). Mermaid releases often (v12 shipped in September 2026 and new types arrive in minor releases), so syntax copied into a skill goes stale; the official pages also say in each heading which version a feature needs.

## Step 1: Name the question the diagram answers

Write down, in one line, what the reader should be able to answer after a glance. The type follows from that question, not from the subject. "How does the payment flow work?" can be a sequence (who calls whom, in order), a state machine (what states a payment passes through) or a sankey (where the money goes) — each answers a different question.

If no type fits the question better than a table or two sentences, use the table or the sentences. A diagram earns its place when it shows order, branching, proportion, overlap or position that prose would flatten.

## Step 2: Pick the type

Look the question up in this table. The left column is the shape of the information; the keyword is what the diagram starts with; the slug names the official page (step 3). "Since" is the first Mermaid version with the type, taken from the official page heading or the changelog; blank means older than v10.3 and safe everywhere.

### Flow, order and behaviour

| Shape of the information | Type (keyword) | Slug | Since |
|---|---|---|---|
| Steps with decisions and loops | `flowchart` | flowchart | |
| Steps split by who does them (team, system per lane) | `swimlane-beta` | swimlanes | 11.16.0 |
| Messages between participants over time | `sequenceDiagram` | sequenceDiagram | |
| Same, written as code-like nested calls | `zenuml` | zenuml | |
| States of one thing and the events that move it | `stateDiagram-v2` | stateDiagram | |
| Commands, events and read models of an event-sourced system | `eventmodeling` | eventmodeling | 11.15.0 |
| Agents, the tasks and tools they run, control and data between them | `agentflow-beta` | agentflow | 12.0.0 |
| A user's steps with how they feel at each | `journey` | userJourney | |
| Grammar of a language, CLI or format (syntax diagram) | `railroad-ebnf-beta` (also `-abnf-`, `-peg-`, plain IR) | railroad | 11.16.0 |

### Structure and relationships

| Shape of the information | Type (keyword) | Slug | Since |
|---|---|---|---|
| Tables, columns and their cardinalities | `erDiagram` | entityRelationshipDiagram | |
| Types, fields, methods, inheritance | `classDiagram` | classDiagram | |
| Services, databases and queues inside cloud or network groups, with icons | `architecture-beta` | architecture | 11.1.0 |
| Boxes you place yourself in rows and columns (layered stack, memory layout) | `block` (`block-beta` on older renderers) | block | |
| System context, containers, components (C4 model) | `C4Context` and siblings | c4 | |
| Actors and what they can do with the system | `usecase-beta` | usecase | 12.0.0 |
| Requirements, their risk and what satisfies or verifies them | `requirementDiagram` | requirementDiagram | |
| Bit or byte layout of a header or wire format | `packet` | packet | 11.0.0 |
| Directory or file tree | `treeView-beta` | treeView | 11.14.0 |
| Ideas branching from one centre | `mindmap` | mindmap | |
| Branches, commits, merges, cherry-picks | `gitGraph` | gitgraph | |

### Quantities and comparison

| Shape of the information | Type (keyword) | Slug | Since |
|---|---|---|---|
| Flow of a quantity from sources to sinks (cost, traffic, users) | `sankey` (`sankey-beta` on older renderers) | sankey | 10.3.0 |
| Values over an ordered axis, as bars and/or lines | `xychart` (`xychart-beta` on older renderers) | xyChart | |
| Shares of one whole, few slices | `pie` | pie | |
| Shares of a whole that nest (cost by service by SKU) | `treemap-beta` | treemap | 11.8.0 |
| Several items scored on the same 3+ axes | `radar-beta` | radar | 11.6.0 |
| Items placed on two axes (effort vs impact) | `quadrantChart` | quadrantChart | |
| Overlap between sets | `venn-beta` | venn | 11.12.3 |

### Time and planning

| Shape of the information | Type (keyword) | Slug | Since |
|---|---|---|---|
| Tasks with dates, durations and dependencies | `gantt` | gantt | |
| Events or periods in order, no exact durations | `timeline` | timeline | |
| Work items by status column | `kanban` | kanban | 11.4.0 |

### Analysis and strategy

| Shape of the information | Type (keyword) | Slug | Since |
|---|---|---|---|
| Causes of one problem, grouped by category (root cause, incident review) | `ishikawa-beta` | ishikawa | 11.12.3 |
| Value chain against evolution (genesis to commodity) | `wardley-beta` | wardley | 11.14.0 |
| Problems sorted into clear / complicated / complex / chaotic | `cynefin-beta` | cynefin | 11.16.0 |

Tie-breakers:

- Proportions → never a flowchart with numbers on the edges; use sankey, pie, treemap or xychart, which draw the size.
- Architecture → `architecture-beta` when the point is what runs where (groups, icons); `flowchart` with subgraphs when the point is the path a request takes; `C4Context` when the reader knows C4.
- Rules of one thing → text, not `requirementDiagram`. A requirement diagram earns its place only when it shows links between requirements and other things (what satisfies, verifies, derives from or refines what), for example one rule traced across specs, code and tests. Boxes that repeat a list of rule titles add nothing, and their copy of the text drifts from the source. An ER diagram answers a different question (which entities relate, with what cardinality), so one does not replace the other.
- A user's goal and the operations it is made of → `usecase-beta`: the actor, the goal inside a `systemBoundary`, and an `include` edge to each operation. Draw it where the goal is written (a story or user-facing spec), not on each operation, which has no actor of its own. It shows who and what, not order; keep the order in a sequence diagram or the text.
- Over about 15 nodes or 30 edges, split the diagram or move the detail into a table. A picture the reader cannot take in at once has stopped helping.

## Step 3: Read the official page for the syntax

Fetch the page's Markdown source. It is the exact text (WebFetch would summarize it), and every feature heading carries the version it needs, such as "(v11.16.0+)":

```bash
curl -sL https://raw.githubusercontent.com/mermaid-js/mermaid/develop/packages/mermaid/src/docs/syntax/<slug>.md
```

Some pages run past 1,000 lines (flowchart, sequenceDiagram); read the first example and `grep` for the feature you need rather than loading the whole page. The rendered page is `https://mermaid.ai/open-source/syntax/<slug>.html`; link to it when the user wants a reference. The source is the `develop` branch, so it can describe a feature newer than the latest release — check the version in the heading against the renderer (step 4).

## Step 4: Check the renderer's version

A diagram that the renderer cannot parse shows as an error box, so the type has to exist in the Mermaid version where it will be read.

| Where it renders | Mermaid version | What to do |
|---|---|---|
| HTML page or report you write | You choose: import a pinned version from cdn.jsdelivr.net (or read the `mermaid@` import of the template you use) | Use any type up to that version. |
| Artifact page | You choose: import a pinned version from cdn.jsdelivr.net, at least two weeks old per the artifact rules (12.1.0 as of 2026-10-20) | Pin it and use types up to it. |
| GitHub (PR, issue, README, wiki) | Not published, but readable from GitHub's viewer bundle: 12.2.0 on 2026-10-20, a week after its release | Check it when you need a type newer than v11.0: `curl -sL https://viewscreen.githubusercontent.com/markdown/mermaid \| grep -o 'mermaidMarkdown-[^"]*\.js'`, fetch that file from `https://viewscreen.githubusercontent.com/static/assets/`, and `grep -o 'renderer.draw([^)]*)'` prints the version. |
| Claude Docs | Follow the docs `topic.diagram` guide: it draws new pictures as SVG widgets and edits an existing ```mermaid block in place | Use this skill's step 1 and step 2 to choose the picture, and the docs guide to draw it. |
| Anywhere else (VS Code preview, Notion, a static site) | Unknown | Treat it like GitHub. |

If the best type is too new for the renderer, take the next best type from step 2 and say in one line why (for example, "a pie instead of a treemap because GitHub cannot render treemap-beta yet").

## Step 5: Check that it renders

Render every diagram before you hand it over. The newer types are where syntax mistakes happen, and a broken block wastes the reader's time more than a missing one.

Write the diagram to a `.mmd` file in your scratchpad (or another temporary directory) and render it next to it:

```bash
mmdc -i diagram.mmd -o diagram.svg --quiet && echo OK
```

A parse error exits non-zero and prints `Parse error on line N` with a caret under the problem. `mmdc` is `@mermaid-js/mermaid-cli` (`npm install -g @mermaid-js/mermaid-cli`, or run it once with `npx -p @mermaid-js/mermaid-cli mmdc`). If it reports `Could not find chrome-headless-shell`, the install skipped puppeteer's browser download; run `npx puppeteer browsers install chrome-headless-shell` once. Its version decides what it can parse: if the renderer runs an older Mermaid than `mmdc`, a pass is necessary but not enough, so also check the "Since" column. On a parse error, fix the line it names from the official page and render again. If `mmdc` is not installed, say that the diagram was not checked, and do not report it as checked.
