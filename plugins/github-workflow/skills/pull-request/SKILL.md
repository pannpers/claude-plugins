---
name: pull-request
description: Use this skill whenever the user wants code changes to land through a GitHub pull request, in English or Japanese: shipping a finished branch or refactor, pushing and opening a PR (against any base, linked to an issue), "レビューに出して", "PR 出して", or taking an existing PR #N to merge ("マージまで持っていって"). Use it even when the request also covers babysitting CI, fixing failing checks, rebasing, resolving conflicts, clearing human or bot review findings, or squash-merging after checks pass. Use it as well when you finish an implementation that is meant to ship as a PR. Prefer it to running git and gh by hand, because it applies the repository's PR conventions and the merge gate. Do not use it for a single step on its own: only committing, only replying to review comments (use react-review), git or GitHub questions, writing CI workflow YAML, or checking branch status.
---

# Pull request

The workflow is: commit, rebase, push, review the branch, create the PR, then a readiness loop (CI, conflicts, review findings) until the PR is merge-ready.

Two steps below hand over to other skills in this plugin. At those steps, read the named file before you continue: a skill that is only mentioned by name tends to be skipped, and then its rules are not applied.

- `${CLAUDE_PLUGIN_ROOT}/skills/git-commit-formatter/SKILL.md`: how to split commits and write their messages.
- `${CLAUDE_PLUGIN_ROOT}/skills/react-review/SKILL.md`: how to judge review comments, reply in their threads and confirm that each one was answered.

## 0. Read the repository's conventions first

Look for `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md` and a PR template (`.github/pull_request_template.md` in any case, or `.github/PULL_REQUEST_TEMPLATE/`). Where they set assignees, reviewers, labels, milestones or project fields, the merge method, or whether you may merge, they win over the defaults below. A repository's rules come from the people who maintain it; the defaults here are only a fallback.

## 1. Check the branch

Run `git branch --show-current`. If you are on the default branch, create a feature branch before committing. Committing straight to the default branch skips review, and a PR needs a branch to compare against.

Find the base branch: the default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`), unless this branch was cut from another feature branch.

## 2. Commit pending changes

If `git status` shows changes:

1. Read the full diff (`git diff` and `git diff --cached`), so that you commit only what belongs to this change.
2. Run the checks the repository defines (its lint, type check and test commands, usually named in AGENTS.md, a Makefile or package.json). Fix failures before committing; a red commit makes CI fail and blocks the PR later anyway.
3. Read `${CLAUDE_PLUGIN_ROOT}/skills/git-commit-formatter/SKILL.md` now, if you have not read it in this session, and commit following it.

## 3. Rebase on the base branch

If the base is the default branch, rebase so that the PR shows only your commits and CI tests what will be merged:

```bash
git fetch origin <base>
git rebase origin/<base>
```

Resolve conflicts file by file, then `git rebase --continue`. If a conflict needs a decision you cannot make from the code (two incompatible intents), run `git rebase --abort` and ask the user.

Skip the rebase when the base is another unmerged feature branch; rebasing onto a moving branch rewrites history that branch's PR still depends on.

## 4. Push

- First push: `git push -u origin HEAD`
- After a rebase: `git push --force-with-lease` (it refuses to overwrite commits someone else pushed in the meantime, which a plain `--force` would destroy)
- Otherwise: `git push`

## 5. Review the branch before opening the PR

Review the whole branch diff once, before anyone else sees it. Doing it here rather than on every commit covers the same changes for a fraction of the cost, and it still happens before reviewers or CI spend time on the PR.

- In Claude Code, invoke the `code-review` skill on the branch (for example `/code-review <branch>`).
- Without it, read the full `git diff <base>...HEAD` yourself (the patch, not only `--stat`) and check it against the repository's conventions (AGENTS.md, CLAUDE.md) for bugs, missing tests, docs that no longer match the code, and leftover debug code.

Fix what the review finds, commit, push, and mention any finding you chose not to fix in the PR body.

## 6. Create the pull request

Write the body for a reviewer who reads it once, before the diff:

- Describe the final state relative to the base branch: what changes for users or callers, and why. Leave out the order in which you worked; reviewers review the result, not the process.
- Fill every section of the PR template if there is one.
- In the testing section, list only the commands you actually ran and their results. If something could not run (a missing tool, no database), say so and say what you did instead. A reviewer relies on this section to decide what still needs checking, so a claim that tests passed when they did not run misleads them.
- Link the issue with a closing keyword, for example `Closes #123`. GitHub closes the issue when the PR is merged, but only for PRs that target the default branch; for any other base, write `Refs #123` instead.

Write the body to a fresh temporary file and pass it with `--body-file`. A shell heredoc mangles backticks and `$`, and a fixed path such as `/tmp/pr-body.md` collides with other sessions.

```bash
body=$(mktemp)
# write the body into "$body" with your file-writing tool
gh pr create --base <base> --title "<conventional-commit-style title>" --body-file "$body" --assignee @me
```

Do not request a review from yourself: GitHub rejects a review request to the PR's author. Add reviewers, labels, milestones or project fields only when the repository's conventions ask for them, and read them back after creation.

Then show the PR as a Markdown link: `**PR created:** [owner/repo#123 — title](url)`.

## 7. Readiness loop

Keep looping until the merge gate below holds, unless the user asked you to stop after creating the PR.

### Watch CI

```bash
gh pr checks <number> --watch --fail-fast
```

Run it in the background and wait for it to finish. It covers every check on the PR. Watching only the latest workflow run misses the other workflows that run in parallel.

If a check fails, read its log (`gh run view <run-id> --log-failed`), find the cause, fix it, push, and watch again. Ask the user first when the fix changes behaviour beyond what the PR set out to do, for example skipping a test or loosening a lint rule.

A green CI does not make the PR merge-ready, so always continue with the next two checks.

### Check for conflicts

`gh pr view <number> --json mergeable,mergeStateStatus`

- `CONFLICTING`: rebase on the base branch, resolve, push, watch CI again.
- `UNKNOWN`: GitHub is still computing; wait a few seconds and ask again.

### Collect review feedback

Review feedback arrives in three places, and bots use all of them:

- inline comments on lines (`pulls/<n>/comments`);
- the body of a review (`pulls/<n>/reviews`), where tools such as CodeRabbit and Copilot often put findings that are not tied to a line;
- conversation comments on the PR (`issues/<n>/comments`).

Run the fetch script of `react-review`, which collects all three and leaves out your own comments:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/react-review/scripts/fetch-comments.sh" --pr <number>
```

If anything is unanswered, read `${CLAUDE_PLUGIN_ROOT}/skills/react-review/SKILL.md` and follow it. It presents a plan and waits for the user's approval before it changes code. After its fixes are pushed, go back to watching CI.

### Merge gate

The PR is merge-ready when all of these hold:

1. Every check passes.
2. `mergeable` is not `CONFLICTING`.
3. Every review finding, from people and from bots, has been fixed or answered in its thread through `react-review`, and its reconcile script exits 0.

Merge only when the user asked you to merge in this conversation, or the repository's instructions say that agents merge green PRs. Otherwise stop here, and report that the PR is merge-ready, with its link. Merging is visible to everyone and hard to undo, so it needs a clear go-ahead.

To merge, use a method the repository allows:

```bash
gh api repos/<owner>/<repo> -q '{squash: .allow_squash_merge, merge: .allow_merge_commit, rebase: .allow_rebase_merge}'
gh pr merge <number> --<method>
```

Then confirm with `gh pr view <number> --json state,mergedAt`, and report the result only after the state reads `MERGED`.

### After the merge

If review findings were addressed along the way, give the user a short summary: for each finding, who raised it, what it said, what you decided and what changed. Skip the summary when the PR merged without review comments.
