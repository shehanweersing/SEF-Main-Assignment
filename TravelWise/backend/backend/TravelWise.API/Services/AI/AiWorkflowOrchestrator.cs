using System;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.Models.AI;
using TravelWise.API.Services.AI.Agents;

namespace TravelWise.API.Services.AI
{
    public class AiWorkflowOrchestrator : IAiWorkflowOrchestrator
    {
        private readonly ApplicationDbContext _dbContext;
        private readonly BudgetAgent _budgetAgent;
        private readonly RiskAgent _riskAgent;
        private readonly CollaborationAgent _collaborationAgent;
        private readonly ItineraryAgent _itineraryAgent;

        public AiWorkflowOrchestrator(
            ApplicationDbContext dbContext,
            BudgetAgent budgetAgent,
            RiskAgent riskAgent,
            CollaborationAgent collaborationAgent,
            ItineraryAgent itineraryAgent)
        {
            _dbContext = dbContext;
            _budgetAgent = budgetAgent;
            _riskAgent = riskAgent;
            _collaborationAgent = collaborationAgent;
            _itineraryAgent = itineraryAgent;
        }

        public async Task<AiWorkflow> StartWorkflowAsync(int tripId, int userId, string objective)
        {
            var workflow = new AiWorkflow
            {
                Id = Guid.NewGuid(),
                TripId = tripId,
                UserId = userId,
                Objective = objective,
                CurrentState = "CREATED",
                Plan = JsonSerializer.Serialize(new { steps = new[] { "COLLABORATION_ANALYSIS", "ITINERARY_PLANNING", "RISK_ANALYSIS", "BUDGET_ANALYSIS", "VALIDATING" } }),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _dbContext.AiWorkflows.Add(workflow);
            await _dbContext.SaveChangesAsync();

            // Fire off background execution or continue synchronously. We continue synchronously for demo.
            return workflow;
        }

        public async Task<AiWorkflow> GetWorkflowStatusAsync(Guid workflowId)
        {
            return await _dbContext.AiWorkflows.FindAsync(workflowId) 
                ?? throw new Exception("Workflow not found");
        }

        public async Task ExecuteWorkflowStepAsync(Guid workflowId)
        {
            var workflow = await GetWorkflowStatusAsync(workflowId);
            if (workflow.CurrentState == "AWAITING_APPROVAL" || workflow.CurrentState == "APPROVED" || workflow.CurrentState == "COMPLETED")
                return;

            try
            {
                // STEP 1: Collaboration Analysis
                if (workflow.CurrentState == "CREATED" || workflow.CurrentState == "COLLABORATION_ANALYSIS")
                {
                    workflow.CurrentState = "COLLABORATION_ANALYSIS";
                    workflow.ActiveAgent = _collaborationAgent.AgentName;
                    await SaveState(workflow);

                    var execution = CreateExecution(workflowId, _collaborationAgent.AgentName);
                    var collabResult = await _collaborationAgent.ExecuteAsync(workflowId, workflow.TripId, null);
                    CompleteExecution(execution, collabResult);

                    UpdateAgentResults(workflow, "Collaboration", collabResult);
                    
                    workflow.CurrentState = "ITINERARY_PLANNING";
                }

                // STEP 2: Itinerary Planning
                if (workflow.CurrentState == "ITINERARY_PLANNING" || workflow.CurrentState == "REVISING")
                {
                    workflow.CurrentState = "ITINERARY_PLANNING";
                    workflow.ActiveAgent = _itineraryAgent.AgentName;
                    await SaveState(workflow);

                    var context = GetAgentResult(workflow, "Collaboration");
                    var execution = CreateExecution(workflowId, _itineraryAgent.AgentName);
                    var itineraryResult = await _itineraryAgent.ExecuteAsync(workflowId, workflow.TripId, context);
                    CompleteExecution(execution, itineraryResult);

                    UpdateAgentResults(workflow, "Itinerary", itineraryResult);
                    workflow.CurrentState = "RISK_ANALYSIS";
                }

                // STEP 3: Risk Analysis
                if (workflow.CurrentState == "RISK_ANALYSIS")
                {
                    workflow.CurrentState = "RISK_ANALYSIS";
                    workflow.ActiveAgent = _riskAgent.AgentName;
                    await SaveState(workflow);

                    var execution = CreateExecution(workflowId, _riskAgent.AgentName);
                    var riskResult = await _riskAgent.ExecuteAsync(workflowId, workflow.TripId, null);
                    CompleteExecution(execution, riskResult);

                    UpdateAgentResults(workflow, "Risk", riskResult);
                    workflow.CurrentState = "BUDGET_ANALYSIS";
                }

                // STEP 4: Budget Analysis
                if (workflow.CurrentState == "BUDGET_ANALYSIS")
                {
                    workflow.CurrentState = "BUDGET_ANALYSIS";
                    workflow.ActiveAgent = _budgetAgent.AgentName;
                    await SaveState(workflow);

                    var execution = CreateExecution(workflowId, _budgetAgent.AgentName);
                    var budgetResult = await _budgetAgent.ExecuteAsync(workflowId, workflow.TripId, null);
                    CompleteExecution(execution, budgetResult);

                    UpdateAgentResults(workflow, "Budget", budgetResult);
                    workflow.CurrentState = "CROSS_AGENT_REVIEW";
                }

                // STEP 5 & 6: Cross-Agent Review and Revising
                if (workflow.CurrentState == "CROSS_AGENT_REVIEW")
                {
                    var riskResultStr = GetAgentResult(workflow, "Risk");
                    var budgetResultStr = GetAgentResult(workflow, "Budget");
                    
                    var riskResult = JsonSerializer.Deserialize<RiskAgentResponse>(riskResultStr ?? "{}");
                    var budgetResult = JsonSerializer.Deserialize<BudgetAgentResponse>(budgetResultStr ?? "{}");

                    if (riskResult?.RiskLevel == "CRITICAL" || riskResult?.RiskLevel == "HIGH" || budgetResult?.BudgetStatus == "AT_RISK")
                    {
                        workflow.RevisionCount++;
                        if (workflow.RevisionCount > 3)
                        {
                            workflow.CurrentState = "SAFE_FAILED";
                            workflow.FinalOutcome = JsonSerializer.Serialize(new { reason = "Max revisions exceeded due to persistent constraints." });
                            await SaveState(workflow);
                            return;
                        }
                        
                        workflow.CurrentState = "REVISING";
                        await SaveState(workflow);
                        
                        // Recall ExecuteWorkflowStepAsync recursively to trigger ITINERARY_PLANNING
                        await ExecuteWorkflowStepAsync(workflowId);
                        return;
                    }

                    workflow.CurrentState = "VALIDATING";
                }

                // STEP 10: Deterministic validation
                if (workflow.CurrentState == "VALIDATING")
                {
                    workflow.CurrentState = "VALIDATING";
                    await SaveState(workflow);

                    var isValid = PerformDeterministicValidation(workflow);
                    if (!isValid)
                    {
                        workflow.CurrentState = "VALIDATION_FAILED";
                    }
                    else
                    {
                        workflow.CurrentState = "AWAITING_APPROVAL";
                    }
                }

                workflow.ActiveAgent = null;
                await SaveState(workflow);
            }
            catch (Exception ex)
            {
                workflow.CurrentState = "AGENT_FAILED";
                workflow.FinalOutcome = JsonSerializer.Serialize(new { error = ex.Message });
                await SaveState(workflow);
            }
        }

        public async Task<bool> ApproveWorkflowAsync(Guid workflowId, int userId)
        {
            var workflow = await GetWorkflowStatusAsync(workflowId);
            if (workflow.CurrentState != "AWAITING_APPROVAL") return false;

            workflow.ApprovalStatus = "APPROVED";
            workflow.ApprovalUserId = userId;
            workflow.ApprovalDecision = "APPROVED";
            workflow.CurrentState = "APPROVED";
            
            var approval = new AiApproval { Id = Guid.NewGuid(), WorkflowId = workflowId, UserId = userId, Status = "APPROVED" };
            _dbContext.AiApprovals.Add(approval);
            
            await SaveState(workflow);
            return true;
        }

        public async Task<bool> RejectWorkflowAsync(Guid workflowId, int userId)
        {
            var workflow = await GetWorkflowStatusAsync(workflowId);
            if (workflow.CurrentState != "AWAITING_APPROVAL") return false;

            workflow.ApprovalStatus = "REJECTED";
            workflow.ApprovalUserId = userId;
            workflow.ApprovalDecision = "REJECTED";
            workflow.CurrentState = "REJECTED";

            var approval = new AiApproval { Id = Guid.NewGuid(), WorkflowId = workflowId, UserId = userId, Status = "REJECTED" };
            _dbContext.AiApprovals.Add(approval);

            await SaveState(workflow);
            return true;
        }

        public async Task<bool> RequestRevisionAsync(Guid workflowId, int userId, string reason)
        {
            var workflow = await GetWorkflowStatusAsync(workflowId);
            if (workflow.CurrentState != "AWAITING_APPROVAL") return false;

            var revision = new AiRevisionRequest { Id = Guid.NewGuid(), WorkflowId = workflowId, UserId = userId, Reason = reason };
            _dbContext.AiRevisionRequests.Add(revision);

            workflow.ApprovalStatus = "REVISION_REQUESTED";
            workflow.CurrentState = "REVISION_REQUIRED";
            await SaveState(workflow);

            // Re-trigger workflow
            workflow.CurrentState = "REVISING";
            await SaveState(workflow);
            await ExecuteWorkflowStepAsync(workflowId);
            return true;
        }

        private AiAgentExecution CreateExecution(Guid workflowId, string agentName)
        {
            var execution = new AiAgentExecution
            {
                Id = Guid.NewGuid(),
                WorkflowId = workflowId,
                AgentName = agentName,
                StartedAt = DateTime.UtcNow,
                Status = "RUNNING"
            };
            _dbContext.AiAgentExecutions.Add(execution);
            _dbContext.SaveChanges();
            return execution;
        }

        private void CompleteExecution(AiAgentExecution execution, object output)
        {
            execution.CompletedAt = DateTime.UtcNow;
            execution.Status = "COMPLETED";
            execution.Output = JsonSerializer.Serialize(output);
            _dbContext.SaveChanges();
        }

        private void UpdateAgentResults(AiWorkflow workflow, string agentKey, object result)
        {
            var resultsDict = JsonSerializer.Deserialize<System.Collections.Generic.Dictionary<string, JsonElement>>(workflow.AgentResults) 
                              ?? new System.Collections.Generic.Dictionary<string, JsonElement>();
            
            var resultStr = JsonSerializer.Serialize(result);
            resultsDict[agentKey] = JsonDocument.Parse(resultStr).RootElement;
            
            workflow.AgentResults = JsonSerializer.Serialize(resultsDict);
        }

        private string? GetAgentResult(AiWorkflow workflow, string agentKey)
        {
            var resultsDict = JsonSerializer.Deserialize<System.Collections.Generic.Dictionary<string, JsonElement>>(workflow.AgentResults);
            if (resultsDict != null && resultsDict.TryGetValue(agentKey, out var val))
            {
                return val.GetRawText();
            }
            return null;
        }

        private async Task SaveState(AiWorkflow workflow)
        {
            workflow.UpdatedAt = DateTime.UtcNow;
            _dbContext.AiWorkflows.Update(workflow);
            await _dbContext.SaveChangesAsync();
        }

        private bool PerformDeterministicValidation(AiWorkflow workflow)
        {
            // Simulate Deterministic Validation
            var isValid = true;
            
            // Check budget
            var budgetResultStr = GetAgentResult(workflow, "Budget");
            if (budgetResultStr != null)
            {
                var b = JsonSerializer.Deserialize<BudgetAgentResponse>(budgetResultStr);
                if (b != null && b.TotalBudget < 0) isValid = false;
            }

            var validationResult = new AiValidationResult
            {
                Id = Guid.NewGuid(),
                WorkflowId = workflow.Id,
                ValidationType = "FULL_WORKFLOW_VALIDATION",
                Passed = isValid,
                Message = isValid ? "Validation passed" : "Validation failed due to constraint violations."
            };
            _dbContext.AiValidationResults.Add(validationResult);
            _dbContext.SaveChanges();

            return isValid;
        }
    }
}
