---
name: jira-create-ticket
description: Create a Jira ticket (Epic, Story, Task, Sub-task, or Bug) in the CMS project. Invoke when the PM or Tech Lead agent needs to add a new ticket to the board. Sets initial status to "To Do".
---

Use this skill to create a Jira ticket in the **CMS** project.

## Project context
- **Project key:** `CMS`
- **Initial status (always):** `To Do`
- **Issue types:** `Epic`, `Story`, `Task`, `Sub-task`, `Bug`

## Inputs the caller must provide
- `issueType` — one of the types above.
- `summary` — imperative title (e.g., "Add article publishing workflow"). Under 100 chars.
- `description` — full description (markdown). Must include an `## Acceptance Criteria` section when the type is `Story`, `Task`, or `Bug`.
- `parentKey` — required for `Sub-task` (parent Story/Task) and for `Story` under an Epic. Omit for Epic.
- `labels` — array. At minimum one of: `frontend`, `backend`, `cross-repo`. Always include `cms`.
- `assignee` — optional account ID.

## Execution

1. Call `mcp__atlassian__jira_create_issue` (or equivalent — verify exact tool name at runtime from the MCP tool list).
2. Set fields:
   - `project.key`: `"CMS"`
   - `issuetype.name`: `issueType`
   - `summary`: `summary`
   - `description`: convert markdown to Atlassian Document Format (ADF) if the MCP tool requires it; many MCP tools accept markdown directly.
   - `labels`: union of caller labels + `["cms"]`.
   - `parent.key`: `parentKey` if provided.
   - `assignee.accountId`: `assignee` if provided.
3. After creation, report the issue key (e.g., `Created CMS-42`).

## Conventions
- Epic titles: noun phrase ("Article publishing", "Media library uploads").
- Story/Task/Sub-task titles: imperative ("Add publish button to ArticleEditor").
- Sub-task summaries are prefixed with `FE:` or `BE:` ("FE: add publish button", "BE: add publish endpoint").

## Acceptance Criteria format inside description

```markdown
## Acceptance Criteria
1. Given an editor on the article detail page, when they click "Publish", then the article transitions to PUBLISHED and an audit row is written.
2. Given a viewer (no edit role), when they GET /articles/:id/publish, then the response is 403.
```
