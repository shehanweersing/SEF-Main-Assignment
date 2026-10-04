using System.ComponentModel.DataAnnotations;

namespace TravelWise.API.DTOs;

/// <summary>Payload for inviting a traveller to a trip.</summary>
public sealed record InviteMemberRequest
{
    [Required, EmailAddress, MaxLength(150)]
    public required string InvitedEmail { get; init; }
}

/// <summary>Represents a member of a collaborative trip.</summary>
public sealed record TripMemberResponse(
    int UserId,
    string FullName,
    string Email,
    string Role,
    DateTimeOffset JoinedAt,
    string Status);

/// <summary>Payload for changing a trip member's role.</summary>
public sealed record UpdateMemberRoleRequest
{
    [Required, RegularExpression("^(Owner|Editor|Viewer)$")]
    public required string Role { get; init; }
}

/// <summary>Payload for submitting one member preference.</summary>
public sealed record SubmitPreferenceRequest
{
    [Required, MaxLength(100)]
    public required string Category { get; init; }

    [Range(1, 5)]
    public double Weight { get; init; } = 1;

    [MaxLength(500)]
    public string? Notes { get; init; }
}

/// <summary>Represents a saved member preference.</summary>
public sealed record MemberPreferenceResponse(
    int Id,
    int UserId,
    string Category,
    double Weight,
    string? Notes);

/// <summary>Payload for voting on a trip activity.</summary>
public sealed record VoteRequest
{
    [Required, RegularExpression("^(Upvote|Downvote)$")]
    public required string VoteType { get; init; }

    [MaxLength(500)]
    public string? Comment { get; init; }
}

/// <summary>Represents a member's activity vote.</summary>
public sealed record VoteResponse(
    int ActivityId,
    int UserId,
    string VoteType,
    string? Comment,
    DateTimeOffset VotedAt);

/// <summary>Payload for resolving the current trip consensus.</summary>
public sealed record ResolveConsensusRequest;

/// <summary>Represents one activity decision in a consensus report.</summary>
public sealed record ConsensusDecision(
    int ActivityId,
    string Title,
    int Upvotes,
    int Downvotes,
    string Outcome,
    bool RequiresArbitration);

/// <summary>Represents the result of resolving trip consensus.</summary>
public sealed record ConsensusResponse(
    int Id,
    int TripId,
    DateTimeOffset ResolvedAt,
    double FairnessScore,
    int ParticipationCount,
    int RequiredParticipation,
    bool RequiresArbitration,
    IReadOnlyList<ConsensusDecision> Decisions);
