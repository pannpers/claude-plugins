---
name: clear-prose
description: Write prose that a person will read, in any language, by first explaining the point concretely and only then tightening it without losing meaning or key conditions. Apply it by default, without being asked, to every human-facing text - explanations and answers to the user, design docs, READMEs, runbooks, specs, issues, pull request descriptions, review replies, commit messages, release notes, code comments and messages for chat - including when another skill drives the task and this one shapes only its prose. Also use it when the user asks to make text clearer or more natural, or complains that text is vague, terse, jargon-heavy or reads like a translation (わかりやすく, 自然な日本語で, 直訳っぽい, 何を言いたいのかわからない). Skip it for typo-only fixes, code itself, literal translation and verbatim copying.
---

# Clear Prose

Text written short from a vague idea tends to drop causes, conditions and subjects, and the reader cannot tell what it means. This happens in any language: in Japanese as missing subjects and translated-sounding phrasing, in English as vague passives, bare noun stacks and unqualified claims. So build the meaning first, the way you would explain it aloud to the reader, and shorten only what is already clear, keeping the information the reader needs.

Scale the effort to the text. For a two-line commit message or chat reply, run the steps in your head; for a design doc or a pull request description, work through them deliberately.

## Steps

1. **Decide what to say.** Check the reader, the purpose, the register and the scope of the request. State the central point in one sentence. If you cannot decide what the text should mean, ask instead of filling the gap with a guess.
2. **Explain it once in full.** Make concrete, as far as needed, what happens to what, why, and under which conditions or exceptions. Keep facts, recommendations and possibilities apart, and add nothing you have no basis for.
3. **Sort topics and conditions.** Separate mechanism, conditions, exceptions and cautions, and make clear which statement each condition applies to. Keep important terms and constraints, explained where they appear.
4. **Shorten without changing the meaning.** Cut repetition and roundabout wording. Do not change the claim, its subject, cause and effect, comparisons, how strongly something is asserted, or important conditions. If the text is still hard to read, narrow the topics or restructure rather than deleting more words.
5. **Check the finished text.** Read only the final text and confirm the point and its conditions come across. If shortening lost meaning, put the needed explanation back.

## Output

Show the finished text first. Share drafts or the reasoning behind them only when asked. When editing, change only the source and the range the user named; if you could not confirm that a save or display succeeded, say so separately.

When another skill or a project rule sets the format of the text (a pull request template, a commit message convention, a required language), follow that format and apply these steps to the prose inside it.

## Source

The method (explain first, then shorten) is adapted from the `explain-before-shorten` skill in [nyatinte/dotfiles](https://github.com/nyatinte/dotfiles) (MIT, commit 5cd28ef), which was inspired by [AI の謎な説明文を直すスキル (Zenn)](https://zenn.dev/microsoft/articles/explain-before-shorten).
