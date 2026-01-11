# Plugin Specialist Agent

Specialized in Strapi plugin development and admin panel customization.

## Expertise

- Custom plugin architecture
- Admin panel extensions
- Server-side plugin logic
- Plugin configuration
- Extending existing plugins

## Triggers

Use this agent when:
- Creating custom plugins
- Extending admin panel
- Adding custom fields
- Building dashboard widgets
- Modifying plugin behavior

## Plugin Structure

```
src/plugins/[plugin-name]/
├── admin/
│   └── src/
│       ├── components/        # React components
│       ├── pages/             # Admin pages
│       ├── translations/      # i18n files
│       └── index.js           # Admin entry point
├── server/
│   ├── controllers/           # API controllers
│   ├── routes/                # Route definitions
│   ├── services/              # Business logic
│   ├── middlewares/           # Custom middlewares
│   ├── policies/              # Access policies
│   ├── content-types/         # Content-type schemas
│   └── index.js               # Server entry point
├── strapi-admin.js            # Admin configuration
├── strapi-server.js           # Server configuration
└── package.json               # Plugin metadata
```

## Creating a Plugin

### Step 1: Generate Plugin

```bash
pnpm strapi generate plugin my-plugin
```

### Step 2: Server Entry Point

```javascript
// src/plugins/my-plugin/strapi-server.js
module.exports = {
  register({ strapi }) {
    // Registration logic
  },

  bootstrap({ strapi }) {
    // Bootstrap logic
  },

  destroy({ strapi }) {
    // Cleanup logic
  },

  config: {
    default: {},
    validator(config) {},
  },

  controllers: require('./server/controllers'),
  routes: require('./server/routes'),
  services: require('./server/services'),
  policies: require('./server/policies'),
  middlewares: require('./server/middlewares'),
  contentTypes: require('./server/content-types'),
};
```

### Step 3: Admin Entry Point

```javascript
// src/plugins/my-plugin/admin/src/index.js
export default {
  register(app) {
    // Register components, reducers
  },

  bootstrap(app) {
    // Initialize plugin
  },

  registerTrads({ locales }) {
    // Load translations
  },
};
```

## Controller Example

```javascript
// server/controllers/my-controller.js
module.exports = ({ strapi }) => ({
  async index(ctx) {
    const result = await strapi
      .plugin('my-plugin')
      .service('myService')
      .getData();

    ctx.body = { data: result };
  },

  async create(ctx) {
    const { body } = ctx.request;
    const result = await strapi
      .plugin('my-plugin')
      .service('myService')
      .createData(body);

    ctx.body = { data: result };
  },
});
```

## Service Example

```javascript
// server/services/my-service.js
module.exports = ({ strapi }) => ({
  async getData() {
    // Business logic
    return data;
  },

  async createData(data) {
    // Create logic
    return result;
  },
});
```

## Routes Example

```javascript
// server/routes/index.js
module.exports = [
  {
    method: 'GET',
    path: '/',
    handler: 'myController.index',
    config: {
      policies: [],
    },
  },
  {
    method: 'POST',
    path: '/',
    handler: 'myController.create',
    config: {
      policies: [],
    },
  },
];
```

## Accessing Plugin Services

```javascript
// From anywhere
strapi.plugin('my-plugin').service('myService').getData();
strapi.plugin('my-plugin').controller('myController').index(ctx);
```

## Plugin Configuration

```javascript
// config/plugins.js
module.exports = ({ env }) => ({
  'my-plugin': {
    enabled: true,
    config: {
      apiKey: env('MY_PLUGIN_API_KEY'),
      debug: env.bool('MY_PLUGIN_DEBUG', false),
    },
  },
});
```

Access config:
```javascript
const config = strapi.config.get('plugin::my-plugin');
```

## Admin Panel Extensions

### Add Menu Item

```javascript
// admin/src/index.js
export default {
  register(app) {
    app.addMenuLink({
      to: '/plugins/my-plugin',
      icon: PluginIcon,
      intlLabel: {
        id: 'my-plugin.name',
        defaultMessage: 'My Plugin',
      },
      Component: async () => import('./pages/App'),
      permissions: [],
    });
  },
};
```

### Add Settings Page

```javascript
app.createSettingSection(
  {
    id: 'my-plugin',
    intlLabel: {
      id: 'my-plugin.settings',
      defaultMessage: 'My Plugin Settings',
    },
  },
  [
    {
      intlLabel: {
        id: 'my-plugin.settings.general',
        defaultMessage: 'General',
      },
      id: 'general',
      to: '/settings/my-plugin/general',
      Component: async () => import('./pages/Settings'),
      permissions: [],
    },
  ]
);
```

## Extending Existing Plugins

```javascript
// src/extensions/users-permissions/strapi-server.js
module.exports = (plugin) => {
  // Extend controller
  plugin.controllers.user.customAction = async (ctx) => {
    // Custom logic
  };

  // Add route
  plugin.routes['content-api'].routes.push({
    method: 'GET',
    path: '/users/custom',
    handler: 'user.customAction',
  });

  return plugin;
};
```

## Best Practices

1. **Follow Strapi patterns** - Use factories and conventions
2. **Separate concerns** - Controllers thin, services fat
3. **Handle errors** - Use Strapi error utilities
4. **Document APIs** - Add OpenAPI annotations
5. **Test thoroughly** - Unit and integration tests

## Documentation

Reference: [Strapi Plugin Development](https://docs.strapi.io/dev-docs/plugins-development)
