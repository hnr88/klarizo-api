# Cloudflare R2 Expert Agent

Specialized in Cloudflare R2 object storage using S3-compatible API.

## Expertise

- S3-compatible API with @aws-sdk/client-s3
- Bucket and object operations
- Presigned URLs for secure uploads/downloads
- Multipart uploads for large files
- CORS configuration
- Content-Type handling
- Error handling patterns

## Triggers

Use this agent when:
- Uploading files to R2
- Generating presigned URLs
- Managing stored objects
- Handling file downloads
- Setting up storage infrastructure

## Environment Variables

```env
R2_ACCOUNT_ID=your-cloudflare-account-id
R2_ACCESS_KEY_ID=your-r2-access-key
R2_SECRET_ACCESS_KEY=your-r2-secret-key
R2_BUCKET_NAME=your-bucket-name
R2_PUBLIC_URL=https://your-bucket.your-domain.com
```

## S3 Client Configuration

```javascript
// src/extensions/r2/client.js
'use strict';

const { S3Client } = require('@aws-sdk/client-s3');

let r2Client = null;

function getR2Client() {
  if (r2Client) return r2Client;

  r2Client = new S3Client({
    region: 'auto',
    endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: process.env.R2_ACCESS_KEY_ID,
      secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
    },
  });

  return r2Client;
}

function getBucketName() {
  return process.env.R2_BUCKET_NAME;
}

function getPublicUrl() {
  return process.env.R2_PUBLIC_URL;
}

module.exports = { getR2Client, getBucketName, getPublicUrl };
```

## Object Operations

### Upload Object

```javascript
// src/extensions/r2/operations.js
'use strict';

const { PutObjectCommand, GetObjectCommand, DeleteObjectCommand, HeadObjectCommand } = require('@aws-sdk/client-s3');
const { getR2Client, getBucketName, getPublicUrl } = require('./client');
const crypto = require('crypto');
const path = require('path');

async function uploadObject(buffer, filename, contentType, folder = 'uploads') {
  const client = getR2Client();
  const bucket = getBucketName();

  // Generate unique key
  const ext = path.extname(filename);
  const baseName = path.basename(filename, ext);
  const hash = crypto.randomBytes(8).toString('hex');
  const key = `${folder}/${baseName}-${hash}${ext}`;

  const command = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    Body: buffer,
    ContentType: contentType,
  });

  await client.send(command);

  return {
    key,
    url: `${getPublicUrl()}/${key}`,
    contentType,
    size: buffer.length,
  };
}

async function getObject(key) {
  const client = getR2Client();
  const bucket = getBucketName();

  const command = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  });

  const response = await client.send(command);

  // Convert stream to buffer
  const chunks = [];
  for await (const chunk of response.Body) {
    chunks.push(chunk);
  }

  return {
    buffer: Buffer.concat(chunks),
    contentType: response.ContentType,
    contentLength: response.ContentLength,
  };
}

async function deleteObject(key) {
  const client = getR2Client();
  const bucket = getBucketName();

  const command = new DeleteObjectCommand({
    Bucket: bucket,
    Key: key,
  });

  await client.send(command);
  return { deleted: true, key };
}

async function objectExists(key) {
  const client = getR2Client();
  const bucket = getBucketName();

  try {
    const command = new HeadObjectCommand({
      Bucket: bucket,
      Key: key,
    });
    await client.send(command);
    return true;
  } catch (error) {
    if (error.name === 'NotFound') {
      return false;
    }
    throw error;
  }
}

module.exports = { uploadObject, getObject, deleteObject, objectExists };
```

### List Objects

```javascript
const { ListObjectsV2Command } = require('@aws-sdk/client-s3');

async function listObjects(prefix = '', maxKeys = 100, continuationToken = null) {
  const client = getR2Client();
  const bucket = getBucketName();

  const command = new ListObjectsV2Command({
    Bucket: bucket,
    Prefix: prefix,
    MaxKeys: maxKeys,
    ContinuationToken: continuationToken,
  });

  const response = await client.send(command);

  return {
    objects: response.Contents || [],
    isTruncated: response.IsTruncated,
    nextToken: response.NextContinuationToken,
  };
}
```

### Copy Object

```javascript
const { CopyObjectCommand } = require('@aws-sdk/client-s3');

async function copyObject(sourceKey, destinationKey) {
  const client = getR2Client();
  const bucket = getBucketName();

  const command = new CopyObjectCommand({
    Bucket: bucket,
    CopySource: `${bucket}/${sourceKey}`,
    Key: destinationKey,
  });

  await client.send(command);

  return {
    sourceKey,
    destinationKey,
    url: `${getPublicUrl()}/${destinationKey}`,
  };
}
```

## Presigned URLs

### Upload URL (PUT)

```javascript
// src/extensions/r2/presigned.js
'use strict';

const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getR2Client, getBucketName, getPublicUrl } = require('./client');
const crypto = require('crypto');
const path = require('path');

async function getUploadUrl(filename, contentType, folder = 'uploads', expiresIn = 3600) {
  const client = getR2Client();
  const bucket = getBucketName();

  // Generate unique key
  const ext = path.extname(filename);
  const baseName = path.basename(filename, ext);
  const hash = crypto.randomBytes(8).toString('hex');
  const key = `${folder}/${baseName}-${hash}${ext}`;

  const command = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    ContentType: contentType,
  });

  const uploadUrl = await getSignedUrl(client, command, { expiresIn });

  return {
    uploadUrl,
    key,
    publicUrl: `${getPublicUrl()}/${key}`,
    expiresIn,
    contentType,
  };
}
```

### Download URL (GET)

```javascript
async function getDownloadUrl(key, expiresIn = 3600) {
  const client = getR2Client();
  const bucket = getBucketName();

  const command = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  });

  const downloadUrl = await getSignedUrl(client, command, { expiresIn });

  return {
    downloadUrl,
    key,
    expiresIn,
  };
}

module.exports = { getUploadUrl, getDownloadUrl };
```

## Multipart Upload (Large Files)

```javascript
// src/extensions/r2/multipart.js
'use strict';

const {
  CreateMultipartUploadCommand,
  UploadPartCommand,
  CompleteMultipartUploadCommand,
  AbortMultipartUploadCommand,
} = require('@aws-sdk/client-s3');
const { getR2Client, getBucketName, getPublicUrl } = require('./client');

const PART_SIZE = 5 * 1024 * 1024; // 5MB minimum part size

async function uploadLargeFile(buffer, key, contentType) {
  const client = getR2Client();
  const bucket = getBucketName();

  // Initiate multipart upload
  const createCommand = new CreateMultipartUploadCommand({
    Bucket: bucket,
    Key: key,
    ContentType: contentType,
  });
  const { UploadId } = await client.send(createCommand);

  try {
    const parts = [];
    let partNumber = 1;

    // Upload parts
    for (let offset = 0; offset < buffer.length; offset += PART_SIZE) {
      const end = Math.min(offset + PART_SIZE, buffer.length);
      const partBuffer = buffer.slice(offset, end);

      const uploadPartCommand = new UploadPartCommand({
        Bucket: bucket,
        Key: key,
        UploadId,
        PartNumber: partNumber,
        Body: partBuffer,
      });

      const { ETag } = await client.send(uploadPartCommand);
      parts.push({ PartNumber: partNumber, ETag });
      partNumber++;
    }

    // Complete multipart upload
    const completeCommand = new CompleteMultipartUploadCommand({
      Bucket: bucket,
      Key: key,
      UploadId,
      MultipartUpload: { Parts: parts },
    });

    await client.send(completeCommand);

    return {
      key,
      url: `${getPublicUrl()}/${key}`,
      size: buffer.length,
      parts: parts.length,
    };
  } catch (error) {
    // Abort on failure
    const abortCommand = new AbortMultipartUploadCommand({
      Bucket: bucket,
      Key: key,
      UploadId,
    });
    await client.send(abortCommand);
    throw error;
  }
}

module.exports = { uploadLargeFile };
```

## Strapi Integration

### Upload Service

```javascript
// src/api/upload/services/r2-upload.js
'use strict';

const { uploadObject, deleteObject } = require('../../../extensions/r2/operations');
const { getUploadUrl } = require('../../../extensions/r2/presigned');

module.exports = ({ strapi }) => ({
  async uploadFile(file, folder = 'uploads') {
    const buffer = file.buffer || Buffer.from(file.stream);
    const result = await uploadObject(buffer, file.name, file.type, folder);

    return {
      url: result.url,
      key: result.key,
      mime: result.contentType,
      size: result.size,
      provider: 'r2',
    };
  },

  async deleteFile(key) {
    return deleteObject(key);
  },

  async getPresignedUploadUrl(filename, contentType, folder = 'uploads') {
    return getUploadUrl(filename, contentType, folder);
  },
});
```

### Controller for Presigned URLs

```javascript
// src/api/upload/controllers/presigned.js
'use strict';

module.exports = {
  async getUploadUrl(ctx) {
    const { filename, contentType, folder } = ctx.request.body;

    if (!filename || !contentType) {
      return ctx.badRequest('filename and contentType are required');
    }

    const result = await strapi.service('api::upload.r2-upload').getPresignedUploadUrl(
      filename,
      contentType,
      folder
    );

    return result;
  },
};
```

### Route for Presigned URLs

```javascript
// src/api/upload/routes/01-presigned.js
module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/upload/presigned',
      handler: 'presigned.getUploadUrl',
      config: {
        policies: ['is-authenticated'],
      },
    },
  ],
};
```

## Error Handling

```javascript
async function safeUpload(buffer, filename, contentType) {
  try {
    return await uploadObject(buffer, filename, contentType);
  } catch (error) {
    if (error.name === 'NoSuchBucket') {
      strapi.log.error('R2 bucket does not exist');
      throw new Error('Storage configuration error');
    }
    if (error.name === 'AccessDenied') {
      strapi.log.error('R2 access denied - check credentials');
      throw new Error('Storage access error');
    }
    if (error.$metadata?.httpStatusCode === 413) {
      throw new Error('File too large');
    }
    strapi.log.error('R2 upload error:', error);
    throw new Error('Failed to upload file');
  }
}
```

## Content-Type Detection

```javascript
const mime = require('mime-types');

function getContentType(filename) {
  return mime.lookup(filename) || 'application/octet-stream';
}

// Common content types
const CONTENT_TYPES = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.pdf': 'application/pdf',
  '.json': 'application/json',
  '.csv': 'text/csv',
  '.zip': 'application/zip',
};
```

## Best Practices

1. **Use presigned URLs** - For direct browser uploads
2. **Set proper Content-Type** - Important for browser handling
3. **Use unique keys** - Add hash/timestamp to prevent collisions
4. **Handle errors gracefully** - Map R2 errors to user-friendly messages
5. **Clean up failed uploads** - Abort multipart uploads on failure
6. **Use appropriate folder structure** - Organize by type/date
7. **Set cache headers** - For public static assets
8. **Validate file types** - Before upload, check allowed types
9. **Limit file sizes** - Prevent abuse

## Common Patterns

| Pattern | Use Case |
|---------|----------|
| Direct upload | Small files, server-side processing |
| Presigned PUT | Large files, browser uploads |
| Presigned GET | Private file downloads |
| Multipart | Files > 100MB |
| Copy | Moving/duplicating files |

## R2 Limits

- Object key: max 1024 bytes
- Object size: max 5TB
- Multipart: 10,000 parts max
- Part size: 5MB min, 5GB max
- Metadata: 2KB max
