# CMS Project Memory

> Consolidated dump of every architectural decision made during planning. Treat this as the source of truth that survives across Claude sessions and onboards new contributors.
> Last updated: 2026-05-17.

---

## 1. Project overview

**Goal:** Build a Content Management System with three independently versioned and deployed repositories:

- `cms-frontend` — Next.js admin/editor UI.
- `cms-backend` — NestJS API, owns business rules and request handling.
- `cms-database` — **single source of truth for the data layer**: Prisma schema, forward-only SQL migrations, seeds, and the homegrown `cms-db` migration runner. Publishes the generated Prisma client as `@khvip87/cms-database` to GitHub Packages on every `v*.*.*` tag. `cms-backend` consumes it as a normal npm dependency.

The system is **component-based** — content is not only articles. Pages and articles are composed of arbitrary block types (hero, rich text, feature grid, CTA, etc.), so the data model has to accommodate variable structure.

All work is tracked in Jira (project key `CMS`) on a single Kanban board with both FE and BE work labeled via tags. Every feature/bug gets a Markdown doc under `docs/features/<id>-<slug>/` or `docs/bugs/<id>-<slug>/`.

---

## 2. Tech stack — at a glance

| Layer | Choice | Why |
|---|---|---|
| FE framework | **Next.js latest (16.x at scaffold)** App Router, TypeScript, **pnpm** | User requirement |
| FE styling | **Tailwind CSS 4** | Came with `create-next-app`; modern, no JS config needed |
| FE state — client | **Redux Toolkit** | Component-based features (page builders, layout editors) benefit from Redux DevTools time-travel and slice structure |
| FE state — server | **TanStack Query** | Best-in-class cache/invalidation/optimistic updates; CMS is mostly server state |
| FE forms | **react-hook-form + zod** | Type-safe forms; do NOT put form state in Redux |
| FE auth | **next-auth v5** | Google, Facebook, Credentials; JWT strategy |
| FE i18n | **i18next + react-i18next + http-backend + ICU** | Per-component namespace lazy loading via HTTP fetch — translators iterate on JSON without rebuilds |
| BE framework | **NestJS** on Node 22 LTS, TypeScript | Opinionated module/DI structure matches CMS domain complexity; `@nestjs/swagger` is best-in-class |
| BE validation | **`nestjs-zod`** with Zod schemas — never class-validator | Same validation library as frontend |
| BE realtime | **`@nestjs/websockets`** with socket.io adapter | Presence, live notifications, future collab editing |
| BE jobs | **`@nestjs/bullmq`** | Scheduled publishing, search reindex, email, image processing |
| DB engine | **PostgreSQL 16+** | Relational core (users/roles/audit) + JSONB for variable component trees |
| Schema home | **`cms-database`** (own GH repo) — Prisma DSL + checked-in `migrations/NNNN_*/up.sql` | Decouples DB lifecycle from backend deploys; ships as `@khvip87/cms-database` on GitHub Packages |
| Migration runner | **Homegrown `cms-db` CLI** (`migrate`, `status`, `diff`, `new`, `adopt`, `seed`) over `pg` | ~150 LOC; checksum drift detection; forward-only |
| ORM | **Prisma** — generated client re-exported by `@khvip87/cms-database` | Best DX; `cms-backend` imports `Prisma`, `DatabaseClient`, enums from the published package |
| Search | **Postgres FTS** initially; Meilisearch later if FTS limits bite | No external service to start |
| Local dev DB | **Docker Postgres + Redis** via workspace `docker-compose.yml` | Single command spin-up |
| CI | **GitHub Actions per repo** — lint + typecheck + test + build | No deploys wired yet |
| Hosting | **Deferred** (FE, BE, DB hosts not chosen yet) | Don't decide until first deploy |
| Jira | **Cloud, `khvip87.atlassian.net`**, project key `CMS`, MCP integration | `@sooperset/mcp-atlassian` configured in `.mcp.json` |

---

## 3. State management — details

**Hybrid:** Redux Toolkit for client/UI state + TanStack Query for server state. Not pure RTK Query.

**Why hybrid:** the CMS scope extends beyond articles into component/builder features where Redux's structure pays off. TanStack Query is still the better tool for queries, mutations, cache invalidation, and websocket-driven invalidation.

**Rules:**
- Server-fetched data → TanStack Query, never Redux.
- Form state → react-hook-form, never Redux.
- next-auth session → next-auth's `useSession`, never Redux.
- UI state (modals, selections, builder state, wizards) → Redux slices.

**File layout:**
```
src/store/
├── index.ts               ← makeStore() with empty reducer registry
├── StoreProvider.tsx      ← client provider, useState lazy init (React 19 friendly)
└── hooks.ts               ← typed useAppDispatch / useAppSelector
```

---

## 4. Internationalization — details

**Library:** `i18next + react-i18next + i18next-http-backend + i18next-icu`.

**Loading model — per-component namespace lazy load:**
Each feature area gets its own JSON namespace. Calling `useTranslation('articleEditor')` in a client component triggers an HTTP fetch of `/locales/<lng>/articleEditor.json` once, cached for the session. Users only download translations for areas they visit.

**Why HTTP-fetched (not bundled + code-split):**
- Translators update JSON without a frontend rebuild.
- Easy future migration to a TMS or backend-served translations.

**Locales at launch:** `en` + `ar`. Exercises full pipeline — LTR + RTL, English 2-form plurals vs Arabic 6-form plurals, Intl number/date formatting.

**Translator workflow:** Git PRs (translators edit JSON files in the repo). Migrate to Tolgee (self-host) or Crowdin/Phrase when translator count > ~3 or locale count > ~5.

**URL routing:** `/[locale]/...` — `/en/articles`, `/ar/articles`. Implemented by `src/proxy.ts` (Next 16 renamed middleware → proxy).

**File layout:**
```
src/i18n/
├── settings.ts            ← locales list, defaultLocale, isLocale(), getDir()
├── i18n.ts                ← client-side init, HTTP backend, ICU
├── I18nProvider.tsx       ← React provider for client tree
└── server.ts              ← RSC helper (filesystem JSON read, no React deps)
public/locales/{en,ar}/
└── <namespace>.json
```

**Content i18n schema (DB):** **separate translation tables** (`<entity>_translations` with `(entityId, locale)` PK). Never embed locales inside the parent JSON column.

---

## 5. Authentication — details

**Pattern: Option A — NextAuth issues JWTs; backend validates with a shared secret. Backend is stateless.**

**Roles:**
- **Frontend + NextAuth** owns OAuth dance (Google, Facebook) and the Credentials provider. Signs JWTs with `NEXTAUTH_SECRET`. Stores token in HTTPOnly session cookie.
- **Backend** owns the User table (source of truth). Exposes `POST /auth/login` (validates email+password) and `POST /auth/upsert-user` (creates/finds user on first OAuth sign-in). Validates incoming JWTs with `@nestjs/jwt`.

**OAuth providers at launch:** Google, Facebook, Credentials. Add GitHub/Apple/magic-link later.

**Shared secret:**
- FE `.env.local`: `NEXTAUTH_SECRET`
- BE `.env`: `JWT_SECRET`
- **Same value, both files.** Generate with `openssl rand -base64 32`.

**JWT payload contract:**
```ts
{
  sub: string                                                            // user.id (cuid)
  email: string
  roles: ('admin' | 'editor' | 'author' | 'viewer')[]
  iat: number
  exp: number
}
```

**RBAC:**
- Roles live on the User row (many-to-many via UserRole join).
- JWT carries `roles: string[]` so `RolesGuard` decides without a DB hit.
- **Per-resource permissions** (e.g., "edit *this* article") are checked in the service layer with a DB query — never trust JWT for object-level auth.

**Token lifetime:** 24h, no refresh tokens initially. Add refresh tokens + Redis denylist when compliance demands.

**Hard rules:**
- Backend NEVER decodes a JWT without verifying signature.
- Secret never in any committed file.
- Both apps must use HS256 (same algorithm).

---

## 6. Database — details

**Engine:** PostgreSQL 16+. **ORM:** Prisma.

**Single source of truth: `cms-database` (own GitHub repo).** Schema, migrations, seeds, and the typed Prisma client all live in [`khvip87/cms-database`](https://github.com/khvip87/cms-database) and ship as the npm package **`@khvip87/cms-database`** published to GitHub Packages on every `v*.*.*` tag. `cms-backend` installs this package like any other dependency and re-exports its client as `DatabaseService` (extends the generated `PrismaClient` with Nest lifecycle hooks).

> **Hard rule: never edit schema or migration files inside `cms-backend`.** The `cms-backend/prisma/` directory was deleted in CMS-16. All schema changes happen in `cms-database/`.

**The dev loop for "add a new table/column" is documented in exactly one place:** [`cms-database/README.md` → Dev loop](https://github.com/khvip87/cms-database#dev-loop--changing-the-schema). This file does not repeat the steps — see [[architecture-cms-database-extract]] for the high-level architecture.

**Hybrid content model:**
- **Relational tables** for users, roles, permissions, audit log, tags, media, comments, sessions, settings, base entity tables (articles, pages).
- **JSONB columns** for variable component trees (e.g., `Page.blocks`, `Article.blocks`). GIN index where queried into.

Why hybrid: every modern CMS (Payload, Strapi v5, Directus, Sanity) converged on this pattern — relational guarantees + document flexibility in the one column that needs it.

**Content i18n schema — separate translation tables:**
```
Article { id, slug, status, authorId, ... }
ArticleTranslation { articleId, locale, title, body, status }
   composite PK (articleId, locale)
```
Allows partial translations, per-locale publish status, clean TMS integration.

**Migrations:**
- All schema changes via `pnpm db:diff -- --name <slug>` **inside `cms-database/`** (wraps `prisma migrate diff` to write `migrations/NNNN_<slug>/up.sql`).
- Apply with `pnpm db:migrate` (the homegrown `cms-db` runner — forward-only, SHA-256 checksum drift detection against `_cms_migrations` table).
- Naming: `<verb>_<entity>` (e.g., `add_articles_table`).
- Never `prisma db push` in shared environments — bypasses the migration runner and breaks drift detection.
- Existing databases without `_cms_migrations` adopt the baseline via `pnpm db:adopt` (one-shot, idempotent).

**Publishing & consumption:**
- Tag `vX.Y.Z` on `cms-database` `main` → `publish.yml` builds and pushes `@khvip87/cms-database@X.Y.Z` to GitHub Packages.
- `cms-backend` bumps `"@khvip87/cms-database"` in its `package.json`; `pnpm install` (with `NODE_AUTH_TOKEN` set) pulls the new version; `pnpm typecheck` picks up the new types.
- CI in `cms-backend` authenticates to GH Packages via repo secret **`GH_PACKAGES_TOKEN`** (a PAT with `read:packages` — `secrets.GITHUB_TOKEN` cannot read packages published by a different repo). CI applies migrations against an ephemeral Postgres via `npx cms-db migrate` before running `pnpm test:e2e`, so any schema bump that breaks e2e fails CI before merge.

**Search:** Postgres full-text search via `tsvector` + GIN. Graduate to Meilisearch only if/when FTS limits clearly bite.

**Local dev DB:** Docker Compose at workspace root with Postgres 16 + Redis (for BullMQ). Backend env: `DATABASE_URL=postgres://cms:cms@localhost:5432/cms`.

---

## 7. Backend stack — details

**Framework:** NestJS, Express adapter by default (swap to Fastify adapter only on benchmark evidence).

**Module convention:** one NestJS module per feature under `src/modules/<feature>/`:
```
modules/<feature>/
├── <feature>.module.ts
├── <feature>.controller.ts
├── <feature>.service.ts
├── dto/
│   ├── create-<feature>.dto.ts        ← Zod via nestjs-zod
│   └── update-<feature>.dto.ts
└── <feature>.controller.spec.ts
```

**Cross-cutting:**
- `PrismaService` (extends `PrismaClient` with `onModuleInit` / `onModuleDestroy`).
- `AuthGuard` (verifies JWT) + `RolesGuard` (checks roles array) + `@Roles()` / `@CurrentUser()` decorators.
- `@nestjs/swagger` decorators on every controller/DTO — exposed **only when `NODE_ENV !== 'production'`**.

**WebSocket gateways** for real-time (presence, live notifications). Default to socket.io adapter.

**Background jobs** via `@nestjs/bullmq` — never `setTimeout` or in-process loops.

**Hard rules:**
- Zod-only validation (no class-validator).
- Swagger never in production.
- Translatable content uses separate translation tables (not embedded JSONB locales).
- Roles checked in guards, not controller bodies.
- Migrations always generated, never `db push` in shared envs.

---

## 8. Frontend stack — details

**Framework:** Next.js 16.x, App Router, TypeScript strict, pnpm, Tailwind 4, ESLint.

**Key Next.js 16 changes from training data:**
- **Middleware renamed to Proxy** — file is `proxy.ts`, function is `proxy()`.
- **Route params are async** — `const { locale } = await params`.
- **Per-version docs bundled** at `node_modules/next/dist/docs/` — read these, not training data, when in doubt. The repo's `AGENTS.md` enforces this rule for agents.

**App layout:**
```
src/
├── proxy.ts                            ← locale routing, ICU-locale negotiation
├── auth.ts                             ← NextAuth v5 factory (handlers, signIn, signOut, auth)
├── app/
│   ├── [locale]/
│   │   ├── layout.tsx                  ← <html lang/dir>, AppProviders wrapper
│   │   └── page.tsx                    ← welcome (server-rendered with i18n)
│   ├── api/auth/[...nextauth]/route.ts ← export GET/POST from auth.ts handlers
│   └── globals.css                     ← Tailwind 4
├── i18n/                               ← settings, client init, server helper, provider
├── store/                              ← Redux store, provider, hooks
├── providers/                          ← QueryProvider, AppProviders (composes all)
├── lib/api.ts                          ← apiFetch base client to cms-backend
├── types/next-auth.d.ts                ← session.user.roles type augmentation
└── features/                           ← (one folder per feature added later)
public/locales/{en,ar}/<namespace>.json
```

**Feature folder convention (per `fe-scaffold-feature` skill):**
```
src/features/<featureName>/
├── components/
├── queries.ts                          ← TanStack Query hooks
├── slice.ts                            ← (only if client state needed)
├── types.ts
└── index.ts                            ← barrel
public/locales/{en,ar}/<featureName>.json
```

---

## 9. CI/CD strategy

**Scope of first cut:** PR-checks-only. No deploy pipelines.

**Per repo `.github/workflows/ci.yml`:**
- **Frontend:** `pnpm lint`, `pnpm typecheck`, `pnpm test` (deferred), `pnpm build`.
- **Backend (when scaffolded):** same four + `prisma validate` + `prisma migrate diff` against `main` + a Postgres service container for tests that hit the DB.
- **PR body check:** fails if the body does not contain `CMS-\d+`.

**Branch strategy:** trunk-based. `main` is the only long-lived branch. Squash-merge.

**Branch protection (apply manually in GitHub UI):**
- Require PR before merge.
- Require status checks: lint, typecheck, build (+ prisma validate for BE).
- Require linear history.
- Require conversation resolution.
- Restrict force-push and deletion on `main`.

**Dependencies:** Renovate, weekly schedule, grouped by ecosystem (next, react, i18next, tanstack, redux, auth).

**Deferred (revisit later):**
- Production deploy workflows.
- Jira auto-transitions (e.g., `Testing → Merged` on PR merge) from CI events.
- Production hosting choices (FE host, BE host, managed DB).

---

## 10. Jira integration

**Instance:** `https://khvip87.atlassian.net` — Jira Cloud.
**Account:** `khvip87@yahoo.com`.
**Project key:** `CMS`.
**Integration:** `@sooperset/mcp-atlassian` MCP server, configured in `.mcp.json`.
**Token:** `JIRA_API_TOKEN` in `.env.local` (gitignored). **Never in chat, never in committed files.**

**Project type:** Jira Software, team-managed Kanban (next-gen).
**Issue types:** Epic, Story, Task, Sub-task, Feature, Bug.

**Workflow statuses (linear forward, backward for rework):**
- `To Do` → planned, not started
- `In Progress` → active development
- `In Review` → PR opened, peer code review
- `Testing` → CI tests / QA running on the branch
- `Merged` → PR merged to `main` (**terminal state**)

**Board layout:** single board for FE+BE; use labels `frontend`, `backend`, or `cross-repo` to filter.

**Transition rules baked into agent skills:**
- `pm` creates tickets in `To Do`.
- `senior-fe`/`senior-be` move to `In Progress` when picking up.
- Move to `In Review` when PR is opened.
- `In Review → Testing` when reviewer approves and tests/QA start.
- `In Review → In Progress` if reviewer requests changes.
- `Testing → Merged` when tests pass and PR merges to `main`.
- `Testing → In Progress` if tests fail and need code fixes.
- `pm` verifies acceptance at `Merged` and may transition back to `In Progress` if criteria aren't met.
- **No `Released` status** — production deploys are not tracked as a Jira state.

---

## 11. Agent & skill structure (Claude Code)

### Subagents (project-level: `.claude/agents/`)

| Agent | Role | Model | Boundary |
|---|---|---|---|
| `pm` | Project Manager — decomposes user requests into Jira epics/stories, maintains the board, verifies acceptance | inherit | No code edits outside `docs/` |
| `tech-lead` | Tech Team Lead — owns cross-repo design, schema changes, API contracts, reviews PRs architecturally | **opus** | Doesn't implement; writes technical design and creates sub-tasks |
| `senior-fe` | Senior Frontend Dev — implements FE sub-tasks | inherit | Works only inside `cms-frontend/` |
| `senior-be` | Senior Backend Dev — implements BE sub-tasks | inherit | Works only inside `cms-backend/` |

Role boundaries enforced via system prompts (not via `tools:` restrictions).

### Skills

**Project-level (`D:\projects\content-mng-sys\.claude\skills\` — CMS-specific):**
- `jira-create-ticket`, `jira-update-ticket`, `jira-link-pr` — codify CMS project key + 5-status workflow
- `pm-decompose-request`, `tech-split-story`, `tech-design-stub` — role-specific templates
- `fe-scaffold-feature`, `be-scaffold-module`, `be-create-migration`, `fe-run-checks`, `be-run-checks`

**User-level (`C:\Users\khvip\.claude\skills\` — reusable across projects):**
- `github-create-pr`, `github-branch-name` — branch + PR conventions (`feat/CMS-42-slug`)
- `feature-doc-create`, `bug-doc-create` — generic doc templates

---

## 12. Documentation structure

**Location:** `docs/` at the workspace root (NOT inside either repo) — features span both repos.

```
docs/
├── README.md                       ← human-facing layout guide
├── features/
│   └── <numeric-jira-id>-<slug>/
│       └── README.md
└── bugs/
    └── <numeric-jira-id>-<slug>/
        └── README.md
```

**Feature doc ownership:**
- `pm` writes Context, Goals, Non-goals, Acceptance Criteria, User Stories list.
- `tech-lead` writes Technical Design (data model, API surface, websocket events, state implications, test plan, rollout).
- `senior-fe` / `senior-be` write their Implementation Checklists and append to Notes/Discussion.

**Bug doc:** `pm` writes Summary, Steps, Environment; investigator writes Root Cause, Fix, Regression Test.

---

## 13. Repo layout (workspace root)

The meta repo `content-mng-sys` is a **documentation/scratch repo only** — it gitignores all three child repos. There is **no `pnpm-workspace.yaml` and no root `package.json`**; each child is a fully independent git repo with its own CI, release cadence, and deploys.

```
D:\projects\content-mng-sys\           ← meta repo (gitignores all 3 children)
├── .claude/
│   ├── agents/                        ← 4 subagent personas
│   └── skills/                        ← CMS-specific skills
├── .mcp.json                          ← Atlassian MCP server (reads ${JIRA_API_TOKEN} from env)
├── .env.local                         ← gitignored — holds JIRA_API_TOKEN
├── .env.local.example                 ← template, committed, placeholder only
├── .gitignore                         ← lists /cms-frontend, /cms-backend, /cms-database
├── docker-compose.yml                 ← Postgres 16 + Redis 7 for local dev
├── scripts/
│   └── load-env.ps1                   ← loads .env.local into shell before launching claude
├── docs/
│   ├── README.md
│   ├── features/
│   │   ├── 1-add-new-articles/
│   │   └── 2-extract-cms-database/
│   └── bugs/
├── PROJECT_MEMORY.md                  ← this file
├── cms-frontend/                      ← github.com/khvip87/cms-frontend  (independent)
├── cms-backend/                       ← github.com/khvip87/cms-backend   (independent)
└── cms-database/                      ← github.com/khvip87/cms-database  (independent)
                                        Publishes @khvip87/cms-database to GH Packages
```

User-level files outside the workspace:
```
C:\Users\khvip\.claude\
└── skills/                         ← reusable cross-project skills
```

---

## 14. Open decisions still pending

| Topic | Notes |
|---|---|
| **Production hosting** — FE | Vercel was my recommendation; user deferred until first deploy |
| **Production hosting** — BE | Railway was my recommendation; user deferred |
| **Production hosting** — DB | Neon was my recommendation; user deferred |
| **Jira CI automation** — auto-transition `Merged` on PR merge from CI events | Deferred; agents transition manually via MCP for now |
| **Branch protection rules** | Documented above; user applies manually in GitHub UI per repo |
| **Vitest setup** in cms-frontend | Not added yet; `test` script and CI step are TODO'd |
| **Initial OAuth client IDs** for Google + Facebook | User generates and adds to `.env.local` when ready to test auth |

---

## 15. Useful commands

**Local dev — load Jira token before launching Claude:**
```powershell
cd D:\projects\content-mng-sys
. .\scripts\load-env.ps1
claude
```

**cms-frontend — run dev:**
```powershell
cd cms-frontend
$env:NEXTAUTH_SECRET = "any-dev-value"
$env:NEXTAUTH_URL = "http://localhost:3000"
pnpm dev
```

**cms-frontend — verify before PR:**
```powershell
pnpm lint
pnpm typecheck
pnpm build
```

**Branch naming:** `<type>/<JIRA-KEY>-<slug>` — e.g., `feat/CMS-42-add-publish-button`.

---

## 16. References

- This file consolidates the per-topic memory entries under `C:\Users\khvip\.claude\projects\D--projects-content-mng-sys\memory\` — those remain the authoritative source for Claude sessions; this file is the human-readable mirror for the repo.
- Next.js 16 bundled docs: `cms-frontend/node_modules/next/dist/docs/`.
- Each agent persona's full instructions: `.claude/agents/*.md`.
- Each skill's invocation pattern: `.claude/skills/<name>/SKILL.md`.
