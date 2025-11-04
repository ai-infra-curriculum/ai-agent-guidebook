# Contributing to AI Agent Guidebook

Thank you for your interest in contributing to the AI Agent Guidebook! This document provides guidelines and instructions for contributing to this project.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Getting Started](#getting-started)
- [Contribution Guidelines](#contribution-guidelines)
- [Style Guidelines](#style-guidelines)
- [Submitting Contributions](#submitting-contributions)
- [Review Process](#review-process)

---

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to ai-infra-curriculum@joshua-ferguson.com.

---

## How Can I Contribute?

### 1. Improve Documentation

**Add or expand guides:**
- Create new guides for AI coding tools
- Expand existing guides with more details
- Add troubleshooting sections
- Include real-world examples

**Improve clarity:**
- Fix typos and grammar
- Clarify confusing sections
- Add diagrams and visuals
- Improve code examples

### 2. Share Examples

**Real-world use cases:**
- Share how you use Claude Code, Copilot, or Gemini CLI
- Contribute workflow examples
- Add case studies
- Document best practices from experience

**Code examples:**
- Add working code examples
- Contribute project templates
- Share configuration files
- Document integration patterns

### 3. Create Templates

**Project templates:**
- CLAUDE.md examples for different project types
- AGENTS.md configurations for various workflows
- MCP server configurations
- CI/CD templates

**Workflow templates:**
- Multi-agent orchestration patterns
- Testing strategies
- Deployment workflows
- Documentation generation

### 4. Document MCP Servers

**Add to catalog:**
- Document new MCP servers
- Provide installation instructions
- Share configuration examples
- Describe use cases

**Create guides:**
- Write tutorials for MCP servers
- Document integration patterns
- Share troubleshooting tips

### 5. Share Claude Skills

**Contribute skills:**
- Share reusable Claude Skills
- Document skill usage
- Provide configuration examples
- Share skill templates

### 6. Report Issues

**Bug reports:**
- Documentation errors
- Broken links
- Outdated information
- Code example issues

**Enhancement requests:**
- New features to document
- Additional tools to cover
- New comparison dimensions
- Suggested improvements

---

## Getting Started

### Fork and Clone

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/ai-agent-guidebook.git
   cd ai-agent-guidebook
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/ai-infra-curriculum/ai-agent-guidebook.git
   ```

### Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b docs/documentation-improvement
# or
git checkout -b fix/bug-description
```

**Branch naming conventions:**
- `feature/` - New features or content
- `docs/` - Documentation improvements
- `fix/` - Bug fixes
- `example/` - New examples
- `template/` - New templates

---

## Contribution Guidelines

### Documentation Guidelines

**Markdown formatting:**
- Use ATX-style headers (`#`, `##`, `###`)
- Include blank lines around headers
- Use fenced code blocks with language identifiers
- Use relative links for internal references

**Content structure:**
- Start with overview/introduction
- Include table of contents for long documents
- Use descriptive headers
- Include examples and code snippets
- End with resources or next steps

**Code examples:**
- Test all code examples
- Include necessary imports and setup
- Add comments explaining key concepts
- Provide complete, runnable examples
- Include error handling where appropriate

**Writing style:**
- Use clear, concise language
- Write in second person ("you") for instructions
- Use active voice
- Be specific and actionable
- Avoid jargon without explanation

### File Organization

**Guide structure:**
```
guides/
├── tool-name/
│   ├── README.md           # Main guide
│   ├── installation.md     # Setup instructions
│   ├── usage.md            # Usage guide
│   ├── advanced.md         # Advanced topics
│   └── troubleshooting.md  # Common issues
```

**Template structure:**
```
templates/
├── template-name/
│   ├── README.md           # Template documentation
│   ├── template-file.md    # Actual template
│   └── example/            # Example usage
```

**Example structure:**
```
examples/
├── example-name/
│   ├── README.md           # Example overview
│   ├── src/                # Source code
│   ├── docs/               # Documentation
│   └── .env.example        # Configuration template
```

### Content Guidelines

**Accuracy:**
- Verify information against official sources
- Test all code examples
- Keep information up-to-date
- Link to authoritative documentation

**Completeness:**
- Cover prerequisites
- Include setup instructions
- Provide working examples
- List known limitations
- Add troubleshooting section

**Clarity:**
- Use clear examples
- Explain complex concepts
- Include visual aids where helpful
- Provide context and rationale

### AI-Generated Content

This repository accepts AI-generated contributions, but with requirements:

**Required:**
- Review and verify all AI-generated content
- Test code examples thoroughly
- Ensure accuracy against official sources
- Disclose AI generation in commit message (optional but encouraged)

**Best practices:**
- Use AI to draft, but human-review before submission
- Fact-check technical details
- Validate code examples
- Ensure examples follow best practices

---

## Style Guidelines

### Markdown Style

**Headers:**
```markdown
# H1 - Document Title

## H2 - Major Section

### H3 - Subsection

#### H4 - Sub-subsection
```

**Code blocks:**
````markdown
```language
code here
```
````

**Lists:**
```markdown
- Unordered list item
- Another item

1. Ordered list item
2. Another item
```

**Links:**
```markdown
[Link text](url)
[Internal link](../path/to/file.md)
[Reference-style link][ref-id]

[ref-id]: url
```

**Emphasis:**
```markdown
**Bold text**
*Italic text*
`Code inline`
```

### Code Style

**Bash/Shell:**
```bash
# Use comments to explain commands
command --flag value

# Use long-form flags for clarity
git commit --message "Clear message"
```

**Python:**
```python
# Use type hints
def function_name(param: str) -> bool:
    """Docstring with description."""
    return True

# Follow PEP 8
```

**JavaScript/TypeScript:**
```typescript
// Use clear variable names
function functionName(param: string): boolean {
  // Comment for complex logic
  return true;
}
```

---

## Submitting Contributions

### Before Submitting

**Checklist:**
- [ ] Read [Code of Conduct](CODE_OF_CONDUCT.md)
- [ ] Check for existing issues or PRs
- [ ] Test all code examples
- [ ] Verify links work
- [ ] Follow style guidelines
- [ ] Update table of contents if needed
- [ ] Add yourself to contributors (optional)

### Commit Messages

**Format:**
```
Short summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain what and why, not how.

- Bullet points are okay
- Use imperative mood ("Add feature" not "Added feature")

Closes #123
```

**Examples:**
```
Add Gemini CLI installation guide

Create comprehensive guide for installing and configuring Gemini CLI
including prerequisites, installation steps, and initial setup.

Closes #45
```

```
Fix broken links in MCP server catalog

Update links to MCP server repositories that have moved.
Verify all links are working.

Fixes #67
```

### Pull Request Process

1. **Update from upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create Pull Request**:
   - Go to the repository on GitHub
   - Click "New Pull Request"
   - Select your branch
   - Fill out PR template

4. **PR Title**: Clear, descriptive title
   ```
   Add comprehensive Gemini CLI guide
   Fix broken links in MCP catalog
   Update Claude Code advanced usage examples
   ```

5. **PR Description**: Include:
   - What changed
   - Why the change was made
   - How to test (if applicable)
   - Related issues
   - Screenshots (if visual changes)

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Documentation update
- [ ] New guide or example
- [ ] Bug fix (broken link, typo, etc.)
- [ ] Template addition
- [ ] Other (please describe)

## Checklist
- [ ] All code examples tested
- [ ] Links verified
- [ ] Style guidelines followed
- [ ] No typos or grammar errors
- [ ] Table of contents updated (if needed)

## Related Issues
Closes #(issue number)

## Additional Notes
Any additional context or information
```

---

## Review Process

### What We Look For

**Content quality:**
- Accuracy and correctness
- Clarity and completeness
- Proper formatting
- Working examples

**Code quality:**
- Examples work as written
- Follow best practices
- Include error handling
- Have clear comments

**Documentation quality:**
- Clear explanations
- Logical organization
- Proper grammar and spelling
- Consistent style

### Timeline

- **Initial review**: Within 3-5 days
- **Follow-up**: 1-2 days for responses
- **Merge**: After approval and any requested changes

### After Your PR

**If changes requested:**
1. Make the requested changes
2. Commit and push to your branch
3. PR automatically updates
4. Respond to reviewer comments

**After merge:**
- Your contribution is live!
- Delete your branch (optional)
- Update from upstream for next contribution

---

## Recognition

Contributors are recognized in several ways:

1. **GitHub Insights**: Your contributions appear in repository insights
2. **Release Notes**: Significant contributions mentioned in CHANGELOG.md
3. **Contributors List**: Optional self-addition to contributors section

---

## Questions?

**Need help?**
- Open an issue with your question
- Email: ai-infra-curriculum@joshua-ferguson.com
- Check existing issues and discussions

**Have suggestions?**
- Open an issue with "enhancement" label
- Start a discussion on GitHub
- Submit a PR with your idea

---

## Resources

**Learning Markdown:**
- [Markdown Guide](https://www.markdownguide.org/)
- [GitHub Flavored Markdown](https://github.github.com/gfm/)

**Git and GitHub:**
- [GitHub Docs](https://docs.github.com/)
- [Git Book](https://git-scm.com/book/en/v2)

**Contributing to Open Source:**
- [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/)
- [First Contributions](https://github.com/firstcontributions/first-contributions)

---

Thank you for contributing to the AI Agent Guidebook! Your contributions help developers worldwide work more effectively with AI coding assistants.

**Questions?** Feel free to ask by opening an issue or starting a discussion!
