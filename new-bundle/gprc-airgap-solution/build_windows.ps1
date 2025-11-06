<# build_windows.ps1
Build & install gRPC v1.76.0 on Windows (VS2022) with bundled third_party deps.
Installs to .\dist\windows\grpc-install (protoc + grpc_*_plugin + headers/libs).
#>
$ErrorActionPreference = 'Stop'
$root   = (Get-Location).Path
$build  = Join-Path $root 'cmake\build-vs17-x64'
$prefix = Join-Path $root 'dist\windows\grpc-install'

git submodule update --init --recursive

# Fresh configure to ensure the prefix is baked in
if (Test-Path $build) { Remove-Item -Recurse -Force $build }

cmake -S $root -B $build `
  -G "Visual Studio 17 2022" -A x64 `
  -DgRPC_INSTALL=ON `
  -DgRPC_BUILD_TESTS=OFF `
  -DgRPC_PROTOBUF_PROVIDER=module `
  -DgRPC_ABSL_PROVIDER=module `
  -DgRPC_CARES_PROVIDER=module `
  -DgRPC_RE2_PROVIDER=module `
  -DgRPC_SSL_PROVIDER=module `
  -DgRPC_ZLIB_PROVIDER=module `
  -DgRPC_BUILD_CSHARP_EXT=ON `
  -DgRPC_BUILD_GRPC_PYTHON_PLUGIN=ON `
  -Dprotobuf_INSTALL=ON -Dprotobuf_BUILD_TESTS=OFF `
  -DCMAKE_BUILD_TYPE=Release `
  -DCMAKE_INSTALL_PREFIX="$prefix"

cmake --build $build --config Release
cmake --install $build --config Release

Write-Host "`nInstalled to: $prefix"
Get-ChildItem -File (Join-Path $prefix 'bin') | Select-Object Name,Length


# run it with the following command
#PowerShell.exe -ExecutionPolicy Bypass -File .\build_windows.ps1

# expected result
# in (dist\windows\grpc-install\bin)
# protoc.exe
# grpc_cpp_plugin.exe
# grpc_csharp_plugin.exe
# grpc_python_plugin.exe