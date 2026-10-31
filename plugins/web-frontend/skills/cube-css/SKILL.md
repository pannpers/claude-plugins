---
name: cube-css
description: Writing and organizing CSS with the CUBE CSS methodology (Composition, Utility, Block, Exception). Use it whenever you write or edit CSS in a project that uses CUBE CSS (signs - grouped class attributes such as class="[ card ] [ flow ]", layers or folders named composition, utility, block and exception, or data-state attributes styled in CSS), decide which layer a rule belongs to, add a composition primitive (stack or flow, cluster, sidebar, switcher, grid, cover, center), add a utility class, or review a block that has grown too large.
---

# CUBE CSS

CUBE CSS is a methodology, not a library: cube.fyi defines it, and each project decides the details (file layout, naming, how layers are declared). This skill is about deciding where a rule belongs.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md), the stylesheet entry point (its `@layer` order and imports), the stylelint config, and two existing blocks, and follow them.

## Read the source

```bash
for p in css composition utility block exception grouping; do
  curl -sL "https://cube.fyi/$p.html" | python3 -c "import sys,re,html;t=sys.stdin.read();t=re.sub(r'<(script|style).*?</\1>','',t,flags=re.S);print(html.unescape(re.sub(r'\s+',' ',re.sub(r'<[^>]+>',' ',t))))"
done
```

The composition primitives come from Every Layout; read the one you use at `https://every-layout.dev/layouts/<name>/` (stack, box, center, cluster, sidebar, switcher, cover, grid, frame, reel, imposter, icon, container).

## Where a rule belongs

Work from the top; each layer should leave less for the next.

1. **Global**: element defaults through the cascade and inheritance (typography, colours, spacing between flow content, focus styles). If most instances of an element need a style, it is global.
2. **Composition**: how elements sit in relation to each other (flow spacing, wrapping rows, sidebar and main, grids). No colour, type or decoration. Prefer an existing primitive with a custom property (`--space`, `--gutter`) over a new layout in a block.
3. **Utility**: one job each, usually one design token (`.color-primary`, `.gap-s`). A utility that sets several unrelated properties is a block.
4. **Block**: what is specific to one component after the layers above have done their part. A long block is the sign that something belongs higher up; move it before adding more.
5. **Exception**: a state or variant of a block, expressed as a data attribute (`data-state="reversed"`) that both CSS and JavaScript can read. When an exception changes the block beyond recognition, make a new block.

In HTML, group the classes so each kind is easy to see; cube.fyi recommends `class="[ block ] [ composition ] [ utilities ]"`, but consistency within the project matters more than the delimiter.

## Verify before you hand over

Run the repository's CSS lint (`stylelint` or the `lint` script). Open the changed screen in a browser at a narrow and a wide viewport, and check that the layout holds without horizontal scrolling and that each state you added (`data-state` values) renders. Report what ran; if no browser was available, say that the result was not seen.
