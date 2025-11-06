#!/usr/bin/env python3
"""
Calculator gRPC client (Python).
Connects to the Python server and calls Calculator.Add.
"""

import grpc
import calculator_pb2
import calculator_pb2_grpc


def run(server_address: str = "localhost:50051") -> None:
    """
    /**
     * @brief Connect to the server and call Add(a,b).
     * @param server_address Address of the server in "host:port" form.
     */
    """
    with grpc.insecure_channel(server_address) as channel:
        stub = calculator_pb2_grpc.CalculatorStub(channel)
        resp = stub.Add(calculator_pb2.AddRequest(a=3.5, b=2.5), timeout=5.0)
        print(f"Add result: {resp.result}")


if __name__ == "__main__":
    run()
