# gRPC C++ Template

## Build
```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=/opt/grpc-v1.76.0
cmake --build build -j
```

## Run
```bash
./build/server & srv=$!; sleep 1; ./build/client; kill $srv
```

## Notes
- If you installed gRPC under a different prefix, pass that via `-DCMAKE_PREFIX_PATH=...`.
- If you want the runtime linker to find shared libs without LD_LIBRARY_PATH, run:
  sudo sh -c 'echo "/opt/grpc-v1.76.0/lib"  > /etc/ld.so.conf.d/grpc.conf'
  sudo sh -c 'echo "/opt/grpc-v1.76.0/lib64" >> /etc/ld.so.conf.d/grpc.conf'
  sudo ldconfig
