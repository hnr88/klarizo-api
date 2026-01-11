# CLAUDE.md - klarizo-api (Backend)

This file provides guidance to Claude Code when working with the klarizo-api backend.

## CRITICAL RULES - VIOLATION MEANS FAILURE

1. **DO EXACTLY WHAT IS ASKED** - Zero extras, zero nice-to-haves. User asks for A, deliver A. NOT A+B.
2. **THINK 3X, DO 1X** - Triple check every line before writing. No exceptions.
3. **NEVER BREAK EXISTING LOGIC** - Preserve all functionality when making changes.
4. **NEVER CHANGE ANYTHING NOT EXPLICITLY REQUESTED** - Fix routes = fix ONLY routes. Fix schema = fix ONLY schema.
5. **WHEN IN DOUBT, ASK** - Better to clarify than break working code. Never assume.

---

## Tech Stack

- **Framework**: Strapi v5.33.2
- **Database**: PostgreSQL
- **Node.js**: >=20.0.0 <=24.x.x
- **Package Manager**: pnpm (NEVER use npm or yarn)
- **Admin Panel**: React 18

---

## Project Structure

```
.
├── config/
│   ├── admin.js              # Admin panel configuration
│   ├── api.js                # API configuration
│   ├── database.js           # Database connections
│   ├── middlewares.js        # Middleware configuration
│   ├── plugins.js            # Plugin settings
│   └── server.js             # Server config (CORS, host, port)
├── database/
│   └── migrations/           # Database migration files
├── src/
│   ├── admin/                # Admin panel extensions
│   ├── api/                  # API content types & controllers
│   │   └── [content-type]/   # Individual content-type folders
│   ├── extensions/           # Extensions (services, middlewares)
│   ├── plugins/              # Custom plugins
│   └── index.js              # Application bootstrap
├── public/
│   └── uploads/              # Media uploads
├── types/                    # TypeScript type definitions
├── .env                      # Environment variables
└── package.json              # Dependencies & scripts
```

---

## Content-Type Structure

```
src/api/[content-type]/
├── content-types/
│   └── [content-type]/
│       ├── schema.json       # Schema definition
│       └── lifecycles.js     # Lifecycle hooks (optional)
├── controllers/
│   └── [content-type].js     # Custom controllers
├── routes/
│   └── [content-type].js     # Route definitions
├── services/
│   └── [content-type].js     # Business logic
├── middlewares/              # Custom middlewares (optional)
└── policies/                 # Custom policies (optional)
```

---

## Strapi v5 Patterns

### Controller Pattern (createCoreController)

```javascript
'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::article.article', ({ strapi }) => ({
  // Custom action
  async customAction(ctx) {
    const sanitizedQuery = await this.sanitizeQuery(ctx);
    const results = await strapi.documents('api::article.article').findMany(sanitizedQuery);
    const sanitizedResults = await this.sanitizeOutput(results, ctx);
    return this.transformResponse(sanitizedResults);
  },

  // Wrap core action
  async find(ctx) {
    const { data, meta } = await super.find(ctx);
    // Add custom logic here
    return { data, meta };
  },
}));
```

### Service Pattern (createCoreService)

```javascript
'use strict';

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::article.article', ({ strapi }) => ({
  async customMethod(params) {
    // Use Document Service API
    const result = await strapi.documents('api::article.article').findMany({
      filters: params.filters,
      populate: params.populate,
    });
    return result;
  },
}));
```

### Document Service API (Strapi v5)

The Document Service API replaces Entity Service from v4. Documents use `documentId` (24-char string), not `id`.

```javascript
// Access via strapi.documents()
const documentService = strapi.documents('api::article.article');

// Find documents
const articles = await documentService.findMany({
  filters: { title: { $contains: 'hello' } },
  populate: ['author', 'category'],
  sort: { createdAt: 'desc' },
  pagination: { page: 1, pageSize: 10 },
  locale: 'en',
  status: 'published', // 'draft' or 'published'
});

// Find one
const article = await documentService.findOne({
  documentId: 'abc123def456ghi789jkl012',
  populate: '*',
});

// Create
const newArticle = await documentService.create({
  data: { title: 'New Article', content: 'Content here' },
  status: 'draft', // or 'published'
});

// Update
const updated = await documentService.update({
  documentId: 'abc123def456ghi789jkl012',
  data: { title: 'Updated Title' },
});

// Delete
await documentService.delete({
  documentId: 'abc123def456ghi789jkl012',
});

// Publish/Unpublish (Draft & Publish enabled)
await documentService.publish({ documentId: 'abc123' });
await documentService.unpublish({ documentId: 'abc123' });
```

### Routes Pattern

**Core Router:**
```javascript
'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::article.article', {
  config: {
    find: {
      auth: false, // Public route
      policies: [],
      middlewares: [],
    },
  },
});
```

**Custom Router:**
```javascript
// Name file with prefix for ordering: 01-custom-article.js
module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/articles/featured',
      handler: 'api::article.article.featured',
      config: {
        auth: false,
        policies: [],
      },
    },
  ],
};
```

### Lifecycle Hooks

```javascript
// src/api/article/content-types/article/lifecycles.js
module.exports = {
  async beforeCreate(event) {
    const { data } = event.params;
    // Modify data before creation
  },

  async afterCreate(event) {
    const { result } = event;
    // Trigger actions after creation
  },

  async beforeUpdate(event) {
    const { data, where } = event.params;
    // Modify data before update
  },

  async afterUpdate(event) {
    const { result } = event;
    // Trigger actions after update
  },
};
```

---

## Naming Conventions

- **Content Types**: kebab-case (`blog-post`, `product-category`)
- **Collection Names**: snake_case plural (`blog_posts`, `product_categories`)
- **Controllers/Services**: kebab-case filename, matches content-type
- **Routes**: kebab-case endpoints (`/blog-posts`, `/product-categories`)
- **Migration Files**: ISO timestamp (`2024.01.02.12.00.00_add_slug.js`)
- **Environment Variables**: UPPER_SNAKE_CASE (`STRAPI_ADMIN_TOKEN`, `DATABASE_CLIENT`)

---

## Command Restrictions

### NEVER Run These Commands
Tell the user to run these themselves:
- `pnpm dev`, `pnpm develop`, `pnpm build`, `pnpm start`
- Any command that starts the server

### CAN Run
- `pnpm strapi generate` commands
- `pnpm strapi routes:list`, `pnpm strapi controllers:list`
- Git read commands (git status, git log, git diff)
- Other bash commands (ls, tree, grep, curl, etc.)

---

## Security Guidelines

### Controller Sanitization (MANDATORY)

Always sanitize queries and outputs to prevent data leaks:

```javascript
async find(ctx) {
  // Sanitize incoming query
  const sanitizedQuery = await this.sanitizeQuery(ctx);

  // Validate query parameters
  await this.validateQuery(ctx);

  // Fetch data
  const results = await strapi.documents('api::article.article').findMany(sanitizedQuery);

  // Sanitize output (removes private fields)
  const sanitizedResults = await this.sanitizeOutput(results, ctx);

  return this.transformResponse(sanitizedResults);
}
```

---

## Import Patterns

```javascript
// Strapi factories
const { createCoreController } = require('@strapi/strapi').factories;
const { createCoreService } = require('@strapi/strapi').factories;
const { createCoreRouter } = require('@strapi/strapi').factories;

// Access strapi instance (in controllers/services)
module.exports = createCoreController('api::article.article', ({ strapi }) => ({
  // strapi available here
}));

// Access in lifecycle hooks
module.exports = {
  async afterCreate(event) {
    // strapi available globally
    await strapi.documents('api::log.log').create({
      data: { action: 'created', entity: event.result.id },
    });
  },
};
```

---

## Execution Standards

- Execute ONLY what is requested
- NO hallucinations
- NO unsolicited improvements
- NO assumptions beyond explicit requirements
- Confirm understanding before implementing complex changes
- Always use Document Service API (not deprecated Entity Service)
- Follow Strapi v5 patterns, not v4

---

## Quick Reference

| Action | Command/Pattern |
|--------|-----------------|
| Generate content-type | `pnpm strapi generate content-type` |
| Generate controller | `pnpm strapi generate controller` |
| Generate service | `pnpm strapi generate service` |
| List routes | `pnpm strapi routes:list` |
| List controllers | `pnpm strapi controllers:list` |
| Open console | `pnpm strapi console` |
| Document Service | `strapi.documents('api::name.name')` |

---

*Last Updated: 2026-01-11*
