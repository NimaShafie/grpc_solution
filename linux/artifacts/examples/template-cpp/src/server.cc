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
