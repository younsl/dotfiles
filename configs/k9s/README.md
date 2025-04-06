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