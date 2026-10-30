---
name: dockerfile-generator
description: Write and optimize Dockerfiles following the user's runtime-only scratch pattern for static binaries and multi-arch releases.
when_to_use: Creating, optimizing, or reviewing Dockerfiles and container image builds, e.g. "도커파일 작성", "이미지 용량 최적화", "scratch 이미지로", "런타임 이미지 변경", "베이스 이미지 범프". Not for CI build pipelines (use github-actions-generator or gitlab-ci-arm64) or chart image tag bumps (use helm-bump).
argument-hint: "[app or Dockerfile path]"
license: Apache-2.0
compatibility: hadolint, docker buildx or podman, trivy
metadata:
  version: "2.1.0"
  category: generator
  related: github-actions-generator gitlab-ci-arm64 rust-generator release-retrigger
allowed-tools: Bash(hadolint *) Bash(docker *) Bash(podman *) Bash(trivy *) Bash(go build *) Bash(cargo zigbuild *) Bash(file *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Dockerfile

Generic practice (pinned bases, no secrets, cache-friendly layer order, `.dockerignore`) applies without restating it.

## Base Image Choice

| Workload | Pattern |
|----------|---------|
| Rust or Go service | Runtime-only `scratch`; binary built in CI (cargo-zigbuild musl or `CGO_ENABLED=0`), copied in per `TARGETARCH` |
| Needs a shell or OS packages | Pinned `alpine` minor (e.g. `alpine:3.23`) |
| JVM, Python, Node | Official slim or vendor runtime image, multi-stage |

- No in-image compilation for Rust or Go (no cargo-chef, `golang`, or builder stages) and no distroless
- scratch images copy `ca-certificates.crt` (and zoneinfo when time zones matter) from a pinned alpine stage
- Base images are pulled through the internal proxy registry when the repo already does so

## Required Content

- Numeric non-root `USER` in every image so `runAsNonRoot` can verify it: `65532:65532`, or the base image's own user by UID (e.g. `1000:1000` for `node`)
- scratch images: `ARG TARGETARCH` then `COPY --chmod=755 <name>-linux-${TARGETARCH} /app/<name>`, the filename contract with the release workflow
- OCI labels `title`, `description`, `version`, `licenses` (when the project declares one), `base.name`, `deprecated`
- `org.opencontainers.image.version` equals the release version (Cargo.toml `version` for Rust, `0.1.0` for a new app) because release workflows key off it
- No `HEALTHCHECK`; Kubernetes probes cover it

## Validation

- `hadolint Dockerfile` exits 0, with `# hadolint ignore=DL3018` on the certs stage `apk add --no-cache ca-certificates`
- Local check, not a CI instruction: `docker buildx build --platform linux/amd64,linux/arm64` (or `podman build --platform linux/amd64,linux/arm64 --manifest <name>`) succeeds after both per-arch binaries are built
- `trivy image` reports no fixable HIGH or CRITICAL
