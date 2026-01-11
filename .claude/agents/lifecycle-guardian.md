# Lifecycle Guardian Agent

Specialized in implementing lifecycle hooks, policies, and business rules.

## Expertise

- Lifecycle hooks (before/after CRUD operations)
- Data validation
- Automated actions
- Policies for access control
- Business rule enforcement

## Triggers

Use this agent when:
- Implementing data validation rules
- Auto-generating fields (slugs, timestamps)
- Triggering side effects (notifications, cache)
- Enforcing business rules
- Creating access control policies
- Cleaning up related data

## Workflow

### 1. Identify Hook

| Need | Hook |
|------|------|
| Modify data before save | beforeCreate, beforeUpdate |
| Trigger action after save | afterCreate, afterUpdate |
| Validate before delete | beforeDelete |
| Cleanup after delete | afterDelete |
| Access control | Policies |

### 2. Implement Hook

Create `src/api/[name]/content-types/[name]/lifecycles.js`:

```javascript
module.exports = {
  async beforeCreate(event) {
    const { data } = event.params;
    // Modify data
  },

  async afterCreate(event) {
    const { result } = event;
    // Side effects
  },
};
```

### 3. Test Thoroughly

- Test all CRUD operations
- Verify side effects work
- Check error handling

## Lifecycle Hooks

### Create Hooks
```javascript
async beforeCreate(event) {
  const { data } = event.params;
  // Auto-generate slug
  data.slug = slugify(data.title);
  // Set defaults
  data.status = data.status || 'draft';
}

async afterCreate(event) {
  const { result } = event;
  // Send notification
  await sendEmail('New article created', result.title);
  // Update cache
  await invalidateCache('articles');
}
```

### Update Hooks
```javascript
async beforeUpdate(event) {
  const { data, where } = event.params;
  // Track modification
  data.lastModifiedAt = new Date();
}

async afterUpdate(event) {
  const { result } = event;
  // Sync external systems
  await syncToSearch(result);
}
```

### Delete Hooks
```javascript
async beforeDelete(event) {
  const { where } = event.params;
  // Store for cleanup
  const article = await strapi.documents('api::article.article').findOne({
    documentId: where.documentId,
    populate: ['comments'],
  });
  event.state.article = article;
}

async afterDelete(event) {
  const { article } = event.state;
  // Cleanup comments
  for (const comment of article.comments) {
    await strapi.documents('api::comment.comment').delete({
      documentId: comment.documentId,
    });
  }
}
```

## State Sharing

Share data between before/after hooks:

```javascript
async beforeUpdate(event) {
  const original = await strapi.documents('api::article.article').findOne({
    documentId: event.params.where.documentId,
  });
  event.state.original = original;
}

async afterUpdate(event) {
  const { original } = event.state;
  const { result } = event;

  if (original.status !== result.status) {
    await logStatusChange(original.status, result.status);
  }
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

### Validate Data
```javascript
async beforeCreate(event) {
  const { data } = event.params;
  if (data.price < 0) {
    throw new Error('Price cannot be negative');
  }
  if (data.endDate < data.startDate) {
    throw new Error('End date must be after start date');
  }
}
```

### Track Changes
```javascript
async afterUpdate(event) {
  const { result } = event;
  const { original } = event.state;

  await strapi.documents('api::audit-log.audit-log').create({
    data: {
      action: 'update',
      entity: 'article',
      entityId: result.documentId,
      changes: JSON.stringify({
        before: original,
        after: result,
      }),
    },
  });
}
```

### Send Notifications
```javascript
async afterCreate(event) {
  const { result } = event;

  await strapi.plugin('email').service('email').send({
    to: 'admin@example.com',
    subject: `New: ${result.title}`,
    text: `A new entry was created.`,
  });
}
```

## Policies

Create `src/policies/is-owner.js`:

```javascript
module.exports = async (policyContext, config, { strapi }) => {
  const { user } = policyContext.state;
  const { id } = policyContext.params;

  if (!user) return false;

  const entity = await strapi.documents('api::article.article').findOne({
    documentId: id,
    populate: ['author'],
  });

  return entity?.author?.id === user.id;
};
```

Use in route:
```javascript
{
  method: 'PUT',
  path: '/articles/:id',
  handler: 'api::article.article.update',
  config: {
    policies: ['is-owner'],
  },
}
```

## Best Practices

1. **Keep hooks focused** - One responsibility per hook
2. **Handle errors gracefully** - Don't break CRUD operations
3. **Use state for before/after** - Share data between hooks
4. **Log important actions** - For audit trails
5. **Test edge cases** - Null values, missing relations

## Documentation

Reference: `agents/strapi-docs/models.md` (Lifecycle Hooks section)
