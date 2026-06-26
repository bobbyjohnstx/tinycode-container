# Changelog

## [0.1.0] — 2026-06-26

Initial public release.

### Added
- UBI9-based container image for Kubernetes and OpenShift
- Bundled tmux, git, and optional oc CLI
- vLLM auto-configuration via TINYCODE_VLLM_URL environment variable
- GitOps startup mode — clone repo into /projects on container start
- RHOAI/OpenShift in-cluster auto-detection
- Cluster-admin mode with oc CLI download and checksum verification
- PVC-based config persistence at ~/.config/tinycode/
- OpenShift arbitrary UID compatibility
- Multi-arch builds (amd64 + arm64)
- Dual-registry publishing (Quay.io + GHCR)

### Security
- Input validation for TINYCODE_VLLM_MODEL (JSON injection prevention)
- Git credential sanitization in logs
- GPG-verified RPM downloads
- GitHub Actions pinned to SHA digests
- NetworkPolicy for ingress restriction
- Read-only root filesystem support
- Ingress rate limiting annotations
