# MCP Server Catalog

Comprehensive catalog of Model Context Protocol (MCP) servers for extending Claude Code and other AI assistants.

---

## Table of Contents

- [Development](#development)
- [Databases](#databases)
- [Infrastructure](#infrastructure)
- [Quality & Testing](#quality--testing)
- [Documentation](#documentation)
- [Web & APIs](#web--apis)
- [Productivity](#productivity)
- [Cloud Services](#cloud-services)
- [Communication](#communication)
- [Data & Analytics](#data--analytics)

---

## Development

### GitHub MCP
**Package**: `@modelcontextprotocol/server-github`

**Features**:
- Create and manage repositories
- Issues and pull requests
- GitHub Actions workflows
- Repository content operations

**Installation**:
```json
{
  "github": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {"GITHUB_TOKEN": "${GITHUB_TOKEN}"}
  }
}
```

**Use Cases**:
- Automated repository creation
- Issue management
- PR workflows
- Code review automation

---

### Filesystem MCP
**Package**: `@modelcontextprotocol/server-filesystem`

**Features**:
- Enhanced file operations
- Directory management
- Bulk operations
- Access control

**Installation**:
```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/project"]
  }
}
```

**Use Cases**:
- Complex file operations
- Multi-file edits
- Directory restructuring

---

### Git MCP
**Package**: `@modelcontextprotocol/server-git`

**Features**:
- Git operations
- Branch management
- Commit history
- Repository status

**Installation**:
```json
{
  "git": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-git", "/path/to/repo"]
  }
}
```

---

### Memory MCP
**Package**: `@modelcontextprotocol/server-memory`

**Features**:
- Knowledge graph persistence
- Entity and relation tracking
- Cross-session state
- Local SQLite storage

**Installation**:
```json
{
  "memory": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-memory", "--memory-path", "/path/to/memory"]
  }
}
```

**Use Cases**:
- Multi-session projects
- State persistence
- Context preservation

---

## Databases

### PostgreSQL MCP
**Package**: `@modelcontextprotocol/server-postgres`

**Features**:
- Execute SQL queries
- Schema inspection
- Data manipulation
- Connection pooling

**Installation**:
```json
{
  "postgres": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-postgres"],
    "env": {"POSTGRES_CONNECTION_STRING": "${POSTGRES_CONNECTION_STRING}"}
  }
}
```

---

### SQLite MCP
**Package**: `@modelcontextprotocol/server-sqlite`

**Features**:
- SQLite database operations
- Local data storage
- Query execution
- Schema management

**Installation**:
```json
{
  "sqlite": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-sqlite", "/path/to/database.db"]
  }
}
```

---

### MongoDB MCP
**Package**: `@drewj/mongodb-mcp-server`

**Features**:
- MongoDB operations
- Document queries
- Collection management
- Aggregation pipelines

**Installation**:
```bash
npm install -g @drewj/mongodb-mcp-server
```

---

## Infrastructure

### Kubernetes MCP
**Package**: `@containers/kubernetes-mcp-server`

**Features**:
- kubectl operations
- Resource management
- Helm charts
- Pod operations
- Deployment management

**Installation**:
```json
{
  "kubernetes": {
    "command": "docker",
    "args": ["run", "-i", "--rm", "-v", "~/.kube:/home/mcp/.kube",
             "quay.io/containers/kubernetes-mcp-server"]
  }
}
```

**Use Cases**:
- K8s resource creation
- Cluster management
- Deployment automation

---

### Docker MCP
**Package**: Various Docker MCP implementations

**Features**:
- Container operations
- Image management
- Docker Compose
- Network management

**Use Cases**:
- Container orchestration
- Image building
- Development environments

---

### Terraform MCP
**Package**: `@ianmacartney/mcp-server-terraform`

**Features**:
- Terraform plan/apply
- State management
- Resource inspection
- Module operations

**Use Cases**:
- Infrastructure as Code
- Cloud provisioning
- Resource management

---

## Quality & Testing

### Quality Guard MCP
**Package**: `@mojoatomic/quality-guard-mcp`

**Features**:
- Automated formatting
- Linting
- Security scanning
- Test coverage
- Pre-commit hooks

**Installation**:
```json
{
  "quality-guard": {
    "command": "npx",
    "args": ["-y", "@mojoatomic/quality-guard-mcp"]
  }
}
```

**Use Cases**:
- Code quality enforcement
- CI/CD integration
- Automated validation

---

### MCP Code Checker
**Package**: `@MarcusJellinghaus/mcp-code-checker`

**Features**:
- Pylint integration
- Pytest execution
- LLM-friendly output
- Python code analysis

**Installation**:
```bash
npm install -g @MarcusJellinghaus/mcp-code-checker
```

---

### Ruff MCP Server
**Package**: `@drewsonne/ruff-mcp-server`

**Features**:
- Fast Python linting
- Code formatting
- Import sorting
- Rule configuration

**Installation**:
```json
{
  "ruff": {
    "command": "npx",
    "args": ["-y", "@drewsonne/ruff-mcp-server"]
  }
}
```

---

### MCP Server Analyzer
**Package**: `@Anselmoo/mcp-server-analyzer`

**Features**:
- RUFF linting
- VULTURE dead code detection
- Code metrics
- Quality reports

---

## Documentation

### Mintlify Documentation MCP
**Package**: Mintlify MCP server

**Features**:
- Automated doc generation
- API documentation
- Code examples
- Markdown conversion

**Use Cases**:
- API docs
- User guides
- Technical documentation

---

### MarkItDown MCP (Microsoft)
**Package**: Microsoft's MarkItDown

**Features**:
- Multi-format conversion
- PDF to Markdown
- Office docs to Markdown
- Image extraction

**Use Cases**:
- Document conversion
- Content migration
- Documentation pipeline

---

### MCP Documentation Service
**Package**: `@alekspetrov/mcp-docs-service`

**Features**:
- Markdown management
- Frontmatter metadata
- Navigation generation
- Documentation aggregation

---

## Web & APIs

### Puppeteer MCP
**Package**: `@modelcontextprotocol/server-puppeteer`

**Features**:
- Web automation
- Screenshot capture
- Form filling
- Web scraping

**Installation**:
```json
{
  "puppeteer": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
  }
}
```

**Use Cases**:
- Web testing
- Data extraction
- Browser automation

---

### Brave Search MCP
**Package**: `@modelcontextprotocol/server-brave-search`

**Features**:
- Web search API
- Local search
- Image search
- News search

**Installation**:
```json
{
  "brave-search": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-brave-search"],
    "env": {"BRAVE_API_KEY": "${BRAVE_API_KEY}"}
  }
}
```

---

### Fetch MCP
**Package**: `@modelcontextprotocol/server-fetch`

**Features**:
- HTTP requests
- API calls
- Content fetching
- Response processing

**Use Cases**:
- API integration
- Web content retrieval
- Data fetching

---

### Context7 MCP
**Package**: Context7 documentation server

**Features**:
- Up-to-date library docs
- API references
- Code examples
- Version-specific docs

**Use Cases**:
- Library documentation
- API research
- Code examples

---

## Cloud Services

### AWS MCP
**Package**: AWS MCP implementations

**Features**:
- S3 operations
- Lambda functions
- CloudFormation
- EC2 management

**Use Cases**:
- Cloud deployments
- Resource management
- Infrastructure automation

---

### Google Cloud MCP
**Package**: GCP MCP servers

**Features**:
- GCS operations
- Compute Engine
- Cloud Functions
- BigQuery

---

### Azure MCP
**Package**: Azure MCP implementations

**Features**:
- Blob storage
- Azure Functions
- App Service
- Resource management

---

## Communication

### Slack MCP
**Package**: `@modelcontextprotocol/server-slack`

**Features**:
- Send messages
- Channel operations
- User management
- File uploads

**Installation**:
```json
{
  "slack": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-slack"],
    "env": {"SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}"}
  }
}
```

---

### Discord MCP
**Package**: Discord MCP implementations

**Features**:
- Bot operations
- Message sending
- Channel management
- User interactions

---

## Data & Analytics

### Pandas MCP
**Package**: Pandas MCP server

**Features**:
- DataFrame operations
- Data analysis
- CSV/Excel processing
- Statistical operations

**Use Cases**:
- Data processing
- Analysis automation
- Report generation

---

### Jupyter MCP
**Package**: Jupyter MCP implementations

**Features**:
- Notebook execution
- Kernel management
- Cell operations
- Output capture

---

## Installation Guide

### Quick Setup

1. **Create MCP config**: `~/.config/claude-code/mcp.json`

2. **Add servers**:
```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name"],
      "env": {"KEY": "value"}
    }
  }
}
```

3. **Set environment variables**: `~/.config/claude-code/.env`
```bash
GITHUB_TOKEN=xxx
BRAVE_API_KEY=xxx
```

4. **Restart Claude Code**

### Testing Installation

```bash
# Claude Code will automatically test servers on startup
# Check logs for errors
```

---

## Configuration Examples

### Complete Development Setup

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {"GITHUB_TOKEN": "${GITHUB_TOKEN}"}
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/projects"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory", "--memory-path", "/path/to/memory"]
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {"POSTGRES_CONNECTION_STRING": "${POSTGRES_CONNECTION_STRING}"}
    },
    "quality-guard": {
      "command": "npx",
      "args": ["-y", "@mojoatomic/quality-guard-mcp"]
    }
  }
}
```

---

## Resources

- **Official Servers**: https://github.com/modelcontextprotocol/servers
- **Awesome MCP**: https://github.com/wong2/awesome-mcp-servers
- **MCP Directory**: https://mcpservers.org/
- **MCP Spec**: https://spec.modelcontextprotocol.io/

---

## Contributing

Submit your MCP server to the community:
1. Publish to npm
2. Add to Awesome MCP Servers
3. Submit to MCP Directory
4. Share in community discussions

---

**Last Updated**: 2025-11-04

**Total Servers**: 50+ and growing
