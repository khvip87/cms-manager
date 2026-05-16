---
name: fe-scaffold-feature
description: Senior FE-only. Scaffold a new feature folder inside cms-frontend with the canonical layout (components, queries, slice, types, i18n namespace JSON). Invoke when starting work on a feature that has no existing folder.
---

Scaffold a new feature in `cms-frontend/`.

## Inputs
- `featureName` — lowercase kebab (e.g., `article-editor`, `media-library`). MUST match the i18n namespace.
- `needsClientState` — boolean. If `true`, create `slice.ts`. Otherwise omit it.

## Files to create

```
cms-frontend/src/features/<featureName>/
├── components/
│   ├── index.ts                  ← barrel
│   └── .gitkeep
├── queries.ts                    ← TanStack Query hooks
├── slice.ts                      ← ONLY if needsClientState
├── types.ts                      ← shared TS types
└── index.ts                      ← top-level barrel

cms-frontend/public/locales/en/<featureName>.json   ← contents: {}
cms-frontend/public/locales/ar/<featureName>.json   ← contents: {}
```

## File templates

### `queries.ts`
```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

const queryKeys = {
  all: ['<featureName>'] as const,
  list: (filters?: unknown) => ['<featureName>', 'list', filters] as const,
  detail: (id: string) => ['<featureName>', 'detail', id] as const,
}

// TODO: replace stubs with real API calls
```

### `slice.ts` (if needsClientState)
```ts
import { createSlice } from '@reduxjs/toolkit'

interface State {
  // TODO
}

const initialState: State = {}

const slice = createSlice({
  name: '<featureName>',
  initialState,
  reducers: {
    // TODO
  },
})

export const { actions, reducer } = slice
```

### `types.ts`
```ts
// Shared types for the <featureName> feature
```

### `index.ts` (top-level barrel)
```ts
export * from './components'
export * from './queries'
export * from './types'
```

### `components/index.ts`
```ts
// re-export components as you add them
```

### `public/locales/{en,ar}/<featureName>.json`
```json
{}
```

## After scaffolding

- If `needsClientState`, register the reducer in `src/store/index.ts` under the same `<featureName>` key.
- The i18n namespace JSON files are auto-discovered by `i18next-http-backend` at runtime — no other registration needed.
- Mention any new feature folder in the FE checklist of the feature doc.
