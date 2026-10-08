using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TravelWise.API.Models.AI
{
    public class AiWorkflow
    {
        [Key]
        public Guid Id { get; set; }

        public int TripId { get; set; }
        
        public int UserId { get; set; }

        [Required]
        public string Objective { get; set; } = string.Empty;

        [Column(TypeName = "jsonb")]
        public string Plan { get; set; } = "{}";

        [Required]
        public string CurrentState { get; set; } = "CREATED";

        public string? ActiveAgent { get; set; }

        [Column(TypeName = "jsonb")]
        public string CompletedSteps { get; set; } = "[]";

        [Column(TypeName = "jsonb")]
        public string AgentResults { get; set; } = "{}";

        public int RetryCount { get; set; } = 0;
        public int RevisionCount { get; set; } = 0;

        public string ApprovalStatus { get; set; } = "PENDING";
        public int? ApprovalUserId { get; set; }
        public string? ApprovalDecision { get; set; }

        [Column(TypeName = "jsonb")]
        public string? FinalOutcome { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("TripId")]
        public Trip? Trip { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }

        [ForeignKey("ApprovalUserId")]
        public User? ApprovalUser { get; set; }
    }

    public class AiAgentExecution
    {
        [Key]
        public Guid Id { get; set; }

        public Guid WorkflowId { get; set; }

        [Required]
        public string AgentName { get; set; } = string.Empty;

        public DateTime StartedAt { get; set; } = DateTime.UtcNow;
        public DateTime? CompletedAt { get; set; }

        [Required]
        public string Status { get; set; } = "RUNNING";

        [Column(TypeName = "jsonb")]
        public string? Input { get; set; }

        [Column(TypeName = "jsonb")]
        public string? Output { get; set; }

        public string? Errors { get; set; }

        [ForeignKey("WorkflowId")]
        public AiWorkflow? Workflow { get; set; }
    }

    public class AiToolExecution
    {
        [Key]
        public Guid Id { get; set; }

        public Guid AgentExecutionId { get; set; }

        [Required]
        public string ToolName { get; set; } = string.Empty;

        [Column(TypeName = "jsonb")]
        public string? Input { get; set; }

        [Column(TypeName = "jsonb")]
        public string? Output { get; set; }

        public DateTime ExecutedAt { get; set; } = DateTime.UtcNow;
        public string Status { get; set; } = "SUCCESS";

        [ForeignKey("AgentExecutionId")]
        public AiAgentExecution? AgentExecution { get; set; }
    }

    public class AiValidationResult
    {
        [Key]
        public Guid Id { get; set; }

        public Guid WorkflowId { get; set; }
        public string? AgentName { get; set; }

        [Required]
        public string ValidationType { get; set; } = string.Empty;

        public bool Passed { get; set; }
        public string? Message { get; set; }
        public DateTime ValidatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("WorkflowId")]
        public AiWorkflow? Workflow { get; set; }
    }

    public class AiApproval
    {
        [Key]
        public Guid Id { get; set; }

        public Guid WorkflowId { get; set; }
        public int UserId { get; set; }

        [Required]
        public string Status { get; set; } = "PENDING"; // APPROVED, REJECTED, REQUESTED_REVISION

        public string? Reason { get; set; }
        public DateTime DecidedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("WorkflowId")]
        public AiWorkflow? Workflow { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }
    }

    public class AiRevisionRequest
    {
        [Key]
        public Guid Id { get; set; }

        public Guid WorkflowId { get; set; }
        public int UserId { get; set; }

        [Required]
        public string Reason { get; set; } = string.Empty;

        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("WorkflowId")]
        public AiWorkflow? Workflow { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }
    }
}
