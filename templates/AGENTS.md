# Multi-Agent System Configuration

Configuration for specialized agents and orchestration patterns.

---

## Overview

This project uses a multi-agent architecture to handle complex workflows. Each agent specializes in specific tasks and can spawn sub-agents as needed.

### Agent Architecture

```
Orchestrator (Main Claude Instance)
    ├── Research Agent
    │   └── Data Analysis Sub-Agent
    ├── Architecture Agent
    │   ├── Design Sub-Agent
    │   └── Documentation Sub-Agent
    ├── Coding Agent
    │   ├── Implementation Sub-Agent
    │   └── Refactoring Sub-Agent
    ├── Testing Agent
    │   ├── Unit Test Sub-Agent
    │   ├── Integration Test Sub-Agent
    │   └── E2E Test Sub-Agent
    └── QA Agent
        ├── Code Review Sub-Agent
        ├── Security Scan Sub-Agent
        └── Performance Test Sub-Agent
```

---

## Agent Definitions

### 1. Research Agent

**Purpose**: Analyze requirements, research solutions, and gather information.

**Capabilities**:
- Requirements analysis
- Technology research
- Best practices investigation
- Competitive analysis
- Documentation review

**Tools**:
- Brave Search MCP (web research)
- Context7 MCP (library documentation)
- Filesystem MCP (read project docs)
- Memory MCP (store findings)

**When to Use**:
```
"Use the research-agent to analyze authentication best practices for our API"
"Have the research-agent investigate PostgreSQL optimization techniques"
```

**Output Format**:
- Research findings document
- Technology recommendations
- Implementation suggestions
- Risk assessment

**Example Usage**:
```
Agent: research-agent
Task: Research modern authentication patterns for REST APIs
Context:
  - Our API serves 100k+ requests/day
  - We need OAuth2 and API key support
  - Security and performance are critical
Output: research/authentication-analysis.md
```

---

### 2. Architecture Agent

**Purpose**: Design system architecture and technical solutions.

**Capabilities**:
- System design
- Component architecture
- Database schema design
- API design
- Integration patterns

**Tools**:
- Filesystem MCP (read/write design docs)
- Memory MCP (store architecture decisions)
- Diagram generation tools
- Documentation tools

**When to Use**:
```
"Use the architecture-agent to design the microservices architecture"
"Have the architecture-agent create the database schema"
```

**Output Format**:
- Architecture diagrams
- Design documents
- API specifications
- Database schemas
- Component interfaces

**Example Usage**:
```
Agent: architecture-agent
Task: Design a scalable notification system
Requirements:
  - Support email, SMS, push notifications
  - Handle 10k notifications/minute
  - Reliable delivery with retries
  - Template management
Output: docs/architecture/notification-system.md
```

---

### 3. Coding Agent

**Purpose**: Implement features and write production code.

**Capabilities**:
- Feature implementation
- Code generation
- Refactoring
- Bug fixes
- API development

**Tools**:
- Filesystem MCP (read/write code)
- GitHub MCP (repository operations)
- Quality Guard MCP (code quality)
- Code Checker MCP (testing)

**When to Use**:
```
"Use the coding-agent to implement the user authentication module"
"Have the coding-agent refactor the payment processing service"
```

**Output Format**:
- Implementation code
- Code documentation
- Inline comments
- Commit messages

**Example Usage**:
```
Agent: coding-agent
Task: Implement JWT authentication middleware
Specifications:
  - Validate JWT tokens from Authorization header
  - Attach user context to request
  - Handle expired tokens gracefully
  - Support token refresh
Files:
  - src/middleware/auth.middleware.ts
  - src/services/auth.service.ts
  - src/types/auth.types.ts
```

---

### 4. Testing Agent

**Purpose**: Generate and execute comprehensive test suites.

**Capabilities**:
- Unit test generation
- Integration tests
- E2E tests
- Test data creation
- Coverage analysis

**Tools**:
- Code Checker MCP (test execution)
- Filesystem MCP (read/write tests)
- Quality Guard MCP (coverage tracking)

**When to Use**:
```
"Use the testing-agent to create tests for the API module"
"Have the testing-agent generate E2E tests for the checkout flow"
```

**Output Format**:
- Test files
- Test data fixtures
- Coverage reports
- Test documentation

**Example Usage**:
```
Agent: testing-agent
Task: Create comprehensive test suite for authentication
Coverage Requirements:
  - Minimum 90% code coverage
  - Test all success paths
  - Test all error scenarios
  - Test edge cases
Output:
  - tests/unit/auth/
  - tests/integration/auth/
  - tests/fixtures/auth-data.ts
```

---

### 5. Documentation Agent

**Purpose**: Create and maintain project documentation.

**Capabilities**:
- API documentation
- User guides
- Technical documentation
- Code comments
- README files

**Tools**:
- Filesystem MCP (read/write docs)
- Mintlify MCP or MarkItDown MCP (doc generation)
- GitHub MCP (update wiki)

**When to Use**:
```
"Use the documentation-agent to create API documentation"
"Have the documentation-agent update the user guide"
```

**Output Format**:
- Markdown documentation
- API reference
- Tutorials
- Architecture diagrams
- Code examples

**Example Usage**:
```
Agent: documentation-agent
Task: Create comprehensive API documentation
Scope:
  - All REST endpoints
  - Request/response schemas
  - Authentication details
  - Error codes
  - Usage examples
Output: docs/api/
```

---

### 6. QA Agent

**Purpose**: Quality assurance, code review, and validation.

**Capabilities**:
- Code review
- Security scanning
- Performance testing
- Best practices validation
- Dependency auditing

**Tools**:
- Quality Guard MCP (quality checks)
- Ruff MCP / ESLint (linting)
- Bandit / npm audit (security)
- Code Checker MCP (testing)

**When to Use**:
```
"Use the qa-agent to review the authentication implementation"
"Have the qa-agent run security scans on the API"
```

**Output Format**:
- Review reports
- Security findings
- Performance metrics
- Recommendations
- Action items

**Example Usage**:
```
Agent: qa-agent
Task: Complete quality review of authentication module
Checks:
  - Code quality (linting, formatting)
  - Security vulnerabilities
  - Test coverage
  - Documentation completeness
  - Performance issues
Output: qa/auth-module-review.md
```

---

### 7. DevOps Agent

**Purpose**: Infrastructure, deployment, and operations.

**Capabilities**:
- Infrastructure as Code
- CI/CD pipeline setup
- Container configuration
- Kubernetes resources
- Monitoring setup

**Tools**:
- Kubernetes MCP (K8s operations)
- Docker MCP (container management)
- GitHub MCP (workflows)
- Filesystem MCP (IaC files)

**When to Use**:
```
"Use the devops-agent to create Kubernetes deployment configs"
"Have the devops-agent set up the CI/CD pipeline"
```

**Output Format**:
- Kubernetes YAML
- Dockerfiles
- GitHub Actions workflows
- Terraform/Pulumi code
- Monitoring configs

**Example Usage**:
```
Agent: devops-agent
Task: Create Kubernetes deployment for API service
Requirements:
  - 3 replicas for high availability
  - Rolling update strategy
  - Health checks
  - Resource limits
  - ConfigMap for environment variables
Output: k8s/api-deployment.yaml
```

---

### 8. Data Agent

**Purpose**: Database operations, migrations, and data processing.

**Capabilities**:
- Database schema design
- Migration creation
- Data seeding
- Query optimization
- ETL processes

**Tools**:
- PostgreSQL MCP / SQLite MCP
- Filesystem MCP (migration files)
- Memory MCP (data tracking)

**When to Use**:
```
"Use the data-agent to create database migrations"
"Have the data-agent optimize slow queries"
```

**Output Format**:
- Migration files
- Seed data scripts
- Query optimization suggestions
- Database documentation

**Example Usage**:
```
Agent: data-agent
Task: Create migration for user authentication tables
Schema:
  - users table (id, email, password_hash, created_at)
  - sessions table (id, user_id, token, expires_at)
  - Include indexes for performance
Output: migrations/001_create_auth_tables.sql
```

---

## Agent Communication Protocol

### Message Format

```json
{
  "from": "orchestrator",
  "to": "agent-name",
  "task_id": "unique-id",
  "priority": "high|medium|low",
  "task": "Task description",
  "context": {
    "files": ["list of relevant files"],
    "dependencies": ["prerequisite tasks"],
    "constraints": ["limitations or requirements"]
  },
  "output_location": "path/to/output",
  "dependencies": ["task-id-1", "task-id-2"],
  "timeout": 3600
}
```

### Response Format

```json
{
  "from": "agent-name",
  "to": "orchestrator",
  "task_id": "unique-id",
  "status": "completed|failed|partial",
  "output": {
    "files_created": ["list of created files"],
    "files_modified": ["list of modified files"],
    "summary": "Task completion summary",
    "issues": ["list of issues encountered"],
    "next_steps": ["recommended next actions"]
  },
  "duration": 120,
  "sub_agents_spawned": ["list of sub-agents used"]
}
```

---

## Orchestration Patterns

### 1. Sequential Workflow

Execute agents in order, each depending on previous results.

```
Phase 1: Research Agent
  ↓ (findings)
Phase 2: Architecture Agent
  ↓ (design)
Phase 3: Coding Agent
  ↓ (implementation)
Phase 4: Testing Agent
  ↓ (tests)
Phase 5: QA Agent
  ↓ (approval)
Phase 6: DevOps Agent
  → (deployment)
```

**Use When:**
- Tasks have clear dependencies
- Each phase builds on previous
- Need validation at each step

**Example:**
```
"Let's build the user authentication system using a sequential workflow:
1. research-agent: Analyze auth best practices
2. architecture-agent: Design the auth system
3. coding-agent: Implement the code
4. testing-agent: Create test suite
5. qa-agent: Review and validate
6. devops-agent: Create deployment configs"
```

---

### 2. Parallel Workflow

Execute multiple agents simultaneously for independent tasks.

```
                  Orchestrator
                       |
        ┌──────────┬───┴───┬──────────┐
        ↓          ↓       ↓          ↓
  Coding Agent  Testing  Docs    DevOps
   (Feature A)  Agent   Agent    Agent
```

**Use When:**
- Tasks are independent
- Need to save time
- Resources available for parallel work

**Example:**
```
"Launch these agents in parallel:
- coding-agent: Implement API endpoints
- testing-agent: Generate unit tests for existing code
- documentation-agent: Update API documentation
- devops-agent: Update Kubernetes configs"
```

---

### 3. Iterative Workflow

Repeat agent execution with refinement.

```
Phase 1: Coding Agent (Implementation)
    ↓
Phase 2: QA Agent (Review)
    ↓
Phase 3: Coding Agent (Refinement) ←┐
    ↓                                |
Phase 4: QA Agent (Re-review) ──────┘
    ↓
Approved ✓
```

**Use When:**
- Quality is critical
- Complex requirements
- Need multiple review rounds

**Example:**
```
"Use an iterative workflow for the payment processing module:
1. coding-agent: Initial implementation
2. qa-agent: Review for issues
3. coding-agent: Address issues
4. qa-agent: Final review
Repeat until approval"
```

---

### 4. Hub-and-Spoke Workflow

Central coordinator delegates to specialists.

```
         Orchestrator (Hub)
               |
    ┌──────┬───┴───┬──────┐
    ↓      ↓       ↓      ↓
  Agent  Agent  Agent  Agent
    1      2      3      4
    ↓      ↓       ↓      ↓
    └──────┴───┬───┴──────┘
               ↓
          Aggregation
```

**Use When:**
- Central coordination needed
- Agents report back to main process
- Need to combine multiple outputs

**Example:**
```
"Coordinate a security review using hub-and-spoke:
Hub: qa-agent
Spokes:
  - Code review specialist
  - Security scan specialist
  - Dependency audit specialist
  - Performance test specialist
Aggregate findings into final report"
```

---

### 5. Pipeline Workflow

Data flows through stages, each transforming it.

```
Input → Agent 1 → Agent 2 → Agent 3 → Output
       (Extract)  (Transform) (Load)
```

**Use When:**
- Data transformation needed
- Clear input/output at each stage
- ETL or processing pipelines

**Example:**
```
"Build a content generation pipeline:
1. research-agent: Gather raw information
2. documentation-agent: Structure into outline
3. documentation-agent: Write detailed content
4. qa-agent: Review and polish
5. devops-agent: Publish to documentation site"
```

---

## State Management

### Memory Persistence

Use Memory MCP for cross-agent state:

```json
{
  "project_state": {
    "current_phase": "implementation",
    "current_agent": "coding-agent",
    "completed_tasks": ["research", "architecture"],
    "in_progress_tasks": ["implementation"],
    "blocked_tasks": []
  },
  "agent_states": {
    "research-agent": {
      "findings_location": "research/findings.md",
      "status": "completed"
    },
    "architecture-agent": {
      "design_location": "docs/architecture/design.md",
      "status": "completed"
    },
    "coding-agent": {
      "implementation_progress": "60%",
      "status": "in_progress"
    }
  }
}
```

### Checkpoint System

Save progress for resumption:

```
"Save checkpoint: authentication-module-implementation"
"Resume from checkpoint: authentication-module-implementation"
```

### Agent Context Sharing

Share context between agents:

```
Agent 1 Output → Saved to Memory → Agent 2 Input
```

---

## Best Practices

### Agent Design

✅ **Single Responsibility**
- Each agent has clear, focused purpose
- Avoid agent bloat

✅ **Clear Interfaces**
- Define input/output formats
- Document expected behavior

✅ **Error Handling**
- Agents report failures clearly
- Provide recovery suggestions

### Orchestration

✅ **Start Simple**
- Begin with sequential workflows
- Add complexity as needed

✅ **Monitor Progress**
- Track agent status
- Set reasonable timeouts

✅ **Handle Failures**
- Implement retry logic
- Define fallback strategies

### Communication

✅ **Explicit Handoffs**
- Clear task boundaries
- Documented dependencies

✅ **Structured Messages**
- Use consistent formats
- Include all necessary context

✅ **State Persistence**
- Save progress frequently
- Enable resumption

---

## Example Workflows

### Complete Feature Development

```
Task: Implement user registration feature

Workflow:
1. research-agent
   - Research registration best practices
   - Analyze security requirements
   - Document findings

2. architecture-agent
   - Design registration flow
   - Design database schema
   - Design API endpoints

3. data-agent
   - Create database migration
   - Add seed data

4. coding-agent
   - Implement registration service
   - Create API endpoints
   - Add input validation

5. testing-agent
   - Generate unit tests
   - Create integration tests
   - Add E2E tests

6. documentation-agent
   - Create API documentation
   - Write user guide

7. qa-agent
   - Code review
   - Security scan
   - Validate test coverage

8. devops-agent
   - Update Kubernetes configs
   - Configure CI/CD
   - Set up monitoring
```

### Bug Fix Workflow

```
Task: Fix authentication timeout bug

Workflow:
1. qa-agent
   - Analyze bug report
   - Reproduce issue
   - Identify root cause

2. coding-agent
   - Implement fix
   - Add error handling

3. testing-agent
   - Create regression test
   - Verify fix

4. qa-agent
   - Validate fix
   - Check for side effects

5. devops-agent
   - Prepare hotfix deployment
```

### Documentation Update

```
Task: Update API documentation

Workflow:
1. documentation-agent (in parallel)
   - Update endpoint docs
   - Add new examples
   - Update changelog

2. qa-agent
   - Review for accuracy
   - Check completeness
   - Validate examples

3. devops-agent
   - Deploy updated docs
```

---

## Agent Invocation

### Automatic Invocation

Claude Code automatically chooses agents:

```
"Search the codebase for authentication logic"
→ Automatically spawns Explore agent
```

### Explicit Invocation

Explicitly request specific agent:

```
"Use the testing-agent to generate tests for the auth module"
```

### Multi-Agent Invocation

Request multiple agents:

```
"Run these agents in parallel:
- testing-agent on the API
- documentation-agent on the services
- qa-agent for code review"
```

---

## Monitoring & Debugging

### Agent Status Tracking

Monitor agent progress:

```
"Show status of all running agents"
"What is the coding-agent working on?"
```

### Debugging Failed Agents

Investigate failures:

```
"Why did the testing-agent fail?"
"Show output from the last qa-agent run"
```

### Performance Monitoring

Track agent performance:

```
"How long did the coding-agent take?"
"Which agents are taking the longest?"
```

---

## Custom Agent Creation

### Define Custom Agent

Add to this AGENTS.md file:

```markdown
### 9. Custom Agent Name

**Purpose**: What this agent does

**Capabilities**:
- Capability 1
- Capability 2

**Tools**:
- Tool 1
- Tool 2

**When to Use**: Description

**Output Format**: Expected outputs
```

### Register with Claude Code

Claude Code automatically reads AGENTS.md and recognizes custom agents.

### Use Custom Agent

```
"Use the custom-agent-name to perform specific task"
```

---

## Troubleshooting

### Agent Not Spawning

**Check:**
- Agent name is correct
- AGENTS.md is in project root
- Task description is clear

### Agent Timeout

**Solutions:**
- Break task into smaller sub-tasks
- Increase timeout if supported
- Use checkpoint system

### Agent Miscommunication

**Solutions:**
- Use explicit task descriptions
- Provide clear context
- Define expected outputs

### State Inconsistency

**Solutions:**
- Use Memory MCP for persistence
- Implement checkpoint system
- Validate state before proceeding

---

## Resources

- [Claude Code Agent Documentation](https://docs.claude.com/claude-code/agents)
- [Multi-Agent Architecture Guide](../../guides/agents-subagents/architecture.md)
- [Orchestration Patterns](../../guides/agents-subagents/orchestration.md)
- [Agent Communication](../../guides/agents-subagents/communication.md)

---

## Notes

### Agent Limitations

- Agents run in isolated contexts
- Limited direct communication
- State must be persisted explicitly

### Performance Considerations

- Parallel agents consume more resources
- Complex workflows take longer
- Monitor token usage

### Best Use Cases

- Complex, multi-step projects
- Parallel independent tasks
- Specialized domain tasks
- Long-running workflows

---

**Last Updated**: 2025-11-04

**Compatible With**: Claude Code 1.0+

**Related**: [CLAUDE.md](CLAUDE.md) for project configuration
