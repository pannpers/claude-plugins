---
name: web-html-a11y
description: Writing semantic, accessible HTML and interactive widgets. Use it whenever you write or edit HTML markup or a component template and choose elements or landmarks, add ARIA roles, states or labels, build an interactive widget (dialog, menu, tabs, combobox, disclosure, tooltip, carousel, listbox), handle keyboard navigation or focus, write a form with labels and error messages, add images (alt text, srcset, sizes, picture, lazy loading) or video, or review markup for accessibility (WCAG, screen readers, contrast).
---

# Semantic HTML and accessibility

The HTML standard, WCAG and the WAI-ARIA Authoring Practices Guide (APG) define the details. This skill is about choosing the element, and proving that the result works with a keyboard and a screen reader.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md) and the existing components for dialogs, forms and buttons, and reuse them instead of building a second version.

## Read the source

```bash
# APG pattern for a widget: roles, states and the expected keyboard behaviour
gh api repos/w3c/aria-practices/contents/content/patterns --jq '.[].name'        # list
curl -sL https://raw.githubusercontent.com/w3c/aria-practices/main/content/patterns/<name>/<name>-pattern.html | python3 -c "import sys,re,html;print(html.unescape(re.sub(r'\s+',' ',re.sub(r'<[^>]+>',' ',sys.stdin.read()))))"
# MDN for an element or attribute (the JSON names the source file)
curl -sL https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/<element>/index.json | python3 -c "import json,sys;print(json.load(sys.stdin)['doc']['source']['folder'])"
```

Check browser support for newer elements and attributes (`<dialog>` with `closedby`, `popover`, `<details name>`, customizable `<select>`) with the Baseline check in the `web-css` skill.

## Decisions

- **Native element first.** A `<button>`, `<a href>`, `<dialog>`, `<details>`, `<select>` or `<input>` brings keyboard handling, focus and the accessible role for free. A `div` with a click handler has none of these; ARIA adds the role but none of the behaviour.
- **No ARIA is better than wrong ARIA.** Add a role or state only when no element provides it, and then implement every keyboard interaction the APG pattern lists.
- **Every control has an accessible name** from visible text, a `<label>`, or `aria-label` when there is no visible text. Placeholder text is not a label.
- **Structure**: one `<main>`, landmarks (`header`, `nav`, `footer`) for the page regions, and headings in order, so that screen-reader users can jump through the page.
- **Focus**: every interactive element is reachable with Tab and shows a visible focus indicator. A dialog moves focus in when it opens and returns it to the opener when it closes; the modal `<dialog>` with `showModal()` does both.
- **Forms**: associate each error message with its field (`aria-describedby`), mark invalid fields (`aria-invalid`), and do not rely on colour alone.
- **Images**: `alt` describes what the image says in context, `alt=""` for decoration. Give `width` and `height` (or `aspect-ratio`) to prevent layout shift, `srcset` with `sizes` for responsive images, and `loading="lazy"` only below the fold; the largest image above the fold gets `fetchpriority="high"` instead.
- **Contrast**: text meets WCAG 2.2 AA (4.5:1, 3:1 for large text and for focus indicators and control boundaries).

## Verify before you hand over

1. Run the repository's accessibility checks (an axe integration in Storybook, Playwright or the unit tests). Without one, run axe against the page (`@axe-core/playwright`, or `npx @axe-core/cli <url>`). Automated checks find only part of the problems.
2. Use the keyboard only: Tab through the changed screen, operate each control with Enter, Space, the arrow keys and Escape as its APG pattern says, and check that focus is visible and never lost.
3. Check the accessible names and roles, for example with Playwright's `locator.ariaSnapshot()` or the browser's accessibility tree.

Report what ran and what you checked by hand; if no browser was available, say so.
