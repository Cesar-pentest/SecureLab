using SecureLab.Services;

namespace SecureLab.Tests;

public class GreetingServiceTests
{
    [Fact]
    public void GetGreeting_ReturnsExpectedMessage()
    {
        var service = new GreetingService();

        var result = service.GetGreeting();

        Assert.Equal("SecureLab CI/CD is running.",result);

    }
}
