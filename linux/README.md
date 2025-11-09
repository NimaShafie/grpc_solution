# gRPC (Linux) — v1.76.0

## Layout
- scripts/ — fetch/build/package helpers (online + air-gapped)
- artifacts/
  - grpc-v1.76.0-linux-<arch>.tar.gz — prebuilt /opt/grpc-v1.76.0
  - offline-bundle-v1.76.0.tar.gz — full offline build bundle
  - SHA256SUMS — checksums for the archives
  - examples/template-cpp — ready-to-build C++ client/server template

## Quick start (use prebuilt install)

sudo tar -C /opt -xzf linux/artifacts/grpc-v1.76.0-linux-$(uname -m).tar.gz
export PKG_CONFIG_PATH=/opt/grpc-v1.76.0/lib/pkgconfig:/opt/grpc-v1.76.0/lib64/pkgconfig:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=/opt/grpc-v1.76.0/lib:/opt/grpc-v1.76.0/lib64:$LD_LIBRARY_PATH

cmake -S linux/artifacts/examples/template-cpp -B linux/artifacts/examples/template-cpp/build -DCMAKE_PREFIX_PATH=/opt/grpc-v1.76.0
cmake --build linux/artifacts/examples/template-cpp/build -j
./linux/artifacts/examples/template-cpp/build/server & srv=$!; sleep 1; ./linux/artifacts/examples/template-cpp/build/client; kill $srv

## Offline rebuild

To reassemble split archives before use:

```bash
bash linux/artifacts/join-large-files.sh
```
See `linux/artifacts/offline-bundle-v1.76.0.tar.gz` and `README_OFFLINE.md` inside the bundle.
