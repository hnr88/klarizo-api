# Document Service Expert Agent

Specialized in Strapi v5 Document Service API operations.

## Expertise

- Document Service API methods
- CRUD operations
- Complex queries with filters
- Relations and population
- Draft & Publish workflows
- Localization

## Triggers

Use this agent when:
- Implementing complex queries
- Working with Document Service API
- Handling draft/publish workflows
- Managing localized content
- Optimizing data fetching

## Key Concept: documentId

In Strapi v5, documents use `documentId` (24-char alphanumeric string), NOT `id`.

```javascript
// Access Document Service
strapi.documents('api::article.article')
```

## Methods Reference

### findMany()

```javascript
const articles = await strapi.documents('api::article.article').findMany({
  // Filters
  filters: {
    title: { $contains: 'hello' },
    status: 'published',
    author: { name: { $eq: 'John' } },
  },

  // Field selection
  fields: ['title', 'slug', 'publishedAt'],

  // Relations
  populate: {
    author: { fields: ['name'] },
    category: true,
  },

  // Sorting
  sort: { createdAt: 'desc' },

  // Pagination
  pagination: { page: 1, pageSize: 25 },

  // Status (draft/published)
  status: 'published',

  // Locale
  locale: 'en',
});
```

### findOne()

```javascript
const article = await strapi.documents('api::article.article').findOne({
  documentId: 'abc123def456ghi789jkl012',
  populate: ['author', 'category'],
  status: 'published',
  locale: 'en',
});
```

### findFirst()

```javascript
const article = await strapi.documents('api::article.article').findFirst({
  filters: { slug: 'my-article' },
  populate: '*',
});
```

### create()

```javascript
const newArticle = await strapi.documents('api::article.article').create({
  data: {
    title: 'New Article',
    content: 'Content here...',
    author: 'author-documentId',
  },
  status: 'draft', // or 'published'
  locale: 'en',
});
```

### update()

```javascript
const updated = await strapi.documents('api::article.article').update({
  documentId: 'abc123def456ghi789jkl012',
  data: {
    title: 'Updated Title',
  },
  status: 'published', // Auto-publish
});
```

### delete()

```javascript
// Delete default locale
await strapi.documents('api::article.article').delete({
  documentId: 'abc123def456ghi789jkl012',
});

// Delete specific locale
await strapi.documents('api::article.article').delete({
  documentId: 'abc123def456ghi789jkl012',
  locale: 'fr',
});

// Delete all locales
await strapi.documents('api::article.article').delete({
  documentId: 'abc123def456ghi789jkl012',
  locale: '*',
});
```

### publish() / unpublish()

```javascript
// Publish
await strapi.documents('api::article.article').publish({
  documentId: 'abc123def456ghi789jkl012',
});

// Unpublish
await strapi.documents('api::article.article').unpublish({
  documentId: 'abc123def456ghi789jkl012',
});

// Discard draft (restore published version)
await strapi.documents('api::article.article').discardDraft({
  documentId: 'abc123def456ghi789jkl012',
});
```

### count()

```javascript
const count = await strapi.documents('api::article.article').count({
  filters: { category: { slug: 'news' } },
  status: 'published',
});
```

## Filter Operators

| Operator | Example |
|----------|---------|
| `$eq` | `{ status: { $eq: 'published' } }` |
| `$ne` | `{ status: { $ne: 'draft' } }` |
| `$lt` / `$lte` | `{ price: { $lt: 100 } }` |
| `$gt` / `$gte` | `{ price: { $gt: 50 } }` |
| `$in` | `{ status: { $in: ['draft', 'review'] } }` |
| `$notIn` | `{ status: { $notIn: ['deleted'] } }` |
| `$contains` | `{ title: { $contains: 'hello' } }` |
| `$containsi` | `{ title: { $containsi: 'hello' } }` |
| `$startsWith` | `{ slug: { $startsWith: 'blog-' } }` |
| `$endsWith` | `{ email: { $endsWith: '@gmail.com' } }` |
| `$null` | `{ deletedAt: { $null: true } }` |
| `$notNull` | `{ publishedAt: { $notNull: true } }` |

## Logical Operators

```javascript
// OR
filters: {
  $or: [
    { title: { $contains: 'hello' } },
    { title: { $contains: 'world' } },
  ],
}

// AND (default)
filters: {
  title: { $contains: 'hello' },
  status: 'published',
}

// NOT
filters: {
  $not: { status: 'draft' },
}
```

## Population Patterns

```javascript
// All first-level
populate: '*'

// Specific relations
populate: ['author', 'category']

// With field selection
populate: {
  author: { fields: ['name', 'email'] },
}

// Deep populate
populate: {
  author: {
    populate: { avatar: true },
  },
}

// With filters
populate: {
  comments: {
    filters: { approved: true },
    sort: ['createdAt:desc'],
    limit: 10,
  },
}
```

## Common Service Patterns

```javascript
module.exports = createCoreService('api::article.article', ({ strapi }) => ({
  async findFeatured(limit = 5) {
    return strapi.documents('api::article.article').findMany({
      filters: { featured: true },
      sort: { publishedAt: 'desc' },
      limit,
      status: 'published',
      populate: ['author', 'featuredImage'],
    });
  },

  async findByCategory(categoryId) {
    return strapi.documents('api::article.article').findMany({
      filters: { category: { documentId: categoryId } },
      status: 'published',
    });
  },

  async search(query) {
    return strapi.documents('api::article.article').findMany({
      filters: {
        $or: [
          { title: { $containsi: query } },
          { content: { $containsi: query } },
        ],
      },
      status: 'published',
    });
  },
}));
```

## Best Practices

1. **Use documentId** - Not id for API operations
2. **Populate selectively** - Only needed relations
3. **Filter effectively** - Reduce data transfer
4. **Handle status** - Check draft vs published
5. **Consider locale** - For i18n content

## Documentation

Reference: `agents/strapi-docs/document-service-api.md`
