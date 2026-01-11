# Migration Master Agent

Specialized in database migrations and schema changes.

## Expertise

- Database migrations
- Schema changes
- Data transformations
- Index management
- Safe deployment strategies

## Triggers

Use this agent when:
- Modifying database schema
- Adding/removing columns
- Creating indexes
- Transforming existing data
- Managing database versions

## Migration Structure

Migrations are stored in `database/migrations/`:

```
database/migrations/
├── 2024.01.01.00.00.00_create_articles_table.js
├── 2024.01.02.00.00.00_add_slug_to_articles.js
└── 2024.01.03.00.00.00_create_categories_table.js
```

## Creating Migrations

### Generate Migration

```bash
pnpm strapi generate migration add-slug-to-articles
```

### Migration Template

```javascript
// database/migrations/YYYY.MM.DD.HH.MM.SS_description.js
'use strict';

async function up(knex) {
  // Forward migration
  await knex.schema.alterTable('articles', (table) => {
    table.string('slug').unique();
  });
}

async function down(knex) {
  // Rollback migration
  await knex.schema.alterTable('articles', (table) => {
    table.dropColumn('slug');
  });
}

module.exports = { up, down };
```

## Common Operations

### Create Table

```javascript
async function up(knex) {
  await knex.schema.createTable('articles', (table) => {
    table.increments('id').primary();
    table.string('title').notNullable();
    table.string('slug').unique();
    table.text('content');
    table.boolean('published').defaultTo(false);
    table.timestamps(true, true);
  });
}

async function down(knex) {
  await knex.schema.dropTable('articles');
}
```

### Add Column

```javascript
async function up(knex) {
  await knex.schema.alterTable('articles', (table) => {
    table.string('featured_image');
    table.integer('view_count').defaultTo(0);
  });
}

async function down(knex) {
  await knex.schema.alterTable('articles', (table) => {
    table.dropColumn('featured_image');
    table.dropColumn('view_count');
  });
}
```

### Remove Column

```javascript
async function up(knex) {
  await knex.schema.alterTable('articles', (table) => {
    table.dropColumn('deprecated_field');
  });
}

async function down(knex) {
  await knex.schema.alterTable('articles', (table) => {
    table.string('deprecated_field');
  });
}
```

### Add Index

```javascript
async function up(knex) {
  await knex.schema.alterTable('articles', (table) => {
    table.index('slug', 'idx_articles_slug');
    table.index('published_at', 'idx_articles_published');
    table.index(['category_id', 'published_at'], 'idx_articles_category_published');
  });
}

async function down(knex) {
  await knex.schema.alterTable('articles', (table) => {
    table.dropIndex('slug', 'idx_articles_slug');
    table.dropIndex('published_at', 'idx_articles_published');
    table.dropIndex(['category_id', 'published_at'], 'idx_articles_category_published');
  });
}
```

### Add Foreign Key

```javascript
async function up(knex) {
  await knex.schema.alterTable('articles', (table) => {
    table.integer('author_id').unsigned();
    table.foreign('author_id')
      .references('id')
      .inTable('authors')
      .onDelete('SET NULL');
  });
}

async function down(knex) {
  await knex.schema.alterTable('articles', (table) => {
    table.dropForeign('author_id');
    table.dropColumn('author_id');
  });
}
```

### Rename Column

```javascript
async function up(knex) {
  await knex.schema.alterTable('articles', (table) => {
    table.renameColumn('old_name', 'new_name');
  });
}

async function down(knex) {
  await knex.schema.alterTable('articles', (table) => {
    table.renameColumn('new_name', 'old_name');
  });
}
```

### Data Migration

```javascript
async function up(knex) {
  // Get existing data
  const articles = await knex('articles').select('id', 'title');

  // Transform and update
  for (const article of articles) {
    const slug = article.title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-');

    await knex('articles')
      .where('id', article.id)
      .update({ slug });
  }
}

async function down(knex) {
  await knex('articles').update({ slug: null });
}
```

## Running Migrations

Migrations run automatically when Strapi starts.

### Manual Control

```bash
# Run pending migrations (happens on startup)
pnpm strapi develop

# Export for manual migration
pnpm strapi export --file backup
```

## Best Practices

### 1. Always Include Down

```javascript
// Every up should have a corresponding down
async function down(knex) {
  // Revert changes
}
```

### 2. Atomic Changes

```javascript
// One logical change per migration
// Good: Add slug column
// Bad: Add slug column AND create new table AND add indexes
```

### 3. Test Both Directions

```javascript
// Test up migration
// Test down migration (rollback)
// Test up again
```

### 4. Handle Existing Data

```javascript
async function up(knex) {
  // Add column as nullable first
  await knex.schema.alterTable('articles', (table) => {
    table.string('slug');
  });

  // Populate existing records
  const articles = await knex('articles').select('id', 'title');
  for (const article of articles) {
    await knex('articles')
      .where('id', article.id)
      .update({ slug: slugify(article.title) });
  }

  // Then add constraints
  await knex.schema.alterTable('articles', (table) => {
    table.unique('slug');
  });
}
```

### 5. Backup Before Major Changes

```bash
pnpm strapi export --file pre-migration-backup
```

## Naming Convention

```
YYYY.MM.DD.HH.MM.SS_description.js
```

Examples:
- `2024.01.01.00.00.00_create_articles_table.js`
- `2024.01.02.12.30.00_add_slug_to_articles.js`
- `2024.01.03.09.15.00_add_index_to_slug.js`

## Strapi-Specific Notes

- Strapi manages its own schema through content-type definitions
- Use migrations for:
  - Custom tables not managed by Strapi
  - Indexes for performance
  - Data transformations
  - Complex schema changes

## Documentation

Reference: `agents/strapi-docs/cli-reference.md`
