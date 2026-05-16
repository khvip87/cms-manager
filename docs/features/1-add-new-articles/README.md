# Article authoring — create new articles

**Jira:** [CMS-1](https://khvip87.atlassian.net/browse/CMS-1)
**Status:** Draft
**Owners:** @pm · @tech-lead · @senior-fe · @senior-be

## Context

The CMS today has no way for an editor to create an article from inside the app. We have the auth and i18n primitives in place (NextAuth JWT, i18next, Prisma + Postgres), but no article model, no API, and no editor UI. Editors currently have no path to produce content, which blocks every downstream feature (publishing workflows, media embedding, the public reader, search).

This epic delivers the first usable authoring path end-to-end: a data model with translatable fields, a small set of REST endpoints to create / read / update / publish / unpublish / soft-delete an article, and the corresponding Next.js pages for listing and editing. It is intentionally minimal — Markdown body only, one translation at create time, no role-based gating — so we can ship and iterate.

It is the foundation for later epics: multi-locale translation management, a JSONB component-tree editor, media embedding, scheduled publishing, and editorial review workflows.

## Goals

- An authenticated user can create a new article in one locale via a simple form.
- An authenticated user can list, view, edit, publish, unpublish, and soft-delete articles.
- Articles have a stable identity separate from their translations, so the same article can carry multiple locale variants later.
- Slugs are unique per locale and auto-generated from the title (overridable).
- The CMS UI loads its strings via the existing i18next per-component namespace pattern.
- Endpoints are documented in Swagger (dev only) and reject unauthenticated requests with `401`.

## Non-goals

- Role-based authorization (any authenticated user can do everything in this epic — role gating is a later epic).
- Multi-locale create / translation management API (`POST /articles/:id/translations`) — only the initial translation at create time is supported here.
- Rich JSONB component-tree editor — the body is plain Markdown for this epic.
- Media library, image upload, or media embedding.
- Scheduled publishing, draft autosave, revision history, or editorial review.
- Public reader site or any unauthenticated read access.
- Hard delete UI / endpoints.
- Full-text search of articles.

## Acceptance criteria (epic-level definition of done)

1. Given an authenticated user, when they navigate to `/articles/new`, fill in title and Markdown body, and submit, then a new article and its initial translation are persisted and they are redirected to the edit page.
2. Given an authenticated user, when they visit `/articles`, then they see a paginated list of non-soft-deleted articles filterable by status (Draft / Published).
3. Given an authenticated user on the edit page, when they click Publish or Unpublish, then the article status flips and the change is reflected in the list view.
4. Given an authenticated user on the edit page, when they delete an article, then it disappears from list and detail views and subsequent GETs return `404`.
5. Given an unauthenticated request to any `/articles*` endpoint, then the response is `401`.
6. Given two articles in the same locale, when both try to use the same slug, then the second create/update fails with a validation error (per-locale slug uniqueness).
7. All endpoints are listed in the Swagger UI in dev with request/response schemas.
8. All FE strings load via a lazy `articles` i18n namespace; no hardcoded user-facing copy.

## User stories

<!-- Replace CMS-STORY-N-TBD with the real Jira key once tickets are created. -->

- **[CMS-2](https://khvip87.atlassian.net/browse/CMS-2)** — BE: add `Article` + `ArticleTranslation` Prisma schema and migration (includes `deletedAt`).
- **[CMS-3](https://khvip87.atlassian.net/browse/CMS-3)** — BE: add `POST /articles` (create with initial translation).
- **[CMS-4](https://khvip87.atlassian.net/browse/CMS-4)** — BE: add `GET /articles/:id`, `GET /articles` (paginated, status filter), and `PATCH /articles/:id`.
- **[CMS-5](https://khvip87.atlassian.net/browse/CMS-5)** — BE: add `POST /articles/:id/publish` and `POST /articles/:id/unpublish`.
- **[CMS-6](https://khvip87.atlassian.net/browse/CMS-6)** — FE: add `/articles` list page (TanStack Query, lazy i18n namespace).
- **[CMS-7](https://khvip87.atlassian.net/browse/CMS-7)** — FE: add `/articles/new` create form (Markdown body, slug auto-from-title).
- **[CMS-8](https://khvip87.atlassian.net/browse/CMS-8)** — FE: add `/articles/:id/edit` page with publish/unpublish actions.
- **[CMS-9](https://khvip87.atlassian.net/browse/CMS-9)** — BE: add `DELETE /articles/:id` soft delete.

## Open questions

All five questions raised by PM in the prior session are resolved:

1. **Body editor:** Markdown for this epic; JSONB component tree deferred.
2. **Authorization:** Any authenticated user; no role gating in this epic.
3. **Multi-locale on create:** Deferred to a later epic; only one translation at create time.
4. **Slug uniqueness:** Per locale (`(locale, slug)` unique).
5. **Soft delete:** Added as Story 8; `Article.deletedAt` nullable added to Story 1.

No remaining open questions for this epic. Any new questions surfaced by the Tech Lead during decomposition should be appended below.

## Technical Design

_To be written by @tech-lead — see `tech-design-stub` skill._

## Implementation checklist

### Frontend (@senior-fe)

- [ ] `/articles` list page wired to `GET /articles`
- [ ] `/articles/new` form wired to `POST /articles`
- [ ] `/articles/:id/edit` form wired to `GET /articles/:id` + `PATCH /articles/:id`
- [ ] Publish / Unpublish actions on edit page
- [ ] Soft-delete action on edit page (and/or list row)
- [ ] `articles` i18n namespace JSON files
- [ ] Slug auto-generation from title in the create form
- [ ] Empty / loading / error states for list and forms

### Backend (@senior-be)

- [ ] `Article` + `ArticleTranslation` Prisma models (including `Article.deletedAt`)
- [ ] Generated migration committed and verified
- [ ] `POST /articles` (zod-validated DTO)
- [ ] `GET /articles` paginated + status filter
- [ ] `GET /articles/:id`
- [ ] `PATCH /articles/:id`
- [ ] `POST /articles/:id/publish`
- [ ] `POST /articles/:id/unpublish`
- [ ] `DELETE /articles/:id` soft delete
- [ ] Per-locale `(locale, slug)` unique constraint enforced + 409/422 on conflict
- [ ] JWT auth guard on all `/articles*` routes
- [ ] Swagger docs for all endpoints (dev only)

## Test plan

_Filled in by Tech Lead and dev agents._

## Rollout

- Feature flag: no (foundational; no existing users yet)
- Phased: all-at-once (no public exposure until later epic ships the reader)

## Notes / discussion

- 2026-05-16 — PM: User confirmed scope choices (answers 1–5 above). Epic and 8 stories drafted; soft delete added as Story 8; `Article.deletedAt` rolled into Story 1's schema/migration.
- 2026-05-16 — PM: Jira tickets could not be created in this session because the `@sooperset/mcp-atlassian` MCP server was not active. Drafts are listed in this doc and attached below for re-creation once the MCP is online.

---

## Appendix: Jira ticket drafts (to be created via `jira-create-ticket`)

These are the exact payloads to feed into `jira-create-ticket` once the Atlassian MCP is connected. Replace `CMS-EPIC-TBD` in each child story's `parentKey` with the real epic key Jira returns.

### Epic — Article authoring — create new articles

- **issueType:** Epic
- **summary:** Article authoring — create new articles
- **labels:** `["cms", "cross-repo"]`
- **description:**
  ```markdown
  Foundational authoring epic: data model, REST endpoints, and Next.js UI to create / read / update / publish / unpublish / soft-delete articles. Markdown body only for this epic; one translation at create time; any authenticated user can perform all actions (no role gating).

  ## Definition of done
  1. All 8 child stories are Done.
  2. An authenticated user can complete the full flow end-to-end in the running app: create, list, edit, publish, unpublish, soft-delete.
  3. Unauthenticated requests to `/articles*` return `401`.
  4. Slug uniqueness is enforced per `(locale, slug)`.
  5. Swagger lists all article endpoints in dev.
  6. FE strings load via the lazy `articles` i18n namespace; no hardcoded user-facing copy.
  7. Feature doc `docs/features/<id>-add-new-articles/README.md` is updated with the Tech Lead's Technical Design section.

  ## Non-goals
  Role-based authorization, multi-locale translation management API, JSONB component-tree editor, media embedding, scheduled publishing, drafts/autosave, revision history, search.
  ```

### Story 1 — BE: add Article + ArticleTranslation schema and migration

- **issueType:** Story
- **parentKey:** `<epic key>`
- **summary:** BE: add Article + ArticleTranslation Prisma schema and migration
- **labels:** `["cms", "backend"]`
- **description:**
  ```markdown
  Add the `Article` and `ArticleTranslation` Prisma models and the generated migration. Article holds identity + status + soft-delete; ArticleTranslation holds locale-scoped fields (title, slug, body).

  ## Acceptance Criteria
  1. Given the migration is applied, when inspecting the `articles` table, then it has columns `id` (uuid, pk), `status` (enum: `DRAFT` | `PUBLISHED`, default `DRAFT`), `created_at`, `updated_at`, `published_at` (nullable), `deleted_at` (nullable timestamp, default `null`).
  2. Given the migration is applied, when inspecting the `article_translations` table, then it has columns `id` (uuid, pk), `article_id` (fk → articles.id, cascade delete), `locale` (string, e.g. `en`), `title` (string, required), `slug` (string, required), `body` (text, Markdown), `created_at`, `updated_at`.
  3. Given two translations of different articles in the same locale, when both use the same slug, then a unique constraint on `(locale, slug)` rejects the second one.
  4. Given a translation row, when the same `(article_id, locale)` pair already exists, then a unique constraint rejects the duplicate.
  5. Given the Prisma schema, when `prisma validate` is run, then it passes.
  6. The migration is generated via the `be-create-migration` skill (named per project convention) and committed alongside the schema change.
  ```

### Story 2 — BE: add POST /articles

- **issueType:** Story
- **parentKey:** `<epic key>`
- **summary:** BE: add POST /articles (create with initial translation)
- **labels:** `["cms", "backend"]`
- **description:**
  ```markdown
  Create an article and its first translation in one request.

  ## Acceptance Criteria
  1. Given an authenticated user, when they `POST /articles` with `{ locale, title, slug?, body }`, then an `Article` row and one `ArticleTranslation` row are created and `201` is returned with the new article id and the translation.
  2. Given the request omits `slug`, when the article is created, then `slug` is derived from `title` (lowercase, kebab-case, non-ASCII transliterated where reasonable).
  3. Given a translation already exists for the requested `(locale, slug)`, when the create is attempted, then the response is `409` (or `422`) with a clear error message; nothing is persisted.
  4. Given an unauthenticated request, when posted, then the response is `401`.
  5. Given an invalid body (missing required fields, empty title, unsupported locale shape), then the response is `400` with zod validation details.
  6. The endpoint appears in Swagger with request/response schemas in dev.
  7. The new article's status defaults to `DRAFT`; `publishedAt` is `null`.
  ```

### Story 3 — BE: add GET /articles, GET /articles/:id, PATCH /articles/:id

- **issueType:** Story
- **parentKey:** `<epic key>`
- **summary:** BE: add GET /articles, GET /articles/:id, PATCH /articles/:id
- **labels:** `["cms", "backend"]`
- **description:**
  ```markdown
  Read and update endpoints for articles.

  ## Acceptance Criteria
  1. Given an authenticated user, when they `GET /articles?page=&pageSize=&status=`, then a paginated list is returned with `{ items, page, pageSize, total }`; soft-deleted articles are excluded.
  2. Given `status=DRAFT` or `status=PUBLISHED`, the list is filtered accordingly. Given no `status`, both are returned.
  3. Given an authenticated user, when they `GET /articles/:id`, then the article and its translations are returned. If the article is soft-deleted or unknown, the response is `404`.
  4. Given an authenticated user, when they `PATCH /articles/:id` with a partial body (title, slug, body, locale-scoped fields), then the matching translation is updated and `200` is returned with the updated article.
  5. Given a `PATCH` that would violate `(locale, slug)` uniqueness, then the response is `409`/`422` and no write happens.
  6. Given an unauthenticated request to any of these endpoints, the response is `401`.
  7. All three endpoints appear in Swagger in dev.
  ```

### Story 4 — BE: add publish and unpublish endpoints

- **issueType:** Story
- **parentKey:** `<epic key>`
- **summary:** BE: add POST /articles/:id/publish and /unpublish
- **labels:** `["cms", "backend"]`
- **description:**
  ```markdown
  Toggle the article between `DRAFT` and `PUBLISHED`.

  ## Acceptance Criteria
  1. Given an authenticated user and an article in `DRAFT`, when they `POST /articles/:id/publish`, then status becomes `PUBLISHED`, `publishedAt` is set to now, and `200` is returned with the updated article.
  2. Given an article already `PUBLISHED`, when publish is called again, then the call is idempotent (`200`, no change to `publishedAt`).
  3. Given an authenticated user and an article in `PUBLISHED`, when they `POST /articles/:id/unpublish`, then status becomes `DRAFT`, `publishedAt` is cleared (`null`), and `200` is returned.
  4. Given an article already `DRAFT`, when unpublish is called, then the call is idempotent (`200`).
  5. Given a soft-deleted or unknown id, the response is `404`.
  6. Given an unauthenticated request, the response is `401`.
  7. Both endpoints appear in Swagger in dev.
  ```

### Story 5 — FE: add /articles list page

- **issueType:** Story
- **parentKey:** `<epic key>`
- **summary:** FE: add /articles list page (TanStack Query, lazy i18n namespace)
- **labels:** `["cms", "frontend"]`
- **description:**
  ```markdown
  Authenticated list view of articles with pagination and status filter.

  ## Acceptance Criteria
  1. Given an authenticated user, when they visit `/articles`, then they see a paginated list of articles from `GET /articles` rendered with TanStack Query.
  2. The page exposes a status filter (All / Draft / Published) that calls the backend with the `status` query param.
  3. The page exposes pagination controls (next / previous, current page indicator) backed by `page` / `pageSize` query params.
  4. Loading, empty (no articles), and error states are rendered (no raw spinners or unhandled errors).
  5. All user-facing strings come from a lazy `articles` i18next namespace (HTTP-loaded JSON), not hardcoded.
  6. Each row links to `/articles/:id/edit`.
  7. A "New article" button links to `/articles/new`.
  8. Unauthenticated visitors are redirected by the existing next-auth guard.
  ```

### Story 6 — FE: add /articles/new create form

- **issueType:** Story
- **parentKey:** `<epic key>`
- **summary:** FE: add /articles/new create form (Markdown body, slug auto-from-title)
- **labels:** `["cms", "frontend"]`
- **description:**
  ```markdown
  Form to create a new article in a single locale.

  ## Acceptance Criteria
  1. Given an authenticated user on `/articles/new`, when they fill `locale`, `title`, optional `slug`, and Markdown `body` and submit, then `POST /articles` is called and on success the user is redirected to `/articles/:id/edit`.
  2. As the user types in `title`, the `slug` field auto-fills with a kebab-case derivation; if the user manually edits `slug`, auto-fill stops.
  3. Given a `409`/`422` slug-conflict response, the form surfaces a clear inline error on the `slug` field and does not navigate away.
  4. Given a network or `500` error, an error toast/banner is shown; form state is preserved.
  5. The body input is a Markdown textarea (no rich component-tree editor in this epic); a hint indicates "Markdown supported".
  6. All strings are loaded via the lazy `articles` i18n namespace.
  7. Submit button is disabled while the request is in flight.
  8. Unauthenticated visitors are redirected by the existing next-auth guard.
  ```

### Story 7 — FE: add /articles/:id/edit page with publish/unpublish

- **issueType:** Story
- **parentKey:** `<epic key>`
- **summary:** FE: add /articles/:id/edit page with publish/unpublish actions
- **labels:** `["cms", "frontend"]`
- **description:**
  ```markdown
  Edit existing article fields and toggle published state.

  ## Acceptance Criteria
  1. Given an authenticated user on `/articles/:id/edit`, when the page loads, then `GET /articles/:id` is called and the form is populated with the current title, slug, and Markdown body for the article's translation.
  2. Given the user edits fields and clicks Save, then `PATCH /articles/:id` is called and a success toast is shown on `200`.
  3. Given the article is `DRAFT`, the page shows a "Publish" button that calls `POST /articles/:id/publish` and updates the visible status on success.
  4. Given the article is `PUBLISHED`, the page shows an "Unpublish" button that calls `POST /articles/:id/unpublish`.
  5. The page shows a "Delete" action that calls `DELETE /articles/:id` (soft delete) after a confirm dialog; on success the user is redirected to `/articles`.
  6. Given the article id is unknown or soft-deleted (`404`), the page shows a "Not found" empty state.
  7. All strings are loaded via the lazy `articles` i18n namespace.
  8. Unauthenticated visitors are redirected by the existing next-auth guard.
  ```

### Story 8 — BE: add DELETE /articles/:id (soft delete)

- **issueType:** Story
- **parentKey:** `<epic key>`
- **summary:** BE: add DELETE /articles/:id (soft delete)
- **labels:** `["cms", "backend"]`
- **description:**
  ```markdown
  Soft-delete an article by marking `deletedAt`. Hides it from list and detail endpoints without dropping the row.

  ## Acceptance Criteria
  1. Given an authenticated user, when they `DELETE /articles/:id` on an existing non-deleted article, then `articles.deleted_at` is set to now and `204` (or `200` with the updated article) is returned.
  2. After soft-delete, `GET /articles` does not include the article in its results.
  3. After soft-delete, `GET /articles/:id` returns `404`.
  4. Given the article is already soft-deleted, when delete is called again, then the call is idempotent — response is the same as if it had just been deleted (no error), and `deleted_at` is not advanced.
  5. Given an unknown id, the response is `404`.
  6. Given an unauthenticated request, the response is `401`.
  7. Endpoint appears in Swagger in dev.
  ```
