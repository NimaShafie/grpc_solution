#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL_DIR="${ROOT}/artifacts/examples/template-cpp"
mkdir -p "${TPL_DIR}/proto" "${TPL_DIR}/src"

# --- CMakeLists.txt ---
cat > "${TPL_DIR}/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.18)
project(grpc_template CXX)
set(CMAKE_CXX_STANDARD 17)

find_package(gRPC CONFIG REQUIRED)
find_package(Protobuf CONFIG REQUIRED)

set(PROTO_DIR ${CMAKE_SOURCE_DIR}/proto)
set(GEN_DIR   ${CMAKE_BINARY_DIR}/gen)
file(MAKE_DIRECTORY ${GEN_DIR})

set(PROTO_FILE ${PROTO_DIR}/helloworld.proto)
protobuf_generate(
  LANGUAGE cpp
  TARGET proto_cc
  PROTOS ${PROTO_FILE}
  IMPORT_DIRS ${PROTO_DIR}
  OUT_VAR PROTO_SRCS
  PROTOC_OUT_DIR ${GEN_DIR}
)
protobuf_generate(
  LANGUAGE grpc
  GENERATE_EXTENSIONS .grpc.pb.h .grpc.pb.cc
  TARGET grpc_cc
  PROTOS ${PROTO_FILE}
  IMPORT_DIRS ${PROTO_DIR}
  OUT_VAR GRPC_SRCS
  PLUGIN "protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>"
  PROTOC_OUT_DIR ${GEN_DIR}
)

add_library(proto_lib ${PROTO_SRCS} ${GRPC_SRCS})
target_include_directories(proto_lib PUBLIC ${GEN_DIR})
target_link_libraries(proto_lib PUBLIC gRPC::grpc++ protobuf::libprotobuf)

add_executable(server src/server.cc)
target_link_libraries(server PRIVATE proto_lib gRPC::grpc++_reflection)

add_executable(client src/client.cc)
target_link_libraries(client PRIVATE proto_lib)
CMAKE

# --- proto/helloworld.proto ---
cat > "${TPL_DIR}/proto/helloworld.proto" <<'PROTO'
syntax = "proto3";
package helloworld;

service Greeter {
  rpc SayHello (HelloRequest) returns (HelloReply);
}
message HelloRequest { string name = 1; }
message HelloReply   { string message = 1; }
PROTO

# --- src/server.cc ---
cat > "${TPL_DIR}/src/server.cc" <<'SRV'
#include <grpcpp/grpcpp.h>
#include <grpcpp/ext/proto_server_reflection_plugin.h>
#include "helloworld.grpc.pb.h"
using helloworld::Greeter; using helloworld::HelloRequest; using helloworld::HelloReply;
using grpc::Server; using grpc::ServerBuilder; using grpc::ServerContext; using grpc::Status;

class GreeterServiceImpl final : public Greeter::Service {
 public:
  Status SayHello(ServerContext*, const HelloRequest* req, HelloReply* rep) override {
    rep->set_message("Hello " + req->name()); return Status::OK;
  }
};

int main() {
  grpc::EnableDefaultHealthCheckService(true);
  grpc::reflection::InitProtoReflectionServerBuilderPlugin();
  GreeterServiceImpl svc; ServerBuilder b;
  b.AddListeningPort("0.0.0.0:50051", grpc::InsecureServerCredentials());
  b.RegisterService(&svc);
  std::unique_ptr<Server> server(b.BuildAndStart());
  std::cout << "Server listening on 0.0.0.0:50051\n";
  server->Wait();
  return 0;
}
SRV

# --- src/client.cc ---
cat > "${TPL_DIR}/src/client.cc" <<'CLI'
#include <grpcpp/grpcpp.h>
#include "helloworld.grpc.pb.h"
using helloworld::Greeter; using helloworld::HelloRequest; using helloworld::HelloReply;

int main() {
  auto channel = grpc::CreateChannel("127.0.0.1:50051", grpc::InsecureChannelCredentials());
  auto stub = Greeter::NewStub(channel);
  HelloRequest req; req.set_name("world"); HelloReply rep; grpc::ClientContext ctx;
  auto st = stub->SayHello(&ctx, req, &rep);
  if (st.ok()) { std::cout << "Greeter received: " << rep.message() << "\n"; return 0; }
  std::cerr << "RPC failed: " << st.error_message() << "\n"; return 1;
}
CLI

# --- README.md ---
cat > "${TPL_DIR}/README.md" <<'MD'
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
MD

echo "[DONE] Template written to: ${TPL_DIR}"
