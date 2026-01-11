# /add-route - Add Custom Route

Add custom routes to an API.

## Usage

```
/add-route [api-name] [method] [path] [action]
```

## Process

### Step 1: Create Custom Route File

Create `src/api/[name]/routes/01-custom-[name].js`:

**Important:** Prefix with number (01-, 02-) to load before core routes.

## Route Templates

### Basic Custom Route

```javascript
module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/articles/featured',
      handler: 'api::article.article.featured',
    },
  ],
};
```

### Multiple Routes

```javascript
module.exports = {
  routes: [
    // Public: Featured articles
    {
      method: 'GET',
      path: '/articles/featured',
      handler: 'api::article.article.featured',
      config: {
        auth: false,
      },
    },

    // Public: Articles by category
    {
      method: 'GET',
      path: '/articles/category/:slug',
      handler: 'api::article.article.findByCategory',
      config: {
        auth: false,
      },
    },

    // Authenticated: Like article
    {
      method: 'POST',
      path: '/articles/:id/like',
      handler: 'api::article.article.like',
      config: {
        policies: ['is-authenticated'],
      },
    },

    // Admin only: Bulk publish
    {
      method: 'POST',
      path: '/articles/bulk-publish',
      handler: 'api::article.article.bulkPublish',
      config: {
        policies: ['is-admin'],
      },
    },
  ],
};
```

### Route with Configuration

```javascript
{
  method: 'GET',
  path: '/articles/search',
  handler: 'api::article.article.search',
  config: {
    // Authentication
    auth: false,  // Public route

    // Policies (access control)
    policies: [
      'is-authenticated',
      {
        name: 'is-owner',
        config: { field: 'author' },
      },
    ],

    // Middlewares
    middlewares: [
      'api::article.cache',
      {
        name: 'global::rate-limit',
        config: { max: 100 },
      },
    ],
  },
}
```

## URL Parameters

```javascript
// Simple parameter
{
  path: '/articles/:id',
  // Access: ctx.params.id
}

// Multiple parameters
{
  path: '/authors/:authorId/articles/:articleId',
  // Access: ctx.params.authorId, ctx.params.articleId
}

// Regex validation
{
  path: '/articles/:category([a-z]+)',
  // Only matches lowercase letters
}

// Optional parameter
{
  path: '/articles/:slug?',
  // Matches /articles and /articles/my-slug
}
```

## Handler Syntax

```
api::[api-name].[controller-name].[action-name]
```

Examples:
- `api::article.article.find`
- `api::article.article.featured`
- `api::user.user.me`

## Core Router Configuration

Modify `src/api/[name]/routes/[name].js`:

```javascript
'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::article.article', {
  // Custom prefix
  prefix: '/v1',

  // Only include specific routes
  only: ['find', 'findOne', 'create'],

  // Exclude specific routes
  except: ['delete'],

  // Configure individual routes
  config: {
    find: {
      auth: false,
      middlewares: ['api::article.cache'],
    },
    findOne: {
      auth: false,
    },
    create: {
      policies: ['is-authenticated'],
    },
    update: {
      policies: ['is-owner'],
    },
    delete: {
      policies: ['is-admin'],
    },
  },
});
```

## Verification

List all routes:
```bash
pnpm strapi routes:list
```

## Notes

- Routes load alphabetically (use 01-, 02- prefixes)
- Custom routes before core routes to prevent conflicts
- Handler must match controller action name exactly
- Set `auth: false` explicitly for public routes
