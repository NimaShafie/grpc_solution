# gRPC Python Demo (Offline/Air-Gapped)

This folder contains a Python gRPC server and client for the **Calculator** service:

- Server: `server.py`
- Client: `client.py`
- Generated stubs: `*_pb2.py`, `*_pb2_grpc.py` (created by `grpc_tools.protoc`)
- Proto source (one level up): `..\proto\calculator.proto`

The demo assumes the gRPC toolchain was installed from the gRPC 1.76.0 build and that you are using a local Python virtual environment created under `grpc_demo\.venv_latest`.

## Prerequisites

1. gRPC toolchain installed to a portable prefix, e.g.:
   `C:\Users\<you>\Desktop\gprc-airgap-solution\grpc_v1_76_0_cloned\dist\windows\grpc-install`
2. Offline Python wheels copied to:
   `C:\Users\<you>\Desktop\gprc-airgap-solution\grpc_demo\python-wheels`
   containing the wheels in `requirements.txt` (matching the target system’s Python & OS).
3. Virtual environment created at:
   `C:\Users\<you>\Desktop\gprc-airgap-solution\grpc_demo\.venv_latest`
   and populated with the offline wheels.

### One-time (connected machine) to prepare wheels

```powershell
# Adjust the root as needed
$root = 'C:\Users\<you>\Desktop\gprc-airgap-solution'
$wheels = Join-Path $root 'grpc_demo\python-wheels'

py -3 -m pip download --only-binary=:all: -d $wheels `
  grpcio==1.76.0 grpcio-tools==1.76.0 protobuf==6.33.0 typing-extensions==4.15.0 setuptools==80.9.0
