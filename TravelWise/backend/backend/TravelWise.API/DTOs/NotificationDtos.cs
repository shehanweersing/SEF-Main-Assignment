namespace TravelWise.API.DTOs;

/// <summary>Represents an invitation notification for the authenticated traveller.</summary>
public sealed record NotificationResponse(
    int Id,
    int TripId,
    int? InvitationId,
    string Message,
    bool IsRead,
    DateTimeOffset CreatedAt);
