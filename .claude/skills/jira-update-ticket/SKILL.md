---
name: jira-update-ticket
description: Transition a Jira ticket's status, add a comment, or update fields on an existing CMS ticket. Invoke when an agent needs to move a ticket through the workflow or leave a status update.
---

Use this skill to update an existing Jira ticket in the **CMS** project.

## CMS workflow statuses

| Status | When |
|---|---|
| `To Do` | Created, not yet picked up |
| `In Progress` | Assignee actively developing |
| `In Review` | PR opened, peer code review in progress |
| `Testing` | CI tests / manual QA running on the branch |
| `Merged` | PR merged to main (terminal state) |

## Allowed transitions

Forward (normal flow):
- `To Do` → `In Progress` (senior-fe or senior-be picks up)
- `In Progress` → `In Review` (PR opened)
- `In Review` → `Testing` (reviewer approved, tests / QA running)
- `Testing` → `Merged` (tests pass, PR merged to main)

Backward (rework):
- `In Review` → `In Progress` (reviewer requested changes)
- `Testing` → `In Progress` (tests failed; needs code fixes)
- `Merged` → `In Progress` (PM acceptance check failed)

`Merged` is the terminal state. `pm` verifies acceptance criteria here; if criteria are not met, comment + transition back to `In Progress`.

## Execution

1. To transition: call `mcp__atlassian__jira_transition_issue` with `issueKey` and target status name.
2. To comment: call `mcp__atlassian__jira_add_comment`.
3. To update other fields: call `mcp__atlassian__jira_update_issue`.

## Comment conventions

Every transition includes a comment explaining who and why:

- `To Do → In Progress`: `"<agent> starting work on this. Branch: <branch_name>."`
- `In Progress → In Review`: `"PR opened for review: <PR_URL>"`
- `In Review → Testing`: `"Review approved. Tests/QA in progress."`
- `Testing → Merged`: `"Tests pass. Merged in <commit_sha> to main."`
- Backward to `In Progress`: `"Reopened: <reason>"`
