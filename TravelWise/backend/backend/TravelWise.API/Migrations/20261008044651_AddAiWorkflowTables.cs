using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TravelWise.API.Migrations
{
    /// <inheritdoc />
    public partial class AddAiWorkflowTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AiWorkflows",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<int>(type: "integer", nullable: false),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    Objective = table.Column<string>(type: "text", nullable: false),
                    Plan = table.Column<string>(type: "jsonb", nullable: false),
                    CurrentState = table.Column<string>(type: "text", nullable: false),
                    ActiveAgent = table.Column<string>(type: "text", nullable: true),
                    CompletedSteps = table.Column<string>(type: "jsonb", nullable: false),
                    AgentResults = table.Column<string>(type: "jsonb", nullable: false),
                    RetryCount = table.Column<int>(type: "integer", nullable: false),
                    RevisionCount = table.Column<int>(type: "integer", nullable: false),
                    ApprovalStatus = table.Column<string>(type: "text", nullable: false),
                    ApprovalUserId = table.Column<int>(type: "integer", nullable: true),
                    ApprovalDecision = table.Column<string>(type: "text", nullable: true),
                    FinalOutcome = table.Column<string>(type: "jsonb", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AiWorkflows", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AiWorkflows_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AiWorkflows_Users_ApprovalUserId",
                        column: x => x.ApprovalUserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_AiWorkflows_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AiAgentExecutions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkflowId = table.Column<Guid>(type: "uuid", nullable: false),
                    AgentName = table.Column<string>(type: "text", nullable: false),
                    StartedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Status = table.Column<string>(type: "text", nullable: false),
                    Input = table.Column<string>(type: "jsonb", nullable: true),
                    Output = table.Column<string>(type: "jsonb", nullable: true),
                    Errors = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AiAgentExecutions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AiAgentExecutions_AiWorkflows_WorkflowId",
                        column: x => x.WorkflowId,
                        principalTable: "AiWorkflows",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AiApprovals",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkflowId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    Reason = table.Column<string>(type: "text", nullable: true),
                    DecidedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AiApprovals", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AiApprovals_AiWorkflows_WorkflowId",
                        column: x => x.WorkflowId,
                        principalTable: "AiWorkflows",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AiApprovals_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AiRevisionRequests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkflowId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    Reason = table.Column<string>(type: "text", nullable: false),
                    RequestedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AiRevisionRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AiRevisionRequests_AiWorkflows_WorkflowId",
                        column: x => x.WorkflowId,
                        principalTable: "AiWorkflows",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AiRevisionRequests_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AiValidationResults",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkflowId = table.Column<Guid>(type: "uuid", nullable: false),
                    AgentName = table.Column<string>(type: "text", nullable: true),
                    ValidationType = table.Column<string>(type: "text", nullable: false),
                    Passed = table.Column<bool>(type: "boolean", nullable: false),
                    Message = table.Column<string>(type: "text", nullable: true),
                    ValidatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AiValidationResults", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AiValidationResults_AiWorkflows_WorkflowId",
                        column: x => x.WorkflowId,
                        principalTable: "AiWorkflows",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AiToolExecutions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AgentExecutionId = table.Column<Guid>(type: "uuid", nullable: false),
                    ToolName = table.Column<string>(type: "text", nullable: false),
                    Input = table.Column<string>(type: "jsonb", nullable: true),
                    Output = table.Column<string>(type: "jsonb", nullable: true),
                    ExecutedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AiToolExecutions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AiToolExecutions_AiAgentExecutions_AgentExecutionId",
                        column: x => x.AgentExecutionId,
                        principalTable: "AiAgentExecutions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AiAgentExecutions_WorkflowId",
                table: "AiAgentExecutions",
                column: "WorkflowId");

            migrationBuilder.CreateIndex(
                name: "IX_AiApprovals_UserId",
                table: "AiApprovals",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AiApprovals_WorkflowId",
                table: "AiApprovals",
                column: "WorkflowId");

            migrationBuilder.CreateIndex(
                name: "IX_AiRevisionRequests_UserId",
                table: "AiRevisionRequests",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AiRevisionRequests_WorkflowId",
                table: "AiRevisionRequests",
                column: "WorkflowId");

            migrationBuilder.CreateIndex(
                name: "IX_AiToolExecutions_AgentExecutionId",
                table: "AiToolExecutions",
                column: "AgentExecutionId");

            migrationBuilder.CreateIndex(
                name: "IX_AiValidationResults_WorkflowId",
                table: "AiValidationResults",
                column: "WorkflowId");

            migrationBuilder.CreateIndex(
                name: "IX_AiWorkflows_ApprovalUserId",
                table: "AiWorkflows",
                column: "ApprovalUserId");

            migrationBuilder.CreateIndex(
                name: "IX_AiWorkflows_TripId",
                table: "AiWorkflows",
                column: "TripId");

            migrationBuilder.CreateIndex(
                name: "IX_AiWorkflows_UserId",
                table: "AiWorkflows",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AiApprovals");

            migrationBuilder.DropTable(
                name: "AiRevisionRequests");

            migrationBuilder.DropTable(
                name: "AiToolExecutions");

            migrationBuilder.DropTable(
                name: "AiValidationResults");

            migrationBuilder.DropTable(
                name: "AiAgentExecutions");

            migrationBuilder.DropTable(
                name: "AiWorkflows");
        }
    }
}
