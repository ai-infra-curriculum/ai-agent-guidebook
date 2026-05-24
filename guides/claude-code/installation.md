# Installing Claude Code

Detailed installation guide for Claude Code across macOS, Linux, and Windows (WSL), including authentication setup and first-run configuration.

---

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
  - [npm (cross-platform)](#install-via-npm-cross-platform)
  - [Homebrew (macOS)](#install-via-homebrew-macos)
  - [Manual binary install](#manual-binary-install)
  - [Windows via WSL](#windows-via-wsl)
- [Verifying the Install](#verifying-the-install)
- [Authentication](#authentication)
- [First-Run Wizard](#first-run-wizard)
- [Updating Claude Code](#updating-claude-code)
- [Uninstalling](#uninstalling)
- [Common Install Issues](#common-install-issues)

---

## System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| OS | macOS 12+, Ubuntu 20.04+, Windows 10 + WSL2 | macOS 14+, Ubuntu 22.04+, Windows 11 + WSL2 |
| Node.js | 18.x | 20.x LTS or 22.x |
| RAM | 4 GB | 16 GB (for parallel agents) |
| Disk | 500 MB | 5 GB (with caches and skills) |
| Network | Outbound HTTPS to `api.anthropic.com` | Same, plus low-latency link |
| Shell | bash 4+ or zsh 5+ | zsh 5.8+ or fish 3+ |

Claude Code expects a POSIX-like environment. On Windows, native PowerShell is unsupported; use WSL2.

---

## Installation Methods

### Install via npm (cross-platform)

The npm package is the canonical distribution. It works on every supported OS and is the only path that gets same-day patch releases.

```bash
# Verify Node 18+ first
node --version

# Install globally
npm install -g @anthropic-ai/claude-code

# Or with a project-local install (preferred in monorepos)
npm install --save-dev @anthropic-ai/claude-code
npx claude-code
```

If you see `EACCES` permission errors, do not use `sudo`. Either fix your npm prefix or use a Node version manager:

```bash
# Set a user-writable prefix once
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
```

A Node version manager (recommended):

```bash
# Install fnm (fast)
curl -fsSL https://fnm.vercel.app/install | bash
fnm install 22
fnm default 22

# Or nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install 22
nvm alias default 22
```

### Install via Homebrew (macOS)

Homebrew is the lowest-friction path on macOS if you do not already manage Node yourself.

```bash
# Tap and install
brew install anthropic/claude/claude-code

# Verify
claude --version
```

The Homebrew formula pins its own Node runtime, so it will not collide with system Node or other version managers. The tradeoff: Homebrew updates lag npm by a few hours to a few days.

### Install via Bun

Bun is supported as a drop-in replacement for npm in CI and on developer machines that already use it:

```bash
bun install -g @anthropic-ai/claude-code
claude --version
```

Performance is comparable. The Bun install path is useful when you want a single runtime in CI containers.

### Manual binary install

For air-gapped environments or pinned reproducible installs, download a release tarball:

```bash
# Replace VERSION with the target release (e.g. 1.2.3)
VERSION=$(curl -fsSL https://api.github.com/repos/anthropics/claude-code/releases/latest | jq -r .tag_name)

# macOS arm64
curl -fsSL "https://github.com/anthropics/claude-code/releases/download/${VERSION}/claude-code-${VERSION}-darwin-arm64.tar.gz" -o claude-code.tar.gz

# Linux x64
curl -fsSL "https://github.com/anthropics/claude-code/releases/download/${VERSION}/claude-code-${VERSION}-linux-x64.tar.gz" -o claude-code.tar.gz

# Extract and install
tar -xzf claude-code.tar.gz
sudo mv claude-code /usr/local/bin/claude
chmod +x /usr/local/bin/claude
```

Verify the SHA-256 against the release page checksums file before installing in any environment you trust.

### Windows via WSL

Claude Code on Windows runs inside WSL2. Native Windows builds are not supported.

```powershell
# In an elevated PowerShell
wsl --install -d Ubuntu-22.04
wsl --set-default-version 2
```

Once Ubuntu is up:

```bash
# Inside the WSL shell
sudo apt update
sudo apt install -y curl git build-essential

# Install Node via fnm
curl -fsSL https://fnm.vercel.app/install | bash
exec $SHELL
fnm install 22
fnm default 22

# Install Claude Code
npm install -g @anthropic-ai/claude-code
claude --version
```

**WSL gotchas:**

- Work inside the Linux filesystem (`/home/you/...`), not `/mnt/c/...`. Filesystem I/O across the Windows/Linux boundary is 10-50x slower.
- Open VS Code with `code .` from inside the WSL shell so it attaches with the Remote-WSL extension.
- If `claude` cannot reach `api.anthropic.com`, check Windows Defender Firewall and corporate proxy settings — WSL inherits Windows network policy.

---

## Verifying the Install

```bash
claude --version
# Expected: claude-code v1.x.x

claude --help
# Should print the full command reference

# Run the built-in diagnostic
claude doctor
```

`claude doctor` checks:
- Node version and PATH
- Auth credentials present and valid
- MCP server config syntax
- Network reachability to `api.anthropic.com`
- Settings file integrity

Sample healthy output:

```
Claude Code Doctor
==================
[ok]   Node v22.5.0
[ok]   claude binary at /opt/homebrew/bin/claude
[ok]   Auth: API key present (sk-ant-***-a8f2)
[ok]   API reachable (142ms)
[ok]   Settings: ~/.claude/settings.json valid
[ok]   MCP config: 3 servers configured
[warn] Skills directory empty
```

---

## Authentication

Claude Code supports three auth flows. Pick one — do not mix.

### Option 1: claude.ai login (recommended for individuals)

If you have a Claude Pro or Max subscription, log in with your Anthropic account. Claude Code rides on the same entitlements as the web app, with no extra billing.

```bash
claude login
```

This opens a browser tab to `claude.ai/oauth/authorize`. After approval, the CLI receives a refresh token stored in:

- macOS: Keychain (`com.anthropic.claude-code`)
- Linux: `~/.config/claude-code/credentials.json` (mode 0600)
- WSL: same as Linux

To switch accounts:

```bash
claude logout
claude login
```

### Option 2: Anthropic API key (recommended for teams and CI)

Best for teams that want per-developer usage tracking, or for CI where browser flows are impossible.

```bash
# Generate at https://console.anthropic.com/settings/keys

# Per-shell
export ANTHROPIC_API_KEY="sk-ant-api03-..."

# Persistent (zsh)
echo 'export ANTHROPIC_API_KEY="sk-ant-api03-..."' >> ~/.zshrc
source ~/.zshrc

# Persistent (bash)
echo 'export ANTHROPIC_API_KEY="sk-ant-api03-..."' >> ~/.bashrc
source ~/.bashrc
```

For better hygiene, use a secret manager rather than plaintext rc files:

```bash
# macOS Keychain
security add-generic-password -s anthropic-api-key -a "$USER" -w "sk-ant-..."
export ANTHROPIC_API_KEY="$(security find-generic-password -s anthropic-api-key -w)"

# 1Password CLI
export ANTHROPIC_API_KEY="$(op read 'op://Personal/Anthropic API/credential')"

# Bitwarden CLI
export ANTHROPIC_API_KEY="$(bw get password anthropic-api-key)"
```

If both `ANTHROPIC_API_KEY` and a logged-in session are present, the env var wins.

### Option 3: Bedrock or Vertex AI

For teams that already have AWS Bedrock or Google Vertex AI commitments:

```bash
# Bedrock
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-east-1
# AWS credentials picked up from ~/.aws/credentials or instance metadata

# Vertex AI
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=us-central1
export ANTHROPIC_VERTEX_PROJECT_ID=my-gcp-project
```

The model IDs differ on these backends. Use the provider-specific names in any `--model` flags (for example `anthropic.claude-opus-4-7-v1:0` on Bedrock).

---

## First-Run Wizard

On first invocation, `claude` walks through a short setup wizard:

```bash
claude
```

You will be asked:

1. **Theme** — dark (default), light, or no-color (for terminals without truecolor).
2. **Default model** — Sonnet 4.6 is the right choice for almost all users. Opt for Opus 4.7 only if you frequently do deep architecture work and accept the cost. Haiku 4.5 is appropriate for high-volume agent fleets.
3. **Permission mode** — `ask` (prompt on every tool call), `accept-edits` (auto-allow file edits but prompt on Bash), or `plan` (read-only exploration with explicit promotion to write). Start with `ask`; relax later.
4. **Telemetry** — anonymous usage telemetry. Off by default in enterprise installs; opt-in elsewhere.
5. **MCP servers** — skip during first run; add later with `/mcp` or by editing config.

Settings written to `~/.claude/settings.json`:

```json
{
  "theme": "dark",
  "model": "claude-sonnet-4-6",
  "permissionMode": "ask",
  "telemetry": false,
  "editor": "$EDITOR",
  "alwaysThinkingEnabled": true
}
```

After the wizard you land in the interactive prompt. Useful first commands:

```
/help            # show all built-in slash commands
/doctor          # re-run diagnostics
/config          # change settings interactively
/mcp             # manage MCP servers
/model           # switch models for this session
/cost            # show running token spend
```

---

## Updating Claude Code

```bash
# npm install
npm update -g @anthropic-ai/claude-code

# Homebrew
brew upgrade claude-code

# Manual binary
# Re-download the latest release and replace /usr/local/bin/claude

# Check installed vs latest
claude --version
npm view @anthropic-ai/claude-code version
```

Auto-update notifications appear at the top of each session when a newer version is available. To suppress:

```json
{
  "updates": { "checkOnStartup": false }
}
```

Pin a specific version in CI:

```bash
npm install -g @anthropic-ai/claude-code@1.2.3
```

---

## Uninstalling

```bash
# npm
npm uninstall -g @anthropic-ai/claude-code

# Homebrew
brew uninstall claude-code
brew untap anthropic/claude

# Manual binary
sudo rm /usr/local/bin/claude

# Remove user data (optional — destroys settings, history, sessions, skills)
rm -rf ~/.claude ~/.config/claude-code
security delete-generic-password -s anthropic-api-key 2>/dev/null
```

Before purging `~/.claude`, back up `settings.json`, `agents/`, and `skills/` if you spent time tuning them.

---

## Common Install Issues

### `command not found: claude`

PATH does not include the npm global bin directory.

```bash
# Find where npm installs globals
npm prefix -g

# Add the bin subdirectory to PATH
echo 'export PATH="$(npm prefix -g)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### `EACCES: permission denied` during install

Do not `sudo npm install`. Switch to a user-writable prefix (see [npm section](#install-via-npm-cross-platform)) or use a version manager.

### `Error: Cannot find module '@anthropic-ai/claude-code'` after install

A stale shim from a previous install is on PATH. Find and remove it:

```bash
which -a claude
# Remove any old paths, reinstall
```

### `401 Unauthorized` from `api.anthropic.com`

The API key is missing, malformed, or revoked. Confirm:

```bash
echo "${ANTHROPIC_API_KEY:0:12}..."   # should start sk-ant-

# Test directly
curl -sS https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-haiku-4-5","max_tokens":8,"messages":[{"role":"user","content":"hi"}]}'
```

If curl works but `claude` does not, an OAuth session is also present and shadowing the env var path. Run `claude logout`, then retry.

### `EAI_AGAIN` or DNS errors

Corporate DNS or proxy. Configure both:

```bash
export HTTPS_PROXY="http://proxy.corp:8080"
export HTTP_PROXY="http://proxy.corp:8080"
export NO_PROXY="localhost,127.0.0.1"
```

If your proxy intercepts TLS, point Node at the right CA bundle:

```bash
export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/corp-root-ca.pem
```

### `glibc version not found` on Linux

The bundled native binaries require glibc 2.31+. Distro upgrades or a switch to the npm install path (which uses your Node's libc) usually fix this.

### Claude hangs on first prompt

Almost always a network reachability problem. Run `claude doctor`. If `API reachable` fails, the corporate firewall is dropping the connection. Whitelist `api.anthropic.com` (Anthropic does not publish stable IP ranges — use hostname rules).

### WSL clock skew breaks auth

WSL2 sometimes drifts during sleep. Force a resync:

```bash
sudo hwclock -s
```

If this recurs, add `sudo hwclock -s` to your shell startup or use the `wsl-vpnkit` workaround for clock drift documented in the WSL issue tracker.

### Multiple Node versions colliding

If you installed with one Node version and then switched, the global package is invisible to the new version. Reinstall under each version, or use `fnm use --install-if-missing` to pin per-project.

### Homebrew "permission denied" on `/opt/homebrew`

```bash
sudo chown -R "$(whoami)" /opt/homebrew
```

### Settings file corrupted

If `~/.claude/settings.json` becomes invalid JSON, the CLI will refuse to start. Restore from a backup, or:

```bash
mv ~/.claude/settings.json ~/.claude/settings.json.broken
claude   # re-runs the first-run wizard
```

---

## Next Steps

- [Configure MCP Servers](mcp-servers.md) to extend tool access.
- [Set up sub-agents](agents.md) for parallel work.
- [Write your first skill](skills.md) for repeatable workflows.
- [Wire up event hooks](hooks.md) for automation.
- See [troubleshooting.md](troubleshooting.md) for the top 20 runtime issues.
