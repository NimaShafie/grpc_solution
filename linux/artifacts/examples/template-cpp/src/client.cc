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
