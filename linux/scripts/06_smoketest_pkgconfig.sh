#!/usr/bin/env bash
set -euo pipefail
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

cp ~/grpc-builder/src/grpc/examples/protos/helloworld.proto .
cat > greeter_server.cc <<'CC'
#include <grpcpp/grpcpp.h>
#include <grpcpp/ext/proto_server_reflection_plugin.h>
#include "helloworld.grpc.pb.h"
using helloworld::Greeter; using helloworld::HelloRequest; using helloworld::HelloReply;
using grpc::Server; using grpc::ServerBuilder; using grpc::ServerContext; using grpc::Status;
class GreeterServiceImpl final : public Greeter::Service {
 public: Status SayHello(ServerContext*, const HelloRequest* req, HelloReply* rep) override {
   rep->set_message("Hello " + req->name()); return Status::OK; } };
int main(){ grpc::EnableDefaultHealthCheckService(true);
  grpc::reflection::InitProtoReflectionServerBuilderPlugin();
  GreeterServiceImpl svc; ServerBuilder b;
  b.AddListeningPort("127.0.0.1:50051", grpc::InsecureServerCredentials());
  b.RegisterService(&svc); auto s=b.BuildAndStart(); return s?0:1; }
CC
cat > greeter_client.cc <<'CC'
#include <grpcpp/grpcpp.h>
#include "helloworld.grpc.pb.h"
using helloworld::Greeter; using helloworld::HelloRequest; using helloworld::HelloReply;
int main(){ auto ch=grpc::CreateChannel("127.0.0.1:50051", grpc::InsecureChannelCredentials());
  auto stub=Greeter::NewStub(ch); HelloRequest r; r.set_name("world"); HelloReply rep; grpc::ClientContext ctx;
  auto st=stub->SayHello(&ctx,r,&rep); return st.ok()?0:1; }
CC

protoc -I . --grpc_out=. --plugin=protoc-gen-grpc=$(which grpc_cpp_plugin) helloworld.proto
protoc -I . --cpp_out=. helloworld.proto

if pkg-config --exists grpc++_reflection; then REF=grpc++_reflection; else REF=; fi

# Try shared first (no --static)
set -x
c++ -std=c++17 greeter_server.cc helloworld.pb.cc helloworld.grpc.pb.cc \
  $(pkg-config --cflags grpc++ protobuf) \
  $(pkg-config --libs grpc++ $REF protobuf) -o greeter_server
c++ -std=c++17 greeter_client.cc helloworld.pb.cc helloworld.grpc.pb.cc \
  $(pkg-config --cflags grpc++ protobuf) \
  $(pkg-config --libs grpc++ protobuf) -o greeter_client
set +x
echo "[OK] pkg-config smoketest compiled."
