# Prompting Best Practices

Effective prompting strategies for AI coding assistants to get better results.

---

## Table of Contents

- [Core Principles](#core-principles)
- [Prompt Structure](#prompt-structure)
- [Specificity](#specificity)
- [Context Provision](#context-provision)
- [Tool-Specific Strategies](#tool-specific-strategies)
- [Common Patterns](#common-patterns)
- [Anti-Patterns](#anti-patterns)
- [Advanced Techniques](#advanced-techniques)

---

## Core Principles

### 1. Be Specific and Clear

❌ **Vague:**
```
"Fix the bug"
```

✅ **Specific:**
```
"Fix the null pointer exception in UserService.getUser() at line 45 that occurs
when the database returns no results"
```

### 2. Provide Context

❌ **No context:**
```
"Add authentication"
```

✅ **With context:**
```
"Add JWT-based authentication to this NestJS API. We're using TypeORM for the
database and need to support both access and refresh tokens. Follow the existing
error handling patterns in src/common/filters/"
```

### 3. Break Down Complex Tasks

❌ **Too complex:**
```
"Build a complete authentication system with OAuth, 2FA, password reset,
email verification, and role-based access control"
```

✅ **Broken down:**
```
"Let's implement authentication in phases:
1. First, set up basic JWT authentication with login/register
2. Then add refresh token rotation
3. Next, implement password reset via email
4. Then add email verification
5. Add OAuth providers (Google, GitHub)
6. Finally, implement 2FA and RBAC"
```

### 4. Specify Expected Output

❌ **Unclear expectations:**
```
"Create a user model"
```

✅ **Clear expectations:**
```
"Create a User model with:
- TypeScript interface with strict typing
- Fields: id, email, passwordHash, createdAt, updatedAt
- Validation using class-validator decorators
- Methods: validatePassword(), hashPassword()
- Include JSDoc comments
- Export as both interface and class"
```

---

## Prompt Structure

### Effective Prompt Template

```
[Context] + [Specific Task] + [Constraints] + [Expected Output]
```

**Example:**
```
Context: We're building a REST API with Express and TypeORM for a task management app

Task: Implement the Task entity with CRUD endpoints

Constraints:
- Use TypeScript with strict mode
- Follow existing code patterns in src/entities/User.ts
- Include proper error handling
- Add input validation
- Write unit tests

Expected Output:
- Task entity class
- Task controller with CRUD operations
- Task service layer
- Unit tests with >80% coverage
- API documentation comments
```

---

## Specificity

### File References

✅ **Specific file references:**
```
"Refactor the authentication logic in src/services/auth.service.ts:45-120
to use dependency injection"
```

### Code Snippets

✅ **Include relevant code:**
```
"Fix this function:

```python
def calculate_total(items):
    return sum([item.price for item in items])
```

It crashes when items is None. Add proper error handling and type hints."
```

### Requirements

✅ **Explicit requirements:**
```
"Create a caching layer with these requirements:
- Use Redis for storage
- Support TTL configuration
- Implement cache invalidation
- Add cache hit/miss metrics
- Handle Redis connection failures gracefully
- Include integration tests"
```

---

## Context Provision

### Project Context

```
"This is a microservices project using:
- Node.js 18 with TypeScript
- NestJS framework
- PostgreSQL database with TypeORM
- Redis for caching
- Docker for containerization
- Jest for testing

We follow:
- Clean architecture principles
- Repository pattern for data access
- Dependency injection throughout
- Comprehensive error handling"
```

### Domain Context

```
"We're building an e-commerce platform. A 'Cart' contains 'CartItems',
each referencing a 'Product'. When checking out:
1. Validate inventory availability
2. Calculate totals with discounts
3. Process payment
4. Create Order
5. Update inventory
6. Send confirmation email"
```

### Technical Context

```
"Our current authentication uses:
- JWT tokens stored in HttpOnly cookies
- Refresh token rotation
- CSRF protection
- Rate limiting on login endpoint
- Password hashing with bcrypt (12 rounds)

We need to add OAuth without breaking existing auth."
```

---

## Tool-Specific Strategies

### Claude Code

**Leverage multi-agent capabilities:**
```
"Use a multi-agent approach:
1. research-agent: Analyze best practices for rate limiting
2. architecture-agent: Design the rate limiting system
3. coding-agent: Implement the rate limiter
4. testing-agent: Create comprehensive tests
5. qa-agent: Review for security issues"
```

**Use MCP servers explicitly:**
```
"Using the PostgreSQL MCP server, query the users table to find all accounts
created in the last 30 days with more than 100 API requests"
```

### GitHub Copilot

**Use comments for context:**
```python
# Function to validate email addresses using regex
# Should support international domains
# Return tuple of (is_valid, error_message)
def validate_email(email: str) -> tuple[bool, str]:
```

**Descriptive variable names:**
```typescript
// Good - Copilot understands intent
const userAuthenticationToken = ...

// Less effective
const token = ...
```

### Gemini CLI

**Leverage large context:**
```
"Analyze this entire codebase (50k lines) and identify:
1. All database query patterns
2. Potential N+1 query issues
3. Missing indexes
4. Query optimization opportunities

[Paste entire codebase]"
```

**Use for complex analysis:**
```
"Compare these two architectural approaches for our microservices:

Approach A: Event-driven with message queue
[details...]

Approach B: RESTful with API gateway
[details...]

Provide detailed trade-off analysis considering:
- Scalability
- Maintainability
- Performance
- Complexity
- Team expertise required"
```

---

## Common Patterns

### Code Generation

```
"Generate a [language] [component type] that:
- [Functionality 1]
- [Functionality 2]
- [Functionality 3]
Following [style guide/patterns]
Include [tests/docs/examples]"
```

**Example:**
```
"Generate a Python class that:
- Implements a connection pool for PostgreSQL
- Supports configurable min/max connections
- Includes connection health checks
- Has retry logic with exponential backoff
- Follows our existing patterns in src/db/base.py
- Include unit tests with mocks
- Add comprehensive docstrings"
```

### Code Review

```
"Review this [component] for:
- [Concern 1]
- [Concern 2]
- [Concern 3]
Provide specific suggestions with code examples"
```

**Example:**
```
"Review this authentication middleware for:
- Security vulnerabilities
- Performance issues
- Error handling gaps
- Missing edge cases
Provide specific suggestions with corrected code"
```

### Refactoring

```
"Refactor [component] to:
- [Improvement 1]
- [Improvement 2]
- [Improvement 3]
While maintaining [constraints]"
```

**Example:**
```
"Refactor UserService to:
- Use dependency injection for database access
- Separate business logic from data access
- Add proper error handling
- Improve testability
While maintaining backward compatibility with existing API"
```

### Documentation

```
"Generate [doc type] for [component] including:
- [Section 1]
- [Section 2]
- [Section 3]
Target audience: [audience]"
```

**Example:**
```
"Generate API documentation for the User endpoints including:
- Endpoint descriptions
- Request/response schemas
- Authentication requirements
- Example requests (curl)
- Possible error responses
Target audience: Frontend developers integrating with our API"
```

---

## Anti-Patterns

### ❌ Too Vague

```
"Make it better"
"Optimize this"
"Fix the issue"
```

### ❌ No Context

```
"Add logging"
// What kind? Where? What level? What format?

"Implement caching"
// What data? What cache? What TTL? What invalidation strategy?
```

### ❌ Assuming Knowledge

```
"Use the same pattern as before"
// AI doesn't remember previous sessions

"Fix it like we discussed"
// Be explicit every time
```

### ❌ Multiple Unrelated Tasks

```
"Add authentication, refactor the database layer, implement caching,
write tests, and update documentation"
// Break into separate requests
```

### ❌ Ambiguous Requirements

```
"Make it faster"
// How much faster? What's slow? What's acceptable?

"Add more validation"
// What specifically needs validation?
```

---

## Advanced Techniques

### Iterative Refinement

```
1. Initial: "Create a user authentication system"
2. Review response
3. Refine: "Add rate limiting to prevent brute force attacks"
4. Review
5. Refine: "Add account lockout after 5 failed attempts"
6. Continue refining until complete
```

### Constraint-Based Prompting

```
"Implement X with these constraints:
- Must not use library Y (due to licensing)
- Must support Node.js 14+ (our deployment target)
- Must have <100ms p99 latency
- Must be backwards compatible with v1 API
- Must follow our error handling conventions"
```

### Example-Driven Prompting

```
"Implement a similar function to this existing one:

[paste example]

But for processing CSV files instead of JSON.
Maintain the same error handling, logging, and structure."
```

### Role-Based Prompting

```
"Acting as a security expert, review this authentication code and identify
vulnerabilities following OWASP Top 10 guidelines."

"As a performance engineer, analyze this database query and suggest
optimizations for handling 1M+ records."
```

### Chain of Thought

```
"Let's implement user registration step by step:

Step 1: Design the database schema
- What fields do we need?
- What constraints?
- What indexes?

[Review]

Step 2: Create the validation logic
- What rules for email?
- Password requirements?
- Username constraints?

[Review]

Step 3: Implement the registration endpoint
..."
```

---

## Testing Your Prompts

### Checklist

Before sending a prompt, ask:

- [ ] Is it specific enough?
- [ ] Have I provided necessary context?
- [ ] Are my expectations clear?
- [ ] Have I specified constraints?
- [ ] Is it a manageable size?
- [ ] Have I included examples if needed?
- [ ] Is the desired output format clear?

### Prompt Refinement Process

1. **Start broad** - Get initial response
2. **Identify gaps** - What's missing or wrong?
3. **Add specificity** - Refine with more details
4. **Iterate** - Continue until satisfied
5. **Document** - Save effective prompts for reuse

---

## Quick Reference

### Prompt Templates

**Bug Fix:**
```
"Fix [specific issue] in [file:line]. The problem is [description].
It should [expected behavior]. Consider [constraints]."
```

**Feature Implementation:**
```
"Implement [feature] with:
- [requirement 1]
- [requirement 2]
- [requirement 3]
Following [patterns/standards]. Include [tests/docs]."
```

**Code Review:**
```
"Review [component] for:
- [aspect 1]
- [aspect 2]
- [aspect 3]
Provide specific, actionable feedback."
```

**Refactoring:**
```
"Refactor [component] to [goal] while:
- [constraint 1]
- [constraint 2]
Explain your changes."
```

---

## Resources

- [Claude Code Guide](../guides/claude-code/README.md)
- [GitHub Copilot Guide](../guides/github-copilot/README.md)
- [Context Management](context-management.md)
- [Example Workflows](../examples/)

---

**Last Updated**: 2025-11-04
