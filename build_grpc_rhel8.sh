#!/bin/bash
# build_grpc_rhel8.sh
# Build gRPC v1.76.0 on RHEL 8 for air-gapped deployment

set -e

echo "=========================================="
echo "gRPC v1.76.0 Builder for RHEL 8"
echo "=========================================="
echo ""

GRPC_VERSION="1.76.0"
INSTALL_DIR="$HOME/grpc-rhel8-install"
BUNDLE_DIR="$HOME/grpc-airgap-bundle"

# Check RHEL version
if [ -f /etc/redhat-release ]; then
    echo "✅ Detected: $(cat /etc/redhat-release)"
else
    echo "⚠️  Warning: Not running on RHEL"
fi

echo ""
echo "This script will:"
echo "  1. Download gRPC and all dependencies (NO git!)"
echo "  2. Build everything"
echo "  3. Create air-gapped bundle"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Install build dependencies (requires internet)
echo ""
echo "[1/5] Installing build dependencies..."
sudo yum groupinstall -y "Development Tools"
sudo yum install -y cmake3 autoconf libtool pkg-config wget unzip

# Create symlink for cmake
sudo ln -sf /usr/bin/cmake3 /usr/bin/cmake || true

# Download gRPC and dependencies (NO git clone!)
echo ""
echo "[2/5] Downloading gRPC and dependencies..."

mkdir -p ~/grpc-download
cd ~/grpc-download

# Download all components as ZIP files
echo "  Downloading gRPC core..."
wget -q --show-progress -O grpc.zip \
    "https://github.com/grpc/grpc/archive/refs/tags/v${GRPC_VERSION}.zip"

echo "  Downloading Abseil..."
wget -q --show-progress -O abseil.zip \
    "https://github.com/abseil/abseil-cpp/archive/refs/tags/20240722.0.zip"

echo "  Downloading Protocol Buffers..."
wget -q --show-progress -O protobuf.zip \
    "https://github.com/protocolbuffers/protobuf/archive/refs/tags/v29.3.zip"

echo "  Downloading RE2..."
wget -q --show-progress -O re2.zip \
    "https://github.com/google/re2/archive/refs/tags/2024-07-02.zip"

echo "  Downloading zlib..."
wget -q --show-progress -O zlib.zip \
    "https://github.com/madler/zlib/archive/refs/tags/v1.3.1.zip"

echo "  Downloading c-ares..."
wget -q --show-progress -O cares.zip \
    "https://github.com/c-ares/c-ares/archive/refs/tags/v1.34.4.zip"

echo "  Downloading BoringSSL..."
wget -q --show-progress -O boringssl.zip \
    "https://github.com/google/boringssl/archive/refs/heads/master.zip"

echo "  Downloading Google Benchmark..."
wget -q --show-progress -O benchmark.zip \
    "https://github.com/google/benchmark/archive/refs/tags/v1.9.1.zip"

# Extract and assemble
echo ""
echo "[3/5] Assembling complete source tree..."

unzip -q grpc.zip
mv "grpc-${GRPC_VERSION}" grpc
cd grpc

unzip -q ../abseil.zip
rm -rf third_party/abseil-cpp
mv abseil-cpp-20240722.0 third_party/abseil-cpp

unzip -q ../protobuf.zip
rm -rf third_party/protobuf
mv protobuf-29.3 third_party/protobuf

unzip -q ../re2.zip
rm -rf third_party/re2
mv re2-2024-07-02 third_party/re2

unzip -q ../zlib.zip
rm -rf third_party/zlib
mv zlib-1.3.1 third_party/zlib

unzip -q ../cares.zip
mkdir -p third_party/cares
rm -rf third_party/cares/cares
mv c-ares-1.34.4 third_party/cares/cares

unzip -q ../boringssl.zip
rm -rf third_party/boringssl-with-bazel
mv boringssl-master third_party/boringssl-with-bazel

unzip -q ../benchmark.zip
rm -rf third_party/benchmark
mv benchmark-1.9.1 third_party/benchmark

echo "✅ Complete source tree assembled"

# Verify all dependencies
echo ""
echo "Verifying dependencies..."
for dir in abseil-cpp protobuf re2 zlib benchmark boringssl-with-bazel; do
    if [ -d "third_party/$dir" ] && [ "$(ls -A third_party/$dir)" ]; then
        echo "  ✅ $dir"
    else
        echo "  ❌ $dir - MISSING OR EMPTY!"
        exit 1
    fi
done
echo "  ✅ c-ares"

# Build gRPC
echo ""
echo "[4/5] Building gRPC (this takes 30-45 minutes)..."

mkdir -p cmake/build
cd cmake/build

cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DgRPC_ABSL_PROVIDER=module \
      -DgRPC_CARES_PROVIDER=module \
      -DgRPC_PROTOBUF_PROVIDER=module \
      -DgRPC_RE2_PROVIDER=module \
      -DgRPC_SSL_PROVIDER=module \
      -DgRPC_ZLIB_PROVIDER=module \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
      ../..

# Build with all available cores
NPROC=$(nproc)
echo "Building with $NPROC parallel jobs..."
make -j$NPROC
make install

echo "✅ gRPC built and installed to $INSTALL_DIR"

# Create air-gapped bundle
echo ""
echo "[5/5] Creating air-gapped bundle..."

mkdir -p "$BUNDLE_DIR/linux-rhel8"
cd "$BUNDLE_DIR/linux-rhel8"

# Copy binaries
mkdir -p binaries/bin binaries/lib binaries/include
cp -r "$INSTALL_DIR/bin"/* binaries/bin/
cp -r "$INSTALL_DIR/lib"/* binaries/lib/
cp -r "$INSTALL_DIR/include"/* binaries/include/

# Create tarball of the source (for air-gapped compilation if needed)
cd ~/grpc-download
tar -czf "$BUNDLE_DIR/linux-rhel8/grpc-complete-source.tar.gz" grpc/

# Python wheels (download for offline installation)
mkdir -p "$BUNDLE_DIR/linux-rhel8/python-wheels"
cd "$BUNDLE_DIR/linux-rhel8/python-wheels"

pip3 download grpcio==1.76.0 grpcio-tools==1.76.0 protobuf==5.29.3 --dest .

echo "✅ Bundle created at $BUNDLE_DIR/linux-rhel8"

# Calculate sizes
BINARIES_SIZE=$(du -sh "$BUNDLE_DIR/linux-rhel8/binaries" | cut -f1)
SOURCE_SIZE=$(du -sh "$BUNDLE_DIR/linux-rhel8/grpc-complete-source.tar.gz" | cut -f1)
PYTHON_SIZE=$(du -sh "$BUNDLE_DIR/linux-rhel8/python-wheels" | cut -f1)

echo ""
echo "=========================================="
echo "✅ BUILD COMPLETE!"
echo "=========================================="
echo "Bundle location: $BUNDLE_DIR/linux-rhel8/"
echo ""
echo "Contents:"
echo "  - binaries/          ($BINARIES_SIZE) - Pre-built gRPC"
echo "  - grpc-complete-source.tar.gz ($SOURCE_SIZE) - Source backup"
echo "  - python-wheels/     ($PYTHON_SIZE) - Python packages"
echo ""
echo "Next steps:"
echo "  1. Create C++ and Python example projects"
echo "  2. Package everything into single archive"
echo "  3. Transfer to air-gapped RHEL 8 system"
echo "=========================================="
