---
name: gh-issue-creator
description: Create a well-scoped GitHub issue with gh, from the repository's issue template when there is one, assigned to yourself, after checking for duplicates; then, when work starts now, a feature branch linked to it. Use it when the user asks to create, file or open an issue or ticket ("issue 作って", "file a bug for this", "start a ticket and a branch"), to kick off a new feature or fix as a tracked task, or right after a spec or plan is finalized and implementation is about to begin. Do not use it for everyday work on a branch that already exists.
---

# Create a GitHub issue

An issue records why the work exists and when it is done; a branch linked to it lets GitHub show the issue, the branch and the PR together.

## 0. Read the repository's conventions

Check `AGENTS.md`, `CLAUDE.md` or `CONTRIBUTING.md` for issue labels, project boards, milestones, assignees and the branch naming scheme. They win over the defaults below.

## 1. Check for an existing issue

Search open and closed issues for the same problem before writing a new one:

```bash
gh issue list --state all --search "<key words>" --limit 10
```

If one already covers it, tell the user and link it instead of creating a duplicate. If related issues or PRs exist, reference them in the new issue, so that the history stays connected.

## 2. Write the issue

1. Look for templates in `.github/ISSUE_TEMPLATE/`. Pick the one that matches the task (bug, feature, ...), and fill every section it asks for, without adding sections of your own. A template marks what the maintainers need in order to act; an empty section usually brings the issue back with questions.
2. Write the title as the outcome, not the activity ("CSV export for the orders table", not "Work on CSV").
3. Keep the body short and non-overlapping: the problem and why it matters, the proposed change, and acceptance criteria that someone else could check. Say each thing once.
4. Write the body to a temporary file and create the issue:

   ```bash
   body=$(mktemp)
   # write the filled template into "$body"
   gh issue create --title "<title>" --body-file "$body" --assignee @me [--label <label>]
   ```

   `@me` assigns the authenticated user, so this works for anyone who runs it. Use only labels that already exist (`gh label list`); inventing labels clutters the repository.
5. Show the result as a Markdown link: `**Issue created:** [owner/repo#123 — title](url)`.

## 3. Create the branch (when work starts now)

Skip this step when the user only wants the issue recorded.

Name the branch `<issue-number>-<short-kebab-description>`, for example `123-csv-export`, unless the repository uses another scheme. Branch from the latest default branch, or from another feature branch when the task explicitly builds on it.

```bash
gh issue develop <number> --name <number>-<short-description> --base <base-branch> --checkout
```

`gh issue develop` creates the branch on GitHub, links it to the issue (it then appears under the issue's Development section) and checks it out. If it fails, for example because the remote is not on GitHub, fall back to `git fetch origin && git switch -c <name> origin/<base-branch>`.

Report the issue link and the branch name.
