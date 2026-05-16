---
name: be-run-checks
description: Senior BE-only. Run lint, typecheck, tests, and Prisma schema validation for cms-backend. Invoke before opening a PR and after significant changes. Never skip failures.
---

Run all quality checks in `cms-backend/`.

## Commands

From `cms-backend/`:

```powershell
pnpm lint
pnpm typecheck
pnpm test
pnpm exec prisma validate
pnpm exec prisma migrate status
```

`prisma migrate status` should report "Database schema is up to date!" — if it lists pending migrations, generate them via `be-create-migration` before opening the PR.

If the scripts don't exist yet, add to `package.json`:

```jsonc
{
  "scripts": {
    "lint": "eslint \"{src,test}/**/*.ts\"",
    "typecheck": "tsc --noEmit",
    "test": "jest"
  }
}
```

## Failure handling

- **Never** bypass with `--no-verify`, skip flags, or `@ts-ignore` / `eslint-disable` without an inline comment that explains *why*.
- **Lint errors:** `pnpm lint --fix` for autofixable rules; manually fix the rest.
- **Typecheck errors:** read, narrow, fix. Do **not** introduce `any`.
- **Test failures:** fix the underlying issue or update the test with justification.
- **Prisma validation errors:** the schema is invalid — fix `prisma/schema.prisma` before migrating.
- **Pending migrations:** run `be-create-migration` with an appropriate slug.

## After a clean run
- Report green status to the calling agent.
- Proceed to PR creation.
