# Extract database concern into a standalone `cms-database` project

**Jira:** [CMS-10](https://khvip87.atlassian.net/browse/CMS-10)
**Status:** In Progress (3/8 stories landed, 5 remaining)
**Owners:** @pm · @tech-lead · @senior-be

## Context

Today `cms-backend` owns the Prisma schema (`prisma/schema.prisma`), the migration history (`prisma/migrations/`), and the seed script (`prisma/seed.ts`). This couples every database change to a backend deploy, makes it awkward to scale the data layer independently, and forces all schema work to live inside a NestJS application repo.

This epic lifts the database concern into a new, **fully independent** GitHub repository at `https://github.com/khvip87/cms-database.git`, hosted as a sibling folder of `cms-backend` and `cms-frontend`. The root `content-mng-sys` repo continues to gitignore all three children and remains a documentation/scratch meta-repo only — **no `pnpm-workspace.yaml`, no root `package.json`**.

`cms-database` becomes the single source of truth for the schema, publishes a versioned typed client (`@khvip87/cms-database`) to GitHub Packages on each tag, and is the only place where DDL/DML migration files live. `cms-backend` consumes it like any other npm dependency.

This is a platform/infrastructure epic — no end-user-facing behavior changes. The in-flight Article authoring epic ([CMS-1](https://khvip87.atlassian.net/browse/CMS-1)) is **paused** for its duration. CMS-2 (In Review) and CMS-3 (In Progress) freeze in place and resume against the new layout after CMS-10 lands.

## Goals

- Segregate the database concern from the backend application code.
- Allow `cms-database` to deploy independently of `cms-backend` (own GitHub repo, own CI, own release cadence, own tags).
- Support future scale-out to additional Postgres servers (read replicas, per-bounded-context DBs) without restructuring.
- Make schema evolution a matter of **adding a new DDL/DML `.sql` file** and running a migration — forward-only versioned migrations.
- Preserve type safety in `cms-backend` by sharing the generated Prisma client via a published package (`@khvip87/cms-database`).
- Keep PostgreSQL as the database engine; the local Docker container is unchanged.

## Non-goals

- Read-replica wiring, sharding, or multi-region.
- Redesigning existing tables or adding new domain models.
- Switching off Prisma in `cms-backend` (we keep the client, just sourced from `@khvip87/cms-database`).
- Any monorepo plumbing at the root (`pnpm-workspace.yaml`, root `package.json`, lerna, nx).
- Production deploy automation for migrations (separate CI/CD epic — covers `db:migrate` against staging/prod).
- Down-migrations (forward-fix only; destructive ops use two-phase: code-stop-reading PR, then drop PR).

## Acceptance criteria (epic-level definition of done)

1. A new GitHub repo `khvip87/cms-database` exists and is cloned locally as a sibling of `cms-backend`.
2. `cms-database/prisma/schema.prisma` is the single source of truth for the schema; `cms-backend/prisma/` is deleted.
3. A fresh developer can spin up Postgres and apply the full schema with one command run from `cms-database/` (`pnpm install && pnpm db:migrate`).
4. The 4 baseline roles seed correctly via `pnpm db:seed` from `cms-database`.
5. An existing developer (live DB has tables but no `_cms_migrations`) can adopt the DB via `pnpm db:adopt`.
6. `cms-database` publishes `@khvip87/cms-database` to GitHub Packages on every `v*.*.*` tag; `cms-backend` installs it via `"@khvip87/cms-database": "^x.y.z"` in `package.json`.
7. `cms-backend` continues to read/write `User`, `Role`, `UserRole`, `Account`, `Article`, `ArticleTranslation`, `AuditLog` with no behavior change; all existing e2e tests pass.
8. `cms-database` CI runs lint + typecheck + migration apply against an ephemeral Postgres on every PR.
9. `cms-backend` CI authenticates to GitHub Packages and runs e2e tests against the schema applied by `cms-database`.
10. `PROJECT_MEMORY.md` and `cms-backend/README.md` are updated to direct future work to `cms-database/`.

## User stories

- **[CMS-11](https://khvip87.atlassian.net/browse/CMS-11)** — DB: scaffold `cms-database` GH repo (package, lint, `.npmrc`, `.env`).
- **[CMS-12](https://khvip87.atlassian.net/browse/CMS-12)** — DB: port schema + generate `0001_baseline` migration + implement `adopt` script.
- **[CMS-13](https://khvip87.atlassian.net/browse/CMS-13)** — DB: implement homegrown migration runner (`migrate`, `status`, `diff`, `_cms_migrations` table).
- **[CMS-14](https://khvip87.atlassian.net/browse/CMS-14)** — DB: port role seed into `seeds/shared/001_roles.ts`; idempotent.
- **[CMS-15](https://khvip87.atlassian.net/browse/CMS-15)** — DB: GH Actions `ci.yml` + `publish.yml` (publish `@khvip87/cms-database` to GitHub Packages on tag).
- **[CMS-16](https://khvip87.atlassian.net/browse/CMS-16)** — BE: rewire `cms-backend` to consume `@khvip87/cms-database` (rename Prisma → Database, delete `cms-backend/prisma`).
- **[CMS-17](https://khvip87.atlassian.net/browse/CMS-17)** — BE: `cms-backend` CI auth to GH Packages + e2e against migrated schema.
- **[CMS-18](https://khvip87.atlassian.net/browse/CMS-18)** — Docs: write feature doc + update `PROJECT_MEMORY` + `cms-backend` README redirect.

## Open questions

Locked in via plan-mode AskUserQuestion (see `C:\Users\khvip\.claude\plans\pm-agent-before-we-glowing-meadow.md`):

1. **Tooling:** Hybrid — `schema.prisma` as the modeling DSL inside `cms-database/`; deploy artifact is checked-in `.sql` generated via `prisma migrate diff`.
2. **Sequencing:** Pause CMS-1 entirely while CMS-10 runs. CMS-2 / CMS-3 freeze and rebase after.
3. **Repo home:** Own GitHub repo (`khvip87/cms-database`). No root workspace plumbing.
4. **Sharing model:** `cms-database` publishes `@khvip87/cms-database` to GitHub Packages on tag; `cms-backend` installs as a normal npm dep.
5. **Migration runner:** Homegrown ~150 LOC over `pg` with own `_cms_migrations` table and SHA-256 checksum drift detection.

Deferred to implementation:

- GH Packages auth: PAT vs. fine-grained token vs. organization-scoped install token (decided during CMS-15).
- Whether `cms-database` uses `pnpm` (default for consistency) or `npm` (only switch if a publish issue surfaces).
- Initial published version: `0.1.0`.
- Final name for the migration tracking table: currently `_cms_migrations`; alternative `cms_schema_migrations` if we want to drop the leading underscore.

## Technical Design

_To be expanded by @tech-lead. Summary of decisions captured in the approved plan at `C:\Users\khvip\.claude\plans\pm-agent-before-we-glowing-meadow.md`._

### Target layout

```
content-mng-sys/                      <- meta repo (gitignores all 3 children)
├── docker-compose.yml                <- unchanged (Postgres 16 + Redis 7)
├── .gitignore                        <- ADD: /cms-database
├── PROJECT_MEMORY.md                 <- updated to point at new schema home
├── docs/features/2-extract-cms-database/README.md   <- this doc
├── cms-backend/    (own GH repo, github.com/khvip87/cms-backend)
├── cms-frontend/   (own GH repo, github.com/khvip87/cms-frontend)
└── cms-database/   (own GH repo, github.com/khvip87/cms-database)   <- NEW
```

### `cms-database/` internal layout

```
cms-database/
├── package.json                      <- name: "@khvip87/cms-database", publishConfig -> GH Packages
├── tsconfig.json
├── README.md
├── .env.example                      <- DATABASE_URL, SHADOW_DATABASE_URL
├── .gitignore                        <- node_modules, src/generated/, dist/
├── .npmrc                            <- @khvip87:registry=https://npm.pkg.github.com
├── prisma/
│   └── schema.prisma                 <- single source of truth for models
├── migrations/
│   ├── 0001_baseline/
│   │   ├── up.sql                    <- full DDL of every current table
│   │   └── meta.json                 <- { name, author, checksum, createdAt }
│   └── README.md                     <- "How to add a new migration"
├── seeds/
│   ├── shared/001_roles.ts           <- idempotent, prod-safe (the 4 roles)
│   └── dev/                          <- dev-only fixtures (empty for now)
├── src/
│   ├── index.ts                      <- public package surface: DatabaseClient, Prisma, enums
│   ├── client.ts                     <- wraps generated PrismaClient
│   ├── runner/
│   │   ├── migrate.ts                <- forward-only ~150-LOC runner
│   │   ├── status.ts                 <- list applied/pending
│   │   ├── diff.ts                   <- wraps `prisma migrate diff`
│   │   ├── adopt.ts                  <- one-shot: marks live DB as at 0001_baseline
│   │   └── seed.ts                   <- runs seeds/shared/* (+ dev/* if flagged)
│   ├── cli.ts                        <- exposes `cms-db migrate|seed|adopt|...` bin
│   └── generated/                    <- prisma generate output, gitignored locally
├── dist/                             <- tsc output (published; includes generated/)
├── scripts/
│   └── new-migration.ts              <- scaffolds migrations/NNNN_<name>/ folder
└── .github/workflows/
    ├── ci.yml                        <- lint + typecheck + migrate against ephemeral PG
    └── publish.yml                   <- on tag v*.*.* -> build + publish to GH Packages
```

### Dev loops

**`cms-database` — schema change:**
```
edit prisma/schema.prisma
pnpm db:diff -- --name add_categories
  -> writes migrations/0003_add_categories/{up.sql, meta.json}
(hand-edit up.sql for triggers, FTS, backfills if needed)
pnpm db:migrate
pnpm db:seed
git commit; git tag v0.3.0; git push --tags
  -> publish.yml builds and pushes @khvip87/cms-database@0.3.0 to GH Packages
```

**`cms-backend` — pick up a new schema:**
```
edit package.json -> bump "@khvip87/cms-database" to ^0.3.0
pnpm install         (.npmrc provides GH Packages auth)
pnpm typecheck       (picks up the new types)
pnpm start:dev
```

### Migration of current state

The local Postgres has one on-disk migration in `_prisma_migrations` (the CMS-2 Article migration). The auth tables (User/Role/UserRole/Account/AuditLog) exist in the DB but have no on-disk migration — they were created during scaffold without a corresponding `prisma migrate dev` commit (confirmed by `cms-backend` git log).

Approach:

1. Re-baseline as one migration: copy `schema.prisma` verbatim; generate `migrations/0001_baseline/up.sql` via `prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma --script`.
2. `pnpm db:adopt` one-shot verifies every table named in the baseline exists in `information_schema.tables`; if so, inserts a single `_cms_migrations` row for `0001_baseline`.
3. Fresh databases run `pnpm db:migrate` and apply `0001_baseline/up.sql` normally.
4. Drop `_prisma_migrations` in a follow-up `0002_drop_prisma_migrations_table` migration after one sprint of safety net.

### `cms-backend` cutover

- Add `.npmrc` configured for `@khvip87` scope → GitHub Packages. CI uses `NODE_AUTH_TOKEN`; local devs authenticate once with a PAT.
- Drop `prisma` (devDep), `@prisma/client`, and the `prisma:*` scripts from `cms-backend/package.json`. Add `"@khvip87/cms-database": "^0.1.0"`.
- Rename `cms-backend/src/prisma/` → `cms-backend/src/database/`. `PrismaService` → `DatabaseService` (extends `DatabaseClient` re-exported from `@khvip87/cms-database`, same Nest lifecycle hooks).
- Grep-and-replace imports in `cms-backend/src/**` — today only `app.module.ts` and `auth/auth.service.ts` touch the old path.
- Delete `cms-backend/prisma/` entirely.

## Implementation checklist

### Database (@senior-be)

- [x] CMS-11 — Scaffold `cms-database` repo + package.json + .npmrc + lint/format (PR [#1](https://github.com/khvip87/cms-database/pull/1), Merged)
- [x] CMS-12 — Port `schema.prisma` + generate `0001_baseline/up.sql` + implement `adopt` (PR [#2](https://github.com/khvip87/cms-database/pull/2), Merged)
- [x] CMS-13 — Implement migration runner + `_cms_migrations` table + checksum drift guard (PR [#3](https://github.com/khvip87/cms-database/pull/3), In Review)
- [ ] CMS-14 — Port role seed into `seeds/shared/001_roles.ts`
- [ ] CMS-15 — GH Actions `ci.yml` + `publish.yml` to GitHub Packages

### Backend (@senior-be)

- [ ] CMS-16 — Install `@khvip87/cms-database`, rename Prisma→Database, delete `cms-backend/prisma/`
- [ ] CMS-17 — Wire `cms-backend` CI auth to GH Packages + e2e against migrated schema

### Docs (@pm + @tech-lead)

- [ ] CMS-18 — Feature doc finalized; `PROJECT_MEMORY.md` updated; `cms-backend/README.md` redirect

## Test plan

After all 8 stories merge and `@khvip87/cms-database@0.1.0` is published:

1. **Fresh-clone scenario.** Clone all three child repos into sibling folders on a clean machine. Bring Postgres up via the meta repo's `docker compose up -d`. Then:
   ```
   cd cms-database && pnpm install && pnpm db:migrate && pnpm db:seed
   cd ../cms-backend && pnpm install && pnpm start:dev
   ```
   Expected: backend boots; `GET /health` returns 200; the 4 roles exist; Article + ArticleTranslation tables exist; no `cms-backend/prisma/` directory present.

2. **Existing-dev scenario.** On the current machine (live DB has tables but no `_cms_migrations`): `cd cms-database && pnpm db:adopt` once. Verify a single row in `_cms_migrations` for `0001_baseline`. Then `cd ../cms-backend && pnpm test:e2e` — all existing tests pass.

3. **New-migration loop.** In `cms-database`, add a trivial column to `schema.prisma`. Run `pnpm db:diff -- --name add_test_column`. Verify `migrations/0002_add_test_column/up.sql` is generated and `pnpm db:migrate` applies it.

4. **Drift detection.** Manually edit an already-applied `up.sql`. Run `pnpm db:migrate`. Expected: runner aborts non-zero with a checksum-mismatch error.

5. **Publish path.** Tag `v0.2.0` in `cms-database`. `publish.yml` triggers, builds, and pushes `@khvip87/cms-database@0.2.0` to GH Packages. In `cms-backend`, bump `package.json` to `^0.2.0`; `pnpm install` pulls it; `pnpm typecheck` picks up the new types.

6. **CI gate.** Open a PR in `cms-database` with a broken SQL migration. Expected: `ci.yml`'s migrate step fails — no publish; `cms-backend` is unaffected because it pins a previous version.

## Rollout

- Feature flag: no (infrastructure refactor; no user-visible behavior change).
- Phased: all-at-once. The cutover lands in a single `cms-backend` PR (CMS-16) that swaps Prisma → `@khvip87/cms-database` and deletes `cms-backend/prisma/`. The new repo, runner, and publish workflow ship first (CMS-11..CMS-15) so `@khvip87/cms-database@0.1.0` exists before the backend depends on it.
- Pre-cutover: ensure all CMS-1 in-flight branches are either merged (CMS-2) or paused (CMS-3) so they can be rebased cleanly afterward.

## Notes / discussion

- 2026-05-17 — CMS-13 opened as PR [#3](https://github.com/khvip87/cms-database/pull/3) (In Review). Shipped the full homegrown runner CLI: `cms-db migrate | status | diff | new | adopt | seed`. All 8 ACs verified; 6/6 integration tests green against live Postgres using isolated per-test schemas. Two real bugs caught and fixed during verification: (a) CRLF-vs-LF checksum drift on Windows — fixed by LF-normalising input to `computeChecksum` and adding `.gitattributes` to pin working-tree line endings; (b) `prisma migrate diff` always emitted `DROP TABLE "_cms_migrations"` because the runner's tracking table isn't in `schema.prisma` — `diff.ts` now filters that statement out before writing migrations, otherwise every generated migration would have dropped the runner's own tracking table on apply.
- 2026-05-17 — CMS-12 merged via PR [#2](https://github.com/khvip87/cms-database/pull/2). Ported `schema.prisma` from `cms-backend`, generated `migrations/0001_baseline/up.sql` via `prisma migrate diff --from-empty`, and implemented the `adopt` one-shot. Verified end-to-end against the live Docker Postgres: adopt happy path, idempotency on re-run, and drift detection all green. Schema diff between `0001_baseline/up.sql` applied to a fresh Postgres and the `schema.prisma` source-of-truth is empty for every Prisma-managed entity — the only delta is `_cms_migrations`, which is intentional (runner-internal table not modelled in Prisma).
- 2026-05-17 — Docker Desktop had to be installed and started before live-DB verification of CMS-12 could happen (~10 min detour mid-story). Explains the gap between CMS-12 PR opening and merge timestamps.
- 2026-05-17 — User confirmed scope and sequencing: pause CMS-1 entirely, start CMS-10 immediately. CMS-2 (In Review) and CMS-3 (In Progress) freeze and rebase after extract lands.
- 2026-05-17 — Plan decisions locked in via AskUserQuestion: Hybrid tooling (Prisma DSL + checked-in SQL), own GH repo, publish `@khvip87/cms-database` to GitHub Packages, homegrown runner. See `C:\Users\khvip\.claude\plans\pm-agent-before-we-glowing-meadow.md`.
- 2026-05-17 — Discovered the three child repos (`cms-backend`, `cms-frontend`, `cms-database`) are intentionally independent — root `content-mng-sys/.gitignore` lists them, so no `pnpm-workspace.yaml` or root `package.json` is introduced.
- 2026-05-17 — Package name changed from `@cms/database` to `@khvip87/cms-database`. GitHub Packages requires the npm scope to match the repo owner (`khvip87`); a free `cms` GitHub org was considered but ruled out for now. CMS-11 scaffold uses `@khvip87/cms-database`; CMS-12..18 follow.
