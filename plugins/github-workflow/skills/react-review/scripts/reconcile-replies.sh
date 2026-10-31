#!/usr/bin/env bash

set -euo pipefail

# reconcile-replies.sh - Verify all fetched comments have been answered.
#
# Usage:
#   reconcile-replies.sh --pr <number> --outdir <path>
#
# Reads the files fetch-comments.sh wrote to <outdir>/ and checks the PR's
# current state:
#   - each inline thread whose latest comment is not from the actor needs a reply;
#   - each review body and conversation comment needs a later comment from the
#     actor that contains its URL, unless its ID is listed in
#     <outdir>/no-reply.txt (one ID per line) as informational.
#
# Prints the unanswered comments and UNREPLIED=<count> to stdout.
#
# Exit code:
#   0 - All comments answered
#   1 - Unanswered comments found or error

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

if [[ -z "$PR_NUMBER" || -z "$OUTDIR" ]]; then
  echo "Error: --pr and --outdir are required." >&2
  echo "Usage: reconcile-replies.sh --pr <number> --outdir <path>" >&2
  exit 1
fi

if [[ ! -f "$OUTDIR/list_inline.json" ]]; then
  echo "Error: $OUTDIR/list_inline.json not found. Run fetch-comments.sh first." >&2
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
ACTOR=$(gh api user --jq '.login' 2>/dev/null || true)
if [[ -z "$ACTOR" ]]; then
  echo "Error: Could not determine the authenticated user (gh api user)." >&2
  exit 1
fi

NO_REPLY="[]"
if [[ -f "$OUTDIR/no-reply.txt" ]]; then
  NO_REPLY=$({ grep -Eo '[0-9]+' "$OUTDIR/no-reply.txt" || true; } | jq -R 'tonumber' | jq -s '.')
fi

# Current state, including replies posted since the fetch
gh api "repos/${REPO}/pulls/${PR_NUMBER}/comments" --paginate \
  | jq -s 'add // []' > "$OUTDIR/current_inline.json"
gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" --paginate \
  | jq -s 'add // []' > "$OUTDIR/current_issue.json"

# Inline threads whose latest comment is not from the actor. This covers a new
# finding (no reply yet) and a reviewer's follow-up inside an existing thread.
UNREPLIED_INLINE=$(jq -r --arg actor "$ACTOR" --argjson skip "$NO_REPLY" '
  group_by(.in_reply_to_id // .id)[]
  | sort_by(.created_at) | last
  | select(.user.login != $actor)
  | select((.id as $id | $skip | index($id)) == null)
  | select(((.in_reply_to_id // .id) as $root | $skip | index($root)) == null)
  | "- ID: \(.id) | \(.path):\(.line // "N/A") | \(.html_url)"' \
  "$OUTDIR/current_inline.json")

# Review bodies and conversation comments: answered when a later actor comment
# (in the conversation or in any inline thread) contains the comment's URL
ACTOR_TEXT=$(jq -s -r --arg actor "$ACTOR" '
  add | [.[] | select(.user.login == $actor) | .body] | join("\n")' \
  "$OUTDIR/current_issue.json" "$OUTDIR/current_inline.json")

unanswered_linked() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  jq -r --argjson skip "$NO_REPLY" --arg text "$ACTOR_TEXT" '
    .[]
    | select((.id as $id | $skip | index($id)) == null)
    | .html_url as $u
    | select(($text | contains($u)) | not)
    | "- ID: \(.id) | \(.user.login) | \(.html_url)"' "$file"
}

UNREPLIED_REVIEW=$(unanswered_linked "$OUTDIR/list_review.json")
UNREPLIED_ISSUE=$(unanswered_linked "$OUTDIR/list_issue.json")

UNREPLIED_COUNT=0
report() {
  local title="$1" lines="$2"
  if [[ -n "$lines" ]]; then
    echo "## $title"
    echo ""
    echo "$lines"
    echo ""
    UNREPLIED_COUNT=$((UNREPLIED_COUNT + $(echo "$lines" | wc -l)))
  fi
}

report "Unreplied Inline Comments" "$UNREPLIED_INLINE"
report "Unanswered Review Bodies" "$UNREPLIED_REVIEW"
report "Unanswered Conversation Comments" "$UNREPLIED_ISSUE"

echo "UNREPLIED=$UNREPLIED_COUNT"

if [[ "$UNREPLIED_COUNT" -gt 0 ]]; then
  exit 1
fi

exit 0
