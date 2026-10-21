<!--
TEMPLATE NOTES (this HTML comment is stripped before Claude sees the file, so it costs no context):
- This template is a menu, not a target. Claude Code loads CLAUDE.md in full every session; the official
  guidance is to keep each CLAUDE.md under ~200 lines. Delete every section Claude could infer from the code.
- Move "sometimes relevant" material to skills (.claude/skills/) or path-scoped rules
  (.claude/rules/*.md with `paths:` frontmatter) instead of keeping it here.
- If this repo also has an AGENTS.md for other coding agents, Claude Code reads only CLAUDE.md when both
  exist. Put shared instructions in AGENTS.md and start this file with the line:  @AGENTS.md
- Run /init to generate a draft from the codebase, and /doctor later to find duplicated or derivable content.
Last verified against Claude Code docs: 2026-10.
-->

# Project Name

Brief description of the project and its goals.

---

## Project Overview

### Purpose
Describe what this project does and why it exists.

### Goals
- Goal 1
- Goal 2
- Goal 3

### Target Users
Who will use this project or benefit from it?

---

## Project Structure

```
project-root/
├── src/                    # Source code
│   ├── api/               # API endpoints
│   ├── services/          # Business logic
│   ├── models/            # Data models
│   └── utils/             # Utilities
├── tests/                 # Test suites
├── docs/                  # Documentation
├── scripts/               # Automation scripts
├── .claude/               # Claude Code configuration
│   ├── settings.json     # Shared permissions, hooks, env (committed)
│   ├── agents/           # Custom sub-agent definitions
│   ├── skills/           # Custom skills
│   ├── rules/            # Path-scoped instruction files
│   └── hooks/            # Event hook scripts
├── .mcp.json             # Project-scoped MCP servers
├── CLAUDE.md             # This file
├── AGENTS.md             # Shared agent instructions (read by many agent tools)
└── README.md             # User-facing documentation
```

---

## Technology Stack

### Core Technologies
- **Language**: Python 3.11+, TypeScript, etc.
- **Framework**: FastAPI, NestJS, React, etc.
- **Database**: PostgreSQL, MongoDB, etc.
- **Infrastructure**: Docker, Kubernetes, etc.

### Development Tools
- **Testing**: pytest, Jest, etc.
- **Linting**: Ruff, ESLint, etc.
- **CI/CD**: GitHub Actions, GitLab CI, etc.

### Key Dependencies
List important third-party libraries and their purposes.

---

## Development Workflow

### Setup
```bash
# Clone repository
git clone https://github.com/org/project.git
cd project

# Install dependencies
npm install  # or pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your configuration

# Initialize database
npm run db:migrate  # or alembic upgrade head
```

### Development
```bash
# Start development server
npm run dev  # or python -m uvicorn main:app --reload

# Run tests
npm test  # or pytest

# Lint code
npm run lint  # or ruff check .
```

### Deployment
```bash
# Build for production
npm run build  # or docker build

# Deploy
npm run deploy  # or kubectl apply -f k8s/
```

---

## Claude Code Integration

### MCP Servers Required

List only servers this project actually needs; each one adds tools (and context) to every session. Examples — verify current package names in the [MCP catalog](../guides/mcp-servers/catalog.md) before adopting:

**Common:**
- GitHub's official MCP server (hosted at `https://api.githubcopilot.com/mcp/`) - Issues, PRs, repository operations
- `postgres-mcp` ("Postgres MCP Pro", via `uvx`) - Database access (if using PostgreSQL)

**Optional:**
- `@modelcontextprotocol/server-memory` - Knowledge-graph memory (Claude Code also has built-in auto memory)
- `kubernetes-mcp-server` - K8s management (if using Kubernetes)

Claude Code's built-in tools already read, edit, and search files in the project, so a filesystem server is only needed for paths outside it.

### MCP Configuration

**Location**: `.mcp.json` at the project root (committed to version control). Add entries with `claude mcp add --scope project <name> -- <command> [args...]` or edit directly:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_TOKEN}"
      }
    },
    "postgres": {
      "command": "uvx",
      "args": ["postgres-mcp", "--access-mode=restricted"],
      "env": {
        "DATABASE_URI": "${DATABASE_URL}"
      }
    }
  }
}
```

### Environment Variables

**Location**: `.env` (gitignored)

```bash
# GitHub Integration
GITHUB_TOKEN=your_github_token_here
GITHUB_ORG=your_organization

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname

# API Keys
API_KEY=your_api_key_here

# Project Paths
PROJECT_ROOT=/path/to/project
```

### Skills Configuration

**Available Skills** (invoke with `/skill-name` or by describing the task):

1. **code-validator** - Automated code quality checks
   ```
   /code-validator
   ```

2. **test-generator** - Generate test suites
   ```
   "Use test-generator for the API module"
   ```

3. **documentation-writer** - Generate documentation
   ```
   "Run documentation-writer on the services directory"
   ```

**Custom Skills**: See `.claude/skills/` directory. Claude Code also bundles skills such as `/code-review`, `/simplify`, and `/verify`.

---

## Multi-Agent Orchestration

### Available Agents

Sub-agents are defined as Markdown files with YAML frontmatter in `.claude/agents/` (ask Claude to create one, or write the file). [AGENTS.md](AGENTS.md) carries shared instructions read by agent tools.

**Quick Reference:**

1. **research-agent** - Requirements analysis and research
2. **architecture-agent** - System design and planning
3. **coding-agent** - Implementation
4. **testing-agent** - Test generation and execution
5. **documentation-agent** - Documentation creation
6. **qa-agent** - Quality assurance and review

### Using Agents

**Spawn an agent:**
```
"Use the coding-agent to implement the user authentication module"
```

**Multi-agent workflow:**
```
"Let's use a multi-phase approach:
1. research-agent: Analyze the requirements
2. architecture-agent: Design the solution
3. coding-agent: Implement the code
4. testing-agent: Create tests
5. qa-agent: Review everything"
```

---

## Coding Standards

### Code Style

**Python:**
- Follow PEP 8
- Use type hints
- Maximum line length: 100 characters
- Use Ruff for linting

**TypeScript:**
- Follow Airbnb style guide
- Strict type checking enabled
- Use ESLint + Prettier

### Naming Conventions

**Files:**
- Python: `snake_case.py`
- TypeScript: `kebab-case.ts` or `PascalCase.tsx`

**Functions/Methods:**
- Python: `snake_case()`
- TypeScript: `camelCase()`

**Classes:**
- Both: `PascalCase`

**Constants:**
- Both: `UPPER_SNAKE_CASE`

### Documentation

**Docstrings (Python):**
```python
def function_name(param1: str, param2: int) -> bool:
    """
    Brief description of what the function does.

    Args:
        param1: Description of param1
        param2: Description of param2

    Returns:
        Description of return value

    Raises:
        ValueError: When this happens
    """
    pass
```

**JSDoc (TypeScript):**
```typescript
/**
 * Brief description of what the function does.
 *
 * @param param1 - Description of param1
 * @param param2 - Description of param2
 * @returns Description of return value
 * @throws {Error} When this happens
 */
function functionName(param1: string, param2: number): boolean {
    // Implementation
}
```

### Testing Standards

**Coverage Requirements:**
- Minimum: 80%
- Target: 90%+

**Test Structure:**
```python
# Python (pytest)
def test_feature_name_scenario():
    """Test that feature behaves correctly when scenario occurs."""
    # Arrange
    setup_data = create_test_data()

    # Act
    result = function_under_test(setup_data)

    # Assert
    assert result == expected_value
```

```typescript
// TypeScript (Jest)
describe('FeatureName', () => {
  it('should behave correctly when scenario occurs', () => {
    // Arrange
    const setupData = createTestData();

    // Act
    const result = functionUnderTest(setupData);

    // Assert
    expect(result).toBe(expectedValue);
  });
});
```

---

## Git Workflow

### Branch Strategy

**Main Branches:**
- `main` - Production-ready code
- `develop` - Integration branch

**Feature Branches:**
- `feature/feature-name` - New features
- `bugfix/bug-name` - Bug fixes
- `hotfix/issue-name` - Production hotfixes

### Commit Messages

Follow Conventional Commits:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Formatting changes
- `refactor:` - Code restructuring
- `test:` - Test additions/changes
- `chore:` - Maintenance tasks

**Example:**
```
feat(auth): add JWT authentication middleware

Implement JWT-based authentication with token validation
and user context attachment to requests.

- Add JWT verification middleware
- Create token validation service
- Add user context to request object
- Include comprehensive error handling

Closes #123
```

### Pull Request Process

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/feature-name
   ```

2. **Make Changes and Commit**
   ```bash
   git add .
   git commit -m "feat: implement feature"
   ```

3. **Push to Remote**
   ```bash
   git push origin feature/feature-name
   ```

4. **Create Pull Request**
   - Use PR template
   - Link related issues
   - Request reviews

5. **Address Review Comments**
   - Make requested changes
   - Push updates

6. **Merge**
   - Squash and merge (preferred)
   - Delete branch after merge

---

## Common Tasks

### Adding a New Feature

```
"I need to add a new feature for user password reset. Let's:
1. Design the API endpoints
2. Implement the password reset service
3. Add email notification
4. Create tests
5. Update documentation"
```

### Refactoring Code

```
"Refactor the UserService class to:
- Use dependency injection
- Improve error handling
- Add comprehensive type hints
- Maintain backward compatibility"
```

### Debugging Issues

```
"There's a bug in the payment processing module. The error occurs at src/payments/processor.ts:78. Let's:
1. Analyze the code around that line
2. Identify the root cause
3. Implement a fix
4. Add regression tests"
```

### Writing Tests

```
"Generate a comprehensive test suite for the authentication module, including:
- Unit tests for each function
- Integration tests for the API endpoints
- Edge cases and error scenarios
- Mock external dependencies"
```

### Generating Documentation

```
"Create API documentation for all endpoints in src/api/, including:
- Endpoint descriptions
- Request/response schemas
- Authentication requirements
- Example requests
- Error responses"
```

---

## Quality Assurance

### Before Committing

- [ ] Code passes linting
- [ ] All tests pass
- [ ] Code coverage meets requirements
- [ ] Documentation updated
- [ ] No secrets in code
- [ ] Security review completed (for sensitive code)

### CI/CD Checks

**Automated Checks:**
- Linting (Ruff, ESLint)
- Type checking (mypy, TypeScript)
- Tests (pytest, Jest)
- Security scanning (Bandit, npm audit)
- Code coverage
- Documentation build

### Manual Review

- [ ] Code follows style guide
- [ ] Logic is sound and efficient
- [ ] Error handling is comprehensive
- [ ] Tests cover edge cases
- [ ] Documentation is clear
- [ ] No performance issues

---

## Security Considerations

### Sensitive Data

**Never commit:**
- API keys
- Passwords
- Private keys
- Connection strings
- Tokens

**Use environment variables:**
```python
import os

API_KEY = os.environ.get('API_KEY')
```

### Input Validation

**Always validate:**
- User inputs
- API requests
- File uploads
- Query parameters

### Authentication & Authorization

**Implement:**
- Strong password requirements
- Token expiration
- Rate limiting
- RBAC (Role-Based Access Control)

### Dependencies

**Keep updated:**
```bash
# Check for vulnerabilities
npm audit  # or pip-audit
```

---

## Troubleshooting

### Common Issues

#### Development Server Won't Start

**Check:**
- Port not already in use
- Environment variables configured
- Dependencies installed
- Database running

#### Tests Failing

**Check:**
- Test database configured
- Mock data setup correctly
- Async operations properly awaited
- Test isolation (no shared state)

#### Claude Code Not Working

**Check:**
- MCP servers configured correctly (`claude mcp list`, `/mcp`)
- Environment variables set
- `permissions.deny` rules in `.claude/settings.json` not blocking needed files
- Project structure matches CLAUDE.md
- Run `/doctor` for a setup checkup, or `claude --safe-mode` to rule out customizations

---

## Resources

### Documentation
- [Project Documentation](docs/)
- [API Reference](docs/api/)
- [Architecture Guide](docs/architecture.md)

### External Resources
- Technology Stack Docs: `<add link>`
- Best Practices: `<add link>`
- Security Guidelines: `<add link>`

### Team Resources
- Team Wiki: `<add link>`
- Runbooks: `<add link>`
- On-Call Guide: `<add link>`

---

## Contact

- **Project Lead**: Name (email@example.com)
- **Team**: team@example.com
- **Issues**: https://github.com/org/project/issues
- **Discussions**: https://github.com/org/project/discussions

---

## Notes for Claude Code

### Preferences

**When generating code:**
- Use type hints/strict typing
- Include comprehensive error handling
- Add docstrings/JSDoc comments
- Follow project style guide
- Write tests alongside implementation

**When making changes:**
- Explain what and why
- Consider backward compatibility
- Update related documentation
- Run tests before finalizing

**When debugging:**
- Read relevant code first
- Check logs and error messages
- Consider edge cases
- Propose multiple solutions if applicable

### Project-Specific Conventions

**Database Queries:**
- Always use parameterized queries
- Handle connection errors
- Use transactions for multi-step operations

**API Endpoints:**
- Use consistent error response format
- Include request validation
- Add rate limiting to public endpoints
- Document all endpoints in OpenAPI/Swagger

**File Operations:**
- Use async I/O when possible
- Handle file not found errors
- Validate file paths
- Clean up resources (use context managers)

---

## Changelog

### Version 1.0.2 (2026-10-21)
- Replaced archived/nonexistent MCP packages (`@modelcontextprotocol/server-github`, `server-postgres`, the fabricated `--memory-path` flag, unpublished QA servers); added the AGENTS.md import pattern and size guidance; removed `/agents` management reference (that UI was removed in v2.1.198)

### Version 1.0.1 (2026-06-11)
- Updated Claude Code integration details (MCP config in `.mcp.json`, agents in `.claude/agents/`, `permissions.deny` for file exclusions)

### Version 1.0.0 (2025-11-04)
- Initial project setup
- Core functionality implemented
- Documentation created

---

**Last Updated**: 2026-10-21

**Claude Code Compatible**: ✅ Yes

**AGENTS.md**: See [AGENTS.md](AGENTS.md) for shared agent instructions
