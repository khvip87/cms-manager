---
name: be-scaffold-module
description: Senior BE-only. Scaffold a new NestJS module inside cms-backend with the canonical layout (module, controller, service, DTOs, tests). Invoke when starting work on a feature that has no existing module.
---

Scaffold a new NestJS module in `cms-backend/`.

## Inputs
- `featureName` — lowercase kebab (e.g., `articles`, `media`, `users`). Must match the route path and (typically) the Prisma model namespace.

## Execution — prefer the Nest CLI

From inside `cms-backend/`:

```powershell
pnpm exec nest g module modules/<featureName>
pnpm exec nest g controller modules/<featureName> --no-spec
pnpm exec nest g service modules/<featureName> --no-spec
```

This generates the boilerplate and auto-registers the module in `src/app.module.ts`.

Then create DTOs and a spec file manually using the templates below.

## Resulting layout

```
cms-backend/src/modules/<featureName>/
├── <featureName>.module.ts
├── <featureName>.controller.ts
├── <featureName>.service.ts
├── dto/
│   ├── create-<featureName>.dto.ts
│   └── update-<featureName>.dto.ts
└── <featureName>.controller.spec.ts
```

## File templates

### `dto/create-<featureName>.dto.ts`
```ts
import { z } from 'zod'
import { createZodDto } from 'nestjs-zod'

export const Create<FeatureName>Schema = z.object({
  // TODO
})

export class Create<FeatureName>Dto extends createZodDto(Create<FeatureName>Schema) {}
```

### `dto/update-<featureName>.dto.ts`
```ts
import { z } from 'zod'
import { createZodDto } from 'nestjs-zod'
import { Create<FeatureName>Schema } from './create-<featureName>.dto'

export const Update<FeatureName>Schema = Create<FeatureName>Schema.partial()
export class Update<FeatureName>Dto extends createZodDto(Update<FeatureName>Schema) {}
```

### `<featureName>.controller.ts`
```ts
import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common'
import { ApiTags, ApiOperation } from '@nestjs/swagger'
import { AuthGuard } from '../../auth/auth.guard'
import { RolesGuard } from '../../auth/roles.guard'
import { Roles } from '../../auth/roles.decorator'
import { <FeatureName>Service } from './<featureName>.service'
import { Create<FeatureName>Dto } from './dto/create-<featureName>.dto'

@ApiTags('<featureName>')
@Controller('<featureName>')
@UseGuards(AuthGuard, RolesGuard)
export class <FeatureName>Controller {
  constructor(private readonly service: <FeatureName>Service) {}

  @Post()
  @Roles('editor')
  @ApiOperation({ summary: 'Create <featureName>' })
  create(@Body() dto: Create<FeatureName>Dto) {
    return this.service.create(dto)
  }
}
```

### `<featureName>.service.ts`
```ts
import { Injectable } from '@nestjs/common'
import { PrismaService } from '../../prisma/prisma.service'

@Injectable()
export class <FeatureName>Service {
  constructor(private readonly prisma: PrismaService) {}

  // TODO
}
```

### `<featureName>.controller.spec.ts`
```ts
import { Test } from '@nestjs/testing'
import { <FeatureName>Controller } from './<featureName>.controller'
import { <FeatureName>Service } from './<featureName>.service'

describe('<FeatureName>Controller', () => {
  let controller: <FeatureName>Controller

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      controllers: [<FeatureName>Controller],
      providers: [{ provide: <FeatureName>Service, useValue: {} }],
    }).compile()
    controller = module.get(<FeatureName>Controller)
  })

  it('compiles', () => {
    expect(controller).toBeDefined()
  })
})
```

## After scaffolding
- Verify `app.module.ts` now imports `<FeatureName>Module`.
- If the feature has a Prisma model, edit `prisma/schema.prisma` then invoke `be-create-migration`.
- Mention any new module in the BE checklist of the feature doc.
