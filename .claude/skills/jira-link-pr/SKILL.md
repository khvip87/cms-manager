---
name: jira-link-pr
description: Link a GitHub PR to a Jira ticket by adding a comment with the PR URL and transitioning the ticket to "In Review". Invoke immediately after opening a PR.
---

Associate a newly opened GitHub PR with its Jira ticket.

## Inputs
- `issueKey` — e.g., `CMS-42`
- `prUrl` — full GitHub PR URL
- `branchName` — e.g., `feat/CMS-42-publish-articles`

## Execution

1. Add a comment to the Jira issue via `mcp__atlassian__jira_add_comment`:
   ```
   PR opened: <prUrl>
   Branch: <branchName>
   ```
2. Transition the issue to `In Review` via `jira-update-ticket`.

## Notes

If Atlassian's GitHub integration is configured for this Jira workspace, the branch (and its PR) will also appear in the issue's **Development** panel automatically — *provided the branch name contains the issue key in uppercase* (e.g., `CMS-42`). The `github-branch-name` skill enforces that, so always use it when creating branches.

If the Development panel does not show the PR within a minute, fall back to the explicit comment (already done in step 1).
