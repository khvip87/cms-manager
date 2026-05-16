---
name: tech-design-stub
description: Tech Lead-only. Generate the Technical Design section to append to a feature doc. Invoke after PM has written the user-facing sections and before sub-tasks are created.
---

Produce a Technical Design section for a feature doc. Append, do not replace.

## Template

```markdown
## Technical Design

### Data model changes

```prisma
// Added:
model Foo {
  id        String   @id @default(cuid())
  …
  createdAt DateTime @default(now())
}

// Changed:
// + new field `Foo.bar`
```

If translatable: also show the `FooTranslation` table with `(fooId, locale)` composite PK.

### Migration plan
- **Name:** `<slug>` (verb_entity, e.g. `add_foos_table`)
- **Forward:** `pnpm exec prisma migrate dev --name <slug>`
- **Reversible:** yes / no — if no, document rollback strategy
- **Data backfill:** yes / no — if yes, describe SQL or script

### API surface

| Method | Path | Auth (min role) | Body | Response | Description |
|---|---|---|---|---|---|
| POST | /foos | editor | CreateFooDto | FooDto | Create draft |
| PATCH | /foos/:id/publish | editor | — | FooDto | Transition to PUBLISHED |
| GET | /foos | viewer | query: filters | FooListDto | List with pagination |

### WebSocket events (only if real-time needed)

| Event | Direction | Payload | Triggered by |
|---|---|---|---|
| `foo:published` | server→client | `{ fooId: string }` | Successful publish mutation |

### Frontend state implications
- Redux slice: <added foosSlice / none>
- TanStack Query keys: `['foos', filters]`, `['foos', 'detail', id]`
- New i18n namespace: `foos.json` (per-locale)
- New routes: `/[locale]/foos`, `/[locale]/foos/[id]`

### Test plan
- **Unit (BE):** service methods, validation errors, RBAC denials.
- **Unit (FE):** slice reducers, query hook contract.
- **Integration (BE):** controller → service → DB with a test Postgres instance.
- **Integration (FE):** component renders given mocked query response.
- **E2E (if applicable):** Playwright scenario for the AC.

### Rollout / rollback
- Feature flag: yes / no — if yes, name it (e.g., `foos.publish.v1`)
- Rollback steps: <e.g., revert migration with `prisma migrate resolve`, redeploy previous tag>
```

## Notes

- This section is owned by the Tech Lead. Senior FE/BE may add notes during implementation but do not change the API surface or schema without escalating.
- If a section is genuinely N/A (e.g., no websocket events), write `_None._` rather than deleting the section — keeps the doc consistent across features.
