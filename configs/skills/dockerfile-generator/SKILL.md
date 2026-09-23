---
name: dockerfile-generator
description: Generate production-ready Dockerfiles. Use when creating, optimizing, or reviewing Dockerfiles and container image builds.
---

# Dockerfile Generator

Generate production-ready, secure, and optimized Dockerfiles.

## Output Requirements

- Multi-stage builds: separate build stage from runtime stage
- Base image versions pinned (never `latest`)
- Package manager cache cleaned in the same RUN layer as install
- Multiple related RUN/COPY commands combined with `&&` and `\`
- Non-root user created and set with `USER` instruction
- `HEALTHCHECK` instruction defined
- Dependency files copied before source code for layer caching
- Instructions ordered from least to most frequently changing
- `.dockerignore` recommended alongside Dockerfile

## Base Image Selection

| Priority | Image | Size | Use Case |
|----------|-------|------|----------|
| 1 | `alpine` | ~5MB | Default choice |
| 2 | `distroless` | ~2MB | Apps without shell needs |
| 3 | `slim` | ~80MB | Apps needing specific system packages |
| 4 | `scratch` | 0MB | Static Go/Rust binaries |

## Security Constraints

- Non-root user required (`USER` instruction)
- No secrets in Dockerfile (no `COPY` of credentials, no `ARG` for secrets)
- Minimal base image preferred
- `--no-install-recommends` for apt-get
- Read-only filesystem compatible when possible

## Layer Optimization

```dockerfile
# Combined install + cleanup in single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
```

## Validation

- `hadolint Dockerfile` for linting
- `docker scout cves` or `trivy image` for vulnerability scanning
