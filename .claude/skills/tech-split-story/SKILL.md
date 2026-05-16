---
name: tech-split-story
description: Tech Lead-only. Given an approved PM story, produce FE and BE sub-task drafts with technical detail. References existing code in cms-frontend and cms-backend before proposing. Invoke after PM hands off a story and before any dev work starts.
---

Decompose an approved PM story into FE and BE sub-tasks.

## Pre-work (do not skip)

1. Read the Story's acceptance criteria from Jira.
2. Read the feature doc's user-facing sections.
3. Grep/Read existing code in:
   - `cms-frontend/src/features/` for touched features.
   - `cms-backend/src/modules/` for touched modules.
   - `cms-backend/prisma/schema.prisma` for the data model.
4. Identify the API surface (existing endpoints, queries, websocket events) the story touches.

## Output format

```markdown
### FE Sub-tasks

**FE-1: <imperative title>** (refs AC 1, 2)
- Files: `cms-frontend/src/features/<feature>/...`
- Changes: <2–3 bullets>
- New i18n keys: <list under namespace>
- Tests: <unit + integration scenarios>

**FE-2: …**

### BE Sub-tasks

**BE-1: <imperative title>** (refs AC 3)
- Module: `cms-backend/src/modules/<feature>/`
- Endpoint: `<METHOD> <path>` — body shape, response shape, auth (role)
- Schema delta:
  ```prisma
  // Added/changed:
  model … { … }
  ```
- Migration name: `<verb>_<entity>` (slug)
- Tests: <unit + integration scenarios>

**BE-2: …**
```

## Rules

- Every sub-task references at least one Acceptance Criterion ID from the parent Story.
- Sub-tasks are **scoped** — one logical unit each. If a sub-task description has the word "and" twice, split it.
- Sub-task summaries are prefixed with `FE:` or `BE:` per the `jira-create-ticket` convention.
- Cross-cutting concerns (auth/RBAC) are NOT new sub-tasks — they're enforced by existing guards. If the story requires a NEW role/permission, that's its own sub-task labeled `cross-repo`.

## Workflow after producing the draft

1. Append the FE/BE breakdown to the feature doc's **Technical Design** section (after the API surface + schema diff produced by `tech-design-stub`).
2. Create Jira sub-tasks via `jira-create-ticket` with `issueType: Sub-task`, `parentKey: <story key>`, and labels `frontend` or `backend` per side.
3. Notify (hand off to) `senior-fe` and/or `senior-be`.
