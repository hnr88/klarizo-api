# Redis BullMQ Expert Agent

Specialized in Redis and BullMQ for job queue management in Strapi.

## Expertise

- Redis connection with ioredis
- BullMQ queue creation and management
- Job producers and consumers
- Worker patterns and concurrency
- Error handling and retries
- Scheduled and delayed jobs
- Queue monitoring and cleanup

## Triggers

Use this agent when:
- Setting up job queues
- Creating background workers
- Implementing scheduled tasks
- Handling async operations
- Managing job retries and failures

## Redis Connection

### Environment Variables

```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_TLS=false
```

### Connection Configuration

```javascript
// src/extensions/redis/connection.js
'use strict';

const Redis = require('ioredis');

let redisConnection = null;

function getRedisConnection() {
  if (redisConnection) return redisConnection;

  const config = {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT, 10) || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
    maxRetriesPerRequest: null, // Required for BullMQ
    enableReadyCheck: false,
  };

  if (process.env.REDIS_TLS === 'true') {
    config.tls = {};
  }

  redisConnection = new Redis(config);

  redisConnection.on('error', (err) => {
    strapi.log.error('Redis connection error:', err);
  });

  redisConnection.on('connect', () => {
    strapi.log.info('Redis connected');
  });

  return redisConnection;
}

module.exports = { getRedisConnection };
```

## BullMQ Patterns

### Queue Creation

```javascript
// src/extensions/queues/email-queue.js
'use strict';

const { Queue } = require('bullmq');
const { getRedisConnection } = require('../redis/connection');

let emailQueue = null;

function getEmailQueue() {
  if (emailQueue) return emailQueue;

  emailQueue = new Queue('email', {
    connection: getRedisConnection(),
    defaultJobOptions: {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 1000,
      },
      removeOnComplete: {
        count: 100,
        age: 24 * 60 * 60, // 24 hours
      },
      removeOnFail: {
        count: 500,
      },
    },
  });

  return emailQueue;
}

module.exports = { getEmailQueue };
```

### Adding Jobs

```javascript
// Add a job
const queue = getEmailQueue();

// Simple job
await queue.add('send-welcome', {
  to: 'user@example.com',
  subject: 'Welcome!',
  template: 'welcome',
});

// Delayed job (send in 1 hour)
await queue.add('send-reminder', {
  to: 'user@example.com',
  subject: 'Reminder',
}, {
  delay: 60 * 60 * 1000,
});

// Scheduled job (cron)
await queue.add('daily-report', {
  type: 'daily',
}, {
  repeat: {
    pattern: '0 9 * * *', // Every day at 9 AM
  },
});

// Priority job
await queue.add('urgent-notification', {
  message: 'Critical alert',
}, {
  priority: 1, // Lower = higher priority
});
```

### Worker Creation

```javascript
// src/extensions/workers/email-worker.js
'use strict';

const { Worker } = require('bullmq');
const { getRedisConnection } = require('../redis/connection');

function startEmailWorker() {
  const worker = new Worker(
    'email',
    async (job) => {
      const { to, subject, template } = job.data;

      strapi.log.info(`Processing email job ${job.id}: ${subject}`);

      try {
        await strapi.plugin('email').service('email').send({
          to,
          subject,
          text: `Email from template: ${template}`,
        });

        return { sent: true, to };
      } catch (error) {
        strapi.log.error(`Email job ${job.id} failed:`, error);
        throw error; // Will trigger retry
      }
    },
    {
      connection: getRedisConnection(),
      concurrency: 5, // Process 5 jobs in parallel
      limiter: {
        max: 10,
        duration: 1000, // Max 10 jobs per second
      },
    }
  );

  worker.on('completed', (job, result) => {
    strapi.log.info(`Job ${job.id} completed:`, result);
  });

  worker.on('failed', (job, err) => {
    strapi.log.error(`Job ${job.id} failed:`, err.message);
  });

  worker.on('stalled', (jobId) => {
    strapi.log.warn(`Job ${jobId} stalled`);
  });

  return worker;
}

module.exports = { startEmailWorker };
```

### Queue Events

```javascript
// src/extensions/queues/queue-events.js
'use strict';

const { QueueEvents } = require('bullmq');
const { getRedisConnection } = require('../redis/connection');

function setupQueueEvents(queueName) {
  const queueEvents = new QueueEvents(queueName, {
    connection: getRedisConnection(),
  });

  queueEvents.on('completed', ({ jobId, returnvalue }) => {
    strapi.log.info(`[${queueName}] Job ${jobId} completed:`, returnvalue);
  });

  queueEvents.on('failed', ({ jobId, failedReason }) => {
    strapi.log.error(`[${queueName}] Job ${jobId} failed:`, failedReason);
  });

  queueEvents.on('progress', ({ jobId, data }) => {
    strapi.log.info(`[${queueName}] Job ${jobId} progress:`, data);
  });

  return queueEvents;
}

module.exports = { setupQueueEvents };
```

## Strapi Integration

### Bootstrap Workers

```javascript
// src/index.js
'use strict';

module.exports = {
  async bootstrap({ strapi }) {
    // Only start workers in non-test environments
    if (process.env.NODE_ENV !== 'test') {
      const { startEmailWorker } = require('./extensions/workers/email-worker');
      const { setupQueueEvents } = require('./extensions/queues/queue-events');

      // Start workers
      startEmailWorker();

      // Setup event listeners
      setupQueueEvents('email');

      strapi.log.info('BullMQ workers started');
    }
  },

  async destroy({ strapi }) {
    // Cleanup on shutdown
    const { getRedisConnection } = require('./extensions/redis/connection');
    const connection = getRedisConnection();
    if (connection) {
      await connection.quit();
    }
  },
};
```

### Service Integration

```javascript
// src/api/notification/services/notification.js
'use strict';

const { createCoreService } = require('@strapi/strapi').factories;
const { getEmailQueue } = require('../../../extensions/queues/email-queue');

module.exports = createCoreService('api::notification.notification', ({ strapi }) => ({
  async sendWelcomeEmail(userId) {
    const user = await strapi.documents('plugin::users-permissions.user').findOne({
      documentId: userId,
      fields: ['email', 'username'],
    });

    if (!user) throw new Error('User not found');

    const queue = getEmailQueue();
    await queue.add('welcome-email', {
      to: user.email,
      username: user.username,
      template: 'welcome',
    });

    return { queued: true };
  },

  async scheduleReminder(userId, reminderDate) {
    const queue = getEmailQueue();
    const delay = new Date(reminderDate).getTime() - Date.now();

    await queue.add('reminder', {
      userId,
      type: 'reminder',
    }, {
      delay: Math.max(0, delay),
    });

    return { scheduled: true, date: reminderDate };
  },
}));
```

## Job Data Best Practices

```javascript
// GOOD: Minimal, serializable data
await queue.add('process-order', {
  orderId: 'abc123def456',
  action: 'confirm',
});

// BAD: Large objects, circular references
await queue.add('process-order', {
  order: fullOrderObject, // Don't pass full objects
  user: fullUserObject,   // Fetch in worker instead
});
```

## Error Handling

```javascript
// Worker with proper error handling
const worker = new Worker('tasks', async (job) => {
  try {
    // Validate job data
    if (!job.data.documentId) {
      throw new Error('Missing documentId');
    }

    // Process job
    const result = await processTask(job.data);

    // Update progress
    await job.updateProgress(100);

    return result;
  } catch (error) {
    // Log error with context
    strapi.log.error({
      jobId: job.id,
      jobName: job.name,
      attempt: job.attemptsMade,
      error: error.message,
    });

    // Rethrow to trigger retry
    throw error;
  }
}, {
  connection: getRedisConnection(),
});
```

## Queue Management

```javascript
// Get queue status
const queue = getEmailQueue();

const counts = await queue.getJobCounts();
// { waiting: 5, active: 2, completed: 100, failed: 3, delayed: 10 }

// Get failed jobs
const failedJobs = await queue.getFailed(0, 10);

// Retry failed jobs
for (const job of failedJobs) {
  await job.retry();
}

// Clean old jobs
await queue.clean(24 * 60 * 60 * 1000, 100, 'completed'); // Remove completed older than 24h

// Pause/Resume
await queue.pause();
await queue.resume();

// Drain queue (remove all jobs)
await queue.drain();
```

## Best Practices

1. **Use minimal job data** - Pass IDs, fetch data in worker
2. **Set appropriate retries** - Use exponential backoff
3. **Handle stalled jobs** - Workers can crash, jobs may stall
4. **Clean old jobs** - Use removeOnComplete/removeOnFail
5. **Monitor queue health** - Log counts, failed jobs
6. **Graceful shutdown** - Close connections on destroy
7. **Separate queues** - Different queues for different job types
8. **Rate limit** - Prevent overwhelming external services

## Common Queue Types

| Queue | Purpose |
|-------|---------|
| `email` | Email sending |
| `notifications` | Push notifications |
| `imports` | Data import processing |
| `exports` | Report generation |
| `media` | Image/video processing |
| `webhooks` | External API calls |
| `cleanup` | Scheduled cleanup tasks |
