---
name: go-connect-rpc
description: Implementing Connect RPC services in Go with connect-go v2 (connectrpc.com/connect/v2). Use it whenever you write or edit a handler that implements a generated *connect service interface, register services on connect.NewServer, write a connect.ServerInterceptor (auth, logging, recovery), read or set headers through CallInfo, return connect errors, implement streaming RPCs, or test handlers with connectinprocess. Also use it to migrate connect-go v1 code to v2.
---

# Connect RPC with connect-go v2

The connect-go docs define the API. This skill is about the decisions they leave to you, and the v1 habits that no longer apply in v2.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md) and one existing handler, and follow where handlers live, how they map application errors and which interceptors are installed.

## Check the version

Look at `go.mod`. `connectrpc.com/connect/v2` is v2; `connectrpc.com/connect` without `/v2` is v1. A module can list both when a dependency is still v1-only; write new code against v2 if the module has it. When the module has only v1, follow the migration guide rather than extending v1 code.

Fetch the docs that match:

```bash
curl -sL https://raw.githubusercontent.com/connectrpc/connect-go/main/docs/v2-guide.md
curl -sL https://raw.githubusercontent.com/connectrpc/connect-go/main/docs/v2-migration.md
curl -sL https://raw.githubusercontent.com/connectrpc/connectrpc.com/main/src/content/docs/docs/go/<page>.md   # interceptors, errors, testing, ...
```

and run `go doc connectrpc.com/connect/v2` from inside the module.

## Decisions

- **Handler shape**: handlers take and return the generated messages, `func(ctx, *FooRequest) (*FooResponse, error)`; there are no `connect.Request[T]` wrappers in v2. Never return `nil, nil`.
- **Metadata**: read and set headers through `connect.CallInfoForServerContext(ctx)`, which returns the call's `*connect.CallInfo` and a bool.
- **Cross-cutting concerns** (authentication, logging, metrics, panic recovery) belong in a `connect.ServerInterceptor` passed to `connect.NewServer`, not in each handler. The first interceptor wraps the outermost call. A v2 interceptor wraps every RPC type, so check the spec's stream type when a concern applies to unary calls only. v2 ships no recovery interceptor; write one.
- **Errors**: only a `*connect.Error` created locally is sent to the client. Any other error reaches the client as a bare code with no message, so a message the client should see must be written on purpose with `connect.NewError(code, message)` or `connect.Errorf`. Attach the underlying error with `WithCause`: it is visible to `errors.Is` on the server and never sent. An error from a downstream Connect call is marked remote and is scrubbed to `CodeInternal` if you return it as is; translate it into your own verdict.
- **Codes**: choose the code from what the client can do next: `InvalidArgument` (fix the request), `NotFound`, `AlreadyExists`, `FailedPrecondition` (the system is not in a state that allows it), `PermissionDenied` or `Unauthenticated`, `Unavailable` (retry later), `Internal` (a bug). `Canceled` maps to HTTP 499.
- **Validation**: validate requests in one interceptor (for example protovalidate's Connect interceptor) rather than in each handler, so that no handler forgets it.

## Testing

Test handlers through a real client and server in the same process, with `connectinprocess.New(server)` as the client's transport. That runs the interceptor chain and error serialization the way production does, without a network listener. Calling the handler method directly skips both.

## Verify before you hand over

Run the repository's own checks (Makefile, AGENTS.md, CI). Otherwise run `go vet ./...`, `golangci-lint run` if configured, and `go test ./...` including the in-process handler tests. Report what ran and its result.
