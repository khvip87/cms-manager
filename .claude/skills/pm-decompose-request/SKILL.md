---
name: pm-decompose-request
description: PM-only. Decompose a user prose feature request into a proposed Jira epic + child stories with acceptance criteria. Produces a draft for user approval BEFORE any Jira items are created. Invoke when the user describes a new feature in conversational language.
---

Take the user's prose feature request and produce a structured decomposition draft.

## Output format

```markdown
## Epic: <Capability name as noun phrase>

**Goal:** <one-sentence user value>
**Definition of done:** <2–4 lines describing the end state>

### Stories

**Story 1: <Imperative title>**
Description: <2–4 lines>
Acceptance criteria:
1. Given …, when …, then …
2. …

**Story 2: <Imperative title>**
…
```

## Decomposition rules

- Each story is deliverable in **1–3 days of one developer's work**. Bigger → split.
- Cross-repo work (FE + BE in one story) is fine — the Tech Lead splits it into FE/BE sub-tasks later.
- Acceptance criteria are **testable and specific**. Vague phrases ("works well", "is fast") are not criteria. "Returns 201 with the created article in <300ms p50" is.
- Every acceptance criterion implies a test the implementing dev will write.
- Edge cases (auth failure, validation failure, empty state, pagination boundary) deserve their own criterion lines.

## Workflow after producing the draft

1. Show the draft to the user **verbatim**.
2. Ask: "Approve, edit any of these, or split further?"
3. Do **not** invoke `jira-create-ticket` until the user explicitly approves.
4. Once approved, create the Epic first, then create each Story with `parent.key` = the Epic's key.

## Clarifying-question budget

If acceptance criteria are ambiguous, ask **1–3** sharp clarifying questions before drafting. Don't ask more — a draft with placeholders is better than 5 questions in a row.
