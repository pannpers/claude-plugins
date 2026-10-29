---
name: web-pwa
description: Building Progressive Web App features. Use it whenever you create or edit a web app manifest, register or change a service worker, choose a caching strategy (Workbox or hand-written), add offline support, handle a service worker update, make an app installable, or add push notifications, background sync, badging, share target or file handling.
---

# Progressive Web Apps

MDN and web.dev document the APIs. This skill is about the decisions that keep a service worker from serving stale or broken pages, and about checking the result in a real browser.

The repository's own rules come first. Read AGENTS.md (or CLAUDE.md), the manifest, the service worker source and the build plugin that generates it (for example `vite-plugin-pwa` or Workbox), and follow them.

## Read the source

```bash
gh api repos/mdn/content/contents/files/en-us/web/progressive_web_apps/guides --jq '.[].name'
curl -sL https://raw.githubusercontent.com/mdn/content/main/files/en-us/web/progressive_web_apps/guides/<guide>/index.md
```

For Workbox, read the version in `package.json` and its docs at `https://developer.chrome.com/docs/workbox/`. Check browser support for each capability (push on iOS, background sync, file handling) with the Baseline check in the `web-css` skill; many are limited to some browsers.

## Decisions

- **Caching strategy per kind of request.** Precache the app shell built with hashed file names (cache first is safe because the name changes with the content). HTML and API responses that must be current use network first, or stale-while-revalidate when a slightly old answer is acceptable. Never cache authenticated or per-user API responses in a cache shared across users of the device without a reason.
- **Updates.** A new service worker waits until every tab of the old one is closed. Decide how the app takes the update: prompt the user to reload, or `skipWaiting` with `clients.claim` only when old pages can work with new assets. Changing either silently can mix old HTML with new JavaScript.
- **Offline** needs a fallback page or state for navigation requests that are not cached, not a browser error.
- **Installability**: the manifest needs `name`, `icons` (192 and 512 px, plus a maskable icon), `start_url` and `display`. Lighthouse no longer has a PWA category (removed in Lighthouse 12); check installability in the browser's DevTools Application panel.
- **Push**: ask for notification permission after a user action that explains why, never on page load. Handle an expired subscription on the server.

## Verify before you hand over

Build the production bundle (service workers often do not run in the dev server) and serve it. In a browser, or with Playwright:

1. Confirm the service worker is active (`navigator.serviceWorker.ready`) and that the manifest loads without errors in DevTools.
2. Go offline (`context.setOffline(true)` in Playwright) and reload the pages that must work offline.
3. Deploy a changed build over the old one and check that the update path you chose happens.

Run the repository's PWA tests if it has them. Report what ran; if no browser was available, say so.
