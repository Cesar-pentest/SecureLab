using SecureLab.Services;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
var greetingService = new GreetingService();


app.MapGet("/", () => greetingService.GetGreeting());

await app.RunAsync();
