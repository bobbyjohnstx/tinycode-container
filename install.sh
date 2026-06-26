#!/bin/sh
# Tinycode container installer
# Usage: curl -fsSL https://raw.githubusercontent.com/bobbyjohnstx/tinycode-container/main/install.sh | sh
set -e

IMAGE="quay.io/bjohns/tinycode-container:latest"
CONTAINER_NAME="tinycode"
INSTALL_DIR="${HOME}/.local/bin"
WRAPPER="${INSTALL_DIR}/tinycode"

# Detect container runtime
detect_runtime() {
  if command -v podman >/dev/null 2>&1; then
    echo "podman"
  elif command -v docker >/dev/null 2>&1; then
    echo "docker"
  else
    echo ""
  fi
}

RUNTIME=$(detect_runtime)

if [ -z "$RUNTIME" ]; then
  echo "Error: Neither podman nor docker found. Install one first."
  exit 1
fi

echo "Using container runtime: $RUNTIME"

# Handle --uninstall
if [ "$1" = "--uninstall" ]; then
  echo "Uninstalling tinycode..."
  $RUNTIME rm -f "$CONTAINER_NAME" 2>/dev/null || true
  $RUNTIME rmi "$IMAGE" 2>/dev/null || true
  rm -f "$WRAPPER"
  echo "Tinycode uninstalled."
  exit 0
fi

# Pull image if not present
if ! $RUNTIME image exists "$IMAGE" 2>/dev/null; then
  echo "Pulling tinycode container image..."
  $RUNTIME pull "$IMAGE"
fi

# Create install directory
mkdir -p "$INSTALL_DIR"

# Create wrapper script
cat > "$WRAPPER" << 'WRAPPER_EOF'
#!/bin/sh
set -e

IMAGE="quay.io/bjohns/tinycode-container:latest"
CONTAINER_NAME="tinycode"

# Detect container runtime
if command -v podman >/dev/null 2>&1; then
  RUNTIME="podman"
elif command -v docker >/dev/null 2>&1; then
  RUNTIME="docker"
else
  echo "Error: Neither podman nor docker found."
  exit 1
fi

# Handle --uninstall
if [ "$1" = "--uninstall" ]; then
  $RUNTIME rm -f "$CONTAINER_NAME" 2>/dev/null || true
  $RUNTIME rmi "$IMAGE" 2>/dev/null || true
  rm -f "$0"
  echo "Tinycode uninstalled."
  exit 0
fi

# Check if container already exists and is running
if $RUNTIME container exists "$CONTAINER_NAME" 2>/dev/null; then
  STATE=$($RUNTIME inspect --format '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
  if [ "$STATE" = "running" ]; then
    # Attach to existing container
    echo "Attaching to running tinycode container..."
    exec $RUNTIME exec -it "$CONTAINER_NAME" tinycode "$@"
  else
    # Start stopped container
    echo "Starting tinycode container..."
    $RUNTIME start "$CONTAINER_NAME"
    echo "Tinycode is running at http://localhost:4096"
    exit 0
  fi
fi

# Create and start new container with persistent volumes
echo "Starting tinycode container..."
$RUNTIME run -d \
  --name "$CONTAINER_NAME" \
  -p 4096:4096 \
  -v tinycode-data:/home/tinycode/.local/share/tinycode \
  -v tinycode-config:/home/tinycode/.config/tinycode \
  "$IMAGE"

echo "Tinycode is running at http://localhost:4096"
WRAPPER_EOF

chmod +x "$WRAPPER"

echo ""
echo "Tinycode installed to $WRAPPER"
echo ""

# Check if INSTALL_DIR is in PATH
case ":$PATH:" in
  *":${INSTALL_DIR}:"*) ;;
  *)
    echo "Add $INSTALL_DIR to your PATH:"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    echo ""
    ;;
esac

echo "Usage:"
echo "  tinycode              Start or attach to tinycode"
echo "  tinycode --uninstall  Remove tinycode container and wrapper"
