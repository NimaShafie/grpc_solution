# build_grpc_windows11.ps1
# Build gRPC v1.76.0 on Windows 11 using vcpkg for air-gapped deployment

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "gRPC v1.76.0 Builder for Windows 11"
Write-Host "=========================================="
Write-Host ""

$GRPC_VERSION = "1.76.0"
$VCPKG_DIR = "C:\vcpkg"
$BUNDLE_DIR = "$HOME\grpc-airgap-bundle"

Write-Host "This script will:"
Write-Host "  1. Install/use vcpkg"
Write-Host "  2. Download and install gRPC (pre-built)"
Write-Host "  3. Create air-gapped bundle"
Write-Host ""
$response = Read-Host "Continue? (y/n)"
if ($response -ne "y") {
    exit 1
}

# Check if vcpkg exists
Write-Host ""
Write-Host "[1/5] Checking vcpkg installation..."

if (-not (Test-Path $VCPKG_DIR)) {
    Write-Host "Installing vcpkg..."
    Set-Location C:\
    git clone https://github.com/Microsoft/vcpkg.git
    Set-Location vcpkg
    .\bootstrap-vcpkg.bat
    Write-Host "✅ vcpkg installed"
} else {
    Write-Host "✅ vcpkg already installed"
}

# Install gRPC
Write-Host ""
Write-Host "[2/5] Installing gRPC via vcpkg..."
Write-Host "  (This downloads pre-built binaries, ~3GB, takes 15-20 min)"

Set-Location $VCPKG_DIR

$grpcInstalled = & "$VCPKG_DIR\vcpkg.exe" list | Select-String "grpc:"
if (-not $grpcInstalled) {
    & "$VCPKG_DIR\vcpkg.exe" install grpc:x64-windows
    Write-Host "✅ gRPC installed"
} else {
    Write-Host "✅ gRPC already installed"
}

# Export vcpkg installation (for air-gapped transfer)
Write-Host ""
Write-Host "[3/5] Exporting vcpkg packages..."

& "$VCPKG_DIR\vcpkg.exe" export grpc:x64-windows --zip --output=grpc-windows-export

Write-Host "✅ Export created"

# Create air-gapped bundle structure
Write-Host ""
Write-Host "[4/5] Creating air-gapped bundle..."

New-Item -ItemType Directory -Force -Path "$BUNDLE_DIR\windows11" | Out-Null
Set-Location "$BUNDLE_DIR\windows11"

# Copy the vcpkg export
Copy-Item "$VCPKG_DIR\grpc-windows-export.zip" "." -Force

# Copy binaries directly (alternative to export)
New-Item -ItemType Directory -Force -Path "binaries\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "binaries\lib" | Out-Null
New-Item -ItemType Directory -Force -Path "binaries\include" | Out-Null
New-Item -ItemType Directory -Force -Path "binaries\tools" | Out-Null

$vcpkgInstalled = "$VCPKG_DIR\installed\x64-windows"

Write-Host "  Copying binaries..."
Copy-Item "$vcpkgInstalled\bin\*.dll" "binaries\bin\" -ErrorAction SilentlyContinue
Copy-Item "$vcpkgInstalled\lib\*.lib" "binaries\lib\" -ErrorAction SilentlyContinue
Copy-Item "$vcpkgInstalled\include\*" "binaries\include\" -Recurse -Force
Copy-Item "$vcpkgInstalled\tools\*" "binaries\tools\" -Recurse -Force

# Download Python wheels
Write-Host ""
Write-Host "[5/5] Downloading Python packages..."

New-Item -ItemType Directory -Force -Path "python-wheels" | Out-Null
Set-Location "python-wheels"

pip download grpcio==1.76.0 grpcio-tools==1.76.0 protobuf==5.29.3

Set-Location "$BUNDLE_DIR\windows11"

# Calculate sizes
$exportSize = (Get-Item "grpc-windows-export.zip").Length / 1MB
$binariesSize = (Get-ChildItem "binaries" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
$pythonSize = (Get-ChildItem "python-wheels" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host ""
Write-Host "=========================================="
Write-Host "✅ BUILD COMPLETE!" -ForegroundColor Green
Write-Host "=========================================="
Write-Host "Bundle location: $BUNDLE_DIR\windows11\"
Write-Host ""
Write-Host "Contents:"
Write-Host "  - grpc-windows-export.zip  ($([math]::Round($exportSize, 2)) MB) - vcpkg export"
Write-Host "  - binaries\                ($([math]::Round($binariesSize, 2)) MB) - Direct binaries"
Write-Host "  - python-wheels\           ($([math]::Round($pythonSize, 2)) MB) - Python packages"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Create C++ and Python example projects"
Write-Host "  2. Package everything into single archive"
Write-Host "  3. Transfer to air-gapped Windows 11 system"
Write-Host "=========================================="

# Create installation instructions
@'
# Windows 11 Air-Gapped Installation

## Option 1: Using vcpkg Export (Recommended)

1. Extract grpc-windows-export.zip
2. Add to your CMake project:
   ```cmake
   set(CMAKE_TOOLCHAIN_FILE "path/to/grpc-windows-export/scripts/buildsystems/vcpkg.cmake")
   ```

## Option 2: Using Direct Binaries

1. Extract binaries/ folder
2. Add to environment:
   ```powershell
   $env:PATH += ";path\to\binaries\bin"
   $env:CMAKE_PREFIX_PATH = "path\to\binaries"
   ```

## Python Installation

```powershell
cd python-wheels
pip install --no-index --find-links=. grpcio grpcio-tools protobuf
```

## Verification

```powershell
# Check protoc
.\binaries\tools\protobuf\protoc.exe --version

# Check Python
python -c "import grpc; print(grpc.__version__)"
```
'@ | Out-File -FilePath "INSTALL_INSTRUCTIONS.txt" -Encoding UTF8

Write-Host ""
Write-Host "✅ Installation instructions created: INSTALL_INSTRUCTIONS.txt"
