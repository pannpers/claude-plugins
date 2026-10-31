---
name: aurelia
description: Writing Aurelia 2 applications. Use it whenever you create or edit an Aurelia component (a .ts view model with its .html template), a template binding (.bind, .trigger, repeat.for, if.bind, au-slot), a @bindable, a lifecycle hook, a DI service (DI.createInterface, resolve), @observable, @computed or @watch state, a value converter, binding behavior or custom attribute, a route or router hook in @aurelia/router, or a test with @aurelia/testing; and when you read an AURxxxx error.
---

# Aurelia 2

The Aurelia docs cover the API. This skill is about the decisions they leave to you, and about the Aurelia 1 and React habits that produce wrong Aurelia 2 code.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md) and one existing component and service, and follow how it injects services, sends events from child to parent, logs, and registers components.

## Check the version and read the docs

Read the `aurelia` and `@aurelia/*` versions in `package.json` (and the lockfile for the installed one). Aurelia 2 shipped as release candidates for a long time; check the release notes when the installed version differs from the current one: `npm view aurelia dist-tags`.

The docs publish every page as Markdown, listed in one index:

```bash
curl -sL https://docs.aurelia.io/llms.txt                       # every page, with a one-line summary
curl -sL https://docs.aurelia.io/components/component-lifecycles.md   # a page: the index URL as is
curl -sL https://docs.aurelia.io/developer-guides/developing-with-ai.md   # the docs' own list of mistakes AI makes
```

For an `AURnnnn` error, find it in `llms.txt` (`grep -i 'AUR0001'`) and read that page; it names the cause and the fix.

## Decisions

- **Observation, not re-rendering.** Bindings update DOM nodes directly when a property changes; there is no virtual DOM. Mutate properties and arrays in place; replacing a whole object to "trigger a render" only adds work. Do not port React hooks one for one: lifecycle hooks, `@watch` and DI cover what `useEffect`, `useContext` and state libraries do.
- **Aurelia 1 syntax is wrong here.** `.delegate` is removed (use `.trigger`), `<require>` is replaced by `<import from="...">`, and the router is `@aurelia/router` with its own configuration. Check the page in the docs before using an API you remember from Aurelia 1.
- **Lifecycle pairs.** Set up in one hook and release in its pair: `binding`/`unbinding`, `attaching`/`detaching`. Anything that `attached` starts (listeners, timers, `requestAnimationFrame`, subscriptions) must stop in `detaching` or `unbinding`, or it leaks each time the component is reused. Hooks may return a promise, and the framework waits for it.
- **Computed values update asynchronously by default.** `@computed` flushes after the current task, which prevents intermediate states; code that reads it right after a change, including a test, must wait (`await tasksSettled()`), or use `batch()` to apply several changes together.
- **Services.** Define a DI interface with `DI.createInterface` and get it with `resolve()` or constructor injection, as the repository does. Shared state lives in a singleton service; per-use helpers are transient.
- **Child-to-parent communication.** Dispatch a DOM `CustomEvent` and bind it with `.trigger`, or pass a callback as a bindable, as the repository does. Use DI or the event aggregator when the components are not parent and child.
- **Templates hold no logic that needs a test.** Move conditions longer than one comparison into a view-model property or a value converter.

## Verify before you hand over

Run the repository's checks (type check, lint, unit tests; see `package.json` scripts and AGENTS.md). Test components with `createFixture` from `@aurelia/testing` and clean up each fixture with `await stop(true)` (`tearDown()` is deprecated). Then open the changed screen in a browser and check the console for `AUR` errors and binding warnings. Report what ran; if you could not open a browser, say so.
