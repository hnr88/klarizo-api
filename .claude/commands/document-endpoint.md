# /document-endpoint - Document API Endpoint

Document a new or existing API endpoint with OpenAPI comments and markdown.

## Usage

```
/document-endpoint [api-name] [action-name]
```

Example:
```
/document-endpoint article featured
```

## Process

### Step 1: Gather Endpoint Information

1. Read the controller action at `src/api/[api-name]/controllers/[api-name].js`
2. Read the route definition at `src/api/[api-name]/routes/`
3. Identify:
   - HTTP method
   - Path
   - Authentication requirements
   - Request parameters
   - Request body schema
   - Response schema

### Step 2: Add OpenAPI Comment

Add JSDoc/OpenAPI comment above the controller action:

```javascript
/**
 * @openapi
 * /api/[path]:
 *   [method]:
 *     summary: [Brief summary]
 *     description: [Detailed description]
 *     tags:
 *       - [API Name]
 *     security: [[] for public, [{ bearerAuth: [] }] for authenticated]
 *     parameters:
 *       [List URL and query parameters]
 *     requestBody:
 *       [For POST/PUT, include schema]
 *     responses:
 *       [List all possible responses]
 */
async [actionName](ctx) {
  // ...
}
```

### Step 3: Create/Update Markdown

1. Check if `agents/api-docs/[api-name].md` exists
2. If not, create it with the endpoint documentation
3. If exists, add/update the endpoint section

### Step 4: Verify

1. Check OpenAPI comment is valid
2. Check markdown is properly formatted
3. Ensure all parameters are documented

## Templates

### Public GET (List)

```javascript
/**
 * @openapi
 * /api/articles:
 *   get:
 *     summary: List articles
 *     description: Returns paginated list of articles
 *     tags:
 *       - Articles
 *     security: []
 *     parameters:
 *       - in: query
 *         name: pagination[page]
 *         schema:
 *           type: integer
 *         description: Page number
 *       - in: query
 *         name: pagination[pageSize]
 *         schema:
 *           type: integer
 *         description: Items per page
 *       - in: query
 *         name: populate
 *         schema:
 *           type: string
 *         description: Relations to populate
 *     responses:
 *       200:
 *         description: Success
 */
```

### Authenticated POST

```javascript
/**
 * @openapi
 * /api/articles:
 *   post:
 *     summary: Create article
 *     description: Creates a new article
 *     tags:
 *       - Articles
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - data
 *             properties:
 *               data:
 *                 type: object
 *                 required:
 *                   - title
 *                 properties:
 *                   title:
 *                     type: string
 *                   content:
 *                     type: string
 *     responses:
 *       201:
 *         description: Created
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 */
```

### Custom Action

```javascript
/**
 * @openapi
 * /api/articles/featured:
 *   get:
 *     summary: Get featured articles
 *     description: Returns articles marked as featured
 *     tags:
 *       - Articles
 *     security: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 5
 *         description: Number of articles
 *     responses:
 *       200:
 *         description: Success
 */
```

## Markdown Template

```markdown
# [API Name] API

Base path: `/api/[api-name]`

## Endpoints

### [METHOD] /api/[path]

[Description]

**Authentication:** [None | Required]

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| [name] | [type] | [Yes/No] | [description] |

**Request Body:** (for POST/PUT)

```json
{
  "data": {
    "field": "value"
  }
}
```

**Response:**

```json
{
  "data": { ... },
  "meta": { ... }
}
```

**Example:**

```bash
curl -X [METHOD] "https://api.example.com/api/[path]" \
  -H "Content-Type: application/json" \
  [-H "Authorization: Bearer TOKEN"] \
  [-d '{"data": {...}}']
```
```

## Notes

- Always include all response status codes
- Document error responses (400, 401, 403, 404, 500)
- Use proper OpenAPI 3.0 syntax
- Keep descriptions concise but complete
