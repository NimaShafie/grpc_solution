# Complete Air-Gapped gRPC Solution for RHEL 8 and Windows 11

## Goal

Create ONE self-contained folder/ZIP that works on air-gapped networks with:
- NO git clone
- NO submodules  
- NO internet access needed
- Pre-built binaries included
- Working C++ and Python examples
- Editable .proto files

---

## What You'll Create

```
grpc-airgap-bundle/
├── linux-rhel8/                    ← For RHEL 8
│   ├── binaries/
│   ├── cpp-project/
│   ├── python-project/
│   └── INSTALL_RHEL8.md
├── windows11/                      ← For Windows 11
│   ├── binaries/
│   ├── cpp-project/
│   ├── python-project/
│   └── INSTALL_WINDOWS11.md
├── shared/
│   ├── calculator.proto
│   └── docs/
└── README.md
```

**Total Size: ~600 MB** (includes everything for both OS)

---

## SOLUTION OVERVIEW

### Linux RHEL 8 Options:
1. **Pre-built binaries** (Fastest - 2 min)
2. **Source bundle** (45 min compile if needed)

### Windows 11 Options:
1. **vcpkg export** (Fastest - 2 min)
2. **Direct binaries** (5 min)

---

## COMPLETE FILE LIST

### Start Here:
1. **MASTER_AIRGAP_GUIDE.md** (This file) - Overview
2. **QUICK_REFERENCE.md** - One-page quick reference for both OS

### Linux RHEL 8:
3. **build_grpc_rhel8.sh** - Build gRPC on RHEL 8
4. **RHEL8_AIRGAP_GUIDE.md** - Complete installation guide for RHEL 8

### Windows 11:
5. **build_grpc_windows11.ps1** - Build using vcpkg on Windows
6. **WINDOWS11_AIRGAP_GUIDE.md** - Complete installation guide for Windows 11

### Bundle Creation:
7. **create_complete_airgap_bundle.sh** - ONE script creates EVERYTHING

### Also Useful:
8. **create_self_contained_repo.md** - Detailed manual instructions
9. **VISUAL_WORKFLOW.md** - Visual diagrams
10. **SOLUTION_SELF_CONTAINED.md** - Alternative approach

---

## QUICKEST PATH TO SUCCESS

### Step 1: On Internet-Connected Machine

**Linux:**
```bash
# One command creates complete bundle for BOTH OS
chmod +x create_complete_airgap_bundle.sh
./create_complete_airgap_bundle.sh

# Takes 1-2 hours
# Creates: ~/grpc-airgap-complete-v1.76.0.tar.gz (600 MB)
```

**Windows (for Windows-only bundle):**
```powershell
# Creates Windows bundle
.\build_grpc_windows11.ps1

# Takes 20-30 minutes
# Creates: $HOME\grpc-airgap-bundle\windows11\
```

### Step 2: Transfer to Air-Gapped Machine

Transfer the `.tar.gz` or `.zip` file via:
- Approved file transfer

### Step 3: Install on Air-Gapped Machine

**RHEL 8:**
```bash
tar -xzf grpc-airgap-complete-v1.76.0.tar.gz
cd grpc-airgap-complete/linux-rhel8
sudo ./install.sh

# Verify
protoc --version
python3 -c "import grpc; print(grpc.__version__)"
```

**Windows 11:**
```powershell
Expand-Archive grpc-airgap-complete-v1.76.0.zip
cd grpc-airgap-complete\windows11
Expand-Archive grpc-windows-export.zip -Dest C:\grpc

# Verify
C:\grpc\tools\protobuf\protoc.exe --version
```

**Done! No internet needed!**

---

## Detailed Guides

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - One-page commands for both OS
- **[RHEL8_AIRGAP_GUIDE.md](RHEL8_AIRGAP_GUIDE.md)** - Complete Linux guide
- **[WINDOWS11_AIRGAP_GUIDE.md](WINDOWS11_AIRGAP_GUIDE.md)** - Complete Windows guide

---

## Key Features

### Linux RHEL 8 Bundle Includes:
- Pre-compiled binaries (protoc, grpc_cpp_plugin, libraries)
- Python wheels (grpcio, grpcio-tools, protobuf)
- Complete source code (if need to rebuild)
- Working C++ and Python examples
- Installation script (system-wide or user)

### Windows 11 Bundle Includes:
- vcpkg export (self-contained, works anywhere)
- Direct binaries (alternative method)
- Python wheels (grpcio, grpcio-tools, protobuf)
- Working C++ and Python examples
- Installation instructions

---

## What You Can Do

After installation, you can:
- Edit .proto files and regenerate code
- Build C++ gRPC applications
- Build Python gRPC applications
- Cross-language communication (C++ ↔ Python)
- Everything works offline

---

## Bundle Contents

| Component | RHEL 8 | Windows 11 |
|-----------|--------|------------|
| Binaries | 200 MB | 300 MB |
| Python wheels | 50 MB | 50 MB |
| Source backup | 100 MB | - |
| Examples | 1 MB | 1 MB |
| **Subtotal** | **~350 MB** | **~350 MB** |
| **Complete Bundle** | **~600 MB** (both OS) |

---

## Time Investment

| Phase | Time |
|-------|------|
| Build bundle (internet) | 1-2 hours (one-time) |
| Transfer to air-gap | 5-10 min |
| Install on RHEL 8 | 2 min |
| Install on Windows 11 | 5 min |
| Verify installation | 2 min |
| **Total to working system** | **~2 hours** |

---

## Complete Workflow

```
┌─────────────────────────────────────────────────────────┐
│          INTERNET-CONNECTED MACHINE                      │
├─────────────────────────────────────────────────────────┤
│  Step 1: Run create_complete_airgap_bundle.sh          │
│          (1-2 hours, one-time)                           │
│                                                          │
│  Creates: grpc-airgap-complete-v1.76.0.tar.gz          │
│           (600 MB, both RHEL 8 + Windows 11)            │
└─────────────────────────────────────────────────────────┘
                        ↓ Transfer
┌─────────────────────────────────────────────────────────┐
│            AIR-GAPPED RHEL 8 MACHINE                     │
├─────────────────────────────────────────────────────────┤
│  Step 2: Extract and install (2 min)                    │
│          tar -xzf bundle.tar.gz                         │
│          cd linux-rhel8 && sudo ./install.sh            │
│                                                          │
│  Step 3: Verify and use                                 │
│          protoc --version                               │
│          Create your gRPC services!                     │
└─────────────────────────────────────────────────────────┘
                        ↓ Transfer
┌─────────────────────────────────────────────────────────┐
│           AIR-GAPPED WINDOWS 11 MACHINE                  │
├─────────────────────────────────────────────────────────┤
│  Step 2: Extract and install (5 min)                    │
│          Expand-Archive bundle.zip                      │
│          Expand-Archive vcpkg-export.zip to C:\grpc     │
│                                                          │
│  Step 3: Verify and use                                 │
│          C:\grpc\tools\protobuf\protoc.exe --version   │
│          Create your gRPC services!                     │
└─────────────────────────────────────────────────────────┘
```

---

## Success Criteria

You know everything worked when:

### RHEL 8:
- [ ] `protoc --version` shows 29.3
- [ ] `grpc_cpp_plugin --version` shows 1.76.0  
- [ ] `python3 -c "import grpc"` works
- [ ] Can compile C++ examples
- [ ] Can run Python examples
- [ ] Can regenerate from .proto files

### Windows 11:
- [ ] `protoc.exe --version` shows 29.3
- [ ] `grpc_cpp_plugin.exe` exists
- [ ] `python -c "import grpc"` works
- [ ] CMake finds gRPC packages
- [ ] Can build C++ projects
- [ ] Can run Python examples

---

## Next Steps

1. Review **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** for commands
2. Run **create_complete_airgap_bundle.sh** (or OS-specific script)
3. Transfer bundle to air-gapped machines
4. Follow OS-specific guide for installation
5. Build and run examples
6. Create your own gRPC services!

---

## File Index

| File | Size | Purpose |
|------|------|---------|
| **MASTER_AIRGAP_GUIDE.md** | 15 KB | This file - overview |
| **QUICK_REFERENCE.md** | 12 KB | One-page command reference |
| **build_grpc_rhel8.sh** | 8 KB | Build for RHEL 8 |
| **build_grpc_windows11.ps1** | 6 KB | Build for Windows 11 |
| **create_complete_airgap_bundle.sh** | 15 KB | Create full bundle |
| **RHEL8_AIRGAP_GUIDE.md** | 18 KB | Complete RHEL 8 guide |
| **WINDOWS11_AIRGAP_GUIDE.md** | 20 KB | Complete Windows 11 guide |

---

**Start with:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for immediate commands, or read the OS-specific guides for detailed instructions.

