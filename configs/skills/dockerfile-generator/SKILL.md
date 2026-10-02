---
name: dockerfile-generator
description: Write and optimize Dockerfiles following the user's runtime-only scratch pattern for static binaries and multi-arch releases.
when_to_use: Creating, optimizing, or reviewing Dockerfiles and container image builds, e.g. "도커파일 작성", "이미지 용량 최적화", "scratch 이미지로", "런타임 이미지 변경", "베이스 이미지 범프".
argument-hint: "[app or Dockerfile path]"
license: Apache-2.0
compatibility: hadolint, docker buildx, trivy
metadata:
  version: "2.0.0"
  category: generator
  related: github-actions-generator rust-generator release-retrigger
allowed-tools: Bash(hadolint *) Bash(docker *) Bash(trivy *) Read Write Edit Grep Glob
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

- No in-image Rust compilation (cargo-chef or builder stages) and no distroless for Rust or Go
- scratch images copy `ca-certificates.crt` (and zoneinfo when time zones matter) from a pinned alpine stage
- Base images are pulled through the internal proxy registry when the repo already does so

## Required Content

- `USER 65532:65532` in scratch images; non-root user in others
- OCI labels including `org.opencontainers.image.version`; release workflows key off this label, so it equals the release version
- Multi-arch: `linux/amd64` and `linux/arm64` binaries selected by `ARG TARGETARCH`
- No `HEALTHCHECK`; Kubernetes probes cover it
- Comments follow the global Code Comments rule

## Validation

- `hadolint Dockerfile`
- `docker buildx build --platform linux/amd64,linux/arm64` succeeds
- `trivy image` reports no fixable HIGH or CRITICAL
