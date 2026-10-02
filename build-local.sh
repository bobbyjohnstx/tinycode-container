#!/bin/sh
# Build tinycode-container locally using source from sibling tinycode directory.
# Copies Go source (excluding vendor/.git) into a temp build context,
# then runs podman build from there.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TINYCODE_SRC="${TINYCODE_SRC:-/Users/bjohns/projects/tinycode}"
IMAGE_TAG="${IMAGE_TAG:-tinycode-container:local}"
BUILD_PLATFORM="${BUILD_PLATFORM:-}"

BUILD_DIR="$(mktemp -d /tmp/tinycode-container-build.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "==> Build context: $BUILD_DIR"
echo "==> tinycode source: $TINYCODE_SRC"
echo ""

echo "==> Copying tinycode source (excluding vendor, dist, .git, node_modules, packages)..."
rsync -a \
  --exclude=vendor --exclude=dist --exclude=.git \
  --exclude=node_modules --exclude=packages \
  "$TINYCODE_SRC/" "$BUILD_DIR/tinycode-src/"

echo "==> Copying ContainerFile.local, entrypoint.sh, config, and plugins..."
cp "$SCRIPT_DIR/ContainerFile.local" "$BUILD_DIR/ContainerFile.local"
cp "$SCRIPT_DIR/entrypoint.sh" "$BUILD_DIR/entrypoint.sh"
cp -r "$SCRIPT_DIR/config" "$BUILD_DIR/config"
cp -r "$SCRIPT_DIR/plugins" "$BUILD_DIR/plugins"

echo "==> Starting build (this takes 3-5 min on first run)..."
echo ""
podman build \
  ${BUILD_PLATFORM:+--platform "$BUILD_PLATFORM"} \
  -f "$BUILD_DIR/ContainerFile.local" \
  -t "$IMAGE_TAG" \
  "$BUILD_DIR"

echo ""
echo "==> Build complete: $IMAGE_TAG"
echo ""
echo "Quick tests:"
echo "  podman run --rm --entrypoint id $IMAGE_TAG"
echo "  podman run -d --name tinycode-test -p 4096:4096 $IMAGE_TAG"
echo "  curl -s http://localhost:4096/global/health | jq ."
echo "  open http://localhost:4096"
echo "  podman stop tinycode-test && podman rm tinycode-test"
