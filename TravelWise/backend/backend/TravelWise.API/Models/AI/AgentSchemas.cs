using System.Collections.Generic;

namespace TravelWise.API.Models.AI
{
    public class BudgetAgentResponse
    {
        public string BudgetStatus { get; set; } = string.Empty; // e.g. AT_RISK, ON_TRACK
        public decimal TotalBudget { get; set; }
        public decimal SpentAmount { get; set; }
        public decimal RemainingAmount { get; set; }
        public decimal EstimatedFinalCost { get; set; }
        public decimal Variance { get; set; }
        public List<string> OverspendingCategories { get; set; } = new();
        public List<string> ExpensiveActivities { get; set; } = new();
        public List<string> Recommendations { get; set; } = new();
        public List<string> ConstraintsForItineraryAgent { get; set; } = new();
        public List<string> Reasoning { get; set; } = new();
        public double Confidence { get; set; }
    }

    public class RiskAgentResponse
    {
        public string RiskLevel { get; set; } = string.Empty; // LOW, MEDIUM, HIGH, CRITICAL
        public int RiskScore { get; set; }
        public Dictionary<string, object> WeatherRisk { get; set; } = new();
        public Dictionary<string, object> DestinationRisk { get; set; } = new();
        public List<Dictionary<string, object>> ActivityRisks { get; set; } = new();
        public List<string> UnsafeActivities { get; set; } = new();
        public List<string> Recommendations { get; set; } = new();
        public List<string> ConstraintsForItineraryAgent { get; set; } = new();
        public List<string> Reasoning { get; set; } = new();
        public double Confidence { get; set; }
    }

    public class CollaborationAgentResponse
    {
        public string ConsensusStatus { get; set; } = string.Empty; // FULL_CONSENSUS, PARTIAL_CONSENSUS, NO_CONSENSUS
        public double ConsensusScore { get; set; }
        public List<Dictionary<string, object>> MemberPreferences { get; set; } = new();
        public List<string> Conflicts { get; set; } = new();
        public List<string> GroupPriorities { get; set; } = new();
        public List<string> RecommendedCompromises { get; set; } = new();
        public List<string> PreferredActivities { get; set; } = new();
        public List<string> ConstraintsForItineraryAgent { get; set; } = new();
        public List<string> Reasoning { get; set; } = new();
        public double Confidence { get; set; }
    }

    public class ItineraryAgentResponse
    {
        public string ItineraryStatus { get; set; } = string.Empty; // READY, REQUIRES_REVISION
        public List<Dictionary<string, object>> Days { get; set; } = new();
        public List<string> Conflicts { get; set; } = new();
        public List<string> ConstraintViolations { get; set; } = new();
        public List<string> Alternatives { get; set; } = new();
        public decimal EstimatedCost { get; set; }
        public List<string> SafetyConsiderations { get; set; } = new();
        public double GroupPreferenceScore { get; set; }
        public List<string> Reasoning { get; set; } = new();
        public double Confidence { get; set; }
    }
}
