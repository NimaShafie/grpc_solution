# gRPC Air-Gapped Build Package v1.76.0

## Overview

This package contains all necessary components to build and deploy gRPC v1.76.0 in an air-gapped network environment. The package supports C++, C#, and Python implementations with cross-language interoperability demonstrations.

## Architecture

The gRPC framework enables high-performance Remote Procedure Call (RPC) communication between services written in different languages. This package demonstrates three interoperability scenarios:

1. C++ client communicating with Python server
2. C# client communicating with Python server  
3. Python client communicating with Python server

## Package Structure

```
grpc-airgap-package/
├── README.md                    # This file
├── docs/                        # Comprehensive documentation
│   ├── BUILD_INSTRUCTIONS.md    # Detailed build steps
│   ├── PROTOBUF_GUIDE.md       # Protocol Buffer usage guide
│   ├── ARCHITECTURE.md         # System architecture documentation
│   └── TROUBLESHOOTING.md      # Common issues and solutions
├── proto/                       # Protocol Buffer definitions
│   └── calculator.proto         # Service definition
├── demos/                       # Language-specific demonstrations
│   ├── cpp/                     # C++ client demo
│   ├── csharp/                  # C# client demo
│   └── python/                  # Python server and client demos
├── build-scripts/               # Build automation scripts
│   ├── build-windows.bat        # Windows build script
│   ├── build-linux.sh          # Linux build script
│   └── CMakeLists.txt          # CMake configuration
└── dependencies/                # Required dependencies manifest

```

## Prerequisites

### On Connected Network (Download Phase)

Before transferring to the air-gapped network, download the following:

1. **gRPC Source Code**
   - Repository: https://github.com/grpc/grpc
   - Version: v1.76.0
   - Command: `git clone --recurse-submodules -b v1.76.0 https://github.com/grpc/grpc`

2. **Required Submodules** (included with --recurse-submodules)
   - abseil-cpp
   - protobuf
   - re2
   - zlib
   - cares
   - boringssl

3. **Build Tools**
   - CMake 3.16 or higher
   - Visual Studio 2022 (Windows)
   - GCC 8+ or Clang 9+ (RHEL 8)
   - Python 3.8+
   - .NET 6.0 SDK or higher

4. **Python Dependencies**
   - Download wheels for offline installation:
     ```bash
     pip download grpcio==1.76.0 grpcio-tools==1.76.0 protobuf -d python-packages/
     ```

5. **NuGet Packages** (C#)
   - Grpc.Core 2.46.6
   - Grpc.Tools 2.46.6
   - Google.Protobuf 3.25.1

### On Air-Gapped Network

Transfer the following to the air-gapped system:
- Complete gRPC v1.76.0 repository with submodules
- This demo package
- All downloaded Python wheels
- NuGet packages
- Build tools installers (if not already present)

## Quick Start

### Windows 11 with Visual Studio 2022

1. Extract the gRPC source to `C:\grpc`
2. Extract this package to `C:\grpc-demos`
3. Open Developer Command Prompt for VS 2022
4. Navigate to `C:\grpc-demos\build-scripts`
5. Run: `build-windows.bat`
6. Follow the demo-specific instructions in each demo directory

### RHEL 8 with CMake

1. Extract the gRPC source to `/opt/grpc`
2. Extract this package to `/opt/grpc-demos`
3. Navigate to `/opt/grpc-demos/build-scripts`
4. Run: `chmod +x build-linux.sh && ./build-linux.sh`
5. Follow the demo-specific instructions in each demo directory

## Demos Included

### Demo 1: C++ Client -> Python Server
Location: `demos/cpp/` and `demos/python/server/`

Demonstrates a C++ client invoking RPC methods on a Python gRPC server.

### Demo 2: C# Client -> Python Server
Location: `demos/csharp/` and `demos/python/server/`

Demonstrates a C# client invoking RPC methods on a Python gRPC server.

### Demo 3: Python Client -> Python Server
Location: `demos/python/`

Demonstrates a Python client invoking RPC methods on a Python gRPC server.

## Documentation

Comprehensive documentation is provided in the `docs/` directory:

- **BUILD_INSTRUCTIONS.md** - Step-by-step build process for each platform
- **PROTOBUF_GUIDE.md** - Guide to modifying and extending Protocol Buffer definitions
- **ARCHITECTURE.md** - System architecture and design decisions
- **TROUBLESHOOTING.md** - Solutions to common build and runtime issues

## Support

For issues specific to this demo package, refer to TROUBLESHOOTING.md.

For general gRPC documentation, see: https://grpc.io/docs/

## Version Information

- gRPC Version: 1.76.0
- Protocol Buffers Version: 3.25.x (bundled with gRPC)
- Target Platforms: Windows 11, RHEL 8
- Build Systems: Visual Studio 2022, CMake 3.16+

## License

This demo package is provided as-is for integration purposes. gRPC and its dependencies are licensed under the Apache License 2.0. Refer to the gRPC repository for complete license information.
