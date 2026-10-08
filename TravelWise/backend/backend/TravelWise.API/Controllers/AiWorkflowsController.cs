using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Threading.Tasks;
using TravelWise.API.Services.AI;
using System.Security.Claims;

namespace TravelWise.API.Controllers
{
    [ApiController]
    [Route("api")]
    [Authorize]
    public class AiWorkflowsController : ControllerBase
    {
        private readonly IAiWorkflowOrchestrator _orchestrator;

        public AiWorkflowsController(IAiWorkflowOrchestrator orchestrator)
        {
            _orchestrator = orchestrator;
        }

        private int GetUserId()
        {
            return int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "1"); // Defaulting to 1 for testing if claims miss
        }

        [HttpPost("trips/{tripId}/ai-workflows")]
        public async Task<IActionResult> StartWorkflow(int tripId, [FromBody] StartWorkflowRequest request)
        {
            var userId = GetUserId();
            var workflow = await _orchestrator.StartWorkflowAsync(tripId, userId, request.Objective);
            
            // Execute the workflow async (in real scenario use a background task queue)
            // For now, fire and forget
            _ = Task.Run(() => _orchestrator.ExecuteWorkflowStepAsync(workflow.Id));

            return Ok(new { workflowId = workflow.Id, status = workflow.CurrentState });
        }

        [HttpGet("ai-workflows/{workflowId}")]
        public async Task<IActionResult> GetWorkflow(Guid workflowId)
        {
            var workflow = await _orchestrator.GetWorkflowStatusAsync(workflowId);
            return Ok(workflow);
        }

        [HttpGet("ai-workflows/{workflowId}/status")]
        public async Task<IActionResult> GetWorkflowStatus(Guid workflowId)
        {
            var workflow = await _orchestrator.GetWorkflowStatusAsync(workflowId);
            return Ok(new { status = workflow.CurrentState, activeAgent = workflow.ActiveAgent });
        }

        [HttpGet("ai-workflows/{workflowId}/results")]
        public async Task<IActionResult> GetWorkflowResults(Guid workflowId)
        {
            var workflow = await _orchestrator.GetWorkflowStatusAsync(workflowId);
            return Ok(workflow.AgentResults);
        }

        [HttpPost("ai-workflows/{workflowId}/approve")]
        public async Task<IActionResult> ApproveWorkflow(Guid workflowId)
        {
            var success = await _orchestrator.ApproveWorkflowAsync(workflowId, GetUserId());
            if (!success) return BadRequest("Workflow is not awaiting approval.");
            return Ok(new { status = "APPROVED" });
        }

        [HttpPost("ai-workflows/{workflowId}/reject")]
        public async Task<IActionResult> RejectWorkflow(Guid workflowId)
        {
            var success = await _orchestrator.RejectWorkflowAsync(workflowId, GetUserId());
            if (!success) return BadRequest("Workflow is not awaiting approval.");
            return Ok(new { status = "REJECTED" });
        }

        [HttpPost("ai-workflows/{workflowId}/revise")]
        public async Task<IActionResult> ReviseWorkflow(Guid workflowId, [FromBody] ReviseWorkflowRequest request)
        {
            var success = await _orchestrator.RequestRevisionAsync(workflowId, GetUserId(), request.Reason);
            if (!success) return BadRequest("Workflow is not awaiting approval.");
            return Ok(new { status = "REVISING" });
        }
    }

    public class StartWorkflowRequest
    {
        public string Objective { get; set; } = "Generate Intelligent Trip Plan";
    }

    public class ReviseWorkflowRequest
    {
        public string Reason { get; set; } = string.Empty;
    }
}
