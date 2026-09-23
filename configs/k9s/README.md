# k9s

For more information, please refer to below k9s docs.

- [Skins](https://k9scli.io/topics/skins/)  
- [Configuration](https://k9scli.io/topics/config/)
- [Views](https://k9scli.io/topics/columns/)

## Skins

This scenario is based on k9s v0.40.x as a latest version.

First, all skins are located in the `$XDG_CONFIG_HOME/k9s/skins` directory.

```bash
$XDG_CONFIG_HOME/
└── k9s/
    └── skins/
        ├── nightfox.yaml
        ├── ... other skins ...
        └── transparent.yaml
```

Set `k9s.ui.skin` in `config.yaml` to use a different skin.

```yaml
# $XDG_HOME/k9s/config.yaml
k9s:
  ui:
    skin: nightfox
```

Verify the skin is applied running `k9s` command.

## Custom Jump Navigation

> [!NOTE]
> This feature is not yet merged upstream. See [derailed/k9s#3737](https://github.com/derailed/k9s/issues/3737) for status.

Custom jump navigation allows you to press **Enter** on a resource to jump directly to a related resource, instead of the default describe view. Rules are defined in `navigations.yaml`.

```bash
$XDG_CONFIG_HOME/
└── k9s/
    └── navigations.yaml
```

### Configured jumps

| Source | Target | Matching |
|--------|--------|----------|
| ExternalSecret | Secret | `fieldSelector` by name |
| ServiceMonitor | Service | `fieldSelector` by name |
| NodePool (Karpenter) | Node | `labelSelector` by `karpenter.sh/nodepool` |

### Example

```yaml
# $XDG_CONFIG_HOME/k9s/navigations.yaml
jumps:
  # ExternalSecret -> Secret (created by ESO)
  "external-secrets.io/v1beta1/externalsecrets":
    targetGVR: "v1/secrets"
    fieldSelector: "metadata.name={{.metadata.name}}"
    targetNamespace: "same"

  # NodePool -> Nodes (Karpenter)
  "karpenter.sh/v1/nodepools":
    targetGVR: "v1/nodes"
    labelSelector: "karpenter.sh/nodepool={{.metadata.name}}"
    targetNamespace: "all"
```

### Configuration options

| Field | Description | Example |
|-------|-------------|---------|
| `targetGVR` | Target resource GVR | `v1/secrets` |
| `labelSelector` | Match by label with template | `app={{.metadata.name}}` |
| `fieldSelector` | Match by field with template | `metadata.name={{.metadata.name}}` |
| `targetNamespace` | Namespace scope | `same`, `all`, or specific namespace |