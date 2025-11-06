# ========= gRPC (shared DLLs) rebuild — user-agnostic =========

# Resolve paths from the current user's profile
$SRC     = Join-Path $env:USERPROFILE 'Desktop\gprc-airgap-solution\grpc_v1_76_0_cloned'
$BUILD   = Join-Path $SRC 'build\shared'
$PREFIX  = Join-Path $env:USERPROFILE 'Desktop\gprc-airgap-solution\grpc-install-shared'

# 1) Ensure submodules (protobuf, abseil, etc.) are present
Set-Location $SRC
git submodule update --init --recursive

# 2) Configure: build SHARED DLLs, install everything, no tests
Remove-Item -Recurse -Force $BUILD -ErrorAction Ignore
cmake -S $SRC -B $BUILD `
  -G "Visual Studio 17 2022" -A x64 `
  -DCMAKE_INSTALL_PREFIX="$PREFIX" `
  -DBUILD_SHARED_LIBS=ON `
  -DgRPC_INSTALL=ON `
  -DgRPC_BUILD_TESTS=OFF `
  -DgRPC_ABSL_PROVIDER=module `
  -DgRPC_PROTOBUF_PROVIDER=module `
  -DgRPC_RE2_PROVIDER=module `
  -DgRPC_CARES_PROVIDER=module `
  -DgRPC_ZLIB_PROVIDER=module `
  -Dprotobuf_BUILD_TESTS=OFF

# 3) Build & install Release
cmake --build $BUILD --config Release --target INSTALL

# 4) Make DLLs visible to your app (build + runtime)
$env:PATH = "$PREFIX\bin;$env:PATH"

# (Optional) sanity checks
Get-ChildItem "$PREFIX\bin" | Where-Object Name -match 'grpc|protobuf|absl' | Select-Object Name
where protoc
