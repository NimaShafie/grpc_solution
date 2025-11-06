/// <summary>
/// Minimal C# client calling Python gRPC server.
/// </summary>
using System;
using Grpc.Core;
using Demo.Calculator;

class Program
{
    /// <summary>
    /// Connects to Calculator service and calls Add.
    /// </summary>
    public static void Main(string[] args)
    {
        string target = "localhost:50051";
        var channel = new Channel(target, ChannelCredentials.Insecure);
        var client = new Calculator.CalculatorClient(channel);
        var request = new AddRequest { A = 5.5, B = 2.5 };
        try
        {
            var reply = client.Add(request, deadline: DateTime.UtcNow.AddSeconds(5));
            Console.WriteLine($"Add result: {reply.Result}");
        }
        catch (RpcException ex)
        {
            Console.Error.WriteLine($"RPC failed: {ex}");
            Environment.Exit(1);
        }
        channel.ShutdownAsync().Wait();
    }
}
