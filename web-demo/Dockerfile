# Multi-stage Dockerfile for Web Demo

# Stage 1: Build frontend
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend

# Copy frontend package files
COPY frontend/package*.json ./
RUN npm install --include=dev --no-audit --no-fund --legacy-peer-deps

# Copy frontend source
COPY frontend/ .

# Build frontend
RUN npm run build

# Stage 2: Build backend
FROM node:18-alpine AS backend-builder

WORKDIR /app/backend

# Copy backend package files
COPY backend/package*.json ./
RUN npm install --include=dev --no-audit --no-fund --legacy-peer-deps

# Copy backend source
COPY backend/ .

# Build backend
RUN npx tsc -p tsconfig.json

# Remove dev dependencies
RUN npm prune --omit=dev

# Stage 3: Production image
FROM node:18-alpine

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy built backend
COPY --from=backend-builder --chown=nodejs:nodejs /app/backend/dist ./dist
COPY --from=backend-builder --chown=nodejs:nodejs /app/backend/node_modules ./node_modules
COPY --from=backend-builder --chown=nodejs:nodejs /app/backend/package*.json ./

# Copy built frontend
COPY --from=frontend-builder --chown=nodejs:nodejs /app/frontend/build ./public

# Environment variables
ENV NODE_ENV=production \
    PORT=3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3001

# Start server with signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
