# Air-Gapped gRPC Quick Reference

## One-Page Reference for RHEL 8 and Windows 11

## Bundle Creation (Internet-Connected Machine)

### Linux (RHEL 8)

```bash
# One command creates everything
./create_complete_airgap_bundle.sh

# Takes 1-2 hours, creates:
# ~/grpc-airgap-complete-v1.76.0.tar.gz (~600 MB)
```

### Windows 11

```powershell
# Using vcpkg
./build_grpc_windows11.ps1

# Creates bundle in:
# $HOME\grpc-airgap-bundle\windows11\
```

---

## Quick Install (Air-Gapped Machine)

### RHEL 8

```bash
# Extract
tar -xzf grpc-airgap-complete-v1.76.0.tar.gz
cd grpc-airgap-complete/linux-rhel8

# Option 1: System-wide (requires sudo)
sudo ./install.sh

# Option 2: User install (no sudo)
cp -r binaries/* ~/.local/
pip3 install --user --no-index --find-links=python-wheels grpcio grpcio-tools

# Verify
protoc --version
python3 -c "import grpc; print(grpc.__version__)"
```

### Windows 11

```powershell
# Extract
Expand-Archive grpc-airgap-complete-v1.76.0.zip

# Option 1: vcpkg Export (Recommended)
Expand-Archive .\windows11\grpc-windows-export.zip -Dest C:\grpc

# Option 2: Direct Binaries
Copy-Item .\windows11\binaries C:\grpc-binaries -Recurse

# Python
cd windows11\python-wheels
pip install --no-index --find-links=. grpcio grpcio-tools

# Verify
C:\grpc\tools\protobuf\protoc.exe --version
python -c "import grpc; print(grpc.__version__)"
```

---

## Generate Code from .proto

### RHEL 8

```bash
# C++
protoc --cpp_out=. --grpc_out=. \
       --plugin=protoc-gen-grpc=$(which grpc_cpp_plugin) \
       myservice.proto

# Python
python3 -m grpc_tools.protoc -I. \
        --python_out=. --grpc_python_out=. \
        myservice.proto
```

### Windows 11

```powershell
# C++ (vcpkg export)
C:\grpc\tools\protobuf\protoc.exe --cpp_out=. --grpc_out=. `
    --plugin=protoc-gen-grpc=C:\grpc\tools\grpc\grpc_cpp_plugin.exe `
    myservice.proto

# C++ (direct binaries)
C:\grpc-binaries\tools\protobuf\protoc.exe --cpp_out=. --grpc_out=. `
    --plugin=protoc-gen-grpc=C:\grpc-binaries\tools\grpc\grpc_cpp_plugin.exe `
    myservice.proto

# Python
python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. myservice.proto
```

---

## Build C++ Project

### RHEL 8

```bash
# Simple compilation
g++ -std=c++17 server.cpp myservice.pb.cc myservice.grpc.pb.cc \
    -o server -lgrpc++ -lgrpc -lprotobuf -lpthread

# Using CMake
mkdir build && cd build
cmake ..
make
```

### Windows 11

```powershell
# CMakeLists.txt with vcpkg export
cmake_minimum_required(VERSION 3.16)
project(MyProject)
set(CMAKE_TOOLCHAIN_FILE "C:/grpc/scripts/buildsystems/vcpkg.cmake")
set(CMAKE_CXX_STANDARD 17)
find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)
add_executable(server server.cpp myservice.pb.cc myservice.grpc.pb.cc)
target_link_libraries(server gRPC::grpc++ protobuf::libprotobuf)

# Build
mkdir build; cd build
cmake ..
cmake --build . --config Release
```

---

## Python Quick Start

### Both OS (Same Commands!)

```python
# server.py
import grpc
from concurrent import futures
import myservice_pb2, myservice_pb2_grpc

class MyServicer(myservice_pb2_grpc.MyServiceServicer):
    def MyMethod(self, request, context):
        return myservice_pb2.Response(result=request.value * 2)

server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
myservice_pb2_grpc.add_MyServiceServicer_to_server(MyServicer(), server)
server.add_insecure_port('[::]:50051')
server.start()
server.wait_for_termination()
```

```python
# client.py
import grpc
import myservice_pb2, myservice_pb2_grpc

with grpc.insecure_channel('localhost:50051') as channel:
    stub = myservice_pb2_grpc.MyServiceStub(channel)
    response = stub.MyMethod(myservice_pb2.Request(value=5))
    print(f"Result: {response.result}")
```

---

## Environment Setup

### RHEL 8 (.bashrc)

```bash
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib:/usr/local/lib:$LD_LIBRARY_PATH"
export CMAKE_PREFIX_PATH="$HOME/.local:/usr/local"
```

### Windows 11 (PowerShell Profile)

```powershell
$env:PATH += ";C:\grpc\tools\protobuf;C:\grpc\tools\grpc"
$env:CMAKE_TOOLCHAIN_FILE = "C:/grpc/scripts/buildsystems/vcpkg.cmake"
# Or
$env:CMAKE_PREFIX_PATH = "C:/grpc-binaries"
```

---

## Common Commands

| Task | RHEL 8 | Windows 11 |
|------|--------|------------|
| Check protoc version | `protoc --version` | `C:\grpc\tools\protobuf\protoc.exe --version` |
| Check Python gRPC | `python3 -c "import grpc"` | `python -c "import grpc"` |
| Install Python offline | `pip3 install --no-index --find-links=wheels grpcio` | `pip install --no-index --find-links=wheels grpcio` |
| Compile C++ | `g++ -o app app.cpp -lgrpc++` | Use CMake + vcpkg |
| Run server | `./server` | `.\Release\server.exe` |

---

## Directory Structure

### After Installation

**RHEL 8:**
```
/usr/local/                    or  ~/.local/
├── bin/
│   ├── protoc
│   └── grpc_cpp_plugin
├── lib/
│   ├── libgrpc++.so
│   ├── libgrpc.so
│   └── libprotobuf.so
└── include/
    ├── grpcpp/
    └── google/
```

**Windows 11:**
```
C:\grpc\                       or  C:\grpc-binaries\
├── tools/
│   ├── protobuf/protoc.exe
│   └── grpc/grpc_cpp_plugin.exe
├── bin/
│   └── *.dll
├── lib/
│   └── *.lib
└── include/
    ├── grpcpp/
    └── google/
```

---

## Troubleshooting

### RHEL 8

| Problem | Solution |
|---------|----------|
| protoc not found | `export PATH="/usr/local/bin:$PATH"` |
| Library not found | `sudo ldconfig` or `export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"` |
| Python grpc missing | `pip3 install --no-index --find-links=wheels grpcio` |
| CMake can't find gRPC | `export CMAKE_PREFIX_PATH="/usr/local"` |

### Windows 11

| Problem | Solution |
|---------|----------|
| CMake can't find gRPC | Set `CMAKE_TOOLCHAIN_FILE` or `CMAKE_PREFIX_PATH` |
| Missing DLLs | Copy from `bin/` to executable directory or add to PATH |
| protoc not recognized | Use full path: `C:\grpc\tools\protobuf\protoc.exe` |
| Python grpc missing | `pip install --no-index --find-links=wheels grpcio` |

---

## Bundle Sizes

| Component | Size |
|-----------|------|
| Linux binaries | ~200 MB |
| Linux source | ~100 MB |
| Windows vcpkg export | ~300 MB |
| Windows binaries | ~200 MB |
| Python wheels (both) | ~100 MB |
| **Complete Bundle** | **~600 MB** |

---

## Verification Commands

### RHEL 8
```bash
protoc --version                           # Should show: libprotoc 29.3
grpc_cpp_plugin --version                  # Should show: 1.76.0
python3 -c "import grpc; print(grpc.__version__)"  # Should show: 1.76.0
ldconfig -p | grep grpc                    # Should show libraries
```

### Windows 11
```powershell
C:\grpc\tools\protobuf\protoc.exe --version  # Should show: libprotoc 29.3
C:\grpc\tools\grpc\grpc_cpp_plugin.exe       # Should show: 1.76.0
python -c "import grpc; print(grpc.__version__)"  # Should show: 1.76.0
```

---

## Workflow Summary

```
Internet Machine          Air-Gapped Machine
     │                           │
     ├─ Build/Download          ├─ Extract bundle
     ├─ Create bundle            ├─ Install
     ├─ Transfer ══════════════> ├─ Verify
     │                           ├─ Generate code
     │                           ├─ Build project
     │                           └─ Run!
```

---

## Key Files

| File | Purpose |
|------|---------|
| `create_complete_airgap_bundle.sh` | Creates full bundle |
| `build_grpc_rhel8.sh` | Linux-only build |
| `build_grpc_windows11.ps1` | Windows-only build |
| `RHEL8_AIRGAP_GUIDE.md` | Detailed Linux guide |
| `WINDOWS11_AIRGAP_GUIDE.md` | Detailed Windows guide |
| `*.proto` | Service definitions |

---

## Fastest Path

### RHEL 8
```bash
# 1. Create bundle (on internet machine)
./create_complete_airgap_bundle.sh

# 2. Transfer and install (on air-gapped)
tar -xzf bundle.tar.gz
cd linux-rhel8
sudo ./install.sh

# 3. Verify
protoc --version && python3 -c "import grpc"
```

### Windows 11
```powershell
# 1. Create bundle (on internet machine)
.\build_grpc_windows11.ps1

# 2. Transfer and install (on air-gapped)
Expand-Archive bundle.zip
Expand-Archive .\windows11\grpc-windows-export.zip -Dest C:\grpc
cd windows11\python-wheels
pip install --no-index --find-links=. grpcio grpcio-tools

# 3. Verify
C:\grpc\tools\protobuf\protoc.exe --version
python -c "import grpc"
```

---

**Keep this page handy for quick reference!**
