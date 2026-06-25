#!/bin/sh
set -e

# Write container defaults to config.json unconditionally on every start.
# tinycode loads config in order: config.json -> tinycode.json -> tinycode.jsonc
# (src/config/config.ts:484-486). Writing to the lowest-priority config.json
# ensures the plugin entry is always present while user customizations in
# PVC-persisted tinycode.jsonc survive image upgrades without being overwritten.

# TINYCODE_OLLAMA_HOST is natively supported by tinycode (issue #8 fix).
# Default to host.containers.internal so local Ollama is reachable from the container.
# Override via TINYCODE_OLLAMA_HOST env var for k8s or custom Ollama locations.
export TINYCODE_OLLAMA_HOST="${TINYCODE_OLLAMA_HOST:-http://host.containers.internal:11434}"

DEFAULTS_FILE="$XDG_CONFIG_HOME/tinycode/config.json"
cat > "$DEFAULTS_FILE" << 'EOF'
{
  "plugin": ["/opt/oh-my-tiny"]
}
EOF

# Copy bundled agents and skills into the PVC-mounted config directory.
# The PVC shadows /home/tinycode/.config/tinycode so files COPY'd into the image
# at build time are hidden. This copies from a staging path (/opt/tinycode-defaults/)
# into the PVC on every startup, ensuring bundled defaults are always present.
# User customizations in the PVC take priority (loaded after bundled defaults by tinycode).
DEFAULTS_SRC="/opt/tinycode-defaults"
if [ -d "$DEFAULTS_SRC/agent" ]; then
  mkdir -p "$XDG_CONFIG_HOME/tinycode/agent"
  cp -n "$DEFAULTS_SRC/agent/"*.md "$XDG_CONFIG_HOME/tinycode/agent/" 2>/dev/null || true
fi
if [ -d "$DEFAULTS_SRC/skills" ]; then
  for skill_dir in "$DEFAULTS_SRC/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "$XDG_CONFIG_HOME/tinycode/skills/$skill_name"
    cp -n "$skill_dir"SKILL.md "$XDG_CONFIG_HOME/tinycode/skills/$skill_name/" 2>/dev/null || true
  done
fi

# ── oc CLI for cluster management mode ───────────────────────────────────────
if [ "${TINYCODE_CLUSTER_ADMIN}" = "true" ]; then
  OC_BIN="/home/tinycode/.local/bin/oc"
  if [ ! -f "$OC_BIN" ]; then
    echo "[tinycode] Downloading oc CLI (version: ${TINYCODE_OC_VERSION:-stable})..."
    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64)  OC_ARCH="amd64" ;;
      aarch64) OC_ARCH="arm64" ;;
      *)       OC_ARCH="amd64" ;;
    esac
    OC_VERSION="${TINYCODE_OC_VERSION:-stable}"
    case "$OC_ARCH" in
      arm64) OC_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux-arm64.tar.gz" ;;
      *)     OC_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux.tar.gz" ;;
    esac
    mkdir -p /home/tinycode/.local/bin
    set +e
    OC_TMP=$(mktemp /tmp/oc-XXXXXX.tar.gz)
    if curl -fsSL --max-time 120 "$OC_URL" -o "$OC_TMP" 2>/dev/null && \
       tar xz -C /home/tinycode/.local/bin oc -f "$OC_TMP" 2>/dev/null; then
      echo "[tinycode] oc CLI installed: $(/home/tinycode/.local/bin/oc version --client 2>/dev/null | head -1)"
    else
      echo "[tinycode] WARNING: Failed to download oc CLI. Cluster-admin agent will be available but oc commands will fail."
    fi
    rm -f "$OC_TMP"
    set -e
  fi

  # Auto-detect cluster type: OpenShift or vanilla Kubernetes
  if oc api-resources --api-group=route.openshift.io --no-headers 2>/dev/null | grep -q "route"; then
    export TINYCODE_CLUSTER_TYPE=openshift
    echo "[tinycode] Cluster type: OpenShift"
  else
    export TINYCODE_CLUSTER_TYPE=kubernetes
    echo "[tinycode] Cluster type: Kubernetes"
  fi
fi

# Session attach: if TINYCODE_SESSION_ID is set, attach to an existing session
# instead of starting a new one. Useful for persistent containers.
if [ -n "$TINYCODE_SESSION_ID" ]; then
  echo "Attaching to session: $TINYCODE_SESSION_ID"
  exec tinycode web --hostname 0.0.0.0 --session "$TINYCODE_SESSION_ID"
fi

# Start tinycode in web mode (HTTP API + embedded SolidJS web UI)
# --hostname 0.0.0.0 required for k8s pod networking (default is 127.0.0.1)
# TINYCODE_PORT env var sets the port (supported natively since issue #1 fix)
exec tinycode web --hostname 0.0.0.0
