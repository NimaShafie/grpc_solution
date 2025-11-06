# RHEL 8 Air-Gapped gRPC Installation Guide

## What This Guide Covers

Complete air-gapped installation of gRPC v1.76.0 on RHEL 8 with:
- Pre-built binaries (no compilation needed)
- Python packages (offline installation)
- Working C++ and Python examples
- Source code backup (if needed)

---

## What You Have

After extracting `grpc-airgap-complete-v1.76.0.tar.gz`, you'll see:

```
grpc-airgap-complete/
└── linux-rhel8/
    ├── binaries/              ← Pre-compiled gRPC
    │   ├── bin/               (protoc, grpc_cpp_plugin)
    │   ├── lib/               (libgrpc++.so, etc.)
    │   └── include/           (headers)
    ├── python-wheels/         ← Python packages
    ├── source/                ← Complete source (backup)
    ├── examples/              ← Working examples
    │   ├── server.cpp
    │   ├── client.cpp
    │   ├── server.py
    │   └── client.py
    └── install.sh             ← Installation script
```

---

## Option 1: Quick Install (Pre-Built Binaries)

### Step 1: Transfer and Extract

```bash
# Transfer grpc-airgap-complete-v1.76.0.tar.gz to RHEL 8 machine
# Extract
tar -xzf grpc-airgap-complete-v1.76.0.tar.gz
cd grpc-airgap-complete/linux-rhel8
```

### Step 2: Install System-Wide

```bash
# Run installation script
sudo ./install.sh

# This installs:
# - Binaries to /usr/local/bin/
# - Libraries to /usr/local/lib/
# - Headers to /usr/local/include/
# - Python packages
```

### Step 3: Verify Installation

```bash
# Check protoc
protoc --version
# Should output: libprotoc 29.3

# Check gRPC plugin
which grpc_cpp_plugin
# Should output: /usr/local/bin/grpc_cpp_plugin

# Check Python
python3 -c "import grpc; print(grpc.__version__)"
# Should output: 1.76.0

# Check libraries
ldconfig -p | grep grpc
# Should show libgrpc++ and libgrpc
```

---

## Option 2: User Install (No Sudo Required)

If you don't have sudo access:

```bash
cd linux-rhel8

# Install to user directory
INSTALL_DIR="$HOME/.local"
mkdir -p "$INSTALL_DIR"/{bin,lib,include}

# Copy binaries
cp -r binaries/bin/* "$INSTALL_DIR/bin/"
cp -r binaries/lib/* "$INSTALL_DIR/lib/"
cp -r binaries/include/* "$INSTALL_DIR/include/"

# Set environment variables
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"' >> ~/.bashrc
echo 'export CMAKE_PREFIX_PATH="$HOME/.local"' >> ~/.bashrc

# Reload
source ~/.bashrc

# Install Python packages (user)
pip3 install --user --no-index --find-links=python-wheels \
    grpcio grpcio-tools protobuf

# Verify
protoc --version
python3 -c "import grpc; print(grpc.__version__)"
```

---

## Python Example

```bash
cd examples

# Run server (Terminal 1)
python3 server.py

# Run client (Terminal 2)
python3 client.py

# Output:
# 10 + 5 = 15
```

---

## 🔧 C++ Example

### Compile

```bash
cd examples

# Compile server
g++ -std=c++17 server.cpp calculator.pb.cc calculator.grpc.pb.cc \
    -o server \
    -lgrpc++ -lgrpc -lprotobuf -lpthread

# Compile client
g++ -std=c++17 client.cpp calculator.pb.cc calculator.grpc.pb.cc \
    -o client \
    -lgrpc++ -lgrpc -lprotobuf -lpthread
```

### Run

```bash
# Terminal 1
./server

# Terminal 2
./client

# Output:
# 10 + 5 = 15
```

---

## Using CMake (Better Way)

Create `CMakeLists.txt` in examples/:

```cmake
cmake_minimum_required(VERSION 3.16)
project(CalculatorGRPC CXX)

set(CMAKE_CXX_STANDARD 17)

find_package(Protobuf REQUIRED)
find_package(gRPC CONFIG REQUIRED)

add_executable(server server.cpp calculator.pb.cc calculator.grpc.pb.cc)
target_link_libraries(server gRPC::grpc++ protobuf::libprotobuf)

add_executable(client client.cpp calculator.pb.cc calculator.grpc.pb.cc)
target_link_libraries(client gRPC::grpc++ protobuf::libprotobuf)
```

Build:

```bash
mkdir build && cd build
cmake ..
make
./server  # Terminal 1
./client  # Terminal 2
```

---

## Editing .proto Files

### Step 1: Edit calculator.proto

```protobuf
// Add new method
service Calculator {
  rpc Add (Numbers) returns (Result) {}
  rpc Power (Numbers) returns (Result) {}  // NEW
}
```

### Step 2: Regenerate Code

```bash
# C++
protoc --cpp_out=. --grpc_out=. \
       --plugin=protoc-gen-grpc=$(which grpc_cpp_plugin) \
       calculator.proto

# Python
python3 -m grpc_tools.protoc -I. \
        --python_out=. --grpc_python_out=. \
        calculator.proto
```

### Step 3: Implement

Update server.cpp / server.py with new method implementation.

### Step 4: Rebuild

```bash
# C++: Recompile
g++ -std=c++17 server.cpp *.pb.cc -o server -lgrpc++ -lgrpc -lprotobuf -lpthread

# Python: Just run (no rebuild needed!)
python3 server.py
```

---

## Option 3: Build from Source (If Needed)

If you need to recompile for different architecture:

```bash
cd source
tar -xzf grpc-v1.76.0-complete.tar.gz
cd grpc

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
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      ../..

make -j$(nproc)
sudo make install
```

**Note:** This takes 30-45 minutes but gives you a custom build.

---

## Troubleshooting

### Problem: "protoc: command not found"

```bash
# Check PATH
echo $PATH | grep local

# If not there, add it
export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
```

### Problem: "error while loading shared libraries: libgrpc++.so.1"

```bash
# Update library cache
sudo ldconfig

# Or add to LD_LIBRARY_PATH
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
echo 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' >> ~/.bashrc
```

### Problem: "No module named 'grpc'"

```bash
# Check if installed
pip3 list | grep grpc

# Reinstall
cd python-wheels
pip3 install --no-index --find-links=. grpcio grpcio-tools protobuf
```

### Problem: CMake can't find gRPC

```bash
# Set CMAKE_PREFIX_PATH
export CMAKE_PREFIX_PATH="/usr/local"
# Or in CMakeLists.txt:
# set(CMAKE_PREFIX_PATH "/usr/local")
```

---

## File Sizes

| Component | Size |
|-----------|------|
| Binaries | ~200 MB |
| Python wheels | ~50 MB |
| Source archive | ~100 MB |
| Examples | ~1 MB |
| **Total** | **~350 MB** |

---

## Verification Checklist

- [ ] `protoc --version` shows 29.3
- [ ] `grpc_cpp_plugin --version` shows 1.76.0
- [ ] `python3 -c "import grpc"` works
- [ ] Python example runs successfully
- [ ] C++ example compiles and runs
- [ ] Can edit .proto and regenerate code

---

## Next Steps

1. Install gRPC (Option 1 or 2)
2. Verify installation
3. Run Python examples
4. Compile and run C++ examples
5. Create your own services!

---

## Quick Reference

```bash
# Install system-wide
sudo ./install.sh

# Install as user
./install.sh --user

# Verify
protoc --version
python3 -c "import grpc; print(grpc.__version__)"

# Run examples
cd examples
python3 server.py  # Terminal 1
python3 client.py  # Terminal 2

# Regenerate from .proto
protoc --cpp_out=. --grpc_out=. \
       --plugin=protoc-gen-grpc=grpc_cpp_plugin \
       calculator.proto
```

---

**You're now ready to develop with gRPC on air-gapped RHEL 8!** 
