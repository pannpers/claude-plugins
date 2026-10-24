---
name: git-commit-formatter
description: Use this skill for any request whose outcome is a new or rewritten git commit: committing working-tree or staged changes (in any language: "commit", "コミットして", "コミットまでやって"), deciding whether changes belong in one commit or several and splitting them, amending or rewording an existing commit message so it follows the team's format, and marking breaking changes. It covers grouping changes into logical commits and writing Conventional Commits messages (`type(scope): description`, why-focused body, `Refs: #123`, `BREAKING CHANGE:` / `!`). Load it before every `git commit` or `git commit --amend`, including the commits made inside a larger task such as opening a PR or addressing review comments. Do not use it for read-only git history questions (log summaries, blame), branch/stash work, releases or tags, or for installing and configuring commit-lint tooling, hooks or CI checks.
---

# Commits

Each commit should be one logical change with a message that lets someone reading `git log` six months from now understand what changed and why, without opening the diff.

## Check the repository's rules first

Read `AGENTS.md`, `CLAUDE.md` or `CONTRIBUTING.md`, and look at a few recent commits (`git log --oneline -15`). Where the repository sets its own types, scopes, a required body or footer, or a commit hook, follow it; the rules below are the fallback.

## Split the changes

Read the whole diff first: `git diff` and `git diff --cached`. Then group the changes:

- **One logical change per commit.** A feature that touches several files or layers (for example a new field in the model, its storage and its API) is one change and belongs in one commit. Splitting it by layer leaves commits that do not work on their own.
- **Keep unrelated changes apart.** A bug fix, an unrelated refactor and a typo fix found along the way are three commits, so that each can be reviewed, reverted or cherry-picked alone.
- **Every commit should build and pass the tests**, so that `git bisect` and reverts keep working.

Stage each group explicitly (`git add <paths>`, or `git add -p` for files that hold more than one change), and check `git diff --cached` before each commit.

## Write the message

```
<type>(<optional scope>): <description>

<optional body>

<optional footers>
```

- **type**: `feat` (new behaviour for users), `fix` (bug fix), `docs`, `refactor` (no behaviour change), `perf`, `test`, `build`, `ci`, `chore`, `style`, `revert`.
- **scope**: the area touched, in the repository's own terms (`parser`, `auth`, `api`). Leave it out rather than invent one.
- **description**: imperative mood ("add", not "added" or "adds"), lowercase start, no final period, about 50 characters at most, so that it fits in one-line logs and PR titles.
- **body**: why the change was needed and what it does differently, wrapped at about 72 characters. The diff already shows how. Skip the body when the description says it all.
- **footers**:
  - `Refs: #123` to link an issue.
  - Use a closing keyword such as `Closes #123` only in the PR description, not in commits: a commit's closing keyword closes the issue as soon as that commit reaches the default branch, even when it holds only part of the work.
  - `BREAKING CHANGE: <what breaks and how to migrate>` for incompatible changes, and also `!` after the type or scope (`feat(api)!: remove v1 endpoints`).

Pass the message with `git commit -F <file>` or several `-m` flags, not with an inline heredoc, so that backticks and `$` survive.

## Example

The working tree holds a fix to date parsing, a new `email` field threaded from the model through storage to the API, and a README typo. That is three commits:

```
fix(parser): accept dates with a trailing timezone offset
feat(user): add email to the user model, store and API
docs: fix a typo in the setup steps
```
