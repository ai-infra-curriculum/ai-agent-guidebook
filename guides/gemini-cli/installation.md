# Gemini CLI Installation

Install and configure the official `@google/gemini-cli` — Google's open-source agentic CLI for the Gemini models.

---

## Table of Contents

- [What You're Installing](#what-youre-installing)
- [Prerequisites](#prerequisites)
- [Install via npm](#install-via-npm)
- [Install via Homebrew](#install-via-homebrew)
- [Other Install Paths](#other-install-paths)
- [Authentication](#authentication)
- [Initial Configuration](#initial-configuration)
- [Verifying the Install](#verifying-the-install)
- [Upgrade and Uninstall](#upgrade-and-uninstall)
- [Common Install Issues](#common-install-issues)

---

## What You're Installing

The `gemini` command is a Node.js-based agent that gives you:

- An interactive, agentic REPL (`gemini`) that can read/edit files and run shell commands with your approval
- One-shot headless prompts (`gemini -p "explain this regex"`) with stdin piping
- File and directory context via `@path` references in prompts (including images and PDFs)
- Hierarchical project context via `GEMINI.md` files
- MCP server support, extensions, and custom slash commands
- JSON output modes for scripting (`--output-format json` / `stream-json`)
- Session checkpointing and resuming

It works with three authentication methods: **Login with Google** (OAuth, free tier), a **Gemini API key** from Google AI Studio, and **Vertex AI** for Google Cloud projects.

> ⚠️ **Consumer-tier transition**: Google has announced that the "Login with Google" consumer tiers (free Code Assist for individuals, Google AI Pro/Ultra) stop being served on **June 18, 2026**, as Gemini CLI transitions to Antigravity CLI. Paid API keys and Code Assist Standard/Enterprise licenses are unaffected. See the [main README](README.md#important-consumer-tier-transition).

---

## Prerequisites

| Requirement | Minimum |
|-------------|---------|
| Node.js | **20.x or newer** |
| npm | Ships with Node |
| Operating system | macOS, Linux, or Windows |

Check your Node version:

```bash
node --version   # must be >= 20
```

For Vertex AI authentication you additionally need:
- A Google Cloud project with the Vertex AI API enabled
- The `gcloud` CLI (for Application Default Credentials) or a service-account key

For Login with Google or an AI Studio API key, no Cloud project is required.

---

## Install via npm

The canonical install path:

```bash
# Global install
npm install -g @google/gemini-cli

# Verify
gemini --version
```

No install at all — run directly:

```bash
npx @google/gemini-cli
```

### Release channels

```bash
npm install -g @google/gemini-cli@latest    # stable (default)
npm install -g @google/gemini-cli@preview   # weekly preview
npm install -g @google/gemini-cli@nightly   # nightly builds
```

---

## Install via Homebrew

For macOS and Linuxbrew:

```bash
brew install gemini-cli
```

Upgrade / uninstall:

```bash
brew upgrade gemini-cli
brew uninstall gemini-cli
```

---

## Other Install Paths

```bash
# MacPorts (macOS)
sudo port install gemini-cli
```

In restricted environments (no system Node), you can create a Node environment with a manager such as Anaconda/conda, nvm, or fnm, then `npm install -g @google/gemini-cli` inside it.

---

## Authentication

Gemini CLI supports three authentication methods. You can switch between them at any time with the `/auth` command inside the REPL. Credentials are cached under `~/.gemini/`.

### Option A: Login with Google (OAuth) — default

The easiest path. Just run the CLI:

```bash
gemini
```

On first run it opens a browser window for Google sign-in. With a personal Google account this grants a free Gemini Code Assist license for individuals:

- **60 requests per minute**
- **1,000 requests per day**

at no cost. (Note the June 18, 2026 consumer-tier cutoff above.)

If you have a Gemini Code Assist **Standard or Enterprise** license through Google Cloud, also set your project:

```bash
export GOOGLE_CLOUD_PROJECT="your-project-id"
gemini
```

### Option B: Gemini API key (Google AI Studio)

For higher or controllable limits, usage-based billing, and scripting/CI:

1. Create a key at <https://aistudio.google.com/app/apikey>.
2. Export it:

```bash
# Add to ~/.zshrc or ~/.bashrc for persistence
export GEMINI_API_KEY="your-api-key-here"

gemini
```

You can also place the key in a `.env` file — the CLI loads `.env` files from the current directory (walking up to the project root or home directory), and `~/.gemini/.env`. Never commit API keys to a repository.

### Option C: Vertex AI (Google Cloud)

For production workloads, org billing, region pinning, and audit logging:

```bash
# Enable the API and set up Application Default Credentials
gcloud services enable aiplatform.googleapis.com --project=YOUR_PROJECT
gcloud auth application-default login

# Tell the CLI to use Vertex AI
export GOOGLE_GENAI_USE_VERTEXAI=true
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_CLOUD_LOCATION="us-central1"

gemini
```

For non-interactive environments (CI, servers), use a service account:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/keys/gemini-sa.json"
export GOOGLE_GENAI_USE_VERTEXAI=true
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_CLOUD_LOCATION="us-central1"
```

The service account needs the `Vertex AI User` role (`roles/aiplatform.user`). On GKE/Cloud Run, prefer Workload Identity over key files.

### Choosing a method

| Aspect | Login with Google | API key (AI Studio) | Vertex AI |
|--------|-------------------|---------------------|-----------|
| Setup time | Seconds | 1 minute | 10–30 minutes |
| Free tier | Yes (60 RPM / 1,000 RPD) | Yes (limited) | No |
| Works headless / in CI | Awkward | Yes | Yes |
| Region pinning / audit logs | No | No | Yes |
| Best for | Personal interactive use | Scripts, CI, higher limits | Production, enterprise |

---

## Initial Configuration

### settings.json

Gemini CLI reads JSON settings from several layers. Precedence, lowest to highest:

1. Built-in defaults
2. System defaults file (e.g. `/etc/gemini-cli/system-defaults.json` on Linux)
3. **User settings**: `~/.gemini/settings.json`
4. **Project settings**: `.gemini/settings.json` (in your repo)
5. System overrides file
6. Environment variables (including `.env` files)
7. Command-line flags

A minimal user `~/.gemini/settings.json`:

```json
{
  "ui": {
    "theme": "GitHub"
  },
  "general": {
    "vimMode": false
  },
  "context": {
    "fileName": "GEMINI.md"
  }
}
```

A project `.gemini/settings.json` is the natural home for team-shared MCP servers and tool policies — commit it (minus secrets) so the whole team gets consistent defaults. Edit settings interactively with the `/settings` command.

### GEMINI.md context files

Project instructions live in `GEMINI.md` files, loaded hierarchically:

- **Global**: `~/.gemini/GEMINI.md` — your personal defaults for all projects
- **Project**: `GEMINI.md` at the repo root (the CLI searches upward until it hits the `.git` boundary or your home directory)
- **Subdirectory**: `GEMINI.md` files deeper in the tree for component-specific context

Generate a starter file for the current project:

```text
gemini
> /init
```

Inspect what is loaded with `/memory show`, reload with `/memory refresh`.

### .geminiignore

Exclude paths from file discovery and `@` references — same syntax as `.gitignore`:

```
# .geminiignore
node_modules/
dist/
*.lock
secrets/
```

The CLI also respects `.gitignore` by default.

### Key environment variables

| Variable | Purpose |
|----------|---------|
| `GEMINI_API_KEY` | AI Studio API key |
| `GEMINI_MODEL` | Override the default model |
| `GOOGLE_GENAI_USE_VERTEXAI` | `true` to route through Vertex AI |
| `GOOGLE_CLOUD_PROJECT` | GCP project ID (Vertex / Code Assist licenses) |
| `GOOGLE_CLOUD_LOCATION` | Vertex region (e.g. `us-central1`) |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to a service-account JSON key |
| `GEMINI_SANDBOX` | Enable/choose the tool-execution sandbox |
| `GEMINI_SYSTEM_MD` | Path to a custom system prompt file |
| `GEMINI_CLI_TRUST_WORKSPACE` | `true` to bypass folder-trust prompts in headless environments |

---

## Verifying the Install

```bash
gemini --version
# → prints the installed version (e.g. 0.46.0)

gemini -p "hello"
# → a short response from the model (verifies auth + connectivity)
```

Then try an interactive session in a project:

```bash
cd my-project
gemini
```

```text
> @README.md summarize this in 3 bullets
> /stats        # token usage for the session
> /quit
```

If all of these work, you're done.

---

## Upgrade and Uninstall

### Upgrade

```bash
# npm
npm install -g @google/gemini-cli@latest

# Homebrew
brew upgrade gemini-cli
```

Check current vs latest:

```bash
gemini --version
npm view @google/gemini-cli version
```

### Uninstall

```bash
# npm
npm uninstall -g @google/gemini-cli

# Homebrew
brew uninstall gemini-cli
```

Remove cached credentials, settings, and session data:

```bash
rm -rf ~/.gemini
```

---

## Common Install Issues

### `command not found: gemini` after npm install

Your npm global `bin` directory isn't on `PATH`:

```bash
npm config get prefix
# → e.g. /Users/you/.npm-global

echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### EACCES permission errors during npm install

Don't reach for `sudo` — fix the permission model:

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc

npm install -g @google/gemini-cli
```

Or use a Node version manager (nvm, fnm, asdf), which sidesteps this entirely.

### Node version too old

Gemini CLI requires Node.js **20+**. Upgrade via your preferred manager:

```bash
# nvm
nvm install 20
nvm use 20
```

### OAuth login loops or fails

- Browser-based login needs a browser on the same machine (or a flow that lets you paste a code). On remote/headless machines, prefer an API key or Vertex AI instead.
- Stale credentials live under `~/.gemini/` — remove them and re-run `gemini` to retry, or use `/auth` to switch methods.

### "Could not load the default credentials" (Vertex)

1. `GOOGLE_APPLICATION_CREDENTIALS` points at a file that doesn't exist or isn't readable.
2. You ran `gcloud auth login` instead of `gcloud auth application-default login` (different credential stores).
3. Workload Identity isn't set up on your cluster/runtime.

Diagnose:

```bash
gcloud auth application-default print-access-token
ls -la "$GOOGLE_APPLICATION_CREDENTIALS"
```

### API key set but not picked up

The CLI reads `GEMINI_API_KEY`. Confirm it's exported in the shell that launches `gemini`, and check `.env` files — project `.env` files in the directory tree are loaded automatically and may override your shell.

### TLS errors behind a corporate proxy

```bash
export HTTPS_PROXY="http://proxy.corp:8080"
export HTTP_PROXY="http://proxy.corp:8080"
export NO_PROXY="localhost,127.0.0.1"
```

If your proxy uses a self-signed CA, add it to Node's trust store:

```bash
export NODE_EXTRA_CA_CERTS="/etc/ssl/certs/corp-ca.pem"
```

### Immediate 429s on the free tier

You've hit the 60 requests/min or 1,000 requests/day caps, or your account's quota was consumed by other tooling. Switch to an API key or Vertex AI for independent quota.

---

## Next Steps

- [Gemini CLI Usage](usage.md) — REPL, slash commands, flags, models
- [Gemini CLI Integration](integration.md) — scripting, JSON output, CI, SDK comparison
- [Main Gemini CLI README](README.md)

---

**Last Updated**: 2026-06-11
