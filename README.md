# tiny-container

Single Podman container image running **tinycode** (web mode) + **oh-my-tiny** (native plugin) for deployment to OpenShift and Kubernetes.

## What is this?

This project packages tinycode and the oh-my-tiny plugin as a self-contained container image suitable for multi-tenant Kubernetes/OpenShift environments. The container runs tinycode's web mode, exposing an HTTP API and embedded SolidJS web UI on port 3000.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/bjohns/tiny-container/main/install.sh | sh
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
  -t ghcr.io/bjohns/tiny-container:latest .

# Build for a specific architecture
podman build -f ContainerFile \
  --platform linux/arm64 \
  --secret id=github_token,src=$HOME/.github-token \
  -t ghcr.io/bjohns/tiny-container:latest .
```

The multi-stage build:
1. **Stage 1** (builder): Clones tinycode, installs Bun, builds self-contained binary
2. **Stage 2** (plugin-builder): Clones oh-my-tiny, installs Node.js 20, compiles plugin
3. **Stage 3** (runtime): UBI9-minimal base with non-root user (UID 1001)

## Run Locally (Quick Test)

```bash
# Run the container in detached mode
podman run -d -p 3000:3000 ghcr.io/bjohns/tiny-container:latest

# Open the web UI
open http://localhost:3000
```

For persistent storage during local testing:

```bash
podman run -d -p 3000:3000 \
  --name tinycode \
  -v tinycode-data:/home/tinycode/.local/share/tinycode \
  -v tinycode-config:/home/tinycode/.config/tinycode \
  ghcr.io/bjohns/tiny-container:latest
```

## Session Attach

Set the `TINYCODE_SESSION_ID` environment variable to attach to an existing session on container start:

```bash
podman run -d -p 3000:3000 \
  -e TINYCODE_SESSION_ID=my-session \
  ghcr.io/bjohns/tiny-container:latest
```

## Deploy to OpenShift

### Base Deployment

```bash
# Deploy base resources (Deployment, Service, Route)
kubectl apply -k k8s/base
```

### Deployment Variants

**Ephemeral (no PVC - testing only):**

```bash
kubectl apply -k k8s/overlays/ephemeral
```

**Generic Kubernetes (Ingress instead of Route):**

```bash
kubectl apply -k k8s/overlays/ingress
```

## Credentials Setup

The tinycode web UI requires authentication. To set the password:

1. Copy the secret template:
   ```bash
   cp k8s/secrets/secret-template.yaml k8s/secrets/secret.yaml
   ```

2. Edit `k8s/secrets/secret.yaml` and set your desired password (base64-encoded)

3. Apply the secret:
   ```bash
   kubectl apply -f k8s/secrets/secret.yaml
   ```

## Container-Readiness Upstream Issues

This project identified 7 container-readiness gaps in the upstream tinycode and oh-my-tiny repositories:

**tinycode issues:**
- Issue #1: Hardcoded config paths not XDG-compliant
- Issue #2: No graceful SIGTERM handling for k8s pod shutdown
- Issue #3: Missing health check endpoints (/health, /ready)
- Issue #4: CLI assumes writable CWD (fails on read-only root filesystem)

**oh-my-tiny issues:**
- Issue #5: Hardcoded absolute plugin paths break container portability
- Issue #6: No plugin.json manifest for version/compatibility metadata
- Issue #7: Missing native dependency documentation (@ast-grep/napi)

See the upstream Gitea repositories for details and tracking.

## Architecture

**Base Image:** Red Hat UBI9-minimal (OpenShift-compatible)  
**Port:** 3000 (HTTP)  
**User:** UID 1001 (non-root), GID 0 (OpenShift arbitrary UID support)  
**Health Probes:** tcpSocket on port 3000 (liveness + readiness)  
**Persistence:** PVC mounts for:
  - `/home/tinycode/.local/share/tinycode` (session state, transcripts)
  - `/home/tinycode/.config/tinycode` (user configuration)

**Configuration Hierarchy:**

The container writes defaults to `config.json` on every startup, ensuring the oh-my-tiny plugin path is always present. User customizations should go in `tinycode.jsonc` (PVC-persisted) to survive image upgrades.

Load order: `config.json` → `tinycode.json` → `tinycode.jsonc`

**XDG Base Directories:**
- `XDG_DATA_HOME=/home/tinycode/.local/share`
- `XDG_CONFIG_HOME=/home/tinycode/.config`
- `XDG_STATE_HOME=/home/tinycode/.local/state`
- `XDG_CACHE_HOME=/home/tinycode/.cache`

## CI/CD

The GitHub Actions workflow (`.github/workflows/build-push.yaml`) automatically builds and pushes multi-arch images to `ghcr.io/bjohns/tiny-container` on every push to main:

- **Platforms:** `linux/amd64`, `linux/arm64`
- **Tags:** `:latest` and `:${github.sha}`
- **Smoke test:** Runs `tinycode --version` on both architectures
- **Registry:** GitHub Container Registry (GHCR)
- **Build:** Uses `docker/build-push-action` with QEMU for cross-compilation

## Known Limitations

- **AST grep tools** (@ast-grep/napi) in oh-my-tiny may experience degraded functionality due to Bun/Node.js native addon compatibility issues in containerized environments
- **Health probes** use tcpSocket instead of httpGet because `/global/health` endpoint requires authentication (see k8s/base/deployment.yaml comments)

## License

Inherits licenses from tinycode and oh-my-tiny upstream projects.
