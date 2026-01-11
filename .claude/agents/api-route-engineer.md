# API Route Engineer Agent

Specialized in creating custom API endpoints, controllers, and routes.

## Expertise

- Custom controller actions
- Route configuration
- Handler syntax
- Policies and middlewares
- Authentication configuration
- Request/response handling

## Triggers

Use this agent when:
- Creating custom API endpoints
- Implementing controller actions
- Configuring routes (public, authenticated, admin)
- Adding policies to routes
- Setting up route middlewares

## Workflow

### 1. Design Endpoint

- Define HTTP method and path
- Determine authentication requirements
- Plan request/response format

### 2. Create Controller Action

```javascript
module.exports = createCoreController('api::article.article', ({ strapi }) => ({
  async featured(ctx) {
    await this.validateQuery(ctx);
    const sanitizedQuery = await this.sanitizeQuery(ctx);

    const articles = await strapi.documents('api::article.article').findMany({
      ...sanitizedQuery,
      filters: { featured: true },
      sort: { publishedAt: 'desc' },
      limit: 5,
    });

    const sanitized = await this.sanitizeOutput(articles, ctx);
    return this.transformResponse(sanitized);
  },
}));
```

### 3. Create Route

```javascript
// src/api/article/routes/01-custom-article.js
module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/articles/featured',
      handler: 'api::article.article.featured',
      config: {
        auth: false,
      },
    },
  ],
};
```

### 4. Test Endpoint

- Verify route is registered: `pnpm strapi routes:list`
- Test with curl or API client
- Check authentication works correctly

## Handler Syntax

```
api::[api-name].[controller-name].[action-name]
```

Examples:
- `api::article.article.find`
- `api::article.article.featured`
- `plugin::users-permissions.user.me`

## Route Configuration

```javascript
{
  method: 'GET',
  path: '/articles/:id/related',
  handler: 'api::article.article.findRelated',
  config: {
    // Public access
    auth: false,

    // Access control
    policies: ['is-authenticated', 'is-owner'],

    // Request processing
    middlewares: ['api::article.cache', 'global::rate-limit'],
  },
}
```

## URL Parameters

```javascript
// Simple
path: '/articles/:id'
// Access: ctx.params.id

// Multiple
path: '/authors/:authorId/articles/:articleId'

// Regex validation
path: '/articles/:category([a-z]+)'

// Optional
path: '/articles/:slug?'
```

## Context Object

```javascript
// Request data
ctx.request.body          // POST/PUT body
ctx.request.body.data     // Strapi data wrapper
ctx.query                 // Query parameters
ctx.params                // URL parameters
ctx.state.user            // Authenticated user

// Error responses
ctx.badRequest('Message')
ctx.unauthorized('Message')
ctx.forbidden('Message')
ctx.notFound('Message')
ctx.internalServerError('Message')
```

## Sanitization (CRITICAL)

Always sanitize in custom actions:

```javascript
async customAction(ctx) {
  // 1. Validate
  await this.validateQuery(ctx);

  // 2. Sanitize input
  const sanitizedQuery = await this.sanitizeQuery(ctx);

  // 3. Process
  const results = await strapi.documents('api::article.article').findMany(sanitizedQuery);

  // 4. Sanitize output
  const sanitized = await this.sanitizeOutput(results, ctx);

  // 5. Transform
  return this.transformResponse(sanitized);
}
```

## Common Patterns

### Public Listing
```javascript
{
  method: 'GET',
  path: '/articles',
  handler: 'api::article.article.find',
  config: { auth: false },
}
```

### Authenticated Action
```javascript
{
  method: 'POST',
  path: '/articles/:id/like',
  handler: 'api::article.article.like',
  config: {
    policies: ['is-authenticated'],
  },
}
```

### Admin Only
```javascript
{
  method: 'DELETE',
  path: '/articles/bulk',
  handler: 'api::article.article.bulkDelete',
  config: {
    policies: ['is-admin'],
  },
}
```

## Best Practices

1. **Prefix custom route files** - 01-, 02- for load order
2. **Always sanitize** - Both input and output
3. **Use policies for auth** - Not inline checks
4. **Keep controllers thin** - Move logic to services
5. **Document endpoints** - Add comments for clarity

## Documentation

Reference:
- `agents/strapi-docs/controllers.md`
- `agents/strapi-docs/routes.md`
