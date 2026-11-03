# =========================================================
# Stage 1: Build React + TypeScript application
# =========================================================
FROM node:22-alpine AS builder

WORKDIR /workspace

# Enable pnpm
RUN corepack enable

# Copy workspace manifests
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY tsconfig.base.json ./

# Copy package manifests for workspace dependency resolution
COPY ./package.json ./package.json
COPY packages/shared/package.json ./packages/shared/package.json

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy application source
COPY . .
COPY packages/shared ./packages/shared

# Build production artifact
RUN pnpm --filter @app/web build

# =========================================================
# Stage 2: Production runtime
# =========================================================
FROM nginxinc/nginx-unprivileged:stable-alpine AS runtime

# Nginx configuration
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Copy React production artifact
COPY --from=builder \
    /workspace/./dist \
    /usr/share/nginx/html

# Container health check
HEALTHCHECK --interval=30s \
    --timeout=5s \
    --start-period=10s \
    --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
