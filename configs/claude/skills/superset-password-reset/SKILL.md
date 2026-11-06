---
name: superset-password-reset
description: Reset an Apache Superset user's password on Kubernetes after confirming from the running app whether Superset or an external identity provider owns the password, with the new password typed only by the operator.
when_to_use: Resetting or unlocking a Superset login for someone, e.g. "superset 패스워드 초기화", "superset 비밀번호 리셋", "superset 로그인 안 된대", "superset 계정 잠김". Not for Keycloak or other IdP account administration (that is the IdP's own console) or for Superset chart and config changes (use helm-chart).
license: Apache-2.0
compatibility: kubectl with exec rights on the Superset web server pod, optional Claude in Chrome for the browser path
metadata:
  version: "1.0.0"
  category: action
  related: k8s-manifest helm-chart
allowed-tools: Bash(kubectl *) Bash(curl *) Read
user-invocable: true
disable-model-invocation: false
---

# Superset Password Reset

## Site Values

Read from `~/.zshrc.local` (untracked), ask once if unset.

| Variable | Meaning | Example |
|----------|---------|---------|
| `SUPERSET_KUBE_CONTEXT` | kubectl context of the cluster running Superset | `shared` |
| `SUPERSET_NAMESPACE` | Namespace of the Superset web server | `superset` |
| `SUPERSET_WEB_DEPLOY` | Web server Deployment and container | `superset-web-server` / `superset` |

## Output Requirements

- The auth mode comes from the running app (`create_app()` then `app.config["AUTH_TYPE"]`), never from grepping `superset_config.py`. Config files often enable OAuth only behind a condition, such as a client secret env var that may be empty
- `AUTH_DB` (local users): the reset happens in Superset. `AUTH_OAUTH`, `AUTH_LDAP`, `AUTH_REMOTE_USER`: Superset holds no usable password, so report which IdP owns it and stop, without changing anything in the IdP unless asked
- The target is confirmed by email or username before any change: id, username, `active`, roles, `last_login`, `login_count`
- Claude never types, generates, or sees the new password. The operator enters it, either in their own terminal or in the browser form
- Never `superset fab reset-password --password <value>`: the value lands in shell history and the transcript
- An empty role list (`roles=[]`) is reported with the reset, since the user can log in but sees nothing
- Port-forwards and browser tabs Claude opened are closed when the operator confirms the reset is done

## Reset Paths

| Path | When | Steps owned by the operator |
|------|------|-----------------------------|
| CLI in a separate terminal | Default | Run `kubectl --context $SUPERSET_KUBE_CONTEXT -n $SUPERSET_NAMESPACE exec -it deploy/$SUPERSET_WEB_DEPLOY -c superset -- superset fab reset-password --username <user>` and type the password twice |
| Browser | Operator prefers the UI | Log in as an Admin, then the reset form at `/users/action/resetpasswords/<id>` |

## Pitfalls

| Symptom | Cause | Response |
|---------|-------|----------|
| `Unable to use a TTY`, `GetPassWarning`, `Aborted!` | Run through Claude Code `!`, which has no TTY for the password prompt | Run the same command in a separate terminal window |
| Public Superset hostname times out | Reachable only from inside the network | `kubectl port-forward svc/$SUPERSET_WEB_DEPLOY 8088:8088` and use `http://localhost:8088` |
| "Access is Denied" toast on the login page | A protected URL opened before logging in redirects to `/login/` with this flash. Not a failed login | Log in first. The web server log shows no `POST /login/` when the operator never submitted |
| Reset done but the user sees an empty Superset | No roles, or roles synced from an IdP at login | Assign a role in Users > Edit (`AUTH_DB`), or fix the IdP group mapping (`AUTH_ROLES_SYNC_AT_LOGIN`) |

## Reference

Runtime auth mode and target lookup, without printing secrets:

```bash
kubectl --context "$SUPERSET_KUBE_CONTEXT" -n "$SUPERSET_NAMESPACE" exec deploy/"$SUPERSET_WEB_DEPLOY" -c superset -- sh -c 'cd /app && python - <<EOF 2>/dev/null
from superset.app import create_app
from flask_appbuilder.const import AUTH_DB, AUTH_OAUTH, AUTH_LDAP, AUTH_REMOTE_USER
app = create_app()
names = {AUTH_DB: "AUTH_DB", AUTH_OAUTH: "AUTH_OAUTH", AUTH_LDAP: "AUTH_LDAP", AUTH_REMOTE_USER: "AUTH_REMOTE_USER"}
with app.app_context():
    print("AUTH_TYPE =", names.get(app.config["AUTH_TYPE"]))
    u = app.appbuilder.sm.find_user(email="user@example.com")
    print(u.id, u.username, "active=", u.active, "roles=", [r.name for r in u.roles], "last_login=", u.last_login, "login_count=", u.login_count)
EOF'
```

## Validation

- The reported auth mode is the runtime `AUTH_TYPE`, and for a non-`AUTH_DB` mode nothing in Superset was changed
- No new password appears in any command Claude ran, any file, or the transcript
- After the operator's reset, `superset fab list-users` shows the target user `active` with the intended roles
- No port-forward or browser tab Claude opened is still running
