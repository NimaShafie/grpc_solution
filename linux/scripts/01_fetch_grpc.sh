#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-v1.76.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Where to clone
SRC_DIR="${ROOT}/src/grpc"

if [[ -d "${SRC_DIR}" ]]; then
  echo "[INFO] src/grpc already exists; refusing to overwrite."
  echo "       Delete it if you want a fresh clone."
  exit 0
fi

echo "[INFO] Cloning gRPC ${VERSION} with full submodules..."
git clone --branch "${VERSION}" --recurse-submodules https://github.com/grpc/grpc "${SRC_DIR}"

# Ensure all submodules are fully populated (no network needed later)
echo "[INFO] Verifying/finalizing submodule checkout..."
git -C "${SRC_DIR}" submodule update --init --recursive

# Make a self-contained source tarball for offline environments
mkdir -p "${ROOT}/artifacts"
TARBALL="${ROOT}/artifacts/grpc-${VERSION}-source-with-submodules.tar.gz"
echo "[INFO] Creating ${TARBALL} ..."
tar -C "${ROOT}/src" -czf "${TARBALL}" grpc

echo "[DONE] Fetch complete."
echo "       Source with submodules: ${TARBALL}"
