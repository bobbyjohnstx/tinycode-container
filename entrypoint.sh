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
  "plugin": ["/opt/oh-my-tiny"],
  "server": {
    "port": 3000
  }
}
EOF

# Start tinycode in web mode (HTTP API + embedded SolidJS web UI)
# --hostname 0.0.0.0 required for k8s pod networking (default is 127.0.0.1)
# TINYCODE_PORT env var sets the port (supported natively since issue #1 fix)
exec tinycode web --hostname 0.0.0.0
