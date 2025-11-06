#include <grpcpp/grpcpp.h>
#include "calculator.grpc.pb.h"
#include "calculator.pb.h"
#include <iostream>

using demo::calculator::AddRequest;
using demo::calculator::AddResponse;
using demo::calculator::Calculator;

int main() {
    auto channel = grpc::CreateChannel("localhost:50051", grpc::InsecureChannelCredentials());
    std::unique_ptr<Calculator::Stub> stub = Calculator::NewStub(channel);

    AddRequest req;
    req.set_a(5);
    req.set_b(7);

    AddResponse resp;
    grpc::ClientContext ctx;

    grpc::Status status = stub->Add(&ctx, req, &resp);
    if (status.ok()) {
        std::cout << "5 + 7 = " << resp.result() << std::endl;
    } else {
        std::cerr << "RPC failed: " << status.error_message() << std::endl;
    }

    return 0;
}
