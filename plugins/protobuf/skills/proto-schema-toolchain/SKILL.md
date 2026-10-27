---
name: proto-schema-toolchain
description: Changing Protocol Buffers schemas safely and running the buf toolchain. Use it whenever you add, remove, renumber or retype a field, reserve numbers, add protovalidate rules (buf.validate) to a .proto file, edit buf.yaml or buf.gen.yaml, or run or fix buf lint, buf format and buf breaking failures, including in CI.
---

# Protocol Buffers schemas and buf

The protobuf language guide, the protovalidate rules and the buf docs define the details. This skill is about keeping existing clients working while the schema changes, and about checking that with buf.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md), `buf.yaml` and `buf.gen.yaml`, and the CI workflow that runs buf, and follow them. In particular, check whether code generation runs locally or only in CI.

## Read the source of truth

```bash
# Language guide: field numbers, compatible type changes, presence
curl -sL https://raw.githubusercontent.com/protocolbuffers/protocolbuffers.github.io/main/content/programming-guides/proto3.md
# Every protovalidate rule, with its documentation
curl -sL https://raw.githubusercontent.com/bufbuild/protovalidate/main/proto/protovalidate/buf/validate/validate.proto
# The buf rules this buf version knows, with categories and defaults
buf config ls-lint-rules --version v2
buf config ls-breaking-rules --version v2
```

buf's rule names and categories change between buf versions, so list them with the installed buf instead of relying on a remembered list.

## Changing a schema

- **Field numbers are the wire format.** Never reuse or change a number, and when you remove a field, `reserved` both its number and its name, so that nobody reuses them later and old data is still read correctly. Numbers 1 to 15 encode in one byte and 16 to 2047 in two; give the low numbers to fields that are set most often.
- **Changing a field's type** is safe only between types the language guide lists as compatible (for example `int32`, `uint32`, `int64`, `uint64` and `bool`; `sint32` and `sint64` only with each other). Anything else needs a new field.
- **Renaming** a field keeps the binary format but breaks JSON and generated code; treat it as a breaking change for clients that use either.
- **Presence**: mark a scalar `optional` when the client must be able to tell "not set" from the zero value.
- **Generated plugins**: before adding a remote plugin to `buf.gen.yaml`, check that it exists and which versions it has (`buf registry plugin info <name>`), and generate with the same major version of the runtime library that the consuming code uses.

## Validation rules

- Use the built-in rules (`string.email`, `string.uuid`, `string.uri`, `min_len`, `max_len`, `gt`, `lte`) instead of a regular expression for the same thing. They are easier to read and behave the same in every language's validator.
- Give every string an upper bound (`max_len`), so that the server never has to handle an unbounded value.
- To skip validation on an unset optional field, use `ignore = IGNORE_IF_ZERO_VALUE`; older names such as `IGNORE_IF_UNPOPULATED` are removed.
- Express rules that compare fields with CEL (`option (buf.validate.message).cel`).
- Adding a rule, or tightening one, can reject requests that were valid before. Treat it as a breaking change for existing clients.

## Verify before you hand over

Run the repository's own targets if it has them (`make lint`, `make breaking`, the CI workflow). Otherwise:

```bash
buf format -d --exit-code
buf lint
buf breaking --against '.git#branch=main'
```

If `buf breaking` fails on purpose (an intended breaking change), say so and follow the repository's process for it rather than changing the check. Report which commands you ran and their result.
