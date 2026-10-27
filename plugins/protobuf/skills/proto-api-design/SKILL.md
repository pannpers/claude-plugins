---
name: proto-api-design
description: Designing gRPC or Connect APIs in Protocol Buffers along Google's API Improvement Proposals (AIP). Use it whenever you add or change a service, an rpc or a request or response message in a .proto file, name resources, fields or enums, design pagination, filtering, partial updates (field masks), batch or long-running methods, or review a proto API change for naming and consistency.
---

# Protocol Buffers API design

Google's AIPs define resource-oriented API design in detail. This skill is about applying them: which ones matter for a change, and when a repository's own convention should win.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md) and the repository's API naming guide if it has one, and look at two existing services. Where the repository deliberately differs from an AIP (for example its request and response naming, or how it names methods), follow the repository: a single consistent API is easier to use than one that follows AIP in some services only.

## Read the AIP, not a summary

AIPs change over time; each page has a changelog. Fetch the one you need:

```bash
curl -sL https://raw.githubusercontent.com/aip-dev/google.aip.dev/master/aip/general/0132.md   # four digits, zero-padded
```

| The change | AIPs |
|---|---|
| Resource names and the resource each service owns | 121, 122, 123 |
| Get, List, Create, Update, Delete | 131, 132, 133, 134, 135 |
| Custom methods (`:cancel`, `:publish`) | 136 |
| Field names, time and duration fields | 140, 142 |
| Enums | 126 |
| Pagination | 158 |
| Filtering and ordering | 160, 132 |
| Partial update with a field mask | 134, 161 |
| Field behavior (required, output only, immutable) | 203 |
| Long-running operations | 151 |
| Batch methods | 231 to 235 |

## Decisions

- **Model resources, then methods.** Start from the nouns the API exposes and their names; use a standard method where one fits, and a custom method only for an action that is not create, read, update or delete. A custom method for each screen of a client produces an API nobody else can reuse.
- **One request and one response message per rpc.** A shared message ties two methods together: adding a field for one changes the other. `buf lint` checks this in its default rules.
- **Enums** start with an `_UNSPECIFIED = 0` value, so that an unset field is distinguishable from a real value.
- **Time** fields are `google.protobuf.Timestamp` named with a `_time` suffix (`create_time`), durations `google.protobuf.Duration`.
- **Lists** that can grow take `page_size` and `page_token` and return `next_page_token` from the start. Adding pagination later is a breaking change for every client that assumed one page.
- **Updates** that change some fields take a `google.protobuf.FieldMask`, so that a client that does not know a newer field does not erase it.
- **Comments**: every service, rpc, message, field and enum value gets a `//` comment that says what it means to a client, including units and limits. Generated client docs are built from them.

## Verify before you hand over

Run `buf lint` and `buf format -d --exit-code`, or the repository's own targets (for example `make lint`). For changes to existing messages, also run the checks in the `proto-schema-toolchain` skill. Report what ran and its result.
