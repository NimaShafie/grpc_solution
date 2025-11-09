#!/usr/bin/env bash
# Source this to use the freshly installed gRPC in builds of your apps.
set -euo pipefail
VERSION="${VERSION:-v1.76.0}"
PREFIX="${PREFIX:-/opt/grpc-${VERSION}}"

export PATH="${PREFIX}/bin:${PATH}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${PREFIX}/lib:${PREFIX}/lib64:${LD_LIBRARY_PATH:-}"

echo "[INFO] gRPC env set for ${PREFIX}"
