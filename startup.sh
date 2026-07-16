#!/usr/bin/env bash
#
# startup.sh - Serve the DevHub Resources TechDocs site locally with podman.
#
# Builds and serves the MkDocs site (with the Backstage techdocs-core plugin)
# in a container, mirroring how DevHub publishes TechDocs. Live-reloads on
# changes to files under resources/ and mkdocs.yml.
#
# Usage:
#   ./startup.sh          # start the docs server on http://localhost:8000
#
# Stop with Ctrl-C, or from another shell: podman stop devhub-docs

set -euo pipefail

CONTAINER_NAME="devhub-docs"
PORT="8000"
IMAGE="docker.io/library/python:3.12-slim"
GENERATED_CONFIG=""
CONTAINER_CONFIG_PATH=""

# Run from the repo root (directory containing this script).
cd "$(dirname "$0")"

if ! command -v podman >/dev/null 2>&1; then
  echo "Error: podman is required but was not found in PATH." >&2
  exit 1
fi

if [[ -f mkdocs.yml ]]; then
  CONTAINER_CONFIG_PATH="/docs/mkdocs.yml"
elif [[ -f mkdocs.yaml ]]; then
  CONTAINER_CONFIG_PATH="/docs/mkdocs.yaml"
else
  GENERATED_CONFIG="$(mktemp "${TMPDIR:-/tmp}/devhub-mkdocs.XXXXXX.yml")"
  cat >"${GENERATED_CONFIG}" <<'EOF'
site_name: DevHub Resources (Local Preview)
docs_dir: /docs/resources
theme:
  name: material
plugins:
  - search
  - techdocs-core
EOF
  CONTAINER_CONFIG_PATH="/tmp/mkdocs.generated.yml"
  trap 'rm -f "${GENERATED_CONFIG}"' EXIT
  echo "No mkdocs.yml found. Using generated config to serve resources/."
fi

# Remove any existing container with the same name.
podman rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "Starting DevHub docs at http://localhost:${PORT}/ (Ctrl-C to stop)..."

PODMAN_ARGS=(
  run
  --rm
  --name "${CONTAINER_NAME}"
  -p "${PORT}:8000"
  -v "${PWD}:/docs:Z"
  -w /docs
)

if [[ -n "${GENERATED_CONFIG}" ]]; then
  PODMAN_ARGS+=( -v "${GENERATED_CONFIG}:/tmp/mkdocs.generated.yml:Z,ro" )
fi

podman "${PODMAN_ARGS[@]}" \
  "${IMAGE}" \
  sh -c "pip install --quiet mkdocs-techdocs-core && mkdocs serve -f ${CONTAINER_CONFIG_PATH} -a 0.0.0.0:8000"
