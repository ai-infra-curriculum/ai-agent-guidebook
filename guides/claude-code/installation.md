# Installing Claude Code

Detailed installation guide for Claude Code across macOS, Linux, and Windows (WSL), including authentication setup and first-run configuration.

---

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
  - [Native installer (recommended)](#install-via-the-native-installer-recommended)
  - [npm (cross-platform)](#install-via-npm-cross-platform)
  - [Homebrew (macOS)](#install-via-homebrew-macos)
  - [Pinning a specific version](#pinning-a-specific-version)
  - [Windows: native or WSL](#windows-native-or-wsl)
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
| OS | macOS 13+, Ubuntu 20.04+ / Debian 10+, Windows 10 1809+ | macOS 14+, Ubuntu 22.04+, Windows 11 |
| Node.js | 18.x (npm install path only) | 20.x LTS or 22.x |
| RAM | 4 GB | 16 GB (for parallel agents) |
| Disk | 500 MB | 5 GB (with caches and skills) |
| Network | Outbound HTTPS to `api.anthropic.com` | Same, plus low-latency link |
| Shell | Bash, Zsh, PowerShell, or CMD | zsh 5.8+ or bash 5+ |

Claude Code runs natively on macOS, Linux, and Windows. On Windows you can use native PowerShell/CMD (Git for Windows recommended so the Bash tool is available) or WSL 2.

---

## Installation Methods

### Install via the native installer (recommended)

The native installer requires no Node.js and auto-updates in the background:

```bash
# macOS, Linux, WSL
curl -fsSL https://claude.ai/install.sh | bash
```

```powershell
# Windows PowerShell
irm https://claude.ai/install.ps1 | iex
```

The binary lands in `~/.local/bin/claude`.

### Install via npm (cross-platform)

The npm package installs the same native binary via a per-platform optional dependency. It requires Node.js 18+ for the install itself; the installed `claude` binary does not invoke Node.

```bash
# Verify Node 18+ first
node --version

# Install globally
npm install -g @anthropic-ai/claude-code
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

Claude Code ships as a Homebrew cask:

```bash
brew install --cask claude-code

# Verify
claude --version
```

Two casks exist: `claude-code` tracks the stable channel (typically about a week behind, skipping releases with major regressions); `claude-code@latest` tracks every release. Homebrew installs do not auto-update — run `brew upgrade claude-code` periodically.

### Pinning a specific version

The native installer accepts a release channel or an exact version, which is the supported path for reproducible installs:

```bash
# Stable channel
curl -fsSL https://claude.ai/install.sh | bash -s stable

# Exact version
curl -fsSL https://claude.ai/install.sh | bash -s 2.1.89
```

Releases publish a signed `manifest.json` with SHA-256 checksums per platform; verify the GPG signature before trusting a binary in sensitive environments. Signed apt, dnf, and apk repositories are also available for Debian/Ubuntu, Fedora/RHEL, and Alpine.

### Windows: native or WSL

Claude Code runs natively on Windows. Run the PowerShell installer above (no Administrator needed), and optionally install [Git for Windows](https://git-scm.com/downloads/win) so Claude Code can use Git Bash for its Bash tool; without it, shell commands run through PowerShell.

WSL 2 is still a good choice for Linux toolchains and is required for sandboxed command execution:

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

# Install Claude Code (native installer; no Node required)
curl -fsSL https://claude.ai/install.sh | bash
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
# Expected: a 2.x.x version string

claude --help
# Should print the full command reference

# Run the built-in diagnostic
claude doctor
```

`claude doctor` reports on your installation health and configuration — installation type and version, auto-update status, and the result of the most recent update attempt — and is the first thing to run when something is off.

---

## Authentication

Claude Code supports three auth flows. Pick one — do not mix.

### Option 1: claude.ai login (recommended for individuals)

If you have a Claude Pro, Max, Team, or Enterprise subscription, log in with your Anthropic account. Claude Code rides on the same entitlements as the web app, with no extra billing. The free claude.ai plan does not include Claude Code access.

```bash
claude
# Follow the browser prompt on first run, or run /login inside the session
```

After approval, the CLI stores credentials locally (macOS Keychain on macOS; under `~/.claude/` on Linux and WSL).

To switch accounts, run `/logout` then `/login` inside a session. For CI and scripts, generate a long-lived OAuth token with `claude setup-token`.

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

The model IDs differ on these backends. Use the provider-specific names in any `--model` flags (Bedrock IDs follow the `us.anthropic.claude-*` pattern — for example a region-prefixed ID for Sonnet 4.6 — check your provider's console for the exact string).

---

## First-Run Wizard

On first invocation, `claude` walks through a short setup wizard:

```bash
claude
```

You will be asked to pick a theme and log in. Sensible defaults to know about:

1. **Theme** — dark (default), light, or colorblind-friendly variants. Change later via `/config`.
2. **Default model** — Sonnet 4.6 is the right choice for almost all users. Opt for Opus 4.8 only if you frequently do deep architecture work and accept the cost. Haiku 4.5 is appropriate for high-volume agent fleets.
3. **Permission mode** — `default` (prompt on first use of each tool), `acceptEdits` (auto-allow file edits but prompt on Bash), `plan` (read-only exploration with explicit promotion to write), or `bypassPermissions` (no prompts; reserve for sandboxes). Start with `default`; relax later. Cycle modes in-session with `Shift+Tab`.
4. **MCP servers** — skip during first run; add later with `claude mcp add` or inspect with `/mcp`.

Example `~/.claude/settings.json`:

```json
{
  "model": "claude-sonnet-4-6",
  "permissions": {
    "defaultMode": "default"
  },
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
# Apply an update immediately (any install method)
claude update

# npm install — avoid `npm update -g`, which can pin to the original semver range
npm install -g @anthropic-ai/claude-code@latest

# Homebrew
brew upgrade claude-code

# Check installed version
claude --version
```

Native installs auto-update in the background. To disable background updates, set the env var in `settings.json`:

```json
{
  "env": { "DISABLE_AUTOUPDATER": "1" }
}
```

To follow the slower, regression-skipping channel, set `"autoUpdatesChannel": "stable"`. Pin a specific version in CI:

```bash
npm install -g @anthropic-ai/claude-code@2.1.89
```

---

## Uninstalling

```bash
# Native installer
rm -f ~/.local/bin/claude
rm -rf ~/.local/share/claude

# npm
npm uninstall -g @anthropic-ai/claude-code

# Homebrew
brew uninstall --cask claude-code

# Remove user data (optional — destroys settings, history, sessions, skills)
rm -rf ~/.claude
rm -f ~/.claude.json
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

If curl works but `claude` does not, an OAuth session is also present and shadowing the env var path. Run `/logout` inside a session (or check `/status` to see which auth method is active), then retry.

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

### Native binary fails on Alpine / musl-based Linux

On Alpine and other musl-based distributions, install `libgcc`, `libstdc++`, and `ripgrep` with your package manager, then set `USE_BUILTIN_RIPGREP=0` in the `env` section of `settings.json`.

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
