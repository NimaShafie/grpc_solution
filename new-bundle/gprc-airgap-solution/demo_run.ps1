<# demo_run.ps1
Prepares and validates the gRPC demos (Python, C#, C++) using the local gRPC install.
Uses the latest installed Python 3 (via `py`) and supports offline wheels.
#>

$ErrorActionPreference = 'Stop'

# --------- Dynamic roots ----------
$solutionRoot = $PSScriptRoot
$repoGrpc     = Join-Path $solutionRoot 'grpc_v1_76_0_cloned'
$prefix       = Join-Path $repoGrpc   'dist\windows\grpc-install'
$demoRoot     = Join-Path $solutionRoot 'grpc_demo'

$proto        = Join-Path $demoRoot 'nuget\demos\proto\calculator.proto'
$protoDir     = Split-Path $proto -Parent
$pyOut        = Join-Path $demoRoot 'nuget\demos\python'
$cppOut       = Join-Path $demoRoot 'nuget\demos\cpp'
$wheels       = Join-Path $demoRoot 'python-wheels'   # optional, used if present

# --------- Preconditions ----------
if (-not (Test-Path $prefix)) { throw "Missing gRPC install prefix at '$prefix'." }
if (-not (Test-Path $proto))  { throw "Missing proto at '$proto'." }

# Ensure tools are on PATH (protoc, grpc_*_plugin.exe)
$env:PATH = "$prefix\bin;$env:PATH"

# Create demo output folders if they do not exist
$null = New-Item -ItemType Directory -Force -Path $pyOut, $cppOut

# --------- Python venv (LATEST Python 3) ----------
Write-Host "== Python venv (latest) & packages ==" -ForegroundColor Cyan

Push-Location $demoRoot
# Create venv with the latest Python 3 detected by the 'py' launcher.
if (-not (Test-Path '.venv_latest')) { & py -3 -m venv .venv_latest }
. .\.venv_latest\Scripts\Activate.ps1

# Upgrade pip
python -m pip install -U pip

# Try offline first (pinned), then offline unpinned, then warn.
$offline = Test-Path $wheels
if ($offline) {
  Write-Host "Installing from offline wheels at $wheels (pinned)" -ForegroundColor DarkCyan
  $pinnedOk = $true
  try {
    python -m pip install --no-index --find-links "$wheels" `
      "protobuf==6.33.0" "grpcio==1.76.0" "grpcio-tools==1.76.0"
  } catch {
    $pinnedOk = $false
  }

  if (-not $pinnedOk) {
    Write-Warning "Pinned versions not found for this Python. Trying offline unpinned."
    try {
      python -m pip install --no-index --find-links "$wheels" protobuf grpcio grpcio-tools
      $pinnedOk = $true
    } catch {
      $pinnedOk = $false
    }
  }

  if (-not $pinnedOk) {
    Write-Warning @"
Offline wheels do NOT match your latest Python ABI.
Either:
  1) Put matching wheels into: $wheels
     (download on a connected box with:  py -3 -m pip download --only-binary=:all: -d <folder> grpcio==1.76.0 grpcio-tools==1.76.0 protobuf==6.33.0)
  2) Temporarily allow online install (remove --no-index / --find-links) if this machine has internet.
"@
    throw "Python dependencies unavailable for the current interpreter."
  }
} else {
  Write-Warning "No wheels folder found at $wheels; falling back to online install."
  python -m pip install "protobuf==6.33.0" "grpcio==1.76.0" "grpcio-tools==1.76.0"
}
Pop-Location

# --------- Generate Python stubs ----------
Write-Host "== Generate Python stubs ==" -ForegroundColor Cyan
$venvPy = Join-Path $demoRoot '.venv_latest\Scripts\python.exe'
& $venvPy -m grpc_tools.protoc `
  -I "$protoDir" `
  --python_out="$pyOut" `
  --grpc_python_out="$pyOut" `
  "$proto"

# --------- Generate C++ stubs ----------
Write-Host "== Generate C++ stubs ==" -ForegroundColor Cyan
protoc -I "$protoDir" `
  --cpp_out="$cppOut" `
  --grpc_out="$cppOut" `
  --plugin=protoc-gen-grpc=grpc_cpp_plugin `
  "$proto"

# --------- Summary + how to run ----------
$gDir = Join-Path $prefix 'lib\cmake\grpc'
$pDir = Join-Path $prefix 'lib\cmake\protobuf'

Write-Host ""
Write-Host "Demos are ready." -ForegroundColor Green
Write-Host ""
Write-Host "Start Python server:" -ForegroundColor Yellow
Write-Host "  cd `"$pyOut`""
Write-Host "  . ..\..\..\..\ .venv_latest\Scripts\Activate.ps1"
Write-Host "  python server.py"
Write-Host ""
Write-Host "Run Python client:" -ForegroundColor Yellow
Write-Host "  cd `"$pyOut`""
Write-Host "  . ..\..\..\..\ .venv_latest\Scripts\Activate.ps1"
Write-Host "  python client.py"
Write-Host ""
Write-Host "Run C# client (.NET 8, offline nuget):" -ForegroundColor Yellow
Write-Host "  cd `"$demoRoot\nuget\demos\csharp\CalculatorClient`""
Write-Host "  dotnet restore --ignore-failed-sources --source ..\..\..\nuget"
Write-Host "  dotnet run -c Release"
Write-Host ""
Write-Host "Build & run C++ client:" -ForegroundColor Yellow
Write-Host "  cd `"$cppOut`""
Write-Host "  cmake -S . -B build -DgRPC_DIR=`"$gDir`" -DProtobuf_DIR=`"$pDir`""
Write-Host "  cmake --build build --config Release"
Write-Host "  .\build\Release\calculator_client.exe"
Write-Host ""
Write-Host "Artifacts generated:" -ForegroundColor Cyan
Get-ChildItem -Name "$pyOut\calculator_pb2*.py", "$cppOut\calculator*.{h,cc}" 2>$null | ForEach-Object { "  $_" }
