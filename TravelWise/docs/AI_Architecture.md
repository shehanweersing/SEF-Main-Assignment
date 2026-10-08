# TravelWise AI Architecture

## 1. Overall Architecture
- **Web/Mobile Client** -> **ASP.NET Core API** -> **AI Workflow Orchestrator** -> **Agents** -> **Gemini AI Service** -> **Supabase Persistence**

## 2. Four-Agent Architecture
- **Collaboration Agent**: Analyzes group preferences and resolves conflicts.
- **Itinerary Agent**: Drafts the optimal schedule based on constraints.
- **Risk Agent**: Assesses weather, destination, and activity risks.
- **Budget Agent**: Analyzes cost limits, detects overspending.

## 3. Agent Responsibility Matrix
| Agent | Responsibility |
| --- | --- |
| Collaboration Agent | Group priorities, consensus, preference aggregation |
| Itinerary Agent | Scheduling, conflict detection, activity mapping |
| Risk Agent | Hazard identification, weather forecasting, safety constraints |
| Budget Agent | Cost estimation, variance analysis, category allocation |

## 4. Agent-to-Tool Permission Matrix
| Agent | Allowed Tools (Backend Repository/Context methods) |
| --- | --- |
| Collaboration | GetTripMembers, GetMemberPreferences |
| Itinerary | GetActivities, CheckScheduleAvailability |
| Risk | GetWeather, GetDestinationRisk |
| Budget | GetTripBudget, GetExpenses |

## 5. AI Model/API Architecture
- **Centralized Service**: `AiModelService` implements `IAiModelService`.
- **Model**: Google Gemini (`gemini-1.5-flash`).
- **Authentication**: A single `GEMINI_API_KEY` injected into the backend via environment variables. The API key is securely isolated and never exposed to the frontend.

## 6. Supabase Database Architecture
- **`AiWorkflows`**: Tracks the top-level state of a workflow (CREATED, PLANNING, AWAITING_APPROVAL, etc.).
- **`AiAgentExecutions`**: Tracks individual runs of an agent, tracking latency and input/output JSONs.
- **`AiToolExecutions`**: Tracks any specific tools invoked by an agent to gather local data.
- **`AiValidationResults`**: Tracks deterministic validity checks.
- **`AiApprovals` / `AiRevisionRequests`**: Tracks human-in-the-loop decisions.

## 7. Workflow State Machine
`CREATED` -> `COLLABORATION_ANALYSIS` -> `ITINERARY_PLANNING` -> `RISK_ANALYSIS` -> `BUDGET_ANALYSIS` -> `CROSS_AGENT_REVIEW` -> `VALIDATING` -> `AWAITING_APPROVAL` <-> `REVISING` -> `APPROVED` / `REJECTED`

## 8. Cross-Agent Communication Flow
The `AiWorkflowOrchestrator` aggregates structured outputs (JSON) from each agent's execution and injects it into the prompt context for subsequent agents (e.g., Risk Agent identifies a high risk, Orchestrator catches this in the `CROSS_AGENT_REVIEW` step and loops back to `REVISING` using the Itinerary Agent).

## 9. Validation Strategy
We employ **Deterministic Validation** in the Orchestrator. We do not rely solely on LLM self-validation. The backend asserts budget values, risk severity enums, and timestamp overlaps.

## 10. Human Approval Flow
The workflow halts at `AWAITING_APPROVAL`. The end user interacts via the Web or Mobile app to review the `AgentResults` payload. They can Approve, Reject, or provide feedback for a Revision.

## 11. Revision Flow
If human revision is requested or cross-agent conflicts occur, the state switches to `REVISING` and the `ItineraryAgent` is re-run with the updated constraint context.

## 12. Error Handling
We track retries and gracefully downgrade to `AGENT_FAILED` or `SAFE_FAILED` if constraints cannot be resolved within 3 iterations.

## 13. Security
- API Keys stored in `.env`.
- Supabase JWT authentication handles RLS and User Identity.
- Agents operate strictly within user context (validated Trip IDs).

## 14. Audit/Observability
- `AiAgentExecutions` and `AiValidationResults` provide a complete auditable timeline of every AI action taken during workflow execution.

## 15. API Endpoints
- `POST /api/trips/{tripId}/ai-workflows`
- `GET /api/ai-workflows/{workflowId}`
- `GET /api/ai-workflows/{workflowId}/status`
- `GET /api/ai-workflows/{workflowId}/results`
- `POST /api/ai-workflows/{workflowId}/approve`
- `POST /api/ai-workflows/{workflowId}/reject`
- `POST /api/ai-workflows/{workflowId}/revise`

## 16. Testing Strategy
- **Unit Tests**: Mocks `IAiModelService` to simulate specific agent responses and assert correct state transitions in `AiWorkflowOrchestrator`.
- **E2E Tests**: Validate full web app flow.

## 17. Colombo -> Ella Demonstration Flow
1. User creates Colombo to Ella trip.
2. Group preferences logged.
3. Orchestrator triggers `Collaboration Agent`.
4. `Itinerary Agent` drafts schedule.
5. `Risk Agent` checks weather in Ella.
6. `Budget Agent` estimates train and activity costs.
7. Validation passes.
8. User is presented with `AWAITING_APPROVAL` UI.
9. User Approves the Intelligent Trip Plan.
