---
name: gitlab-ci-arm64
description: Move GitLab CI container image builds onto arm64 runners, as a multi-arch build (amd64 + arm64 + manifest) or a single native arm64 build, chosen by where the app is scheduled.
when_to_use: Moving a .gitlab-ci.yml image build to arm64 or Graviton, adding or dropping multi-arch or manifest-list jobs, or simplifying docker build steps, e.g. "멀티아치 빌드 전환", "Graviton 전환", "arm64 단일 빌드로 전환", "Gitlab CI arm64 전환", "manifest 잡 추가", "manifest 잡 제거", "buildx 빼고 docker build 로", "CI 주석 정리". Not for GitHub Actions (use github-actions-generator), Dockerfile contents (use dockerfile-generator), or committing and opening the MR (use git-ship).
argument-hint: "[.gitlab-ci.yml path] [multi|single]"
license: Apache-2.0
compatibility: glab (ci lint), docker, kubectl for the rollout check
metadata:
  version: "2.1.0"
  category: generator
  related: dockerfile-generator k8s-manifest git-ship
allowed-tools: Bash(glab ci lint *) Bash(glab api *) Bash(kubectl get *) Bash(kubectl describe *) Bash(docker buildx imagetools inspect *) Bash(grep *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# GitLab CI arm64 Build

Runners are split per architecture, so a job's runner tag decides the image architecture: untagged jobs land on the default amd64 runner, `tags: [arm64]` jobs on the arm64 runner.

## Mode

| Mode | When | Result |
|------|------|--------|
| `multi` (default) | Any environment the pipeline deploys to still schedules the app on amd64, or scheduling is unknown | Per-arch build jobs and a manifest job; one tag serves both architectures |
| `single` | Every environment passes Before Switching | One arm64 build job, no manifest |

Only a literal `multi` or `single` argument overrides the check, a prose claim ("모든 환경 arm64로 옮겼어") does not. A gate row that cannot be run counts as unknown, so the result stays `multi` and the response lists the unchecked rows. Forcing `single` on an app still scheduled on amd64 fails with `no match for platform in manifest`, so the MR states it as a blocker.

## Output Requirements

- `docker build`, never `docker buildx build`; no `--platform` flag, the runner's native architecture fills `TARGETARCH`
- `docker build --tag <image>:<tag>` names the image in the build step, then `docker push <image>:<tag>`; no separate `docker tag` step
- The deploy tag keeps its existing form without an architecture suffix (`tag-$CI_COMMIT_SHORT_SHA`), the tag the deploy repo's values file references
- `DOCKER_BUILDKIT: "1"` stays set when the Dockerfile uses `RUN --mount=type=secret`; secrets go through `--secret id=<id>,env=<VAR>`, never `--build-arg`
- Jobs that referenced a removed job through `needs:` or `dependencies:` point at the job that now produces the deploy tag
- Registry path, build args, rules, job image, and existing cache steps carry over verbatim; when branches of one repo already differ, each keeps its own values and the MR notes the difference
- Dockerfile stays as is unless it hardcodes an architecture (`GOARCH=amd64`, `FROM --platform=linux/amd64`, `x86_64` download URLs)
- Comments inside the jobs this change rewrites go, trailing `# ...` and section banners included. Comments elsewhere stay unless the request asks for cleanup ("CI 주석 정리")

### Multi Mode

- A hidden `.deploy-docker` job holds the shared part (stage, rules, dind service, registry login); every build and manifest job extends it, so each one logs in. Steps that read build artifacts (`test -f $JAR`) stay in the build jobs
- `deploy-docker-amd64` runs untagged with `ARCH: amd64`; `deploy-docker-arm64` extends it with `tags: [arm64]` and `ARCH: arm64`; both push `<tag>-$ARCH` in parallel
- `deploy-manifest` has `needs:` on both build jobs and `dependencies: []`, and joins them under the deploy tag with `docker buildx imagetools create`, the only buildx use

## Before Switching

Gate for `single` in every environment the pipeline deploys to:

| Check | Pass condition |
|-------|----------------|
| Current pod nodes | `kubectl get node <node> -L kubernetes.io/arch` shows `arm64` for every pod of the app |
| Chart scheduling | The values file the deploy-tag job edits pins arm64: `nodeSelector` `kubernetes.io/arch: arm64`, an arm64 nodepool, or matching affinity and tolerations |
| arm64 capacity | An arm64 nodepool exists in that cluster |

## Reference

```yaml
.deploy-docker:
  extends: .docker-dind
  before_script:
    - !reference [.registry-login, script]

deploy-docker-amd64:
  extends: .deploy-docker
  variables:
    ARCH: amd64
  script:
    - docker build --secret id=npm_token,env=NPM_TOKEN --build-arg APP_ENV=$TARGET_ENV --tag $IMAGE:$TAG-$ARCH .
    - docker push $IMAGE:$TAG-$ARCH

deploy-docker-arm64:
  extends: deploy-docker-amd64
  tags:
    - arm64
  variables:
    ARCH: arm64

deploy-manifest:
  extends: .deploy-docker
  dependencies: []
  needs:
    - deploy-docker-amd64
    - deploy-docker-arm64
  script:
    - docker buildx imagetools create --tag $IMAGE:$TAG $IMAGE:$TAG-amd64 $IMAGE:$TAG-arm64
```

`single` is one job named `deploy-docker` with `tags: [arm64]`, `--tag $IMAGE:$TAG`, and no `ARCH`. From `multi`, the amd64 job is renamed and `.deploy-docker` folds into it. No per-architecture jobs and no manifest-list job.

## Validation

- Static `glab ci lint` reports valid; `glab ci lint --dry-run --ref <branch>` simulates a push pipeline and fails on workflow rules that accept only `web`, and such rules also skip API-created runs, so a test deploy uses the "Run pipeline" page (`/-/pipelines/new?ref=<branch>&var[KEY]=value`)
- `grep -nE 'buildx build|--platform|docker tag' .gitlab-ci.yml` returns nothing; `single` also returns nothing for `imagetools|docker manifest|\$ARCH`
- `grep -nE '^\s*#|\s#\s' .gitlab-ci.yml` shows no comment inside the rewritten jobs (`${#VAR}` is shell, not a comment)
- The runner API `architecture` field is the runner manager's, not the job pod's; the job log's package index (`x86_64`, `aarch64`) shows the build architecture
- After a deploy run: `multi` shows `linux/amd64` and `linux/arm64` in `docker buildx imagetools inspect $IMAGE:$TAG`; `single` shows `aarch64` in the build log; a new pod runs with no `ErrImagePull`
