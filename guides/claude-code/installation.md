# Installing Claude Code

Detailed installation guide for Claude Code across macOS, Linux, and Windows (native or WSL), including authentication setup and first-run configuration.

Last verified: 2026-10 (against the official [advanced setup](https://code.claude.com/docs/en/setup) and [authentication](https://code.claude.com/docs/en/authentication) docs; latest release at time of writing: v2.1.306). Prefer a GUI? The [Claude Desktop app](https://code.claude.com/docs/en/desktop) (macOS, Windows, and Linux beta) runs the same engine without a terminal.

---

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
  - [Native installer (recommended)](#install-via-the-native-installer-recommended)
  - [npm (cross-platform)](#install-via-npm-cross-platform)
  - [Homebrew (macOS)](#install-via-homebrew-macos)
  - [WinGet and Linux package managers](#winget-and-linux-package-managers)
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
| OS | macOS 13+, Ubuntu 20.04+ / Debian 10+ / Alpine 3.19+, Windows 10 1809+ or Server 2019+ | macOS 14+, Ubuntu 22.04+, Windows 11 |
| CPU | x64 or ARM64 | — |
| Node.js | 22+ (npm install path only) | 22.x LTS |
| RAM | 4 GB | 16 GB (for parallel agents) |
| Disk | Not specified by the docs (the native download is ~75 MB on Linux x64) | Room for caches, session transcripts, and worktrees |
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

```batch
:: Windows CMD
curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd
```

On macOS and Linux, `~/.local/bin/claude` is a launcher symlink into `~/.local/share/claude/versions/`. If the shell says `claude` isn't found, open a new terminal; if it still isn't, add `~/.local/bin` to `PATH`.

### Install via npm (cross-platform)

The npm package installs the same native binary via a per-platform optional dependency (e.g. `@anthropic-ai/claude-code-darwin-arm64`). The package now declares **Node.js 22 or later**; on older Node, npm prints an `EBADENGINE` warning but the install completes, because the installed `claude` binary does not invoke Node at runtime. Your package manager must allow optional dependencies.

```bash
# Check Node first (22+ recommended)
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

Two casks exist: `claude-code` tracks the stable channel (typically about a week behind, skipping releases with major regressions); `claude-code@latest` tracks every release. Homebrew installs do not auto-update by default — run `brew upgrade claude-code` periodically, or set `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` to have Claude Code run the upgrade for you in the background.

### WinGet and Linux package managers

```powershell
winget install Anthropic.ClaudeCode
# later: winget upgrade Anthropic.ClaudeCode
```

Signed apt, dnf, and apk repositories (served from `downloads.claude.ai`) are available for Debian/Ubuntu, Fedora/RHEL, and Alpine, each with `stable` and `latest` channels. Follow the repository setup in the [official instructions](https://code.claude.com/docs/en/setup#install-with-linux-package-managers) and verify the published key fingerprint before trusting it. These installs update through your normal system upgrade workflow, not through Claude Code.

### Pinning a specific version

The native installer accepts a release channel or an exact version, which is the supported path for reproducible installs:

```bash
# Stable channel
curl -fsSL https://claude.ai/install.sh | bash -s stable

# Exact version
curl -fsSL https://claude.ai/install.sh | bash -s 2.1.89
```

Releases publish a signed `manifest.json` with SHA-256 checksums per platform; verify the GPG signature before trusting a binary in sensitive environments.

A newly launched model can require a version newer than the stable channel serves (for example, Opus 5.5 requires v2.1.280+, Sonnet 5.5 v2.1.284+, Haiku 5.5 v2.1.293+). If a model request fails with "Claude Code does not support this model," update or switch to the latest channel.

### Windows: native or WSL

Claude Code runs natively on Windows. Run the PowerShell or CMD installer above (no Administrator needed), and optionally install [Git for Windows](https://git-scm.com/downloads/win) so Claude Code can use Git Bash for its Bash tool (the Monitor tool also needs Git Bash); without it, shell commands run through the PowerShell tool.

WSL 2 is still a good choice for Linux toolchains and is required for sandboxed command execution (the Bash sandbox isn't supported on native Windows or WSL 1):

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

`claude doctor` prints read-only installation and settings diagnostics without starting a session — install health, auto-update status and the last update attempt, settings-file validation errors, and warnings with suggested fixes. Inside a session, `/doctor` (alias `/checkup`) goes further: since v2.1.205 it diagnoses *and offers to fix* problems, including unused skills, MCP servers, and plugins weighed against their context cost, duplicated or derivable `CLAUDE.md` content, and slow hooks. It asks before changing anything.

---

## Authentication

Claude Code requires a Pro, Max, Team, Enterprise, or Console account, or a third-party provider. Pick one auth path — do not mix.

### Option 1: claude.ai login (recommended for individuals)

If you have a Claude Pro, Max, Team, or Enterprise subscription, log in with your Anthropic account. Claude Code rides on the same entitlements as the web app, with no extra billing. The free claude.ai plan does not include Claude Code access.

```bash
claude
# Follow the browser prompt on first run, or run /login inside the session
```

After approval, the CLI stores credentials locally: the macOS Keychain on macOS (falling back to `~/.claude/.credentials.json`, mode `0600`, if the Keychain rejects the write), `~/.claude/.credentials.json` on Linux, and `%USERPROFILE%\.claude\.credentials.json` on Windows.

To switch accounts, run `/logout` then `/login` inside a session. For CI and scripts, generate a long-lived OAuth token with `claude setup-token` and expose it as `CLAUDE_CODE_OAUTH_TOKEN`.

### Option 2: Anthropic API key (recommended for teams and CI)

Best for teams that want per-developer usage tracking, or for CI where browser flows are impossible.

```bash
# Generate a key in the Claude Console (platform.claude.com)

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

If both `ANTHROPIC_API_KEY` and a logged-in subscription are present, interactive Claude Code asks once whether to use the key; once approved, the key wins. Run `unset ANTHROPIC_API_KEY` to fall back to your subscription, and `/status` to see which credential is active.

### Option 3: Cloud providers (Bedrock, Google Cloud's Agent Platform, Microsoft Foundry)

For teams that already have cloud commitments. Interactive wizards (`/setup-bedrock`, `/setup-vertex`) walk through auth, region, and model pins:

```bash
# Bedrock
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-east-1
# AWS credentials picked up from ~/.aws/credentials or instance metadata;
# the region is also read from ~/.aws config files when AWS_REGION is unset

# Google Cloud's Agent Platform (formerly Vertex AI)
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=us-central1
export ANTHROPIC_VERTEX_PROJECT_ID=my-gcp-project
```

Model IDs and alias targets differ on these backends. The Anthropic API docs list Bedrock IDs such as `anthropic.claude-opus-5-5` (Bedrock also offers region-prefixed inference profiles), while Google Cloud and Foundry use the Claude API IDs (`claude-opus-5-5`). Aliases can lag: on Bedrock and Agent Platform, `opus` resolves to Opus 5.5 but `sonnet` to Sonnet 4.5 and `haiku` to Haiku 4.5 — pin newer models with `ANTHROPIC_DEFAULT_SONNET_MODEL` / `ANTHROPIC_DEFAULT_HAIKU_MODEL` or the full ID. Check your provider's console for the exact string.

---

## First-Run Wizard

On first invocation, `claude` walks through a short setup wizard:

```bash
claude
```

You will be asked to pick a theme and log in, and to trust the folder you launched from. Sensible defaults to know about:

1. **Theme** — `auto` (match your terminal), light, dark, colorblind-friendly (daltonized), and ANSI variants. Change later via `/theme` or `/config`.
2. **Default model** — as of v2.1.280 the account default is **Opus 5.5** on Pro, Max, Team, Enterprise, and the Anthropic API (Sonnet 4.5 on Foundry). Switch with `/model`: `sonnet` (Sonnet 5.5, $2/$10 per MTok on the API) for cheaper day-to-day work, `haiku` (Haiku 5.5) for high-volume fleets, `fable` (Fable 5.1, $10/$50) for long, ambiguous, multi-hour tasks. Fable is never the default and may bill to usage credits on subscription plans.
3. **Permission mode** — interactive sessions now start in **auto mode** (a classifier reviews actions instead of prompting you) on v2.1.283+. Alternatives: Manual (`default`, prompts for edits and commands), `acceptEdits`, `plan`, `dontAsk`, and `bypassPermissions` (sandboxes only). Cycle modes in-session with `Shift+Tab`. See [settings-and-permissions.md](settings-and-permissions.md#permission-modes).
4. **MCP servers** — skip during first run; add later with `claude mcp add` or inspect with `/mcp`.

Example `~/.claude/settings.json`:

```json
{
  "model": "sonnet",
  "permissions": {
    "defaultMode": "acceptEdits"
  },
  "outputStyle": "Concise"
}
```

Aliases (`opus`, `sonnet`, `haiku`, `fable`) track the newest model on your provider; pin a full ID such as `claude-sonnet-5-5` when you need reproducibility.

After the wizard you land in the interactive prompt. Useful first commands:

```
/help            # show all built-in slash commands
/doctor          # setup checkup that proposes fixes
/config          # change settings interactively (or /config key=value)
/mcp             # manage MCP servers
/model           # switch models (saves your choice as the default)
/effort          # set reasoning effort for the current model
/usage           # session cost and plan limits (/cost is an alias)
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

Native installs auto-update in the background (updates take effect the next time you start Claude Code). To disable background updates, set the env var in `settings.json`:

```json
{
  "env": { "DISABLE_AUTOUPDATER": "1" }
}
```

`DISABLE_AUTOUPDATER` stops only the background check; `claude update` still works. Set `DISABLE_UPDATES` to block every update path when you distribute Claude Code yourself. To follow the slower, regression-skipping channel, set `"autoUpdatesChannel": "stable"`; add `minimumVersion` to keep that switch from downgrading you. Pin a specific version in CI:

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

# WinGet
winget uninstall Anthropic.ClaudeCode

# Remove user data (optional — destroys settings, history, sessions, skills)
rm -rf ~/.claude
rm -f ~/.claude.json
security delete-generic-password -s anthropic-api-key 2>/dev/null
```

Before purging `~/.claude`, back up `settings.json`, `agents/`, and `skills/` if you spent time tuning them.

---

## Common Install Issues

### `command not found: claude`

For native installs, `~/.local/bin` isn't on `PATH` yet — open a new terminal, or add it to your shell rc. For npm installs, PATH does not include the npm global bin directory:

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
  -d '{"model":"claude-haiku-5-5","max_tokens":8,"messages":[{"role":"user","content":"hi"}]}'
```

If curl works but `claude` does not, check `/status` to see which credential is active — you may have declined the key prompt, or another credential (such as `ANTHROPIC_AUTH_TOKEN` or an `apiKeyHelper`) takes precedence. Fix that, then retry.

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

On Alpine and other musl-based distributions, install `bash` and `curl` (needed by the install command) plus `libgcc`, `libstdc++`, and `ripgrep` (`apk add bash curl libgcc libstdc++ ripgrep`; `ripgrep` is in the community repository), then set `USE_BUILTIN_RIPGREP=0` in the `env` section of `settings.json`. Alternatively, use the signed apk repository.

### Claude hangs on first prompt

Almost always a network reachability problem. Run `claude doctor` and test `curl -v https://api.anthropic.com` from the same shell. If that fails, the corporate firewall is dropping the connection; see the [network configuration](https://code.claude.com/docs/en/network-config) page for the network access requirements.

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

If `~/.claude/settings.json` becomes invalid JSON, `claude doctor` reports the validation error. Fix it, restore from a backup, or move it aside:

```bash
mv ~/.claude/settings.json ~/.claude/settings.json.broken
claude
```

To check whether a customization is the culprit at all, launch with `claude --safe-mode`: CLAUDE.md, skills, plugins, hooks, MCP servers, and custom commands and agents don't load, while auth, model selection, and permissions still work.

---

## Next Steps

- [Configure MCP Servers](mcp-servers.md) to extend tool access.
- [Set up sub-agents](agents.md) for parallel work.
- [Write your first skill](skills.md) for repeatable workflows.
- [Wire up event hooks](hooks.md) for automation.
- See [troubleshooting.md](troubleshooting.md) for the top 20 runtime issues.
