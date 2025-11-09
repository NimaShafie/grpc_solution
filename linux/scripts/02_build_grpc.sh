#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-v1.76.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${ROOT}/src/grpc"
BUILD_DIR="${ROOT}/build/grpc"
PREFIX="${PREFIX:-/opt/grpc-${VERSION}}"

# Toggle shared/static (shared simplifies linking; static needs --static in pkg-config)
# Set SHARED=OFF to build static-only.
SHARED="${SHARED:-ON}"   # ON builds .so + .a, OFF builds static-only

if [[ ! -d "${SRC_DIR}" ]]; then
  echo "[ERROR] Source dir ${SRC_DIR} not found. Run scripts/01_fetch_grpc.sh first."
  exit 1
fi

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DgRPC_ABSL_PROVIDER=module \
      -DgRPC_CARES_PROVIDER=module \
      -DgRPC_PROTOBUF_PROVIDER=module \
      -DgRPC_RE2_PROVIDER=module \
      -DgRPC_SSL_PROVIDER=module \
      -DgRPC_ZLIB_PROVIDER=module \
      -DBUILD_SHARED_LIBS="${SHARED}" \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      "${SRC_DIR}"

cmake --build . -j"$(nproc)"
cmake --install .

# -------- Post-install: pkg-config helpers (re2, grpc++_reflection) --------
# Determine pkgconfig dir
PCDIR="${PREFIX}/lib/pkgconfig"
[[ -d "${PCDIR}" ]] || PCDIR="${PREFIX}/lib64/pkgconfig"
mkdir -p "${PCDIR}"

# 1) Stub re2.pc (vendored RE2 => no upstream .pc)
if [[ ! -f "${PCDIR}/re2.pc" ]]; then
  cat > "${PCDIR}/re2.pc" <<EOF
prefix=${PREFIX}
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: re2
Description: Stub RE2 for vendored gRPC build
Version: 0
Libs:
Cflags:
EOF
  echo "[INFO] Installed stub ${PCDIR}/re2.pc"
fi

# 2) Shim grpc++_reflection.pc (lib is installed but no .pc upstream)
if [[ ! -f "${PCDIR}/grpc++_reflection.pc" ]]; then
  cat > "${PCDIR}/grpc++_reflection.pc" <<EOF
prefix=${PREFIX}
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: grpc++_reflection
Description: gRPC C++ reflection library (pkg-config shim)
Version: ${VERSION}
Requires.private: grpc++
Libs: -L\${libdir} -lgrpc++_reflection
Cflags:
EOF
  echo "[INFO] Installed shim ${PCDIR}/grpc++_reflection.pc"
fi
# --------------------------------------------------------------------------

# Package the installation tree
mkdir -p "${ROOT}/artifacts"
OUT_TGZ="${ROOT}/artifacts/grpc-${VERSION}-linux-$(uname -m).tar.gz"
tar -C "$(dirname "${PREFIX}")" -czf "${OUT_TGZ}" "$(basename "${PREFIX}")"

echo "[DONE] Installed to: ${PREFIX}"
echo "[DONE] Packed install: ${OUT_TGZ}"
echo "[HINT] Add to your shell: export PKG_CONFIG_PATH=${PCDIR}:\$PKG_CONFIG_PATH"
