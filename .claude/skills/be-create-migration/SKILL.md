---
name: be-create-migration
description: Senior BE-only. Generate a Prisma migration with the project naming convention after editing prisma/schema.prisma. Verifies the generated SQL before committing. NEVER use prisma db push in shared environments.
---

Generate a reviewable Prisma migration.

## Naming convention
Slug format: `<verb>_<entity_or_change>` — all lowercase, underscores, no spaces.

Examples:
- `add_articles_table`
- `add_publish_status_to_articles`
- `rename_users_email_to_email_address`
- `drop_legacy_categories`

## Execution

From `cms-backend/`:

```powershell
pnpm exec prisma migrate dev --name <slug>
```

This:
1. Applies pending schema changes to the dev database.
2. Generates `prisma/migrations/<timestamp>_<slug>/migration.sql`.
3. Regenerates the Prisma Client.

## Post-generation checklist

1. **Open the generated SQL file and read it.**
2. Verify rename operations are actually `ALTER ... RENAME ...` and not `DROP + CREATE` (which would lose data). Prisma sometimes guesses wrong on renames — edit the SQL before committing if so.
3. Verify index choices: foreign keys generate indexes automatically; composite indexes from `@@index([…])` are explicit.
4. If the migration includes a data backfill, add a `prisma/migrations/<timestamp>_<slug>/backfill.sql` next to `migration.sql` and reference it in the feature doc's migration plan.

## Hard rules

- Never run `prisma db push` in shared environments (staging, prod, or any env other than the dev's local). It bypasses migrations and creates drift.
- Never edit a migration that has been merged. If wrong, create a corrective migration that fixes the issue forward.
- Never commit a migration without running `pnpm exec prisma migrate status` and confirming it's the latest.
