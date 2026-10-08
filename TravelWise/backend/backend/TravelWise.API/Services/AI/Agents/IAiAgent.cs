using System;
using System.Threading.Tasks;

namespace TravelWise.API.Services.AI.Agents
{
    public interface IAiAgent<TResponse>
    {
        string AgentName { get; }
        Task<TResponse> ExecuteAsync(Guid workflowId, int tripId, object context);
    }
}
