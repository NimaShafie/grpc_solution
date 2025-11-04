# Windows 11 Air-Gapped gRPC Installation Guide

## What This Guide Covers

Complete air-gapped installation of gRPC v1.76.0 on Windows 11 with:
- Multiple installation options
- Pre-built binaries
- Python packages (offline installation)
- Working C++ and Python examples

---

## What You Have

After extracting `grpc-airgap-complete-v1.76.0.tar.gz`:

```
grpc-airgap-complete/
└── windows11/
    ├── grpc-windows-export.zip    ← vcpkg export (Option 1)
    ├── binaries/                  ← Direct binaries (Option 2)
    │   ├── bin/                   (protoc.exe, DLLs)
    │   ├── lib/                   (*.lib files)
    │   ├── include/               (headers)
    │   └── tools/                 (protobuf, grpc tools)
    ├── python-wheels/             ← Python packages
    ├── examples/                  ← Working examples
    └── INSTALL_INSTRUCTIONS.txt
```

---

## Option 1: vcpkg Export (RECOMMENDED)

### What is vcpkg Export?

A self-contained package with everything needed - no vcpkg installation required on air-gapped machine!

### Step 1: Extract

```powershell
# Extract main bundle
Expand-Archive grpc-airgap-complete-v1.76.0.zip -DestinationPath C:\

# Extract vcpkg export
cd C:\grpc-airgap-complete\windows11
Expand-Archive grpc-windows-export.zip -DestinationPath C:\grpc
```

### Step 2: Use in Your Project

Create `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.16)
project(MyGrpcProject)

# Point to vcpkg toolchain
set(CMAKE_TOOLCHAIN_FILE "C:/grpc/scripts/buildsystems/vcpkg.cmake")

set(CMAKE_CXX_STANDARD 17)

find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)

add_executable(myapp main.cpp)
target_link_libraries(myapp gRPC::grpc++ protobuf::libprotobuf)
```

### Step 3: Build

```powershell
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

**Done!** vcpkg export handles everything automatically.

---

## Option 2: Direct Binaries

### Step 1: Extract and Setup

```powershell
cd C:\grpc-airgap-complete\windows11

# Copy binaries to a permanent location
Copy-Item binaries C:\grpc-binaries -Recurse

# Add to PATH
$env:PATH += ";C:\grpc-binaries\bin"
$env:CMAKE_PREFIX_PATH = "C:\grpc-binaries"

# Make permanent (Run as Administrator)
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, "Machine")
[Environment]::SetEnvironmentVariable("CMAKE_PREFIX_PATH", "C:\grpc-binaries", "Machine")
```

### Step 2: Verify

```powershell
# Check protoc
C:\grpc-binaries\tools\protobuf\protoc.exe --version
# Output: libprotoc 29.3

# Check plugin
C:\grpc-binaries\tools\grpc\grpc_cpp_plugin.exe --version
# Output: grpc_cpp_plugin 1.76.0
```

### Step 3: Use in CMake

```cmake
cmake_minimum_required(VERSION 3.16)
project(MyGrpcProject)

set(CMAKE_PREFIX_PATH "C:/grpc-binaries")
set(CMAKE_CXX_STANDARD 17)

find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)

add_executable(myapp main.cpp)
target_link_libraries(myapp gRPC::grpc++ protobuf::libprotobuf)
```

---

## Python Installation

### Step 1: Install Offline

```powershell
cd C:\grpc-airgap-complete\windows11\python-wheels

# Install all packages
pip install --no-index --find-links=. grpcio grpcio-tools protobuf
```

### Step 2: Verify

```powershell
python -c "import grpc; print(grpc.__version__)"
# Output: 1.76.0
```

### Step 3: Run Python Example

```powershell
cd ..\examples

# Terminal 1
python server.py

# Terminal 2
python client.py

# Output: 10 + 5 = 15
```

---

## Option 3: Visual Studio Integration

### Using vcpkg Export

1. Open Visual Studio 2022
2. File → Open → CMake → Select CMakeLists.txt
3. CMake will automatically use vcpkg toolchain
4. Build and run!

### Using Direct Binaries

Add to your project properties:

**Include Directories:**
```
C:\grpc-binaries\include
```

**Library Directories:**
```
C:\grpc-binaries\lib
```

**Linker → Input → Additional Dependencies:**
```
grpc++.lib
grpc.lib
protobuf.lib
```

---

## Creating Your First Project

### Step 1: Create calculator.proto

```protobuf
syntax = "proto3";

package calculator;

service Calculator {
  rpc Add (Numbers) returns (Result) {}
}

message Numbers {
  int32 a = 1;
  int32 b = 2;
}

message Result {
  int32 value = 1;
}
```

### Step 2: Generate Code

```powershell
# Using vcpkg export
C:\grpc\tools\protobuf\protoc.exe --cpp_out=. --grpc_out=. `
    --plugin=protoc-gen-grpc=C:\grpc\tools\grpc\grpc_cpp_plugin.exe `
    calculator.proto

# Using direct binaries
C:\grpc-binaries\tools\protobuf\protoc.exe --cpp_out=. --grpc_out=. `
    --plugin=protoc-gen-grpc=C:\grpc-binaries\tools\grpc\grpc_cpp_plugin.exe `
    calculator.proto

# Python
python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. calculator.proto
```

### Step 3: Create server.cpp

```cpp
#include <iostream>
#include <grpcpp/grpcpp.h>
#include "calculator.grpc.pb.h"

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;

class CalculatorImpl final : public calculator::Calculator::Service {
  Status Add(ServerContext* ctx, const calculator::Numbers* req, 
             calculator::Result* res) override {
    res->set_value(req->a() + req->b());
    std::cout << req->a() << " + " << req->b() << " = " << res->value() << std::endl;
    return Status::OK;
  }
};

int main() {
  std::string addr("0.0.0.0:50051");
  CalculatorImpl service;
  ServerBuilder builder;
  builder.AddListeningPort(addr, grpc::InsecureServerCredentials());
  builder.RegisterService(&service);
  std::unique_ptr<Server> server(builder.BuildAndStart());
  std::cout << "Server listening on " << addr << std::endl;
  server->Wait();
  return 0;
}
```

### Step 4: Create CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.16)
project(CalculatorGRPC CXX)

# Option 1: vcpkg export
set(CMAKE_TOOLCHAIN_FILE "C:/grpc/scripts/buildsystems/vcpkg.cmake")

# Option 2: Direct binaries
# set(CMAKE_PREFIX_PATH "C:/grpc-binaries")

set(CMAKE_CXX_STANDARD 17)

find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)

add_executable(server 
    server.cpp 
    calculator.pb.cc 
    calculator.grpc.pb.cc)
target_link_libraries(server gRPC::grpc++ protobuf::libprotobuf)

add_executable(client 
    client.cpp 
    calculator.pb.cc 
    calculator.grpc.pb.cc)
target_link_libraries(client gRPC::grpc++ protobuf::libprotobuf)
```

### Step 5: Build

```powershell
mkdir build
cd build
cmake ..
cmake --build . --config Release

# Run
.\Release\server.exe   # Terminal 1
.\Release\client.exe   # Terminal 2
```

---

## Editing .proto Files

### Step 1: Edit calculator.proto

```protobuf
service Calculator {
  rpc Add (Numbers) returns (Result) {}
  rpc Multiply (Numbers) returns (Result) {}  // NEW
}
```

### Step 2: Regenerate

```powershell
# Using vcpkg export path
C:\grpc\tools\protobuf\protoc.exe --cpp_out=. --grpc_out=. `
    --plugin=protoc-gen-grpc=C:\grpc\tools\grpc\grpc_cpp_plugin.exe `
    calculator.proto

# Python
python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. calculator.proto
```

### Step 3: Implement

Add to server.cpp:

```cpp
Status Multiply(ServerContext* ctx, const calculator::Numbers* req,
                calculator::Result* res) override {
  res->set_value(req->a() * req->b());
  return Status::OK;
}
```

### Step 4: Rebuild

```powershell
cd build
cmake --build . --config Release
```

---

## Troubleshooting

### Problem: "CMake cannot find gRPC"

**Solution:**
```cmake
# Add to CMakeLists.txt
set(CMAKE_TOOLCHAIN_FILE "C:/grpc/scripts/buildsystems/vcpkg.cmake")
# OR
set(CMAKE_PREFIX_PATH "C:/grpc-binaries")
```

### Problem: "Missing DLLs when running"

**Solution:**
```powershell
# Copy DLLs to executable directory
Copy-Item C:\grpc-binaries\bin\*.dll .\build\Release\

# OR add to PATH
$env:PATH += ";C:\grpc-binaries\bin"
```

### Problem: "protoc not recognized"

**Solution:**
```powershell
# Use full path
C:\grpc\tools\protobuf\protoc.exe --version

# Or add to PATH
$env:PATH += ";C:\grpc\tools\protobuf"
```

### Problem: "ModuleNotFoundError: No module named 'grpc'"

**Solution:**
```powershell
cd python-wheels
pip install --no-index --find-links=. grpcio grpcio-tools protobuf
```

---

## Installation Options Comparison

| Option | Setup Time | Complexity | Best For |
|--------|-----------|------------|----------|
| vcpkg Export | 5 min | Low | CMake projects |
| Direct Binaries | 10 min | Medium | Any build system |
| Visual Studio | 5 min | Low | VS projects |
| Python Only | 2 min | Very Low | Python only |

---

## 🎯 Recommended Approach

### For C++ Development:
1. Use **vcpkg Export** (Option 1)
2. Extract to `C:\grpc`
3. Set toolchain in CMakeLists.txt
4. Build with CMake

### For Python Only:
1. Install Python wheels
2. Use immediately
3. No C++ setup needed

### For Visual Studio:
1. Use **vcpkg Export**
2. Open CMake project in VS
3. Build and debug

---

## Quick Reference

```powershell
# Extract vcpkg export
Expand-Archive grpc-windows-export.zip -DestinationPath C:\grpc

# Install Python
cd python-wheels
pip install --no-index --find-links=. grpcio grpcio-tools protobuf

# Generate code
C:\grpc\tools\protobuf\protoc.exe --cpp_out=. --grpc_out=. `
    --plugin=protoc-gen-grpc=C:\grpc\tools\grpc\grpc_cpp_plugin.exe `
    myservice.proto

# Build
mkdir build && cd build
cmake -DCMAKE_TOOLCHAIN_FILE=C:/grpc/scripts/buildsystems/vcpkg.cmake ..
cmake --build . --config Release
```

---

## Verification Checklist

- [ ] protoc.exe runs and shows version
- [ ] grpc_cpp_plugin.exe runs
- [ ] Python import grpc works
- [ ] Python example runs
- [ ] C++ project builds successfully
- [ ] Can generate code from .proto files

---

## Next Steps

1. Choose installation option
2. Install and verify
3. Run Python examples
4. Build C++ examples
5. Create your own services!

---

**You're now ready to develop with gRPC on air-gapped Windows 11!**
