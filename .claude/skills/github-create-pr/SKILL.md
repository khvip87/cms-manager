---
name: github-create-pr
description: Open a GitHub PR with a templated body that includes a Jira link, feature doc reference, summary, and test plan checklist. Invoke after pushing any branch and before linking to Jira.
---

Open a PR using the `gh` CLI with a standardized body.

## Inputs the caller must provide
- `title` — under 70 chars, imperative voice (e.g., "Add article publishing workflow").
- `jiraKey` — e.g., `CMS-42`. Pass `(none)` only for trivial workspace-meta changes.
- `featureDocPath` — e.g., `docs/features/42-publish-articles/README.md`. Pass `(none)` for one-off fixes.
- `summary` — array of 1–3 bullet points.
- `testPlan` — array of verification steps (each becomes a checkbox).

## Execution (PowerShell)

Always use a single-quoted heredoc (`@'...'@`) for the body to avoid PowerShell interpolating `$` signs:

```powershell
$body = @'
## Summary
<bullet lines>

## Jira
- <jiraKey>: https://khvip87.atlassian.net/browse/<jiraKey>

## Feature doc
- <featureDocPath>

## Test plan
- [ ] <step 1>
- [ ] <step 2>

---
Opened by Claude Code subagent.
'@

gh pr create --title "<title>" --body $body
```

If `jiraKey` is `(none)`, omit the Jira section. Same for `featureDocPath`.

## After opening
- Capture the returned PR URL from `gh pr create` stdout.
- Hand the URL to `jira-link-pr` so the ticket gets the PR link and transitions to `In Review`.

## Rules
- Branch must follow the project convention: `feature/<JIRA_KEY>-<slug>` (see `github-branch-name` skill).
- Title must NOT include the Jira key (the branch already contains it; Atlassian's integration handles linking). Keep titles human-readable.
- Body must NOT contain secrets, screenshots of internal data, or customer information.
