---
name: web-css
description: Using modern CSS features and layout correctly, checked against Baseline browser support. Use it whenever you write or edit CSS and choose between Flexbox, Grid and subgrid, use container queries or media queries, logical properties, clamp() fluid sizing, custom properties or @property, colour functions (oklch, color-mix, relative colours), cascade layers, nesting, @scope, :has(), popover, anchor positioning, view transitions, scroll-driven animations or @starting-style, define design tokens, or replace JavaScript that does what CSS can now do.
---

# Modern CSS

MDN documents each feature, and web-features (behind webstatus.dev and the Baseline labels on MDN) records where it works. This skill is about choosing a feature and confirming that it works for the browsers the project supports.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md), the stylelint config, the token file and the browser targets (`browserslist` in `package.json` or `.browserslistrc`, or the build tool's `target`), and follow them.

## Check Baseline before you use a feature

Do not rely on memory for browser support; it changes every month.

```bash
# Feature status: limited, newly (all core browsers, < 30 months) or widely
curl -s "https://api.webstatus.dev/v1/features?q=id:anchor-positioning" | python3 -c "import json,sys;[print(f['feature_id'],f['baseline']) for f in json.load(sys.stdin)['data']]"
# Search by name when you do not know the id
curl -s "https://api.webstatus.dev/v1/features?q=name:popover"
```

A feature can be `limited` as a whole while the parts you use are Baseline. Check the specific properties and values in web-features:

```bash
curl -s https://cdn.jsdelivr.net/npm/web-features/data.json | python3 -c "
import json,sys;f=json.load(sys.stdin)['features']['anchor-positioning']['status']['by_compat_key']
[print(k,v.get('baseline'),v.get('baseline_low_date')) for k,v in f.items()]"
```

Then decide: Baseline for the project's targets, use it; not Baseline, use it only as an enhancement that fails safely (`@supports`, or a layout that is acceptable without it), or use the older technique. Say which you chose.

## Read the reference page

```bash
# MDN: the page's JSON names its source file and its compat keys
curl -sL https://developer.mozilla.org/en-US/docs/Web/CSS/<name>/index.json | python3 -c "import json,sys;d=json.load(sys.stdin)['doc'];print(d['source']['folder'],d.get('browserCompat'))"
curl -sL https://raw.githubusercontent.com/mdn/content/main/files/<folder>/index.md
```

## Decisions

- **Layout engine**: Flexbox for one direction where the content sets the size (toolbars, wrapping tags); Grid for two dimensions or when the container sets the tracks; subgrid when children of different items must line up with each other.
- **Container queries or media queries**: a component that appears in containers of different widths responds to its container (`@container`); page-level changes and user preferences (`prefers-reduced-motion`, `prefers-color-scheme`) use `@media`.
- **Sizing**: let content and intrinsic sizing (`min()`, `max()`, `clamp()`, `auto-fit` with `minmax()`) do the work before adding breakpoints.
- **Logical properties** (`margin-inline`, `padding-block`, `inset-inline-start`) when the layout must follow writing direction.
- **Custom properties** carry design tokens and per-instance values; register them with `@property` when they must animate or need a type.
- **CSS before JavaScript**: positioning popups, state-dependent styling, scroll-linked effects and page transitions often no longer need script. Check Baseline first, and keep keyboard and screen-reader behaviour (see the `web-html-a11y` skill) when replacing a scripted widget.
- **Motion** respects `prefers-reduced-motion`.

## Verify before you hand over

Run the repository's CSS lint. Open the result in a browser at a narrow and a wide viewport, and in each browser engine the project supports when the feature is newly Baseline or an enhancement. Report the Baseline status you found and what you checked; if no browser was available, say so.
