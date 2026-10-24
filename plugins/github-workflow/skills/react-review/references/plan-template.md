# Review Plan Template

Use the **Write tool** to create `$OUTDIR/react-review-plan.md` following this structure.
Give every entry all four fields (Review Comment, Assessment, Response, Rationale), so that the user can approve or overrule each decision without opening the PR. List informational comments under their own heading, with the IDs you put in `no-reply.txt`.

```markdown
## Review Comments Analysis

### ✅ Will Address (N comments)

1. **[ID: 123456]** [filename.go:42](https://github.com/...)
   - **Review Comment**: "Use `context.WithTimeout` for database calls."
   - **Assessment**: Correct — no timeout, could block. Standard Go pattern. Low blast radius. In scope.
   - **Response**: Add 5-second timeout to DB calls in this file.
   - **Rationale**: Aligns with existing pattern in `user_handler.go:88`.

### 🤔 Needs Clarification (N comments)

1. **[ID: 345678]** [api.go:100](https://github.com/...)
   - **Review Comment**: "Consider using dependency injection here."
   - **Assessment**: Too vague — could mean interface, constructor, or DI container. Blast radius unknown.
   - **Response**: Ask reviewer to clarify scope before proceeding.
   - **Rationale**: Implementing the wrong pattern could add unnecessary abstraction.

### ⏭️ Won't Fix (N comments)

1. **[ID: 901234]** [test.go:200](https://github.com/...)
   - **Review Comment**: "Add more edge case tests for parsing."
   - **Assessment**: Cases already covered in `integration/parser_test.go`. Out of scope.
   - **Response**: Won't fix.
   - **Rationale**: Duplicating coverage adds maintenance burden without benefit.
```
