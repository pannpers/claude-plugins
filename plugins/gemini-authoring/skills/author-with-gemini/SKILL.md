---
name: author-with-gemini
description: Default way to produce a written document or plan when Gemini (Antigravity CLI, `agy`) and Plannotator are installed. Claude has Gemini write or rewrite the document or plan, a person reviews it in Plannotator, and their annotations go back to Gemini until they approve. Claude runs the loop; Gemini only writes. Use it whenever the user asks Claude to create, rewrite or restructure documentation (README, design doc, runbook, report, proposal), an OpenSpec change or spec, an implementation plan or any other plan that a person will read, and when the user asks for a Gemini or agy draft or a Plannotator review. Use it even when the user names neither tool. Skip it for code, small edits such as a typo or one sentence, an unattended run (the review needs a person at the screen), and when the user says to write it yourself.
compatibility: Needs `agy` (tested with 1.4.7) and `plannotator` (tested with 0.29.3) on PATH, and a person who can answer in a browser.
---

# Author with Gemini, review in Plannotator

Gemini writes or rewrites the document or plan, a person reviews it, Claude runs the loop between them. The user prefers Gemini's prose for documents and wants a person to approve before a document counts as done.

```
Claude ─ task ─▶ agy (write) ─▶ files ─▶ checks ─▶ Plannotator (person) ─┬─ approved   → done
   ▲                                                                     ├─ annotated  → back to agy
   └───────────── annotations, same conversation ◀───────────────────────┘ └─ dismissed  → ask the person
```

Claude owns the loop because the person may take a long time to answer. A headless `agy -p` run cannot wait that long and cannot answer an approval prompt, so `agy` never calls Plannotator itself.

## 1. Decide whether to use it

Use it when the result is a document or plan for a person to read. A round trip costs minutes and a review in the browser, so skip it for a typo, a single sentence, a code comment or anything the user asked you to write yourself, and say in one line that you skipped it.

Run `command -v agy plannotator`. If either is missing, or nobody is at the screen (a scheduled or CI run), write the document yourself and say why. Do not install tools on your own.

## 2. Choose where Gemini works

`agy` reads the `AGENTS.md` (and `GEMINI.md`) of its working directory and does not read `CLAUDE.md`. Checked with a probe directory that held one file of each. So:

- Run it from the repository or worktree that will hold the document, so that repository's `AGENTS.md` applies.
- Anything that lives only in `CLAUDE.md`, or in the user's own global instructions (language, tone, naming rules), is invisible to it. Put those rules in the task.
- Let it write in an isolated place: a throwaway worktree cut from the default branch, or a scratch directory. A checkout that holds uncommitted work, such as an OpenSpec store, must stay untouched.

## 3. Write the task

Keep it short and concrete. A task Gemini can act on states:

- the goal, and who will read the result;
- for a new document, the exact paths it may write; for a rewrite, the existing path and the change wanted, and that everything the request does not touch stays as it is;
- that it writes nowhere else and runs no git commands;
- an existing file to imitate for structure and wording, and the repository's vocabulary for defined names;
- the language of the document;
- the user's own rules from step 2;
- that it replies with only the list of files it wrote.

Naming a model file to imitate works better than listing every format rule, because `agy` can read the repository itself.

Plans come in two forms. A plan that is a file in the repository (an OpenSpec `design.md` or `tasks.md`, a plan document) is written like any other document. A plan the person only reads before any work starts can use `--mode plan` (step 4). When Claude Code is itself in plan mode, prefer `--mode plan` so that no file is written, and carry the result into your plan.

## 4. Run `agy`

```bash
cd <worktree>
agy -p "<task>" --mode accept-edits --output-format json --print-timeout 540s < /dev/null > draft.json 2> draft.err
```

- Run it in the background and wait for the notification; do not poll.
- Add `--model <name>` when the user names one (`agy models` lists them).
- `accept-edits` approves file edits inside the workspace and is the narrowest setting that lets a writing task finish. `--mode plan` writes no workspace files: it puts a plan at `~/.gemini/antigravity-cli/brain/<conversation_id>/implementation_plan.md`, which you pass to the review step.
- Do not trust the exit code. A shell command that needs approval ends a headless run with no output and exit 0. Read `.response`, check stderr, and check which files exist. If it stopped on an approval, retry once with `--dangerously-skip-permissions`, only inside the isolated worktree.
- Keep `.conversation_id` from the JSON. Every later round resumes it.
- `duration_seconds` is cumulative for the whole conversation, not for the last call. Time a call yourself if you need to know.

## 5. Check before a person sees it

Run the repository's own checks first: the validator, linter or build that its `AGENTS.md` names (for an OpenSpec change, `openspec validate <change> --strict`). Confirm with `git status --short` that only the allowed paths changed. If a check fails, resume the conversation with the error text:

```bash
agy -p "<error output and what to fix>" --conversation <id> --mode accept-edits --output-format json --print-timeout 540s < /dev/null
```

Allow two such rounds, then show the person the failure instead of looping on it.

## 6. Hand it to the person

```bash
bash <skill-dir>/scripts/review.sh <result.json> "<title>" <file>...
```

The script starts Plannotator's gated review, opens the browser (WSL, macOS and Linux), waits as long as the person needs and prints the decision. Run it in the background and wait for the notification. Several files open as one review, and the person gives one decision for all of them.

| `decision` | What it means | What to do |
|---|---|---|
| `approved` | The person accepts the result | Finish: step 8 |
| `annotated` | Comments on selected text, in `feedback` | Step 7 |
| `dismissed` | The person closed the tab | Do not treat it as approval. Ask what they want |

## 7. Return annotations to Gemini

`feedback` names each selected passage, the file and line, and the comment. Pass it to the same conversation without paraphrasing, and say what must stay fixed (structural headings, keywords the validator needs, names that must stay untranslated):

```bash
agy -p "A reviewer annotated your draft. Apply every annotation: <feedback>. <constraints>. Reply with only what you changed." --conversation <id> --mode accept-edits --output-format json --print-timeout 540s < /dev/null
```

Then repeat steps 5 and 6. Between rounds, diff the files against the previous round and read the diff yourself: Gemini applies a comment to the letter and can weaken something nearby. In one trial, a fix for an awkward English `SHALL NOT` in a Japanese sentence replaced it with a plain negative, which kept the validator happy and made the requirement less binding. Stop after three review rounds and ask the person how to proceed.

## 8. Finish

- Move the approved files to their final place, or leave them in the worktree for the person's own commit, as they prefer.
- Remove the throwaway worktree and branch once nothing is left in them.
- Report what you verified, quoting the signals (the validator's last line, `"decision":"approved"`), and what you did not check.
