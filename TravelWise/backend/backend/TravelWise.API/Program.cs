using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

// 1. Add PostgreSQL Database Context
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString))
    throw new InvalidOperationException("Supabase PostgreSQL connection is required. Set ConnectionStrings:DefaultConnection using user-secrets or an environment variable.");

var connectionBuilder = new NpgsqlConnectionStringBuilder(connectionString);
if (string.IsNullOrWhiteSpace(connectionBuilder.Host) ||
    !connectionBuilder.Host.Contains("supabase", StringComparison.OrdinalIgnoreCase))
    throw new InvalidOperationException("TravelWise must use the Supabase PostgreSQL database. Check ConnectionStrings:DefaultConnection.");

if (string.Equals(connectionBuilder.Host, "db.omhbchuhfwrqnkflqbox.supabase.co", StringComparison.OrdinalIgnoreCase))
{
    connectionBuilder.Host = "aws-0-ap-southeast-2.pooler.supabase.com";
    if (string.Equals(connectionBuilder.Username, "postgres", StringComparison.OrdinalIgnoreCase))
        connectionBuilder.Username = "postgres.omhbchuhfwrqnkflqbox";
    connectionString = connectionBuilder.ConnectionString;
}
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(
        connectionString,
        npgsqlOptions => npgsqlOptions.EnableRetryOnFailure(
            maxRetryCount: 3,
            maxRetryDelay: TimeSpan.FromSeconds(5),
            errorCodesToAdd: null)));

// 2. Register Services and Controllers
builder.Services.AddScoped<BudgetService>();
builder.Services.AddControllers();
var allowedOrigins = builder.Configuration
    .GetSection("Frontend:AllowedOrigins")
    .Get<string[]>()
    ?? ["http://localhost:5173"];
builder.Services.AddCors(options => options.AddPolicy("Frontend", policy =>
    policy.WithOrigins(allowedOrigins)
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials()));


// Add services to the container.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Bearer {token}\"",
        Name = "Authorization",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});
builder.Services.AddScoped<ActivityService>();
builder.Services.AddScoped<RiskService>();
builder.Services.AddScoped<ReadinessService>();
builder.Services.AddScoped<ICollaborationService, CollaborationService>();
builder.Services.AddScoped<IEmailSender, EmailSender>();
builder.Services.Configure<EmailOptions>(builder.Configuration.GetSection("Email"));
builder.Services.AddHttpClient<WeatherTelemetryService>(client => client.Timeout = TimeSpan.FromSeconds(5));

// JWT Authentication Configuration
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
    });

var app = builder.Build();

app.UseCors("Frontend");

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}


// 3. Map controllers and enable authorization
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();