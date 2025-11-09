#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-v1.76.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SRC_TGZ="${ROOT}/artifacts/grpc-${VERSION}-source-with-submodules.tar.gz"
if [[ ! -f "${SRC_TGZ}" ]]; then
  echo "[ERROR] Missing ${SRC_TGZ}. Run scripts/01_fetch_grpc.sh first."
  exit 1
fi

# Put an offline build script & README into a bundle together with the source tarball.
WORK="${ROOT}/artifacts/offline-bundle-${VERSION}"
rm -rf "${WORK}"
mkdir -p "${WORK}"

cp "${SRC_TGZ}" "${WORK}/"
cat > "${WORK}/README_OFFLINE.md" <<'EOF'
# Offline (air-gapped) gRPC build (v1.76.0)

## Prereqs (RHEL 8 or Ubuntu)
- Compilers & tools: gcc, g++, make, cmake, autoconf, libtool, pkg-config, perl, tar, gzip
- No network required once you have this bundle on the machine.

## Steps
1) Extract the bundle:
   tar -xzf offline-bundle-*.tar.gz
   cd offline-bundle-*

2) Extract gRPC sources (with submodules):
   tar -xzf grpc-v1.76.0-source-with-submodules.tar.gz
   mkdir -p build/grpc
   PREFIX=/opt/grpc-v1.76.0

3) Configure & build using only bundled third_party deps:
   cd build/grpc
   cmake -DgRPC_INSTALL=ON \
         -DgRPC_BUILD_TESTS=OFF \
         -DCMAKE_BUILD_TYPE=Release \
         -DgRPC_ABSL_PROVIDER=module \
         -DgRPC_CARES_PROVIDER=module \
         -DgRPC_PROTOBUF_PROVIDER=module \
         -DgRPC_RE2_PROVIDER=module \
         -DgRPC_SSL_PROVIDER=module \
         -DgRPC_ZLIB_PROVIDER=module \
         -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
         ../../grpc

   cmake --build . -j"$(nproc)"
   cmake --install .

4) (Optional) Package the install tree:
   tar -C /opt -czf grpc-v1.76.0-linux-$(uname -m).tar.gz grpc-v1.76.0

5) Using gRPC after install:
   - Headers:   ${PREFIX}/include
   - Libraries: ${PREFIX}/lib or lib64 (depending on system)
   You may need to export:
     export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH
     export LD_LIBRARY_PATH=${PREFIX}/lib:${PREFIX}/lib64:$LD_LIBRARY_PATH
EOF

# Produce an offline bundle tarball that you can carry to the air-gapped host.
BUNDLE_TGZ="${ROOT}/artifacts/offline-bundle-${VERSION}.tar.gz"
tar -C "${ROOT}/artifacts" -czf "${BUNDLE_TGZ}" "$(basename "${WORK}")"

echo "[DONE] Offline bundle: ${BUNDLE_TGZ}"
