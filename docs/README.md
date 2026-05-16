# CMS Documentation

This folder is the source of truth for **feature design** and **bug investigations** across the CMS project. It lives at the workspace root (not inside `cms-frontend/` or `cms-backend/`) because features and bugs routinely span both repos.

## Layout

```
docs/
├── README.md                          ← you are here
├── features/
│   └── <jira-id>-<slug>/
│       └── README.md                  ← one feature doc per Jira epic/story
└── bugs/
    └── <jira-id>-<slug>/
        └── README.md                  ← one bug doc per Jira bug
```

Folder names use the **numeric portion of the Jira key** (e.g., `42-add-publish-button`, not `CMS-42-add-publish-button`).

## Who owns what

| Section of a feature doc | Owner |
|---|---|
| Context, Goals, Non-goals, Acceptance Criteria | `pm` agent |
| User Stories list | `pm` agent (updated as Tech Lead creates sub-tasks) |
| Technical Design (data model, API, websocket, state, test plan, rollout) | `tech-lead` agent |
| Frontend Implementation Checklist | `senior-fe` agent |
| Backend Implementation Checklist | `senior-be` agent |
| Notes / Discussion | All agents append; nobody edits prior entries |

For bug docs, `pm` owns Summary + Steps + Environment; whoever investigates owns Root Cause + Fix + Regression Test.

## How docs get created

- **Feature** → invoke the `feature-doc-create` skill (user-level). Pass the Jira key, slug, and title. The skill produces the full template at `docs/features/<id>-<slug>/README.md`.
- **Bug** → invoke the `bug-doc-create` skill (user-level). Same idea under `docs/bugs/`.

## Conventions

- Each doc is **one Markdown file**, not a folder of files. Keep it scannable.
- Append-only **Notes / Discussion** section at the bottom — preserve the chronological history of decisions.
- Link Jira tickets and PRs from the doc, never the other way around — the doc is the durable artifact.
- When a feature has multiple Jira stories, group them in **one feature doc** under the parent epic, not one doc per story.
- When closing a feature, set `Status: Merged` at the top of the doc and add a final Notes entry with the merge commit and date.

## Tooling

- The agent personas (`pm`, `tech-lead`, `senior-fe`, `senior-be`) live in `.claude/agents/`.
- Skills (`jira-*`, `feature-doc-create`, `bug-doc-create`, scaffolders, etc.) live in `.claude/skills/` (project-scoped CMS-specific ones) and `~/.claude/skills/` (generic reusable ones).
- See `.claude/agents/*.md` for the responsibilities and workflows of each persona.
