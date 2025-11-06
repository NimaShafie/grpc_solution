#!/usr/bin/env bash
# build_rhel8.sh — Build & install gRPC v1.76.0 on RHEL8 with bundled deps.
set -euo pipefail
ROOT="$(pwd)"
BUILD="$ROOT/cmake/build-rhel8"
PREFIX="$ROOT/dist/rhel8/grpc-install"

# Optional: enable newer GCC
if [ -f /opt/rh/gcc-toolset-12/enable ]; then
  source /opt/rh/gcc-toolset-12/enable
fi

git submodule update --init --recursive
rm -rf "$BUILD"

cmake -S "$ROOT" -B "$BUILD" \
  -DgRPC_INSTALL=ON \
  -DgRPC_BUILD_TESTS=OFF \
  -DgRPC_PROTOBUF_PROVIDER=module \
  -DgRPC_ABSL_PROVIDER=module \
  -DgRPC_CARES_PROVIDER=module \
  -DgRPC_RE2_PROVIDER=module \
  -DgRPC_SSL_PROVIDER=module \
  -DgRPC_ZLIB_PROVIDER=module \
  -DgRPC_BUILD_CSHARP_EXT=ON \
  -DgRPC_BUILD_GRPC_PYTHON_PLUGIN=ON \
  -Dprotobuf_INSTALL=ON -Dprotobuf_BUILD_TESTS=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX"

cmake --build "$BUILD" --parallel
cmake --install "$BUILD" --prefix "$PREFIX"

echo "Installed to: $PREFIX"
ls -1 "$PREFIX/bin"


# quick validation afterwards
# export PATH="$PWD/dist/rhel8/grpc-install/bin:$PATH"
# protoc --version
# grpc_cpp_plugin --version
# grpc_csharp_plugin --version
# grpc_python_plugin --version
