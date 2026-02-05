# Dockerfile Generator

Generate production-ready, secure, and optimized Dockerfiles.

## When to Use
- Creating new Dockerfiles for applications
- Optimizing existing Dockerfiles
- Converting application requirements to container images

## Core Rules

### 1. Use Multi-Stage Builds

Separate build tools from runtime to minimize image size.

### 2. Pin Image Version

Never use `latest` tag. Always pin specific version (e.g., `node:20.11-alpine`).

### 3. Clean Cache in Same Layer

Remove package manager cache after install.

### 4. Combine Multiple RUN/COPY

Use `&&` and `\` to reduce layers.

```dockerfile
# Bad
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# Good
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
```

### 5. Base Image Priority

| Image | Size | Use Case |
|-------|------|----------|
| `alpine` | ~5MB | Default choice |
| `distroless` | ~2MB | Apps without shell |
| `slim` | ~80MB | Apps needing specific packages |
| `scratch` | 0MB | Static Go binaries |

Pick order: `alpine` > `distroless` > `slim` > `scratch`

## Dockerfile Best Practices

### Multi-Stage Build Template (Required)
```dockerfile
# ============================================
# Stage 1: Build
# ============================================
FROM <base-image>:<version> AS builder

WORKDIR /app

# Install dependencies first (for better caching)
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy source and build
COPY . .
RUN npm run build

# ============================================
# Stage 2: Production
# ============================================
FROM <minimal-base-image>:<version>

# Security: Create non-root user
RUN addgroup --gid 1000 appgroup && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos "" appuser

WORKDIR /app

# Copy only necessary artifacts from builder
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules

# Security: Run as non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

EXPOSE 8080

CMD ["node", "dist/main.js"]
```

### Language-Specific Templates

#### Node.js
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build && npm prune --production

FROM node:20-alpine
RUN addgroup -g 1000 node && adduser -u 1000 -G node -s /bin/sh -D node
WORKDIR /app
COPY --from=builder --chown=node:node /app/dist ./dist
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

#### Go
```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o main .

FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/main /main
USER 1000:1000
ENTRYPOINT ["/main"]
```

#### Python
```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install --no-cache-dir poetry
COPY pyproject.toml poetry.lock ./
RUN poetry export -f requirements.txt -o requirements.txt
RUN pip install --no-cache-dir --target=/app/deps -r requirements.txt

FROM python:3.12-slim
RUN useradd --uid 1000 --create-home appuser
WORKDIR /app
COPY --from=builder /app/deps /app/deps
COPY --chown=appuser:appuser . .
ENV PYTHONPATH=/app/deps
USER appuser
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### Java (Spring Boot)
```dockerfile
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY gradle gradlew build.gradle settings.gradle ./
COPY src ./src
RUN ./gradlew build -x test --no-daemon

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -g 1000 java && adduser -u 1000 -G java -s /bin/sh -D java
WORKDIR /app
COPY --from=builder --chown=java:java /app/build/libs/*.jar app.jar
USER java
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## Security Guidelines

### Required Security Measures
1. **Non-root user**: Always run as non-root
2. **Minimal base image**: Use alpine, distroless, or scratch
3. **No secrets**: Never COPY secrets or use ARG for secrets
4. **Pinned versions**: Always pin base image versions
5. **Read-only filesystem**: Design for read-only when possible

### Security Checklist
```
[ ] Using specific image version (not 'latest')
[ ] Running as non-root user (USER instruction)
[ ] Using minimal base image
[ ] No secrets in Dockerfile
[ ] No unnecessary packages installed
[ ] HEALTHCHECK defined
[ ] Using multi-stage build
```

## Optimization Guidelines

### Layer Caching
- Copy dependency files first, then source code
- Combine RUN commands to reduce layers
- Order instructions from least to most frequently changing

### Size Reduction
```dockerfile
# Clean up in same layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Use .dockerignore
# .git, node_modules, *.log, etc.
```

## Validation After Generation
```bash
# Lint Dockerfile
hadolint Dockerfile

# Build and check size
docker build -t test:latest .
docker images test:latest

# Scan for vulnerabilities
docker scout cves test:latest
# or
trivy image test:latest
```
