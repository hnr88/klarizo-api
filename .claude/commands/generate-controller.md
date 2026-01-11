# /generate-controller - Create Custom Controller

Generate a controller with custom actions.

## Usage

```
/generate-controller [api-name] [actions...]
```

## Process

### Step 1: CLI Generation (Optional)

Tell user to run:
```bash
pnpm strapi generate controller [name]
```

### Step 2: Create Controller File

Create `src/api/[name]/controllers/[name].js`:

## Controller Templates

### Basic Core Controller

```javascript
'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::[name].[name]');
```

### With Custom Actions

```javascript
'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::article.article', ({ strapi }) => ({
  // Custom action: Get featured articles
  async featured(ctx) {
    await this.validateQuery(ctx);
    const sanitizedQuery = await this.sanitizeQuery(ctx);

    const articles = await strapi.documents('api::article.article').findMany({
      ...sanitizedQuery,
      filters: { ...sanitizedQuery.filters, featured: true },
      sort: { publishedAt: 'desc' },
      limit: 5,
    });

    const sanitized = await this.sanitizeOutput(articles, ctx);
    return this.transformResponse(sanitized);
  },

  // Custom action: Like an article
  async like(ctx) {
    const { id } = ctx.params;

    const article = await strapi.documents('api::article.article').findOne({
      documentId: id,
      fields: ['likes'],
    });

    if (!article) {
      return ctx.notFound('Article not found');
    }

    const updated = await strapi.documents('api::article.article').update({
      documentId: id,
      data: { likes: (article.likes || 0) + 1 },
    });

    const sanitized = await this.sanitizeOutput(updated, ctx);
    return this.transformResponse(sanitized);
  },
}));
```

### Wrapping Core Actions

```javascript
module.exports = createCoreController('api::article.article', ({ strapi }) => ({
  // Wrap find to add total count
  async find(ctx) {
    const { data, meta } = await super.find(ctx);

    const total = await strapi.documents('api::article.article').count({
      status: 'published',
    });

    return {
      data,
      meta: { ...meta, total },
    };
  },

  // Wrap create to set author
  async create(ctx) {
    if (ctx.state.user) {
      ctx.request.body.data.author = ctx.state.user.id;
    }
    return super.create(ctx);
  },
}));
```

## Sanitization (CRITICAL)

Always sanitize in custom actions:

```javascript
async customAction(ctx) {
  // 1. Validate query
  await this.validateQuery(ctx);

  // 2. Sanitize query
  const sanitizedQuery = await this.sanitizeQuery(ctx);

  // 3. Fetch data
  const results = await strapi.documents('api::article.article').findMany(sanitizedQuery);

  // 4. Sanitize output
  const sanitized = await this.sanitizeOutput(results, ctx);

  // 5. Transform response
  return this.transformResponse(sanitized);
}
```

## Context Object (ctx)

```javascript
ctx.request.body          // POST/PUT body
ctx.request.body.data     // Strapi data wrapper
ctx.query                 // Query parameters
ctx.params                // URL parameters (:id)
ctx.state.user            // Authenticated user

// Error responses
ctx.badRequest('Message')
ctx.unauthorized('Message')
ctx.forbidden('Message')
ctx.notFound('Message')
```

## Post-Creation

1. Add route for custom action (see /add-route)
2. Set permissions in admin panel
3. Test endpoint
