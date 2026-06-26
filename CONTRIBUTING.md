# Contributing to tinycode-container

## Development Setup

1. Install [Podman](https://podman.io) or Docker
2. Clone the repository
3. Review [CONTAINER.md](CONTAINER.md) for the environment variable contract

## Commands

```bash
# Build container locally
./build-local.sh

# Install into local cluster
./install.sh

# Test entrypoint locally
podman run --rm -it -e TINYCODE_COMMAND="version" localhost/tinycode:latest
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes to:
   - `ContainerFile` / `ContainerFile.local` — container images
   - `entrypoint.sh` — entrypoint logic
   - `k8s/` manifests — Kubernetes YAML
   - `config/` — default configuration files
4. Test the container build and entrypoint behavior
5. Use conventional commit messages: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
6. Push and open a PR against `main`

## Container Architecture

The container wraps the tinycode server with:
- Configurable entry points (see `CONTAINER.md`)
- Pre-configured MCP servers
- Volume-based persistence for config and data
- Optional init container for config injection

## Testing Changes

1. Build locally: `./build-local.sh`
2. Deploy to test cluster: `./install.sh`
3. Verify:
   - Entrypoint executes as expected
   - Environment variables are honored
   - Config files mount correctly
   - Logs are clean

## Environment Variables

See [CONTAINER.md](CONTAINER.md) for the complete environment variable contract. All new env vars must be documented there.

## Questions?

Open a [GitHub Issue](https://github.com/bobbyjohnstx/tinycode-container/issues) for bugs or feature requests.
