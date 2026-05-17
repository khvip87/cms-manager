---
name: github-branch-name
description: Generate a consistent branch name from any Jira ticket (story, bug, chore, task) so Atlassian's GitHub integration auto-links the branch to the ticket. Invoke before creating any branch.
---

All branches — features, bug fixes, chores, tasks — use the same format:

```
feature/<JIRA_KEY>-<slug>
```

## Fields
- `JIRA_KEY`: Jira issue key in UPPERCASE exactly as Jira displays it. e.g., `CMS-42`.
- `slug`: lowercase kebab, 2–5 words, no articles (`the`, `a`, `an`), describes the change concisely.

## Examples

- `feature/CMS-42-add-publish-button`
- `feature/CMS-87-translate-article-list`
- `feature/CMS-128-article-list-pagination-off-by-one`
- `feature/CMS-200-upgrade-tanstack-query`
- `feature/CMS-215-fix-slug-uniqueness-constraint`

## Why this format

Atlassian's GitHub integration scans branch names for Jira keys and auto-populates the issue's **Development** panel with the branch, its commits, and any associated PR. The integration is case-sensitive — keep the key uppercase.

Using a single `feature/` prefix for all ticket types keeps the convention simple and consistent across the whole project.

## Execution

```powershell
$branch = "feature/<JIRA_KEY>-<slug>"
git checkout -b $branch
```

## Rules
- Use `feature/` prefix for **all** ticket types — stories, bugs, chores, tasks.
- Never include emojis, spaces, or special characters in the slug.
- Never reuse a branch name — suffix with `-v2` if you need to redo work on the same ticket.
- Never push directly to `main`. Every change goes through a branch + PR.
