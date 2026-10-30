---
name: k8s-manifest
description: Author and review raw Kubernetes manifests and CRD resources (Karpenter, External Secrets, Gateway API, Istio, admission policies) following EKS conventions and the user's field rules.
when_to_use: Writing or reviewing Deployments, Services, NodePools, ExternalSecrets, HTTPRoutes, DestinationRules, admission policies, or other YAML resources, e.g. "매니페스트 작성", "NodePool 추가", "ExternalSecret 생성", "ArgoCD diff 해소", "VAP 정책 작성", "kyverno 정책 작성". Not for Helm template structure (use helm-chart), chart or image version bumps (use helm-bump), Falco rules (use falco-rules), or AWS resources such as the interruption SQS queue (use terraform-generator).
argument-hint: "[manifest path or resource kind]"
license: Apache-2.0
compatibility: kubeconform; kubectl for server-side dry-run
metadata:
  version: "2.2.0"
  category: generator
  related: helm-chart done-check
allowed-tools: Bash(kubeconform *) Bash(kubectl apply --dry-run=server *) Bash(kubectl get *) Bash(kubectl api-resources *) Bash(jq *) Bash(yq *) Bash(diff *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Kubernetes Manifest

Standard production practice (pinned tags, non-root `securityContext`, probes, `app.kubernetes.io/*` labels, PDB, HA replicas) applies without restating it. Comments follow the global Code Comments rule. Below are the conventions that differ from defaults.

## Workloads

- Memory limit set, CPU limit omitted (CFS throttling); CPU request only
- CPU request sized from baseline usage under normal load, never from history recorded under a CPU limit (throttling distorts it). Memory limit equals memory request
- Without a CPU limit, pin the runtime CPU count to the request: `GOMAXPROCS` (Go), `-XX:ActiveProcessorCount` (JVM), `DOTNET_PROCESSOR_COUNT` (.NET). Otherwise thread pools size to every node core
- A namespace LimitRange default or ResourceQuota on `limits.cpu` must not inject or require a CPU limit
- CPU limit only for exclusive cores (static CPU manager, Guaranteed pod with integer CPU) or platforms that force requests equal to limits
- Omit fields a controller owns: `spec.replicas` under HPA, KEDA, or Rollouts; resources under VPA. Otherwise add ArgoCD `ignoreDifferences`
- `nodeAffinity.matchExpressions` and Karpenter NodePool `requirements` order: `kubernetes.io/os`, `kubernetes.io/arch`, worker selector (node kind label, `karpenter.sh/nodepool`), then zone or others; a worker label requested for a NodePool goes in both `template.metadata.labels` and `requirements`
- Clusters mix amd64 and arm64 nodes; images must be multi-arch or the arch constraint explicit
- `resizePolicy` right after `resources`: cpu `NotRequired`, memory `RestartContainer`
- `preStop` sleep with matching `terminationGracePeriodSeconds`; `automountServiceAccountToken: false` unless the API is called; `dnsConfig.options.ndots: "2"` after testing
- Under `ndots: "2"`, in-cluster names are `svc`, `svc.ns`, or the full `svc.ns.svc.cluster.local`, never `svc.ns.svc` (tried as absolute first and fails once). StatefulSet pod names such as `web-0.nginx.ns` use the full domain. Hot external names with one dot get a trailing dot (`example.com.`)

## Services And Traffic

- Services set `trafficDistribution: PreferSameZone`, never the deprecated `PreferClose` alias. Backends spread across every zone with `topologySpreadConstraints` on `topology.kubernetes.io/zone`, and replicas (HPA `minReplicas` included) stay at or above the zone count, otherwise one zone falls back to cross-zone
- Skip `PreferSameZone` when clients concentrate in one zone (no capacity spillover, that zone overloads) or when `internalTrafficPolicy: Local` already applies
- gRPC Services with long-lived clients are balanced per request by an L7 proxy: Istio ambient waypoint (`istio.io/use-waypoint` label on the Service) and a DestinationRule with `loadBalancer.simple: LEAST_REQUEST` plus `outlierDetection`. ztunnel alone is L4 and pins every call on a connection to one pod
- Judge gRPC balancing by server-side p99 per pod, not by even request counts. No proxy is needed when clients use gRPC `round_robin` against a headless Service

## CRDs With Server-Side Defaults

Write CRD default fields explicitly so ArgoCD does not show permanent drift.

| Resource | Fields to spell out |
|----------|---------------------|
| ExternalSecret `data[].remoteRef`, `dataFrom[].extract`, `dataFrom[].find` (ESO before v2.9.0, harmless after) | `conversionStrategy: Default`, `decodingStrategy: None`, `metadataPolicy: None` (not on `find`). On ESO v2.3.0 to v2.6.x only, also `nullBytePolicy: Ignore` (field absent before v2.3.0) |
| ExternalSecret `spec`, `target` | `refreshInterval` (any explicit value), `creationPolicy: Owner`, `deletionPolicy: Retain` |
| ExternalSecret `target.template`, `templateFrom[]` (when used) | `engineVersion: v2`, `mergePolicy: Replace`, `templateFrom[].target: Data` |
| Gateway API `parentRefs`, `backendRefs` | `group`, `kind`, `name`, `namespace` |

Defaults vary by operator version. Read the installed CRD (`kubectl get crd <name> -o yaml`) before relying on the table, and scope any no-drift claim to that version.

Verify with an empty `diff <(kubectl get <kind> <name> -n <ns> -o json | jq -S .spec) <(yq -o json .spec <file> | jq -S .)`.

## Karpenter

- NodePool with a single instance type limits by `limits.nodes`, not cpu or memory
- System and workload pools are separated by a node kind label plus matching taints
- EC2NodeClass AMIs are AL2023 or Bottlerocket (cgroup v2), never AL2. The kubelet `failCgroupV1: false` override is only a short migration bridge. Set `singleProcessOOMKill: true` only for workloads that depend on per-process OOM kills, since cgroup v2 kills the whole container
- Interruption handling belongs to Karpenter: `settings.interruptionQueue` points at the cluster's SQS queue. Remove AWS Node Termination Handler when moving nodes to Karpenter and never run both (two node lifecycle owners cause launch and terminate churn). Karpenter does not drain on rebalance recommendations, so NTH alongside it only when proactive rebalance draining is a hard requirement

## Secrets And Policies

- Secret keys named by value type, consistent across siblings (`Amd64RunnerToken`, `Arm64RunnerToken`)
- Kyverno policies carry `policies.kyverno.io/title` and `policies.kyverno.io/description` annotations and messages in English. VAP and MAP need only an English `message` or `messageExpression`
- Admission policies default to ValidatingAdmissionPolicy and MutatingAdmissionPolicy (CEL in kube-apiserver, no webhook to fail). Kyverno only for generate, cleanup, `verifyImages`, background reports, and external data beyond `paramRef`. An explicit Kyverno request gets Kyverno, and the reply adds one line noting the VAP fit when the rule fits VAP
- Policy and binding ship together. Bindings roll out with `validationActions: ["Warn", "Audit"]`, then `["Deny"]` once nothing legitimate is flagged. Kyverno rules likewise start at `Audit`, then `Enforce`. Check VAP or MAP is served (`kubectl api-resources --api-group=admissionregistration.k8s.io`) before relying on it
- `failurePolicy: Fail` also fires on CEL evaluation errors, so test expressions against real objects first

## Operations

- Never use `kubectl port-forward` for verification; query in-cluster or read resources
- Never modify kubeconfig contexts; cluster-changing commands are handed to the user unless they asked Claude to apply

## Review Output

Errors, then warnings, one line each with `file:line` and the fix; then validation results.

## Validation

- `kubeconform -strict -summary -schema-location default -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'` passes
- `kubectl apply --dry-run=server` passes where cluster access exists
