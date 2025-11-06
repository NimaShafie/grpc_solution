#!/usr/bin/env python3
"""
Calculator gRPC server (Python).
Implements the Calculator service defined in calculator.proto.
"""

from concurrent import futures
import grpc
import calculator_pb2
import calculator_pb2_grpc


class CalculatorServicer(calculator_pb2_grpc.CalculatorServicer):
    """
    Calculator service implementation.

    /**
     * @brief Add two numbers.
     * @param request AddRequest with fields a and b.
     * @param context gRPC ServicerContext.
     * @return AddResponse with the sum of a and b.
     */
    """
    def Add(self, request, context):
        return calculator_pb2.AddResponse(result=request.a + request.b)

    """
    /**
     * @brief Liveness check (no payload).
     * @param request Empty message.
     * @param context gRPC ServicerContext.
     * @return Empty.
     */
    """
    def Ping(self, request, context):
        return calculator_pb2.Empty()


def serve(bind_address: str = "0.0.0.0:50051") -> None:
    """
    /**
     * @brief Start the gRPC Calculator server.
     * @param bind_address Address to bind to in "host:port" form.
     */
    """
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    calculator_pb2_grpc.add_CalculatorServicer_to_server(CalculatorServicer(), server)
    server.add_insecure_port(bind_address)
    server.start()
    print(f"Calculator server started on {bind_address}")
    server.wait_for_termination()


if __name__ == "__main__":
    serve()
