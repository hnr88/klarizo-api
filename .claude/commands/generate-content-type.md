# /generate-content-type - Create Content-Type Schema

Generate a content-type schema definition.

## Usage

```
/generate-content-type [name] [options]
```

## Process

### Option 1: CLI Generation

Tell user to run:
```bash
pnpm strapi generate content-type
```

Interactive prompts:
- Display name
- Singular name (API)
- Plural name (API)
- Kind: collectionType or singleType
- Draft & Publish: yes/no
- Internationalization: yes/no

### Option 2: Manual Creation

Create `src/api/[name]/content-types/[name]/schema.json`:

## Schema Templates

### Collection Type (Multiple Entries)

```json
{
  "kind": "collectionType",
  "collectionName": "articles",
  "info": {
    "singularName": "article",
    "pluralName": "articles",
    "displayName": "Article",
    "description": "Blog articles"
  },
  "options": {
    "draftAndPublish": true
  },
  "attributes": {
    "title": {
      "type": "string",
      "required": true,
      "maxLength": 255
    },
    "slug": {
      "type": "uid",
      "targetField": "title",
      "required": true
    },
    "content": {
      "type": "richtext"
    },
    "featuredImage": {
      "type": "media",
      "multiple": false,
      "allowedTypes": ["images"]
    }
  }
}
```

### Single Type (One Entry)

```json
{
  "kind": "singleType",
  "collectionName": "homepages",
  "info": {
    "singularName": "homepage",
    "pluralName": "homepages",
    "displayName": "Homepage"
  },
  "options": {
    "draftAndPublish": true
  },
  "attributes": {
    "heroTitle": {
      "type": "string",
      "required": true
    },
    "heroDescription": {
      "type": "text"
    }
  }
}
```

## Attribute Types Reference

| Type | Description | Options |
|------|-------------|---------|
| string | Short text | maxLength, minLength, required |
| text | Long text | maxLength, minLength |
| richtext | Rich HTML content | - |
| email | Email address | required, unique |
| password | Hashed password | required, minLength |
| uid | URL-friendly ID | targetField, required |
| integer | Whole number | min, max, default |
| decimal | Decimal number | min, max, default |
| boolean | True/false | default |
| date | Date only | - |
| datetime | Date and time | - |
| enumeration | Select options | enum: [...] |
| json | JSON data | - |
| media | Files/images | multiple, allowedTypes |
| relation | Link to other content | relation, target, inversedBy/mappedBy |
| component | Nested component | component, repeatable |
| dynamiczone | Multiple component types | components: [...] |

## Relation Examples

```json
{
  "author": {
    "type": "relation",
    "relation": "manyToOne",
    "target": "api::author.author",
    "inversedBy": "articles"
  },
  "tags": {
    "type": "relation",
    "relation": "manyToMany",
    "target": "api::tag.tag"
  }
}
```

## Post-Creation

1. Restart Strapi (user runs `pnpm dev`)
2. Configure permissions in admin panel
3. Add sample content
4. Test API endpoints
