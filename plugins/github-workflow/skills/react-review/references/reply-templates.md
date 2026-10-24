# Reply Templates

## Classification Table

| Category | When to use |
|---|---|
| ✅ Will Address | Correct, best approach, in scope |
| ✅ Will Address (alternative) | Real issue, but a better fix exists |
| ✅ Already Addressed | Duplicate of a previously handled comment |
| 🤔 Needs Clarification | Ambiguous intent or multiple interpretations |
| ⏭️ Won't Fix (defer) | Valid but out of scope for this PR |
| ⏭️ Won't Fix (disagree) | Assertion is incorrect or based on misunderstanding |
| ℹ️ Informational | Asks for nothing (walkthrough summary, coverage report); add its ID to `no-reply.txt` and do not reply |

## Templates

Each reply says what was pointed out, what was done, and why, so that the reviewer can close the thread without asking again.

### Addressed

```
✅ Addressed in {commit_sha}.

**What was changed**: {description}
**Why**: {rationale}
```

### Addressed with alternative

```
✅ Addressed in {commit_sha}, using a different approach.

**Suggested**: {reviewer's suggestion}
**Done instead**: {alternative}
**Why**: {rationale}
```

### Already addressed

```
✅ Already addressed in {commit_sha}.

{explanation — e.g., duplicate of comment ID X}
```

### Needs clarification

```
🤔 Could you clarify {specific_aspect}?

{what_is_ambiguous}. Happy to proceed once the intent is clear.
```

### Won't fix (defer)

```
Thanks for the suggestion!

Not implementing this because {rationale}. Open to further discussion if you see it differently.
```

### Respectfully disagreeing

```
Thanks for flagging this. I believe the current implementation is correct.

**Concern**: {summary}
**Current behavior**: {what the code does and why}
**Why it's correct**: {evidence}

Happy to discuss further if I'm missing something.
```

### Answering review bodies and conversation comments

These have no thread, so answer them together in one PR comment. Start each answer with the comment's URL, which `reconcile-replies.sh` looks for.

```
Answers to the review feedback outside line comments:

- {html_url} — ✅ Addressed in {commit_sha}: {what changed and why}
- {html_url} — ⏭️ Won't fix: {rationale}
```

