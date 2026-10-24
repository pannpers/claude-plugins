#!/usr/bin/env bash

set -euo pipefail

# fetch-comments.sh - Fetch, filter, and parse PR review comments into a task list.
#
# Usage:
#   fetch-comments.sh [--pr <number>] [--outdir <path>]
#
# Options:
#   --pr <number>   PR number. Auto-detected from current branch if omitted.
#   --outdir <path> Output directory. Created via mktemp -d if omitted.
#
# Output files (in <outdir>/):
#   list_inline.json  - Filtered inline review comments (excluding actor's own)
#   list_review.json  - Review bodies with text (excluding actor's own)
#   list_issue.json   - Filtered issue comments (excluding actor's own)
#   task.md           - Structured task list
#
# Prints to stdout:
#   OUTDIR=<path>
#   REPO=<owner/repo>
#   PR=<number>
#   INLINE=<count>
#   REVIEW=<count>
#   ISSUE=<count>
#   TOTAL=<count>

PR_NUMBER=""
OUTDIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)
      PR_NUMBER="$2"
      shift 2
      ;;
    --outdir)
      OUTDIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Resolve repo
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
if [[ -z "$REPO" ]]; then
  echo "Error: Could not resolve repository." >&2
  exit 1
fi

# Resolve PR number
if [[ -z "$PR_NUMBER" ]]; then
  PR_NUMBER=$(gh pr view --json number --jq '.number' 2>/dev/null || true)
  if [[ -z "$PR_NUMBER" ]]; then
    echo "Error: Could not auto-detect PR number. Use --pr <number>." >&2
    exit 1
  fi
fi

# Resolve actor (to filter out own comments)
ACTOR=$(gh api user --jq '.login' 2>/dev/null || true)

# Create output directory
if [[ -z "$OUTDIR" ]]; then
  OUTDIR=$(mktemp -d)
fi
mkdir -p "$OUTDIR"

# Fetch inline comments (review threads) with pagination flattening
gh api "repos/${REPO}/pulls/${PR_NUMBER}/comments" --paginate \
  | jq -s 'add // []' \
  > "$OUTDIR/raw_inline.json"

# Fetch reviews; only those with a body carry feedback outside line comments
gh api "repos/${REPO}/pulls/${PR_NUMBER}/reviews" --paginate \
  | jq -s 'add // [] | [.[] | select((.body // "") != "")]' \
  > "$OUTDIR/raw_review.json"

# Fetch issue comments (general conversation) with pagination flattening
gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" --paginate \
  | jq -s 'add // []' \
  > "$OUTDIR/raw_issue.json"

# Filter out actor's own comments
if [[ -n "$ACTOR" ]]; then
  jq --arg actor "$ACTOR" '[.[] | select(.user.login != $actor)]' \
    "$OUTDIR/raw_inline.json" > "$OUTDIR/list_inline.json"
  jq --arg actor "$ACTOR" '[.[] | select(.user.login != $actor)]' \
    "$OUTDIR/raw_review.json" > "$OUTDIR/list_review.json"
  jq --arg actor "$ACTOR" '[.[] | select(.user.login != $actor)]' \
    "$OUTDIR/raw_issue.json" > "$OUTDIR/list_issue.json"
else
  cp "$OUTDIR/raw_inline.json" "$OUTDIR/list_inline.json"
  cp "$OUTDIR/raw_review.json" "$OUTDIR/list_review.json"
  cp "$OUTDIR/raw_issue.json" "$OUTDIR/list_issue.json"
fi

# Count
INLINE_COUNT=$(jq 'length' "$OUTDIR/list_inline.json")
REVIEW_COUNT=$(jq 'length' "$OUTDIR/list_review.json")
ISSUE_COUNT=$(jq 'length' "$OUTDIR/list_issue.json")
TOTAL=$((INLINE_COUNT + REVIEW_COUNT + ISSUE_COUNT))

# Generate task.md
{
  echo "# Review Comments Task List"
  echo ""
  echo "Repo: ${REPO} | PR: #${PR_NUMBER} | Total: ${TOTAL} (inline: ${INLINE_COUNT}, review: ${REVIEW_COUNT}, issue: ${ISSUE_COUNT})"
  echo ""

  if [[ "$INLINE_COUNT" -gt 0 ]]; then
    echo "## Inline Comments"
    echo ""
    jq -r '.[] | "- [ ] **ID: \(.id)** | \(.path):\(.line // "N/A") | ReplyTo: \(.in_reply_to_id // "None") | [\(.user.login)](\(.html_url))\n  > \(.body | split("\n") | first | if length > 120 then .[:120] + "..." else . end)"' \
      "$OUTDIR/list_inline.json"
    echo ""
  fi

  if [[ "$REVIEW_COUNT" -gt 0 ]]; then
    echo "## Review Bodies"
    echo ""
    jq -r '.[] | "- [ ] **ID: \(.id)** | Review (\(.state)) | [\(.user.login)](\(.html_url))\n  > \(.body | split("\n") | first | if length > 120 then .[:120] + "..." else . end)"' \
      "$OUTDIR/list_review.json"
    echo ""
  fi

  if [[ "$ISSUE_COUNT" -gt 0 ]]; then
    echo "## Issue Comments"
    echo ""
    jq -r '.[] | "- [ ] **ID: \(.id)** | General | [\(.user.login)](\(.html_url))\n  > \(.body | split("\n") | first | if length > 120 then .[:120] + "..." else . end)"' \
      "$OUTDIR/list_issue.json"
    echo ""
  fi
} > "$OUTDIR/task.md"

# Output summary to stdout (machine-parseable)
echo "OUTDIR=$OUTDIR"
echo "REPO=$REPO"
echo "PR=$PR_NUMBER"
echo "INLINE=$INLINE_COUNT"
echo "REVIEW=$REVIEW_COUNT"
echo "ISSUE=$ISSUE_COUNT"
echo "TOTAL=$TOTAL"
