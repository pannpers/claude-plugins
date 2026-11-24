---
name: draft-with-gemini
description: Have Gemini (Antigravity CLI, `agy`) draft a document, spec, plan or proposal, then put it in front of the user in Plannotator to annotate or approve, and feed their annotations back to Gemini until it is approved. Claude runs the loop; Gemini only writes. Use this whenever the user asks for a doc, README, design note, OpenSpec change or spec, plan or proposal and wants Gemini to write it, says Gemini reads better, asks for "agy で下書き", "Gemini に書かせて", "Plannotator でレビューして", or asks Claude to produce a document that a person will review. Use it even when the user does not name agy or Plannotator, as long as both are installed and the user prefers Gemini-written prose. Skip it for code, tiny edits and unattended runs, because the review step needs a person at the screen.
compatibility: Needs `agy` (tested with 1.4.7) and `plannotator` (tested with 0.29.3) on PATH, and a person who can answer in a browser.
---

# Draft with Gemini, review in Plannotator

Gemini writes the draft, a person reviews it, Claude runs the loop between them.

```
Claude ─ task ─▶ agy (draft) ─▶ files ─▶ checks ─▶ Plannotator (person) ─┬─ approved   → done
   ▲                                                                     ├─ annotated  → back to agy
   └───────────── annotations, same conversation ◀───────────────────────┘ └─ dismissed  → ask the person
```

Claude owns the loop because the person may take a long time to answer. A headless `agy -p` run cannot wait that long and cannot answer an approval prompt, so `agy` never calls Plannotator itself.

## 1. Check the preconditions

Run `command -v agy plannotator`. If either is missing, or nobody is at the screen (a scheduled or CI run), write the document yourself and say in one line that you did, and why. Do not install tools on your own.

## 2. Choose where Gemini works

`agy` reads the `AGENTS.md` (and `GEMINI.md`) of its working directory and does not read `CLAUDE.md`. Checked with a probe directory that held one file of each. So:

- Run it from the repository or worktree that will hold the document, so that repository's `AGENTS.md` applies.
- Anything that lives only in `CLAUDE.md`, or in the user's own global instructions (language, tone, naming rules), is invisible to it. Put those rules in the task.
- Let it write in an isolated place: a throwaway worktree cut from the default branch, or a scratch directory. A checkout that holds uncommitted work, such as an OpenSpec store, must stay untouched.

## 3. Write the task

Keep it short and concrete. A task Gemini can act on states:

- the goal, and who will read the result;
- the exact paths it may write, and that it must write nowhere else and run no git commands;
- an existing file to imitate for structure and wording, and the repository's vocabulary for defined names;
- the language of the document;
- the user's own rules from step 2;
- that it replies with only the list of files it wrote.

Describing a goal and naming a model file to imitate works better than listing every format rule, because `agy` can read the repository itself.

## 4. Run `agy`

```bash
cd <worktree>
agy -p "<task>" --mode accept-edits --output-format json --print-timeout 540s < /dev/null > draft.json 2> draft.err
```

- Run it in the background and wait for the notification; do not poll.
- Add `--model <name>` when the user names one (`agy models` lists them).
- `accept-edits` approves file edits inside the workspace and is the narrowest setting that lets a drafting task finish. Use `--mode plan` only when the user wants an implementation plan before any coding: it writes no workspace files and puts the plan at `~/.gemini/antigravity-cli/brain/<conversation_id>/implementation_plan.md`, which you pass to the review step.
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
| `approved` | The person accepts the draft | Finish: step 8 |
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
