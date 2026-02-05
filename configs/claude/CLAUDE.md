# Global Claude Code Policy

## Skills Security Policy

This dotfiles repo is public on GitHub. Follow these rules when creating or modifying skills files.

### Prohibited Items

- Internal IP ranges and CIDRs (e.g., actual private network ranges like `10.20.30.0/24`)
- Company domains and hostnames (e.g., `*.company-internal.io`, `api.corp.com`)
- Company-specific naming patterns (e.g., `corp_worker`, `internal_` prefixes)
- API keys, tokens, passwords (actual credentials)
- Real AWS account IDs and ARNs (e.g., `111122223333`)
- Personal info (real emails, names, Slack IDs)

### Allowed Example Values

| Item | Value |
|------|-------|
| Domain | `example.com` |
| IP | `10.0.0.0/16` |
| AWS Account | `123456789012` |
| Secret | `${SECRET_NAME}` |
