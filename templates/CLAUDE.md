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
│   ├── skills/           # Custom skills
│   └── hooks/            # Event hooks
├── CLAUDE.md             # This file
├── AGENTS.md             # Multi-agent configuration
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

**Essential:**
- `@modelcontextprotocol/server-github` - Repository management
- `@modelcontextprotocol/server-filesystem` - File operations
- `@modelcontextprotocol/server-memory` - State persistence

**Recommended:**
- `@modelcontextprotocol/server-postgres` - Database access (if using PostgreSQL)
- `@mojoatomic/quality-guard-mcp` - Code quality checks
- `@MarcusJellinghaus/mcp-code-checker` - Testing integration

**Optional:**
- `@containers/kubernetes-mcp-server` - K8s management (if using Kubernetes)
- Docker MCP - Container operations

### MCP Configuration

**Location**: `~/.config/claude-code/mcp.json`

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/this/project"
      ]
    },
    "memory": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-memory",
        "--memory-path",
        "/path/to/this/project/.claude/memory"
      ]
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

**Available Skills:**

1. **code-validator** - Automated code quality checks
   ```
   "Run the code-validator skill"
   ```

2. **test-generator** - Generate test suites
   ```
   "Use test-generator for the API module"
   ```

3. **documentation-writer** - Generate documentation
   ```
   "Run documentation-writer on the services directory"
   ```

**Custom Skills**: See `.claude/skills/` directory

---

## Multi-Agent Orchestration

### Available Agents

See [AGENTS.md](AGENTS.md) for detailed agent definitions.

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
- MCP servers configured correctly
- Environment variables set
- `.claudeignore` not excluding needed files
- Project structure matches CLAUDE.md

---

## Resources

### Documentation
- [Project Documentation](docs/)
- [API Reference](docs/api/)
- [Architecture Guide](docs/architecture.md)

### External Resources
- [Technology Stack Docs](#)
- [Best Practices](#)
- [Security Guidelines](#)

### Team Resources
- [Team Wiki](#)
- [Runbooks](#)
- [On-Call Guide](#)

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

### Version 1.0.0 (2025-11-04)
- Initial project setup
- Core functionality implemented
- Documentation created

---

**Last Updated**: 2025-11-04

**Claude Code Compatible**: ✅ Yes

**AGENTS.md**: See [AGENTS.md](AGENTS.md) for multi-agent configuration
