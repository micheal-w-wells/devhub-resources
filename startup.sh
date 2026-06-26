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

# Run from the repo root (directory containing this script).
cd "$(dirname "$0")"

# Remove any existing container with the same name.
podman rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "Starting DevHub docs at http://localhost:${PORT}/ (Ctrl-C to stop)..."

podman run --rm --name "${CONTAINER_NAME}" \
  -p "${PORT}:8000" \
  -v "${PWD}:/docs:Z" \
  -w /docs \
  "${IMAGE}" \
  sh -c "pip install --quiet mkdocs-techdocs-core && mkdocs serve -a 0.0.0.0:8000"
