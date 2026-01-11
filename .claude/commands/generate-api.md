# /generate-api - Create Complete API

Generate a complete API with content-type, controller, service, and routes.

## Usage

```
/generate-api [name]
```

## Process

### Step 1: Generate API Structure

Tell user to run:
```bash
pnpm strapi generate api [name]
```

Or generate manually:

### Step 2: Create Content-Type Schema

Create `src/api/[name]/content-types/[name]/schema.json`:

```json
{
  "kind": "collectionType",
  "collectionName": "[name_plural]",
  "info": {
    "singularName": "[name]",
    "pluralName": "[name-plural]",
    "displayName": "[Display Name]"
  },
  "options": {
    "draftAndPublish": true
  },
  "attributes": {
    "title": {
      "type": "string",
      "required": true
    }
  }
}
```

### Step 3: Create Controller

Create `src/api/[name]/controllers/[name].js`:

```javascript
'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::[name].[name]');
```

### Step 4: Create Service

Create `src/api/[name]/services/[name].js`:

```javascript
'use strict';

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::[name].[name]');
```

### Step 5: Create Route

Create `src/api/[name]/routes/[name].js`:

```javascript
'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::[name].[name]');
```

## Post-Generation

1. **Set Permissions**
   - Configure in admin panel under Settings > Roles
   - Enable public/authenticated access as needed

2. **Test Endpoints**
   - GET `/api/[name-plural]`
   - POST `/api/[name-plural]`
   - GET `/api/[name-plural]/:id`
   - PUT `/api/[name-plural]/:id`
   - DELETE `/api/[name-plural]/:id`

## Example

```
/generate-api article
```

Creates:
```
src/api/article/
├── content-types/article/schema.json
├── controllers/article.js
├── routes/article.js
└── services/article.js
```
