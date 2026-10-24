---
name: react-review
description: Respond to review feedback on a GitHub pull request. Fetch every inline comment, review body and conversation comment (bots such as CodeRabbit and Copilot included), judge each one on its merits instead of accepting it, present a plan for approval, implement the approved fixes, reply in the original threads and check that nothing was left unanswered. Use this when the user asks to address, handle, reply to or resolve review comments ("レビュー対応して", "reply to the CodeRabbit comments"), and whenever a PR you are driving has unanswered review feedback.
---

# Respond to PR review feedback

A review comment is a claim about the code, not an order. Some are right, some are right with a better fix, and some are wrong. Your job is to find out which, fix what deserves fixing, and leave every reviewer a reply that says what you did and why.

Before your first commit, read `${CLAUDE_PLUGIN_ROOT}/skills/git-commit-formatter/SKILL.md` and commit following it.

## 1. Fetch the feedback

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/fetch-comments.sh" [--pr <number>] [--outdir <dir>]
```

The script finds the PR from the current branch when `--pr` is omitted, and collects three kinds of feedback, leaving out your own:

- inline comments on lines (`list_inline.json`);
- review bodies with text in them (`list_review.json`), which is where many bots put findings that are not tied to a line;
- conversation comments (`list_issue.json`).

It prints `OUTDIR=`, `REPO=`, `PR=` and the counts, and writes `$OUTDIR/task.md`, a checklist with each comment's ID. Read `task.md` and state the counts ("3 inline, 1 review body, 2 conversation: 6 in total"), so that the user can see that nothing was dropped.

Use the scripts rather than ad hoc `gh api` pipelines: they paginate, which a single `gh api` call does not, and reconciliation in step 5 depends on the files they write.

## 2. Judge each comment and plan

For each comment, read the code it points at and answer:

1. Is the claim correct?
2. Is the current code actually worse, or is it intentional and right?
3. Is the suggested fix the best one, or is there a simpler or safer alternative?
4. What else could the change break: tests, public API, other open work?
5. Is it in scope for this PR, or better as a follow-up?

Then classify it with the table in `references/reply-templates.md`. Informational comments that ask for nothing (a bot's walkthrough summary, a coverage report) need no reply; list their IDs, one per line, in `$OUTDIR/no-reply.txt`.

Write the plan following `references/plan-template.md`, put the whole plan in your message to the user (not just a path: `$OUTDIR` is a temporary directory they would have to dig out), and stop until they approve it. Also save it to `$OUTDIR/react-review-plan.md` so that you can work from it after approval. The user knows the intent behind the code and the priorities better than the reviewer or you do, so a fix that goes in without their approval may need reverting.

## 3. Implement the approved plan

Work in this order: bugs, security issues and breaking changes first; then correctness, performance and reliability; then readability; then minor polish. Run the repository's lint and tests, and commit each related group of fixes on its own, so that each reply can point at the commit that answers it. Push when done.

## 4. Reply where the comment was made

Each reply says what was pointed out, what you did and why, using the templates in `references/reply-templates.md`. Check each comment ID against `task.md` before you reply, so that no reply lands on the wrong comment.

- **Inline comment**: reply in its thread.

  ```bash
  gh api repos/<owner>/<repo>/pulls/<pr>/comments/<comment_id>/replies -f body="..."
  ```

  Never answer an inline comment with a new top-level PR comment (`issues/<pr>/comments`, or an MCP tool such as `add_issue_comment`): the answer then sits apart from the thread, and the reviewer cannot see that the thread was handled.
- **Review body or conversation comment**: these have no thread to reply in, so post one conversation comment that answers them and includes each one's URL (`html_url` in the JSON files). Reconciliation looks for those URLs.

  ```bash
  gh pr comment <pr> --body-file <file>
  ```

## 5. Confirm nothing was missed

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/reconcile-replies.sh" --pr <number> --outdir "$OUTDIR"
```

It exits 0 when every inline comment has a reply from you in its thread, and every review body and conversation comment is either linked from one of your later comments or listed in `no-reply.txt`. Otherwise it lists what is still open. Answer those, run it again, and report completion only when it exits 0. Then make sure the PR's CI is still green after your pushes.
