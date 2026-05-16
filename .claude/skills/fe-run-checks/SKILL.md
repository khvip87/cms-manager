---
name: fe-run-checks
description: Senior FE-only. Run lint, typecheck, and tests for cms-frontend. Invoke before opening a PR and after significant changes. Never skip failures.
---

Run all quality checks in `cms-frontend/`.

## Commands

From `cms-frontend/`:

```powershell
pnpm lint
pnpm typecheck
pnpm test
```

If these scripts don't exist yet, add them to `package.json`:

```jsonc
{
  "scripts": {
    "lint": "next lint",
    "typecheck": "tsc --noEmit",
    "test": "vitest run"
  }
}
```

## Failure handling

- **Never** bypass with `--no-verify`, `-- --no-tests`, or `@ts-ignore` / `eslint-disable` without an inline comment that explains *why* (and references a tracking ticket).
- **Lint errors:** `pnpm lint --fix` for autofix-eligible rules; manually fix the rest.
- **Typecheck errors:** read the error, narrow the type. Do **not** introduce `any` to silence.
- **Test failures:** read the failure. If a real bug, fix it. If the test is outdated (genuine assertion shift), update the test and explain why in the commit message.

## After a clean run
- Report green status to the calling agent.
- Proceed to PR creation.
