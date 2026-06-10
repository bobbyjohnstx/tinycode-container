#!/bin/sh
set -e

# Write container defaults to config.json unconditionally on every start.
# tinycode loads config in order: config.json -> tinycode.json -> tinycode.jsonc
# (src/config/config.ts:484-486). Writing to the lowest-priority config.json
# ensures the plugin entry is always present while user customizations in
# PVC-persisted tinycode.jsonc survive image upgrades without being overwritten.
# Ollama host: containers can't reach the host via localhost.
# host.containers.internal resolves to the container host on podman/Docker.
# Override with OLLAMA_HOST env var for custom locations or k8s deployments.
OLLAMA_HOST="${OLLAMA_HOST:-http://host.containers.internal:11434}"

DEFAULTS_FILE="$XDG_CONFIG_HOME/tinycode/config.json"
cat > "$DEFAULTS_FILE" << EOF
{
  "plugin": ["/opt/oh-my-tiny"],
  "server": {
    "port": 3000
  },
  "provider": {
    "ollama": {
      "options": {
        "baseURL": "${OLLAMA_HOST}/v1"
      }
    }
  }
}
EOF

# Start tinycode in web mode (HTTP API + embedded SolidJS web UI)
# --hostname 0.0.0.0 required for k8s pod networking (default is 127.0.0.1)
# --port 3000 aligns with the config.json default and k8s Service targetPort
exec tinycode web --hostname 0.0.0.0 --port 3000
