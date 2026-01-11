# /add-lifecycle - Add Lifecycle Hooks

Add lifecycle hooks to a content-type.

## Usage

```
/add-lifecycle [content-type] [hooks...]
```

## Process

### Step 1: Create Lifecycle File

Create `src/api/[name]/content-types/[name]/lifecycles.js`:

## Lifecycle Templates

### Basic Lifecycle

```javascript
module.exports = {
  async beforeCreate(event) {
    const { data } = event.params;
    // Modify data before creation
  },

  async afterCreate(event) {
    const { result } = event;
    // Actions after creation
  },
};
```

### Complete Lifecycle

```javascript
module.exports = {
  // CREATE
  async beforeCreate(event) {
    const { data } = event.params;
    // Validate or modify data
    data.slug = slugify(data.title);
  },

  async afterCreate(event) {
    const { result } = event;
    // Send notification, update cache, etc.
    await sendNotification(result);
  },

  // UPDATE
  async beforeUpdate(event) {
    const { data, where } = event.params;
    // Modify data before update
    data.updatedAt = new Date();
  },

  async afterUpdate(event) {
    const { result } = event;
    // Invalidate cache, trigger sync
    await invalidateCache(result.id);
  },

  // DELETE
  async beforeDelete(event) {
    const { where } = event.params;
    // Check permissions, clean up relations
  },

  async afterDelete(event) {
    const { result } = event;
    // Remove from search index, cleanup
    await removeFromSearch(result);
  },

  // FIND
  async beforeFindOne(event) {
    // Modify query
  },

  async afterFindOne(event) {
    const { result } = event;
    // Modify result
  },

  async beforeFindMany(event) {
    // Modify query
  },

  async afterFindMany(event) {
    // Modify results
  },

  // COUNT
  async beforeCount(event) {},
  async afterCount(event) {},

  // BULK OPERATIONS
  async beforeCreateMany(event) {},
  async afterCreateMany(event) {},
  async beforeUpdateMany(event) {},
  async afterUpdateMany(event) {},
  async beforeDeleteMany(event) {},
  async afterDeleteMany(event) {},
};
```

## Event Object

```javascript
{
  action: 'beforeCreate',           // Event type
  model: {
    uid: 'api::article.article',
    // ... model info
  },
  params: {
    data: { ... },                  // Entry data
    where: { ... },                 // Query conditions
    select: [ ... ],                // Selected fields
    populate: { ... },              // Relations
  },
  result: { ... },                  // In afterXXX only
  state: {},                        // Shared between before/after
}
```

## Common Patterns

### Auto-Generate Slug

```javascript
async beforeCreate(event) {
  const { data } = event.params;
  if (data.title && !data.slug) {
    data.slug = data.title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');
  }
}
```

### Set Author

```javascript
async beforeCreate(event) {
  const { data } = event.params;
  // Note: User context not directly available in lifecycles
  // Pass from controller if needed
}
```

### Validate Data

```javascript
async beforeCreate(event) {
  const { data } = event.params;
  if (data.price < 0) {
    throw new Error('Price cannot be negative');
  }
}
```

### Track Changes

```javascript
async beforeUpdate(event) {
  const original = await strapi.documents('api::article.article').findOne({
    documentId: event.params.where.documentId,
  });
  event.state.original = original;
}

async afterUpdate(event) {
  const { result } = event;
  const { original } = event.state;

  if (original.status !== result.status) {
    await logStatusChange(result, original.status, result.status);
  }
}
```

### Send Notifications

```javascript
async afterCreate(event) {
  const { result } = event;

  await strapi.plugin('email').service('email').send({
    to: 'admin@example.com',
    subject: `New article: ${result.title}`,
    text: `A new article was created.`,
  });
}
```

### Cleanup Relations

```javascript
async beforeDelete(event) {
  const { where } = event.params;

  // Remove from related content
  await strapi.documents('api::comment.comment').deleteMany({
    filters: { article: { documentId: where.documentId } },
  });
}
```

## Available Hooks

| Hook | Trigger |
|------|---------|
| beforeCreate | Before creating entry |
| afterCreate | After creating entry |
| beforeUpdate | Before updating entry |
| afterUpdate | After updating entry |
| beforeDelete | Before deleting entry |
| afterDelete | After deleting entry |
| beforeFindOne | Before finding single entry |
| afterFindOne | After finding single entry |
| beforeFindMany | Before finding multiple entries |
| afterFindMany | After finding multiple entries |
| beforeCount | Before counting entries |
| afterCount | After counting entries |

## Notes

- Lifecycle hooks run on Document Service operations
- Direct Knex queries don't trigger hooks
- Use `event.state` to share data between before/after
- Handle errors gracefully to avoid blocking operations
