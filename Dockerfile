# Use Node.js 20 Alpine image as base
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# Install system dependencies required for Strapi
RUN apk add --no-cache libc6-compat python3 make g++ vips-dev
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml* ./
# Install pnpm and dependencies
RUN corepack enable pnpm && pnpm install --frozen-lockfile

# Build stage
FROM base AS builder
WORKDIR /app
# Install build dependencies
RUN apk add --no-cache vips-dev
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build Strapi admin
RUN corepack enable pnpm && pnpm run build

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Install runtime dependencies for sharp/vips
RUN apk add --no-cache vips

# Create non-root user
RUN addgroup --system --gid 1001 strapi
RUN adduser --system --uid 1001 strapi

# Copy built application
COPY --from=builder --chown=strapi:strapi /app ./

# Ensure uploads directory exists with correct permissions
RUN mkdir -p /app/public/uploads && chown -R strapi:strapi /app/public/uploads

USER strapi

# Expose Strapi default port (internal)
EXPOSE 1337

ENV PORT=1337
ENV HOST=0.0.0.0

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:1337/api/health || exit 1

# Start Strapi
CMD ["node_modules/.bin/strapi", "start"]
