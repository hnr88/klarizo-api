# /generate-service - Create Custom Service

Generate a service with business logic.

## Usage

```
/generate-service [api-name] [methods...]
```

## Process

### Step 1: CLI Generation (Optional)

Tell user to run:
```bash
pnpm strapi generate service [name]
```

### Step 2: Create Service File

Create `src/api/[name]/services/[name].js`:

## Service Templates

### Basic Core Service

```javascript
'use strict';

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::[name].[name]');
```

### With Custom Methods

```javascript
'use strict';

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::article.article', ({ strapi }) => ({
  // Find featured articles
  async findFeatured(limit = 5) {
    return strapi.documents('api::article.article').findMany({
      filters: { featured: true },
      sort: { publishedAt: 'desc' },
      limit,
      populate: ['author', 'featuredImage'],
      status: 'published',
    });
  },

  // Find by category
  async findByCategory(categoryId, params = {}) {
    return strapi.documents('api::article.article').findMany({
      ...params,
      filters: {
        ...params.filters,
        category: { documentId: categoryId },
      },
      status: 'published',
    });
  },

  // Find by author
  async findByAuthor(authorId, params = {}) {
    return strapi.documents('api::article.article').findMany({
      ...params,
      filters: {
        ...params.filters,
        author: { documentId: authorId },
      },
      status: 'published',
    });
  },

  // Get article with related
  async findWithRelated(documentId) {
    const article = await strapi.documents('api::article.article').findOne({
      documentId,
      populate: ['category', 'tags'],
    });

    if (!article) return null;

    const related = await strapi.documents('api::article.article').findMany({
      filters: {
        category: { documentId: article.category?.documentId },
        documentId: { $ne: documentId },
      },
      limit: 3,
      status: 'published',
    });

    return { ...article, related };
  },

  // Increment view count
  async incrementViews(documentId) {
    const article = await strapi.documents('api::article.article').findOne({
      documentId,
      fields: ['views'],
    });

    if (!article) return null;

    return strapi.documents('api::article.article').update({
      documentId,
      data: { views: (article.views || 0) + 1 },
    });
  },

  // Search articles
  async search(query, params = {}) {
    return strapi.documents('api::article.article').findMany({
      ...params,
      filters: {
        $or: [
          { title: { $containsi: query } },
          { content: { $containsi: query } },
          { excerpt: { $containsi: query } },
        ],
      },
      sort: { publishedAt: 'desc' },
      status: 'published',
    });
  },
}));
```

### Wrapping Core Methods

```javascript
module.exports = createCoreService('api::article.article', ({ strapi }) => ({
  // Auto-generate slug on create
  async create(params) {
    if (params.data.title && !params.data.slug) {
      params.data.slug = slugify(params.data.title);
    }
    return super.create(params);
  },

  // Add default filter to find
  async find(...args) {
    if (!args[0]) args[0] = {};
    args[0].filters = {
      ...args[0].filters,
      status: 'published',
    };
    return super.find(...args);
  },
}));
```

## Using Services

### From Controllers

```javascript
module.exports = createCoreController('api::article.article', ({ strapi }) => ({
  async featured(ctx) {
    const articles = await strapi.service('api::article.article').findFeatured();
    return this.transformResponse(await this.sanitizeOutput(articles, ctx));
  },
}));
```

### From Other Services

```javascript
async createWithNotification(data) {
  const article = await strapi.documents('api::article.article').create({ data });
  await strapi.service('api::notification.notification').send(article);
  return article;
}
```

### From Lifecycle Hooks

```javascript
// lifecycles.js
module.exports = {
  async afterCreate(event) {
    await strapi.service('api::article.article').sendNotification(event.result);
  },
};
```

## Best Practices

1. **Keep reusable** - No ctx-specific logic
2. **Return data** - Let controllers handle responses
3. **Use Document Service** - Not Entity Service
4. **Handle errors** - Throw meaningful errors
5. **Document methods** - Add JSDoc comments
