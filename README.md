# tinycode-container

Single container image running **tinycode** (web mode) + **oh-my-tiny** (native plugin) for deployment to OpenShift and Kubernetes.

## What is this?

This project packages tinycode and the oh-my-tiny plugin as a self-contained container image suitable for multi-tenant Kubernetes/OpenShift environments. The container runs tinycode's web mode, exposing an HTTP API and embedded SolidJS web UI on port 4096.

The container interface (port, UID, health endpoints, volume mounts, environment variables) is documented in [CONTAINER.md](CONTAINER.md), which is the authoritative contract between this image and the tinycode-operator that deploys it.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/bjohns/tinycode-container/main/install.sh | sh
```

This installs a `tinycode` wrapper script that:
- Pulls the container image if not present
- Starts a named container with persistent volumes on first run
- Attaches to the existing container on subsequent runs (sub-second startup)
- Detects `podman` vs `docker` automatically

To uninstall: `tinycode --uninstall`

## Prerequisites

- **podman** or **docker** (for running and local builds)
- **kubectl** or **oc** (for Kubernetes/OpenShift deployment)
- **GitHub token** with repo read access to private repositories (bjohns/tinycode and bjohns/oh-my-tiny)

## Multi-Architecture Support

The container image is built for both `linux/amd64` and `linux/arm64`. CI produces a multi-arch manifest, so `podman pull` or `docker pull` selects the correct architecture automatically.

## Build Locally

```bash
# Save your GitHub token to a file
echo $GITHUB_TOKEN > ~/.github-token

# Build for the current architecture
podman build -f ContainerFile \
  --secret id=github_token,src=$HOME/.github-token \
  -t quay.io/bjohns/tinycode-container:latest .

# Build for a specific architecture
podman build -f ContainerFile \
  --platform linux/arm64 \
  --secret id=github_token,src=$HOME/.github-token \
  -t quay.io/bjohns/tinycode-container:latest .
```

The multi-stage build:
1. **Stage 1** (builder): Clones tinycode, installs Bun, builds self-contained binary
2. **Stage 2** (plugin-builder): Clones oh-my-tiny, installs Node.js 20, compiles plugin
3. **Stage 3** (runtime): UBI9-minimal base with non-root user (UID 1001, GID 0)

## Run Locally (Quick Test)

```bash
# Run the container in detached mode
podman run -d -p 4096:4096 quay.io/bjohns/tinycode-container:latest

# Open the web UI
open http://localhost:4096
```

For persistent storage during local testing:

```bash
podman run -d -p 4096:4096 \
  --name tinycode \
  -v tinycode-data:/home/tinycode/.local/share/tinycode \
  -v tinycode-config:/home/tinycode/.config/tinycode \
  quay.io/bjohns/tinycode-container:latest
```

## Session Attach

Set the `TINYCODE_SESSION_ID` environment variable to attach to an existing session on container start:

```bash
podman run -d -p 4096:4096 \
  -e TINYCODE_SESSION_ID=my-session \
  ghcr.io/bjohns/tinycode-container:latest
```

## Deploy to OpenShift

### Base Deployment

```bash
# Deploy base resources (Deployment, Service, Route)
kubectl apply -k k8s/base
```

### Deployment Variants

**Ephemeral (no PVC — testing only):**

```bash
kubectl apply -k k8s/overlays/ephemeral
```

**Generic Kubernetes (Ingress instead of Route):**

```bash
kubectl apply -k k8s/overlays/ingress
```

For production OpenShift deployments, consider using the [tinycode-operator](https://github.com/bobbyjohnstx/tinycode-operator), which manages `TinycodeInstance` CRs and handles storage, routing, and SCCs automatically.

## Credentials Setup

The tinycode web UI requires authentication. To set the password:

1. Copy the secret template:
   ```bash
   cp k8s/secrets/secret-template.yaml k8s/secrets/secret.yaml
   ```

2. Edit `k8s/secrets/secret.yaml` and set your desired password (base64-encoded).

3. Apply the secret:
   ```bash
   kubectl apply -f k8s/secrets/secret.yaml
   ```

## Architecture

**Base Image:** Red Hat UBI9-minimal (OpenShift-compatible)
**Port:** 4096 (HTTP)
**User:** UID 1001 (non-root), GID 0 (OpenShift arbitrary UID support via `g=u`)
**Health Probes:** `GET /global/health` (unauthenticated, liveness + readiness)
**Persistence:** PVC mounts for:
- `/home/tinycode/.local/share/tinycode` (SQLite DB, session history)
- `/home/tinycode/.config/tinycode` (user configuration)
- `/projects` (user workspace files, separate PVC)

**Configuration Hierarchy:**

The entrypoint writes defaults to `config.json` on every startup, ensuring the oh-my-tiny plugin path is always present. User customizations should go in `tinycode.jsonc` (PVC-persisted) to survive image upgrades.

Load order (lowest to highest priority): `config.json` → `tinycode.json` → `tinycode.jsonc`

**XDG Base Directories:**

| Variable | Value |
|----------|-------|
| `XDG_DATA_HOME` | `/home/tinycode/.local/share` |
| `XDG_CONFIG_HOME` | `/home/tinycode/.config` |
| `XDG_STATE_HOME` | `/home/tinycode/.local/state` |
| `XDG_CACHE_HOME` | `/home/tinycode/.cache` |

**Environment Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `TINYCODE_SERVER_PASSWORD` | *(none — unauthenticated)* | Server auth password |
| `TINYCODE_OLLAMA_HOST` | `http://host.containers.internal:11434` | Ollama endpoint |
| `TINYCODE_PORT` | `4096` | Override server port |
| `TINYCODE_DISABLE_LSP_DOWNLOAD` | `1` | Skip LSP binary auto-download |
| `TINYCODE_SESSION_ID` | *(none)* | Attach to existing session on start |
| `OPENROUTER_API_KEY` | *(none)* | OpenRouter API key for cost tracking and balance display |

## CI/CD

The GitHub Actions workflow (`.github/workflows/build-push.yaml`) automatically builds and pushes multi-arch images to `quay.io/bjohns/tinycode-container` on every push to main:

- **Platforms:** `linux/amd64`, `linux/arm64`
- **Tags:** `:latest` and `:<git-sha>`
- **Smoke test:** Runs `tinycode --version` on both architectures
- **Registries:** Quay.io (primary), GitHub Container Registry (mirror)
- **Build:** Uses `docker/build-push-action` with QEMU for cross-compilation

## Features

**Swarm Tool:** The container includes `tmux` (compiled from source in the builder stage) to support the `/swarm` tool, which launches supervised multi-worker sessions with shared persistence. The swarm tool is particularly useful for distributed task solving via OpenRouter or other compatible providers.

## Known Limitations

- **AST grep tools** (`@ast-grep/napi`) in oh-my-tiny may experience degraded functionality due to Bun/Node.js native addon compatibility issues in containerized environments.
- **Health probes** can use tcpSocket instead of `GET /global/health` if the health endpoint requires authentication in your deployment (see `k8s/base/deployment.yaml` comments).

## Ecosystem

| Project | Description | Repository |
|---------|-------------|------------|
| [tinycode](https://github.com/bobbyjohnstx/tinycode) | Core AI coding assistant — server, TUI, web UI | `github.com/bobbyjohnstx/tinycode` |
| [tinycode-operator](https://github.com/bobbyjohnstx/tinycode-operator) | OpenShift Operator managing `TinycodeInstance` CRs | `github.com/bobbyjohnstx/tinycode-operator` |

## License

Inherits licenses from tinycode and oh-my-tiny upstream projects.
