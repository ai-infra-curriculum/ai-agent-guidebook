# Security Policy

## Reporting a Vulnerability

The AI Agent Guidebook project takes security seriously. We appreciate your efforts to responsibly disclose any security vulnerabilities you find.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by emailing:

📧 **ai-infra-curriculum@joshua-ferguson.com**

Include the following information:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### What to Expect

1. **Acknowledgment**: We'll acknowledge receipt within 48 hours
2. **Assessment**: We'll assess the vulnerability and determine severity
3. **Updates**: We'll keep you informed of our progress
4. **Resolution**: We'll work on a fix and coordinate disclosure
5. **Credit**: We'll credit you for the discovery (unless you prefer to remain anonymous)

### Response Timeline

- **Critical vulnerabilities**: Addressed within 24-48 hours
- **High severity**: Addressed within 1 week
- **Medium severity**: Addressed within 2 weeks
- **Low severity**: Addressed in next regular release

---

## Scope

### In Scope

This repository primarily contains documentation and templates. Security concerns include:

**Documentation Security:**
- Insecure code examples
- Vulnerable configuration recommendations
- Exposure of sensitive information patterns
- Misleading security guidance

**Template Security:**
- Insecure default configurations
- Missing security best practices
- Vulnerable code patterns in templates

**Repository Security:**
- Compromised dependencies (if any)
- Malicious contributions
- Social engineering attempts

### Out of Scope

The following are generally out of scope:
- Vulnerabilities in third-party tools documented (Claude Code, GitHub Copilot, etc.)
- Issues with MCP servers themselves (report to their maintainers)
- General questions or feature requests

---

## Security Best Practices

### For Users of This Repository

**When Using Templates:**
- ✅ Review all templates before using in production
- ✅ Update placeholder credentials and secrets
- ✅ Follow security best practices for your specific use case
- ✅ Keep dependencies up to date
- ✅ Never commit secrets or credentials

**When Using Code Examples:**
- ✅ Review code for security issues before using
- ✅ Validate inputs appropriately
- ✅ Use parameterized queries for databases
- ✅ Implement proper authentication and authorization
- ✅ Follow OWASP guidelines

**When Using AI Assistants:**
- ✅ Review all AI-generated code before using
- ✅ Don't trust AI suggestions for security-critical code without verification
- ✅ Validate AI suggestions against security best practices
- ✅ Never share sensitive data with AI assistants
- ✅ Use local models for sensitive code when possible

### For Contributors

**When Contributing:**
- ✅ Don't include real credentials or secrets in examples
- ✅ Use placeholder values (e.g., `your_api_key_here`)
- ✅ Review code examples for common vulnerabilities:
  - SQL injection
  - Command injection
  - Path traversal
  - XSS (if applicable)
  - Insecure deserialization
  - Missing authentication/authorization
- ✅ Follow secure coding practices
- ✅ Include security considerations in documentation

---

## Common Security Considerations

### AI-Generated Code

**Risks:**
- AI may generate insecure code
- AI may miss security edge cases
- AI may use outdated security practices
- AI may expose sensitive patterns

**Mitigations:**
- Always review AI-generated code
- Test for common vulnerabilities
- Validate against security checklist
- Use security scanning tools
- Have security expert review critical code

### MCP Servers

**Risks:**
- MCP servers have broad access to your system
- Malicious MCP servers could compromise your data
- MCP servers may have vulnerabilities

**Mitigations:**
- Only use MCP servers from trusted sources
- Review MCP server code before installing
- Use principle of least privilege
- Monitor MCP server activity
- Keep MCP servers updated

### Secrets Management

**Never commit:**
- API keys
- Passwords
- Private keys
- OAuth tokens
- Database credentials
- Any sensitive information

**Instead:**
- Use environment variables
- Use secret management tools (Vault, AWS Secrets Manager, etc.)
- Use `.env` files (and add to `.gitignore`)
- Use GitHub Secrets for CI/CD
- Rotate credentials regularly

### Template Security

**When using CLAUDE.md or AGENTS.md:**
- Replace all placeholder credentials
- Review and customize security settings
- Don't use default/example values in production
- Follow security best practices for your tech stack
- Implement proper access controls

---

## Security Checklist

### For Code Examples

- [ ] No hardcoded credentials
- [ ] Input validation implemented
- [ ] SQL injection prevention (parameterized queries)
- [ ] Command injection prevention
- [ ] XSS prevention (if web-related)
- [ ] Proper error handling (no sensitive info in errors)
- [ ] Authentication and authorization implemented
- [ ] HTTPS/TLS for sensitive communications
- [ ] Secure session management
- [ ] CSRF protection (if web-related)

### For Configuration Examples

- [ ] Secure defaults used
- [ ] Placeholder values for secrets
- [ ] Comments explaining security considerations
- [ ] Principle of least privilege applied
- [ ] Security features enabled
- [ ] Dangerous features disabled or documented

### For Documentation

- [ ] Security warnings where appropriate
- [ ] Best practices highlighted
- [ ] Common pitfalls documented
- [ ] Links to security resources
- [ ] Up-to-date security guidance

---

## Security Resources

### OWASP Resources
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)

### AI Security
- [OWASP Machine Learning Security Top 10](https://owasp.org/www-project-machine-learning-security-top-10/)
- [OWASP LLM Top 10](https://owasp.org/www-project-top-10-for-large-language-model-applications/)

### General Security
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

### Secure Coding
- [CERT Secure Coding Standards](https://wiki.sei.cmu.edu/confluence/display/seccode)
- [Google Security Best Practices](https://cloud.google.com/security/best-practices)

---

## Vulnerability Disclosure Policy

### Our Commitments

We commit to:
- Respond to vulnerability reports promptly
- Keep you informed throughout the process
- Work with you to understand and resolve the issue
- Publicly acknowledge your responsible disclosure (if desired)
- Not take legal action against researchers who:
  - Act in good faith
  - Follow this policy
  - Don't access or modify data beyond what's necessary to demonstrate the vulnerability

### Your Responsibilities

When researching vulnerabilities, please:
- Act in good faith
- Don't access or modify other users' data
- Don't perform attacks that could harm availability
- Don't publicly disclose the vulnerability before we've addressed it
- Give us reasonable time to fix the issue before public disclosure
- Don't use vulnerabilities for personal gain

---

## Security Updates

Security updates will be:
- Released as soon as possible after discovery
- Documented in [CHANGELOG.md](CHANGELOG.md)
- Announced via GitHub releases
- Communicated to affected users when possible

Subscribe to repository notifications to stay informed about security updates.

---

## Questions?

For security questions that aren't vulnerabilities, you can:
- Open a public issue (for general security questions)
- Email ai-infra-curriculum@joshua-ferguson.com
- Start a discussion on GitHub

---

**Thank you for helping keep the AI Agent Guidebook and its users safe!**

Last updated: 2025-11-04
