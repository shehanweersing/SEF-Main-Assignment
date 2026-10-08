# ADR 001: Replace AI Travel Readiness Agent with Group Collaboration & Consensus Agent

## Context
The original TravelWise concept included a Travel Readiness Agent that relied heavily on user document uploads to determine readiness. While this concept was interesting, it proved to have a dependency on users consistently uploading highly sensitive personal travel documents. This creates privacy concerns and friction.

## Decision
We are intentionally replacing the **Readiness Agent** with the **Group Collaboration & Consensus Agent**.

## Reason
- Better user experience
- No unnecessary document-upload dependency
- Stronger multi-user functionality
- Enables preference aggregation
- Enables conflict resolution
- Enables consensus
- Creates stronger interaction between agents

## Consequences
- The architectural diagrams and documentation should be updated to reflect the `Collaboration Agent` instead of the `Readiness Agent`.
- Existing `ReadinessService` and UI components can remain as independent user tracking features but they will not be integrated into the AI agent workflow.
- Group member preferences, voting, and consensus will drive the AI workflow planning constraints.
