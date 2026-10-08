using System;
using System.Threading.Tasks;
using TravelWise.API.Models.AI;

namespace TravelWise.API.Services.AI
{
    public interface IAiWorkflowOrchestrator
    {
        Task<AiWorkflow> StartWorkflowAsync(int tripId, int userId, string objective);
        Task<AiWorkflow> GetWorkflowStatusAsync(Guid workflowId);
        Task<bool> ApproveWorkflowAsync(Guid workflowId, int userId);
        Task<bool> RejectWorkflowAsync(Guid workflowId, int userId);
        Task<bool> RequestRevisionAsync(Guid workflowId, int userId, string reason);
        Task ExecuteWorkflowStepAsync(Guid workflowId);
    }
}
