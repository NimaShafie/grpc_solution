using System;
using System.Threading.Tasks;
using Grpc.Net.Client;
using Demo.Calculator;

class Program
{
    static async Task Main(string[] args)
    {
        using var channel = GrpcChannel.ForAddress("http://127.0.0.1:50051");
        var client = new Calculator.CalculatorClient(channel);

        var reply = await client.AddAsync(new AddRequest { A = 2, B = 4 });
        Console.WriteLine($"Add result: {reply.Result}");
    }
}
"@