var builder = WebApplication.CreateBuilder(args);

// Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

var app = builder.Build();

// Log startup
app.Logger.LogInformation("Worker service starting on port 5001");

// Root endpoint - status
app.MapGet("/", () =>
{
    app.Logger.LogInformation("Status endpoint called");
    return Results.Ok(new
    {
        service = "worker",
        status = "ok",
        timestamp = DateTime.UtcNow,
        version = "1.0.0"
    });
});

// Health check endpoint
app.MapGet("/health", () =>
{
    app.Logger.LogInformation("Health check endpoint called");
    return Results.Ok(new { healthy = true });
});

app.Logger.LogInformation("Worker service started successfully");

app.Run();
