using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TravelWise.API.DTOs;
using TravelWise.API.Services;

namespace TravelWise.API.Controllers;

[Authorize]
[ApiController]
[Route("api/trips/{tripId:int}")]
public sealed class CollaborationController(ICollaborationService service) : ControllerBase
{
    [HttpPost("members/invite")]
    public async Task<IActionResult> Invite(int tripId, InviteMemberRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var result = await service.InviteMemberAsync(tripId, CurrentUserId(), request, cancellationToken);
            return result.Error is not null ? Conflict(result.Error) : Created($"/api/trips/{tripId}/members", result.Member);
        }
        catch (EmailConfigurationException exception)
        {
            return Problem(
                detail: exception.Message,
                statusCode: StatusCodes.Status503ServiceUnavailable,
                title: "Invitation email is not configured.");
        }
        catch (EmailDeliveryException exception)
        {
            return Problem(
                detail: exception.Message,
                statusCode: StatusCodes.Status502BadGateway,
                title: "Invitation email could not be sent.");
        }
    }

    [HttpGet("members")]
    public async Task<IActionResult> GetMembers(int tripId, CancellationToken cancellationToken)
    {
        var members = await service.GetMembersAsync(tripId, CurrentUserId(), cancellationToken);
        return members is null ? NotFound() : Ok(members);
    }

    [HttpPut("members/{userId:int}/role")]
    public async Task<IActionResult> ChangeRole(int tripId, int userId, UpdateMemberRoleRequest request, CancellationToken cancellationToken)
    {
        var error = await service.ChangeRoleAsync(tripId, CurrentUserId(), userId, request, cancellationToken);
        return error is null ? NoContent() : error == "Trip not found." || error == "Member not found." ? NotFound(error) : ForbidOrConflict(error);
    }

    [HttpDelete("members/{userId:int}")]
    public async Task<IActionResult> RemoveMember(int tripId, int userId, CancellationToken cancellationToken)
    {
        var error = await service.RemoveMemberAsync(tripId, CurrentUserId(), userId, cancellationToken);
        return error is null ? NoContent() : error == "Trip not found." || error == "Member not found." ? NotFound(error) : ForbidOrConflict(error);
    }

    [HttpPost("preferences")]
    public async Task<IActionResult> SavePreference(int tripId, SubmitPreferenceRequest request, CancellationToken cancellationToken)
    {
        var result = await service.SavePreferenceAsync(tripId, CurrentUserId(), request, cancellationToken);
        return result.Error is null ? Ok(result.Preference) : NotFound(result.Error);
    }

    [HttpPost("activities/{activityId:int}/vote")]
    public async Task<IActionResult> Vote(int tripId, int activityId, VoteRequest request, CancellationToken cancellationToken)
    {
        var result = await service.SaveVoteAsync(tripId, activityId, CurrentUserId(), request, cancellationToken);
        return result.Error is null ? Ok(result.Vote) : result.Error.StartsWith("Each member", StringComparison.Ordinal) ? Conflict(result.Error) : NotFound(result.Error);
    }

    [HttpPost("resolve-consensus")]
    public async Task<IActionResult> ResolveConsensus(int tripId, ResolveConsensusRequest _, CancellationToken cancellationToken)
    {
        var result = await service.ResolveConsensusAsync(tripId, CurrentUserId(), cancellationToken);
        return result.Error is null ? Ok(result.Consensus) : result.Error.StartsWith("Consensus requires", StringComparison.Ordinal) ? Conflict(result.Error) : ForbidOrConflict(result.Error);
    }

    [HttpGet("consensus-report")]
    public async Task<IActionResult> GetConsensusReport(int tripId, CancellationToken cancellationToken)
    {
        var report = await service.GetConsensusReportAsync(tripId, CurrentUserId(), cancellationToken);
        return report is null ? NotFound() : Ok(report);
    }

    private int CurrentUserId() =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ? userId : 0;

    private IActionResult ForbidOrConflict(string error) =>
        error.StartsWith("Only", StringComparison.Ordinal) ? Forbid() : Conflict(error);
}
