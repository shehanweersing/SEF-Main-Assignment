using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.DTOs;
using TravelWise.API.Models;

namespace TravelWise.API.Services;

public interface ICollaborationService
{
    Task<IReadOnlyList<TripMemberResponse>?> GetMembersAsync(int tripId, int userId, CancellationToken cancellationToken);
    Task<(TripMemberResponse? Member, string? Error)> InviteMemberAsync(int tripId, int userId, InviteMemberRequest request, CancellationToken cancellationToken);
    Task<string?> ChangeRoleAsync(int tripId, int actorId, int targetUserId, UpdateMemberRoleRequest request, CancellationToken cancellationToken);
    Task<string?> RemoveMemberAsync(int tripId, int actorId, int targetUserId, CancellationToken cancellationToken);
    Task<(MemberPreferenceResponse? Preference, string? Error)> SavePreferenceAsync(int tripId, int userId, SubmitPreferenceRequest request, CancellationToken cancellationToken);
    Task<(VoteResponse? Vote, string? Error)> SaveVoteAsync(int tripId, int activityId, int userId, VoteRequest request, CancellationToken cancellationToken);
    Task<(ConsensusResponse? Consensus, string? Error)> ResolveConsensusAsync(int tripId, int userId, CancellationToken cancellationToken);
    Task<ConsensusResponse?> GetConsensusReportAsync(int tripId, int userId, CancellationToken cancellationToken);
}

public sealed class CollaborationService(ApplicationDbContext context) : ICollaborationService
{
    private readonly ApplicationDbContext _context = context;

    public async Task<IReadOnlyList<TripMemberResponse>?> GetMembersAsync(int tripId, int userId, CancellationToken cancellationToken)
    {
        var trip = await _context.Trips.AsNoTracking().SingleOrDefaultAsync(t => t.Id == tripId, cancellationToken);
        if (trip is null || !await IsMemberAsync(trip, userId, cancellationToken))
            return null;

        var members = await _context.TripMembers.AsNoTracking()
            .Where(m => m.TripId == tripId && m.Status == "Joined")
            .Include(m => m.User)
            .ToListAsync(cancellationToken);

        if (!members.Any(m => m.UserId == trip.UserId))
        {
            var owner = await _context.Users.AsNoTracking().SingleAsync(u => u.Id == trip.UserId, cancellationToken);
            members.Insert(0, new TripMember { TripId = tripId, UserId = owner.Id, User = owner, Role = "Owner", Status = "Joined", JoinedAt = trip.CreatedAt });
        }

        return members.Select(ToMemberResponse).ToList();
    }

    public async Task<(TripMemberResponse? Member, string? Error)> InviteMemberAsync(
        int tripId, int userId, InviteMemberRequest request, CancellationToken cancellationToken)
    {
        var trip = await _context.Trips.SingleOrDefaultAsync(t => t.Id == tripId, cancellationToken);
        if (trip is null) return (null, "Trip not found.");
        if (!await HasRoleAsync(trip, userId, "Owner", "Editor", cancellationToken)) return (null, "Only trip owners and editors can invite members.");

        var email = request.InvitedEmail.Trim().ToLowerInvariant();
        var existingInvitation = await _context.Invitations.AnyAsync(i =>
            i.TripId == tripId && i.InvitedEmail == email && i.Status == "Pending" && i.ExpiresAt > DateTime.UtcNow, cancellationToken);
        if (existingInvitation) return (null, "A pending invitation already exists for this email.");

        var invitedUser = await _context.Users.SingleOrDefaultAsync(u => u.Email.ToLower() == email, cancellationToken);
        if (invitedUser is not null && await IsMemberAsync(trip, invitedUser.Id, cancellationToken))
            return (null, "That user is already a member of the trip.");

        _context.Invitations.Add(new Invitation
        {
            TripId = tripId,
            InvitedEmail = email,
            Token = Guid.NewGuid().ToString("N"),
            ExpiresAt = DateTime.UtcNow.AddDays(7),
            Status = "Pending"
        });

        if (invitedUser is not null)
        {
            _context.TripMembers.Add(new TripMember
            {
                TripId = tripId,
                UserId = invitedUser.Id,
                Role = "Viewer",
                JoinedAt = DateTime.UtcNow,
                Status = "Joined"
            });
        }

        await _context.SaveChangesAsync(cancellationToken);

        if (invitedUser is null)
            return (new TripMemberResponse(0, string.Empty, email, "Viewer", DateTimeOffset.UtcNow, "Pending"), null);

        return (new TripMemberResponse(invitedUser.Id, invitedUser.FullName, invitedUser.Email, "Viewer", DateTimeOffset.UtcNow, "Pending"), null);
    }

    public async Task<string?> ChangeRoleAsync(int tripId, int actorId, int targetUserId, UpdateMemberRoleRequest request, CancellationToken cancellationToken)
    {
        var trip = await _context.Trips.SingleOrDefaultAsync(t => t.Id == tripId, cancellationToken);
        if (trip is null) return "Trip not found.";
        if (!await IsOwnerAsync(trip, actorId, cancellationToken)) return "Only the trip owner can change member roles.";
        if (targetUserId == trip.UserId && request.Role != "Owner") return "A trip must have at least one Owner.";

        var member = await _context.TripMembers.SingleOrDefaultAsync(m => m.TripId == tripId && m.UserId == targetUserId && m.Status == "Joined", cancellationToken);
        if (member is null && targetUserId != trip.UserId) return "Member not found.";
        if (targetUserId == trip.UserId) return null;
        if (request.Role == "Owner")
        {
            if (member is not null) member.Role = "Owner";
        }
        else
        {
            if (member is not null) member.Role = request.Role;
        }
        await _context.SaveChangesAsync(cancellationToken);
        return null;
    }

    public async Task<string?> RemoveMemberAsync(int tripId, int actorId, int targetUserId, CancellationToken cancellationToken)
    {
        var trip = await _context.Trips.SingleOrDefaultAsync(t => t.Id == tripId, cancellationToken);
        if (trip is null) return "Trip not found.";
        if (!await IsOwnerAsync(trip, actorId, cancellationToken)) return "Only the trip owner can remove members.";
        if (targetUserId == trip.UserId) return "The trip must always have an Owner.";

        var member = await _context.TripMembers.SingleOrDefaultAsync(m => m.TripId == tripId && m.UserId == targetUserId && m.Status == "Joined", cancellationToken);
        if (member is null) return "Member not found.";
        _context.TripMembers.Remove(member);
        await _context.SaveChangesAsync(cancellationToken);
        return null;
    }

    public async Task<(MemberPreferenceResponse? Preference, string? Error)> SavePreferenceAsync(
        int tripId, int userId, SubmitPreferenceRequest request, CancellationToken cancellationToken)
    {
        var trip = await _context.Trips.SingleOrDefaultAsync(t => t.Id == tripId, cancellationToken);
        if (trip is null || !await IsMemberAsync(trip, userId, cancellationToken)) return (null, "Trip member not found.");

        var category = request.Category.Trim();
        var preference = await _context.MemberPreferences.SingleOrDefaultAsync(p =>
            p.TripId == tripId && p.UserId == userId && p.Category == category, cancellationToken);
        if (preference is null)
        {
            preference = new MemberPreference { TripId = tripId, UserId = userId, Category = category };
            _context.MemberPreferences.Add(preference);
        }
        preference.Weight = request.Weight;
        preference.Notes = request.Notes;
        await _context.SaveChangesAsync(cancellationToken);
        return (new MemberPreferenceResponse(preference.Id, userId, preference.Category, preference.Weight, preference.Notes), null);
    }

    public async Task<(VoteResponse? Vote, string? Error)> SaveVoteAsync(
        int tripId, int activityId, int userId, VoteRequest request, CancellationToken cancellationToken)
    {
        var trip = await _context.Trips.SingleOrDefaultAsync(t => t.Id == tripId, cancellationToken);
        if (trip is null || !await IsMemberAsync(trip, userId, cancellationToken)) return (null, "Trip member not found.");
        if (!await _context.Activities.AnyAsync(a => a.Id == activityId && a.TripId == tripId, cancellationToken)) return (null, "Activity not found.");
        if (await _context.Votes.AnyAsync(v => v.ActivityId == activityId && v.UserId == userId, cancellationToken)) return (null, "Each member can vote once per activity.");

        var vote = new Vote { ActivityId = activityId, UserId = userId, VoteType = request.VoteType, Comment = request.Comment, VotedAt = DateTime.UtcNow };
        _context.Votes.Add(vote);
        await _context.SaveChangesAsync(cancellationToken);
        return (new VoteResponse(activityId, userId, vote.VoteType, vote.Comment, new DateTimeOffset(vote.VotedAt, TimeSpan.Zero)), null);
    }

    public async Task<(ConsensusResponse? Consensus, string? Error)> ResolveConsensusAsync(int tripId, int userId, CancellationToken cancellationToken)
    {
        var trip = await _context.Trips.SingleOrDefaultAsync(t => t.Id == tripId, cancellationToken);
        if (trip is null || !await HasRoleAsync(trip, userId, "Owner", "Editor", cancellationToken)) return (null, "Only trip owners and editors can resolve consensus.");

        var memberIds = await GetMemberIdsAsync(trip, cancellationToken);
        var participation = await _context.Votes.Where(v => v.Activity!.TripId == tripId).Select(v => v.UserId).Distinct().CountAsync(cancellationToken);
        var required = (int)Math.Ceiling(memberIds.Count * 0.6);
        if (participation < required) return (null, $"Consensus requires participation from at least {required} members.");

        var activities = await _context.Activities.AsNoTracking().Where(a => a.TripId == tripId).OrderBy(a => a.StartTime).ToListAsync(cancellationToken);
        var votes = await _context.Votes.AsNoTracking().Where(v => activities.Select(a => a.Id).Contains(v.ActivityId)).ToListAsync(cancellationToken);
        var decisions = activities.Select(activity =>
        {
            var activityVotes = votes.Where(v => v.ActivityId == activity.Id).ToList();
            var upvotes = activityVotes.Count(v => v.VoteType == "Upvote");
            var downvotes = activityVotes.Count(v => v.VoteType == "Downvote");
            var tied = upvotes == downvotes;
            return new ConsensusDecision(activity.Id, activity.Title, upvotes, downvotes, tied ? "Arbitration" : upvotes > downvotes ? "Accepted" : "Declined", tied);
        }).ToList();

        var preferences = await _context.MemberPreferences.AsNoTracking()
            .Where(p => p.TripId == tripId)
            .ToListAsync(cancellationToken);
        var voteFairness = decisions.Count == 0
            ? 0
            : decisions.Average(d => (double)Math.Max(d.Upvotes, d.Downvotes) / Math.Max(1, d.Upvotes + d.Downvotes));
        var totalPreferenceWeight = preferences.Sum(p => p.Weight);
        var preferenceFairness = totalPreferenceWeight == 0
            ? voteFairness
            : decisions.Where(d => d.Outcome == "Accepted")
                .Select(d => activities.First(a => a.Id == d.ActivityId).InterestType)
                .Where(category => !string.IsNullOrWhiteSpace(category))
                .SelectMany(category => preferences.Where(p => string.Equals(p.Category, category, StringComparison.OrdinalIgnoreCase)))
                .Sum(p => p.Weight) / totalPreferenceWeight;
        var fairness = Math.Round((voteFairness + preferenceFairness) / 2 * 100, 2);
        var record = new ConsensusRecord
        {
            TripId = tripId,
            ResolvedAt = DateTime.UtcNow,
            FairnessScore = fairness,
            DecisionsJson = JsonSerializer.Serialize(decisions)
        };
        _context.ConsensusRecords.Add(record);
        await _context.SaveChangesAsync(cancellationToken);
        return (ToConsensusResponse(record, participation, required, decisions), null);
    }

    public async Task<ConsensusResponse?> GetConsensusReportAsync(int tripId, int userId, CancellationToken cancellationToken)
    {
        var trip = await _context.Trips.AsNoTracking().SingleOrDefaultAsync(t => t.Id == tripId, cancellationToken);
        if (trip is null || !await IsMemberAsync(trip, userId, cancellationToken)) return null;
        var record = await _context.ConsensusRecords.AsNoTracking().Where(r => r.TripId == tripId).OrderByDescending(r => r.ResolvedAt).FirstOrDefaultAsync(cancellationToken);
        if (record is null) return null;
        var memberIds = await GetMemberIdsAsync(trip, cancellationToken);
        var participation = await _context.Votes.Where(v => v.Activity!.TripId == tripId).Select(v => v.UserId).Distinct().CountAsync(cancellationToken);
        var decisions = JsonSerializer.Deserialize<List<ConsensusDecision>>(record.DecisionsJson) ?? [];
        return ToConsensusResponse(record, participation, (int)Math.Ceiling(memberIds.Count * 0.6), decisions);
    }

    private static Task<bool> IsOwnerAsync(Trip trip, int userId, CancellationToken _) =>
        Task.FromResult(trip.UserId == userId);

    private async Task<bool> HasRoleAsync(Trip trip, int userId, string role1, string role2, CancellationToken ct) =>
        trip.UserId == userId || await _context.TripMembers.AnyAsync(m => m.TripId == trip.Id && m.UserId == userId && (m.Role == role1 || m.Role == role2) && m.Status == "Joined", ct);

    private async Task<bool> IsMemberAsync(Trip trip, int userId, CancellationToken ct) =>
        trip.UserId == userId || await _context.TripMembers.AnyAsync(m => m.TripId == trip.Id && m.UserId == userId && m.Status == "Joined", ct);

    private async Task<List<int>> GetMemberIdsAsync(Trip trip, CancellationToken ct)
    {
        var ids = await _context.TripMembers.Where(m => m.TripId == trip.Id && m.Status == "Joined").Select(m => m.UserId).ToListAsync(ct);
        if (!ids.Contains(trip.UserId)) ids.Add(trip.UserId);
        return ids;
    }

    private static TripMemberResponse ToMemberResponse(TripMember member) =>
        new(member.UserId, member.User?.FullName ?? string.Empty, member.User?.Email ?? string.Empty, member.Role, new DateTimeOffset(member.JoinedAt, TimeSpan.Zero), member.Status);

    private static ConsensusResponse ToConsensusResponse(ConsensusRecord record, int participation, int required, IReadOnlyList<ConsensusDecision> decisions) =>
        new(record.Id, record.TripId, new DateTimeOffset(record.ResolvedAt, TimeSpan.Zero), record.FairnessScore, participation, required, decisions.Any(d => d.RequiresArbitration), decisions);
}
