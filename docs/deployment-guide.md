# Deployment Guide

How to run tinycode in a container — locally with podman/docker, or on Kubernetes/OpenShift.

## Quick Start (podman)

```bash
# Pull and run
podman run -d --name tinycode \
  -p 4096:4096 \
  quay.io/bjohns/tinycode-container:latest

# Get the auth token (auto-generated on first start)
podman exec tinycode cat /home/tinycode/.local/share/tinycode/web_token

# Open the web UI
open http://localhost:4096
```

Login with the token from above.

## Quick Start (docker)

```bash
docker run -d --name tinycode \
  -p 4096:4096 \
  quay.io/bjohns/tinycode-container:latest

docker exec tinycode cat /home/tinycode/.local/share/tinycode/web_token
open http://localhost:4096
```

## Persistent Storage

Without volumes, sessions and config are lost when the container stops.

```bash
podman run -d --name tinycode \
  -p 4096:4096 \
  -v tinycode-data:/home/tinycode/.local/share/tinycode \
  -v tinycode-config:/home/tinycode/.config/tinycode \
  -v tinycode-projects:/projects \
  quay.io/bjohns/tinycode-container:latest
```

| Volume | Contents |
|--------|----------|
| `tinycode-data` | SQLite DB, session history, auth token |
| `tinycode-config` | Config files (`tinycode.jsonc` for user settings) |
| `tinycode-projects` | Workspace files, git repos |

## Connecting to an LLM

The container has no built-in model — you must connect to an external LLM provider.

### Local Ollama (host machine)

```bash
podman run -d --name tinycode \
  -p 4096:4096 \
  -e TINYCODE_OLLAMA_HOST=http://host.containers.internal:11434 \
  quay.io/bjohns/tinycode-container:latest
```

For docker, use `host.docker.internal` instead of `host.containers.internal`.

### vLLM (Kubernetes service)

```bash
podman run -d --name tinycode \
  -p 4096:4096 \
  -e TINYCODE_VLLM_URL=http://vllm-service:8000 \
  -e TINYCODE_VLLM_MODEL=meta-llama/Llama-3.1-70B-Instruct \
  quay.io/bjohns/tinycode-container:latest
```

### OpenRouter (cloud)

```bash
podman run -d --name tinycode \
  -p 4096:4096 \
  -e OPENROUTER_API_KEY=sk-or-... \
  quay.io/bjohns/tinycode-container:latest
```

## Set a Password

By default, tinycode generates a random auth token. To set a fixed password:

```bash
podman run -d --name tinycode \
  -p 4096:4096 \
  -e TINYCODE_SERVER_PASSWORD=my-secret-password \
  quay.io/bjohns/tinycode-container:latest
```

## GitOps Mode

Clone a git repo on startup so tinycode has project context:

```bash
podman run -d --name tinycode \
  -p 4096:4096 \
  -e TINYCODE_GIT_REPO=https://github.com/org/repo.git \
  -e TINYCODE_GIT_BRANCH=main \
  -e TINYCODE_GIT_PULL_ON_RESTART=true \
  -v tinycode-projects:/projects \
  quay.io/bjohns/tinycode-container:latest
```

For private repos, mount credentials:

```bash
-v ~/.git-credentials:/home/tinycode/.git-credentials:ro
```

## Session Attach

Resume a specific session on container restart:

```bash
podman run -d --name tinycode \
  -p 4096:4096 \
  -e TINYCODE_SESSION_ID=ses_abc123 \
  -v tinycode-data:/home/tinycode/.local/share/tinycode \
  quay.io/bjohns/tinycode-container:latest
```

## Remote TUI (attach from host)

Connect the native TUI to a running container instead of using the web UI:

```bash
TOKEN=$(podman exec tinycode cat /home/tinycode/.local/share/tinycode/web_token)
tinycode attach http://localhost:4096 -p "$TOKEN"
```

## Kubernetes Deployment

### Namespace + base resources

```bash
kubectl apply -k k8s/base
```

This creates:
- Namespace `tinycode`
- Deployment (1 replica, UID 1001, read-only root filesystem)
- Service (port 4096)
- Route (OpenShift) or Ingress
- PVCs for data and projects
- NetworkPolicy

### Create auth secret

```bash
kubectl create secret generic tinycode-auth \
  -n tinycode \
  --from-literal=server-password=my-secret-password
```

### Configure vLLM

Edit the deployment or use a kustomize overlay:

```yaml
env:
- name: TINYCODE_VLLM_URL
  value: "http://vllm-service.default.svc.cluster.local:8000"
- name: TINYCODE_VLLM_MODEL
  value: "meta-llama/Llama-3.1-70B-Instruct"
```

### Ephemeral (no PVC — testing only)

```bash
kubectl apply -k k8s/overlays/ephemeral
```

### Generic Kubernetes (Ingress instead of Route)

```bash
kubectl apply -k k8s/overlays/ingress
```

### OpenShift with operator

For production OpenShift, use the [tinycode-operator](https://github.com/bobbyjohnstx/tinycode-operator):

```yaml
apiVersion: tinycode.io/v1alpha1
kind: TinycodeInstance
metadata:
  name: my-tinycode
spec:
  replicas: 1
  storage:
    size: 5Gi
  vllm:
    url: http://vllm-service:8000
    model: meta-llama/Llama-3.1-70B-Instruct
```

## Cluster Admin Mode

Enable the ops agent with `oc` CLI access:

```bash
podman run -d --name tinycode \
  -p 4096:4096 \
  -e TINYCODE_CLUSTER_ADMIN=true \
  -e TINYCODE_OC_VERSION=stable \
  -v ~/.kube/config:/home/tinycode/.kube/config:ro \
  quay.io/bjohns/tinycode-container:latest
```

The entrypoint downloads the `oc` CLI and auto-detects whether the cluster is OpenShift or vanilla Kubernetes.

## Health Checks

| Endpoint | Purpose | Auth |
|----------|---------|------|
| `GET /global/health` | Liveness + readiness | Required (Bearer token) |

```bash
TOKEN=$(podman exec tinycode cat /home/tinycode/.local/share/tinycode/web_token)
curl -H "Authorization: Bearer $TOKEN" http://localhost:4096/global/health
# {"checks":{"database":"ok"},"healthy":true,"version":"v2.6.1"}
```

## API Smoke Test

Verify the container is working:

```bash
TOKEN=$(podman exec tinycode cat /home/tinycode/.local/share/tinycode/web_token)
BASE=http://localhost:4096
AUTH="Authorization: Bearer $TOKEN"

# Health
curl -s -H "$AUTH" "$BASE/global/health"

# Providers
curl -s -H "$AUTH" "$BASE/provider"

# Create a session
curl -s -H "$AUTH" -H "Content-Type: application/json" \
  -X POST "$BASE/session" \
  -d '{"directory":"/projects","title":"smoke-test"}'

# List sessions
curl -s -H "$AUTH" "$BASE/session?limit=5"

# Config
curl -s -H "$AUTH" "$BASE/config"
```

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Container exits immediately | Missing volume for read-only root | Add emptyDir volumes for `/tmp`, `/home/tinycode/.local/bin`, etc. |
| 401 on all endpoints | Auth token required | Get token: `podman exec tinycode cat /home/tinycode/.local/share/tinycode/web_token` |
| Can't reach Ollama | Wrong gateway hostname | Use `host.containers.internal` (podman) or `host.docker.internal` (docker) |
| vLLM model not found | Model string mismatch | Verify with `curl $TINYCODE_VLLM_URL/v1/models` |
| Git clone fails | Private repo, no credentials | Mount `.git-credentials` or `.netrc` |
| Plugins not loading | Plugin binaries not in PATH | Check `/opt/tinycode-plugins/` — plugin bundle downloads during build |

## Environment Variable Reference

See [CONTAINER.md](../CONTAINER.md) for the complete list.

## Build from Source

Override the tinycode version:

```bash
podman build -f ContainerFile \
  --build-arg TINYCODE_VERSION=2.6.1 \
  -t tinycode-container:custom .
```

No Go toolchain needed — the build downloads pre-built release binaries.
