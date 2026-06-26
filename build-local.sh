#!/bin/sh
# Build tinycode-container locally using source from sibling directories.
# Copies source (excluding node_modules/.git) into a temp build context,
# then runs podman build from there.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TINYCODE_SRC="${TINYCODE_SRC:-/Users/bjohns/projects/tinycode}"
OH_MY_TINY_SRC="${OH_MY_TINY_SRC:-/Users/bjohns/projects/oh-my-tiny}"
IMAGE_TAG="${IMAGE_TAG:-tinycode-container:local}"

BUILD_DIR="$(mktemp -d /tmp/tinycode-container-build.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "==> Build context: $BUILD_DIR"
echo "==> tinycode source: $TINYCODE_SRC"
echo "==> oh-my-tiny source: $OH_MY_TINY_SRC"
echo ""

echo "==> Copying tinycode source (excluding node_modules, dist, .git)..."
rsync -a --exclude=node_modules --exclude=dist --exclude=.git \
  "$TINYCODE_SRC/" "$BUILD_DIR/tinycode-src/"

echo "==> Copying oh-my-tiny source (excluding node_modules, dist, .git)..."
rsync -a --exclude=node_modules --exclude=dist --exclude=.git \
  "$OH_MY_TINY_SRC/" "$BUILD_DIR/oh-my-tiny-src/"

echo "==> Copying ContainerFile.local, entrypoint.sh, and config..."
cp "$SCRIPT_DIR/ContainerFile.local" "$BUILD_DIR/ContainerFile.local"
cp "$SCRIPT_DIR/entrypoint.sh" "$BUILD_DIR/entrypoint.sh"
cp -r "$SCRIPT_DIR/config" "$BUILD_DIR/config"

echo "==> Starting build (this takes 5-10 min on first run)..."
echo ""
podman build \
  -f "$BUILD_DIR/ContainerFile.local" \
  -t "$IMAGE_TAG" \
  "$BUILD_DIR"

echo ""
echo "==> Build complete: $IMAGE_TAG"
echo ""
echo "Quick tests:"
echo "  podman run --rm --entrypoint id $IMAGE_TAG"
echo "  podman run -d --name tinycode-test -p 3000:3000 $IMAGE_TAG"
echo "  curl -s http://localhost:3000/global/health | jq ."
echo "  open http://localhost:3000"
echo "  podman stop tinycode-test && podman rm tinycode-test"
