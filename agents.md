# klarizo-api Agent Reference

Quick reference for AI agents available in the klarizo-api backend.

---

## Available Agents

| Agent | Purpose | Location |
|-------|---------|----------|
| **Schema Architect** | Design & modify content-type schemas | `.claude/agents/schema-architect.md` |
| **API Route Engineer** | Create & modify API endpoints | `.claude/agents/api-route-engineer.md` |
| **Lifecycle Guardian** | Implement lifecycle hooks & policies | `.claude/agents/lifecycle-guardian.md` |
| **Document Service Expert** | Handle Document Service API operations | `.claude/agents/document-service-expert.md` |
| **Migration Master** | Database migrations & schema changes | `.claude/agents/migration-master.md` |
| **Plugin Specialist** | Custom plugin development | `.claude/agents/plugin-specialist.md` |
| **Strapi Entity Manager** | Create/update entities via API | `.claude/agents/strapi-entity-manager.md` |
| **Strapi Doctor** | Troubleshooting & debugging | `.claude/agents/strapi-doctor.md` |

---

## Agent Triggers

### Schema Architect
**Use when:**
- Creating new content-types
- Modifying existing schemas
- Adding/removing/changing fields
- Setting up relations between content-types

### API Route Engineer
**Use when:**
- Creating custom API endpoints
- Implementing controller actions
- Configuring routes (public, authenticated, admin)
- Adding policies to routes

### Lifecycle Guardian
**Use when:**
- Implementing business rules on data changes
- Data validation requirements
- Automated actions (notifications, cache)
- Creating access control policies

### Document Service Expert
**Use when:**
- Complex document queries
- Draft/publish workflows
- Bulk operations
- Advanced filtering/sorting

### Migration Master
**Use when:**
- Database schema changes
- Data migrations
- Adding indexes
- Transforming existing data

### Plugin Specialist
**Use when:**
- Creating custom plugins
- Extending admin panel
- Adding custom fields
- Building dashboard widgets

### Strapi Entity Manager
**Use when:**
- Creating content types via API
- Managing CMS entities programmatically
- Bulk content operations

### Strapi Doctor
**Use when:**
- Application errors
- Performance issues
- Configuration problems
- Unexpected behavior

---

## Available Commands

| Command | Description |
|---------|-------------|
| `/start` | Initialize backend session |
| `/generate-api` | Create complete API structure |
| `/generate-content-type` | Create content-type schema |
| `/generate-controller` | Generate controller |
| `/generate-service` | Generate service |
| `/add-route` | Add custom routes |
| `/add-lifecycle` | Add lifecycle hooks |

---

## Key Patterns

### Document Service API (CRITICAL)
Always use `strapi.documents()` instead of deprecated Entity Service:

```javascript
// Correct (Strapi v5)
strapi.documents('api::article.article').findMany(...)

// Wrong (deprecated)
strapi.entityService.findMany(...)
```

### Controller Sanitization (MANDATORY)
```javascript
async customAction(ctx) {
  await this.validateQuery(ctx);
  const sanitizedQuery = await this.sanitizeQuery(ctx);
  const results = await strapi.documents('api::article.article').findMany(sanitizedQuery);
  const sanitized = await this.sanitizeOutput(results, ctx);
  return this.transformResponse(sanitized);
}
```

### Route Prefixing
Custom routes should be prefixed for load order:
```
src/api/article/routes/
├── 01-custom-article.js    # Loads first
└── article.js              # Core routes
```

---

## Quick Diagnostics

```bash
# List all routes
pnpm strapi routes:list

# List all controllers
pnpm strapi controllers:list

# List all content-types
pnpm strapi content-types:list

# Open console for debugging
pnpm strapi console
```

---

## Best Practices

1. **Use Document Service API** - Never Entity Service
2. **Always sanitize** - Both input and output in controllers
3. **Prefix custom routes** - 01-, 02- for load order
4. **Keep controllers thin** - Move logic to services
5. **Use policies for auth** - Not inline checks
6. **Test with routes:list** - Verify routes registered
