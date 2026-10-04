using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.DTOs;
using TravelWise.API.Models;

namespace TravelWise.API.Controllers;

[Authorize]
[ApiController]
[Route("api/notifications")]
public sealed class NotificationsController(ApplicationDbContext context) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<NotificationResponse>>> GetNotifications(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        var notifications = await context.Notifications.AsNoTracking()
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .Select(n => new NotificationResponse(n.Id, n.TripId, n.InvitationId, n.Message, n.IsRead, new DateTimeOffset(n.CreatedAt, TimeSpan.Zero)))
            .ToListAsync(cancellationToken);
        return Ok(notifications);
    }

    [HttpPost("{id:int}/accept")]
    public async Task<IActionResult> Accept(int id, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        var notification = await context.Notifications.Include(n => n.Invitation).SingleOrDefaultAsync(n => n.Id == id && n.UserId == userId, cancellationToken);
        if (notification?.Invitation is null) return NotFound();
        if (notification.Invitation.ExpiresAt <= DateTime.UtcNow || notification.Invitation.Status != "Pending") return Conflict("This invitation has expired or has already been handled.");

        var alreadyMember = await context.TripMembers.AnyAsync(m => m.TripId == notification.TripId && m.UserId == userId && m.Status == "Joined", cancellationToken);
        if (!alreadyMember)
            context.TripMembers.Add(new TripMember { TripId = notification.TripId, UserId = userId, Role = "Viewer", Status = "Joined", JoinedAt = DateTime.UtcNow });
        notification.Invitation.Status = "Accepted";
        notification.IsRead = true;
        await context.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    [HttpPost("{id:int}/leave")]
    public async Task<IActionResult> Leave(int id, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        var notification = await context.Notifications.Include(n => n.Invitation).SingleOrDefaultAsync(n => n.Id == id && n.UserId == userId, cancellationToken);
        if (notification?.Invitation is null) return NotFound();
        notification.Invitation.Status = "Declined";
        notification.IsRead = true;
        await context.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private bool TryGetUserId(out int userId) =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out userId) && userId > 0;
}
