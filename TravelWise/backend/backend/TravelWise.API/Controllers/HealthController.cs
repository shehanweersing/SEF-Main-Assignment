using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;

namespace TravelWise.API.Controllers;

[ApiController]
[Route("api/health")]
public sealed class HealthController(ApplicationDbContext context) : ControllerBase
{
    [AllowAnonymous]
    [HttpGet("database")]
    public async Task<IActionResult> CheckDatabase(CancellationToken cancellationToken)
    {
        var canConnect = await context.Database.CanConnectAsync(cancellationToken);
        return canConnect
            ? Ok(new { status = "ok", provider = "supabase-postgresql" })
            : StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                status = "unavailable",
                provider = "supabase-postgresql",
                message = "The Supabase database could not be reached."
            });
    }
}
