#!/usr/bin/env bash
# Open files in Plannotator's gated annotation UI and wait for the reviewer's decision.
#
# Usage: review.sh <result-file> <title> <file>...
#
# Prints the decision JSON on stdout:
#   {"decision":"approved"}
#   {"decision":"annotated","feedback":"..."}   feedback names the selected text, the comment and the file
#   {"decision":"dismissed"}                    the reviewer closed the tab; this is not an approval
#
# Exit status: 0 a decision was published, 2 bad usage or Plannotator missing,
#              3 Plannotator exited without a decision, 4 no session URL appeared.
# Set REVIEW_NO_OPEN=1 to skip opening the browser (the URL is still printed on stderr).
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "usage: review.sh <result-file> <title> <file>..." >&2
  exit 2
fi
if ! command -v plannotator >/dev/null 2>&1; then
  echo "plannotator is not on PATH" >&2
  exit 2
fi

result=$1
title=$2
shift 2

rm -f -- "$result"
log=$(mktemp)
pid=
cleanup() {
  if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || true; fi
  rm -f -- "$log"
}
trap cleanup EXIT

plannotator annotate "$@" --gate --json --title "$title" --result-file "$result" >"$log" 2>&1 &
pid=$!

url=
for _ in $(seq 1 40); do
  url=$(grep -o 'http://localhost:[0-9]*' "$log" | head -n 1 || true)
  [ -n "$url" ] && break
  kill -0 "$pid" 2>/dev/null || break
  sleep 0.5
done
if [ -z "$url" ]; then
  cat "$log" >&2
  echo "no review session URL appeared" >&2
  exit 4
fi
echo "Review session: $url" >&2

# Plannotator cannot open a browser from WSL or a remote shell, so open it here.
open_url() {
  [ "${REVIEW_NO_OPEN:-}" = "1" ] && return 0
  if grep -qi microsoft /proc/version 2>/dev/null; then
    local ps
    ps=$(command -v powershell.exe || echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe)
    "$ps" -NoProfile -Command "Start-Process -FilePath '$1'" >/dev/null 2>&1 || echo "could not open the browser; open $1" >&2
  elif command -v open >/dev/null 2>&1; then
    open "$1" || echo "could not open the browser; open $1" >&2
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$1" >/dev/null 2>&1 || echo "could not open the browser; open $1" >&2
  else
    echo "no browser opener found; open $1" >&2
  fi
}
open_url "$url"

# A person decides when to answer, so wait without a time limit.
wait "$pid" || true
pid=

if [ ! -s "$result" ]; then
  echo "Plannotator exited without a decision" >&2
  exit 3
fi
cat -- "$result"
