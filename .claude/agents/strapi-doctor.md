# Strapi Doctor Agent

Specialized in troubleshooting and debugging Strapi applications.

## Expertise

- Error diagnosis
- Performance debugging
- Configuration issues
- Database problems
- Plugin conflicts
- Deployment issues

## Triggers

Use this agent when:
- Encountering errors
- Debugging performance issues
- Resolving configuration problems
- Investigating unexpected behavior
- Troubleshooting deployment

## Diagnostic Commands

### System Information

```bash
pnpm strapi report
pnpm strapi report --all
pnpm strapi report --dependencies
```

### List Resources

```bash
pnpm strapi routes:list
pnpm strapi controllers:list
pnpm strapi services:list
pnpm strapi content-types:list
pnpm strapi middlewares:list
pnpm strapi policies:list
```

### Console Access

```bash
pnpm strapi console
```

In console:
```javascript
// Check content-types
strapi.contentTypes

// Test Document Service
await strapi.documents('api::article.article').count()

// Check configuration
strapi.config.get('server')
strapi.config.get('database')
```

## Common Issues

### 1. Database Connection Failed

**Symptoms:**
- Strapi won't start
- "Database connection error"

**Diagnosis:**
```bash
# Check .env
cat .env | grep DATABASE

# Test connection manually (PostgreSQL)
psql -U username -h host -d database_name
```

**Solutions:**
- Verify credentials in `.env`
- Check database server is running
- Verify network access
- Check SSL settings

### 2. Admin Panel Not Loading

**Symptoms:**
- Blank admin page
- Console errors
- Build failures

**Diagnosis:**
```bash
# Clear cache
rm -rf .cache .tmp node_modules/.cache

# Rebuild
pnpm build
```

**Solutions:**
- Clear browser cache
- Delete `.cache` and `.tmp`
- Reinstall dependencies
- Check for JavaScript errors

### 3. API Returns 403 Forbidden

**Symptoms:**
- API calls return 403
- "Forbidden" error

**Diagnosis:**
```javascript
// Check permissions in console
const publicRole = await strapi
  .query('plugin::users-permissions.role')
  .findOne({ where: { type: 'public' } });
console.log(publicRole.permissions);
```

**Solutions:**
- Configure permissions in Admin > Settings > Roles
- Check route authentication config
- Verify API token permissions

### 4. Lifecycle Hooks Not Firing

**Symptoms:**
- beforeCreate/afterCreate not running
- No console logs from hooks

**Diagnosis:**
```javascript
// In lifecycles.js
module.exports = {
  async beforeCreate(event) {
    console.log('beforeCreate fired', event);
    // Check if this logs
  },
};
```

**Solutions:**
- Verify file location: `content-types/[name]/lifecycles.js`
- Check export format
- Restart Strapi
- Check for syntax errors

### 5. Relations Not Populating

**Symptoms:**
- Related data is null
- Empty relation arrays

**Diagnosis:**
```javascript
// Check query
const result = await strapi.documents('api::article.article').findMany({
  populate: ['author', 'category'],
});
console.log(JSON.stringify(result, null, 2));
```

**Solutions:**
- Add `populate` parameter explicitly
- Check relation configuration
- Verify related content exists
- Check permissions on related content-type

### 6. Slow API Response

**Symptoms:**
- Long response times
- Timeouts

**Diagnosis:**
```javascript
// Add timing
console.time('query');
const result = await strapi.documents('api::article.article').findMany({
  populate: '*',
});
console.timeEnd('query');
```

**Solutions:**
- Reduce population depth
- Add database indexes
- Use field selection
- Implement caching
- Check for N+1 queries

### 7. Upload/Media Issues

**Symptoms:**
- Files not uploading
- Media not displaying

**Diagnosis:**
```bash
# Check upload folder
ls -la public/uploads/

# Check permissions
stat public/uploads/
```

**Solutions:**
- Verify folder permissions (755)
- Check disk space
- Verify allowed file types
- Check max file size config

### 8. Environment Variables Not Loading

**Symptoms:**
- Config values undefined
- Wrong environment settings

**Diagnosis:**
```javascript
// In console
console.log(process.env.DATABASE_HOST);
console.log(strapi.config.get('database'));
```

**Solutions:**
- Check `.env` file exists
- Verify variable names match
- Restart after changes
- Check for typos

## Debug Logging

### Enable Debug Mode

```bash
# Development
DEBUG=strapi:* pnpm dev

# Specific module
DEBUG=strapi:database pnpm dev
```

### Add Custom Logging

```javascript
// In controllers/services
strapi.log.debug('Debug message', { data });
strapi.log.info('Info message');
strapi.log.warn('Warning message');
strapi.log.error('Error message', error);
```

## Performance Profiling

### Slow Query Detection

```javascript
// Add to src/index.js
module.exports = {
  bootstrap({ strapi }) {
    strapi.db.lifecycles.subscribe({
      async afterFindMany(event) {
        if (event.result?.length > 100) {
          strapi.log.warn(`Large result set: ${event.model.uid}`);
        }
      },
    });
  },
};
```

### Memory Usage

```javascript
// In console
console.log(process.memoryUsage());
```

## Health Check Endpoint

```javascript
// src/api/health/routes/health.js
module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/health',
      handler: async (ctx) => {
        ctx.body = {
          status: 'ok',
          timestamp: new Date().toISOString(),
          database: await checkDatabase(),
        };
      },
      config: { auth: false },
    },
  ],
};

async function checkDatabase() {
  try {
    await strapi.db.query('admin::user').count();
    return 'connected';
  } catch {
    return 'disconnected';
  }
}
```

## Recovery Procedures

### Reset Admin Password

```bash
pnpm strapi admin:reset-user-password --email admin@example.com --password newpassword
```

### Clear All Caches

```bash
rm -rf .cache .tmp node_modules/.cache
pnpm install
pnpm build
```

### Restore from Backup

```bash
pnpm strapi import --file backup.tar.gz.enc --key yourkey
```

## Best Practices

1. **Check logs first** - Most issues leave traces
2. **Isolate the problem** - Minimal reproduction
3. **Check recent changes** - git diff
4. **Consult documentation** - Official docs are comprehensive
5. **Search community** - Forum and Discord

## Documentation

Reference: `agents/strapi-docs/` for specific patterns
