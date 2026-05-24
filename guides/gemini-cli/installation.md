# Gemini CLI Installation

Install and configure the official `gemini` CLI for the Gemini 2.5 model family.

> **Note**: This guide covers the **official `@google/gemini-cli`** released in 2025 — a standalone Node.js binary. It is distinct from the older "Python SDK with a custom wrapper" pattern shown in the [main README](README.md), which remains valid but is now the lower-level option.

---

## Table of Contents

- [What You're Installing](#what-youre-installing)
- [Prerequisites](#prerequisites)
- [Install via npm](#install-via-npm)
- [Install via Homebrew](#install-via-homebrew)
- [Install via asdf](#install-via-asdf)
- [Authentication](#authentication)
- [Initial Configuration](#initial-configuration)
- [Verifying the Install](#verifying-the-install)
- [Upgrade and Uninstall](#upgrade-and-uninstall)
- [Common Install Issues](#common-install-issues)

---

## What You're Installing

The `gemini` CLI is a single executable that gives you:

- Interactive REPL-style sessions (`gemini`)
- One-shot prompts (`gemini "explain this regex"`)
- File-aware prompts (`gemini -f src/app.ts "review this"`)
- Image, PDF, and audio input
- Streaming responses
- Multi-turn sessions with persistent history
- JSON-mode output for scripting
- Model selection across the Gemini 2.5 family (Pro, Flash, Flash-Thinking)

The CLI sits on top of the [Google GenAI SDK](https://github.com/googleapis/js-genai) and works with both **Google AI Studio** API keys (free tier available) and **Vertex AI** service accounts (production / enterprise).

---

## Prerequisites

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Node.js | 18.x | 20.x LTS or newer |
| npm (or pnpm/yarn) | 9.x | Latest |
| Operating system | macOS 12+, Linux (glibc 2.31+), Windows 10+ | — |
| Disk space | ~150 MB | — |

For Vertex AI authentication you additionally need:
- A Google Cloud project with the Vertex AI API enabled.
- `gcloud` CLI installed (for ADC), or a downloaded service-account JSON key.

For Google AI Studio you only need an API key — no Cloud project required.

---

## Install via npm

The canonical install path.

```bash
# Global install
npm install -g @google/gemini-cli

# Verify
gemini --version
```

If you don't want to install globally:

```bash
# One-off invocation
npx @google/gemini-cli "summarize the README"
```

### Per-project install

For repos that want a pinned version:

```bash
cd my-project
npm install --save-dev @google/gemini-cli

# Invoke via the bin
npx gemini --version

# Or add to package.json scripts
```

```json
{
  "scripts": {
    "ai": "gemini",
    "ai:review": "gemini -f src/ \"review for bugs\""
  }
}
```

### pnpm / yarn equivalents

```bash
pnpm add -g @google/gemini-cli
yarn global add @google/gemini-cli
```

---

## Install via Homebrew

For macOS and Linuxbrew:

```bash
brew install gemini-cli
```

This pulls a pre-built binary that doesn't require a Node runtime — handy if you don't otherwise use Node.

Upgrade:

```bash
brew upgrade gemini-cli
```

Uninstall:

```bash
brew uninstall gemini-cli
```

> The Homebrew formula tracks the latest stable release. For pre-release / beta versions, install via `npm install -g @google/gemini-cli@next` instead.

---

## Install via asdf

If you manage versions with [asdf](https://asdf-vm.com/):

```bash
# Install the plugin
asdf plugin add gemini-cli https://github.com/asdf-community/asdf-gemini-cli.git

# List available versions
asdf list-all gemini-cli

# Install latest
asdf install gemini-cli latest
asdf global gemini-cli latest

# Verify
gemini --version
```

For per-project pinning, create a `.tool-versions` file in your repo:

```
gemini-cli 1.4.0
```

---

## Authentication

The CLI supports two authentication paths. Pick one — you can switch later.

### Option A: Google AI Studio (API key)

Easiest. Free tier is generous (rate-limited, not capability-limited).

1. Visit <https://aistudio.google.com/app/apikey>.
2. Click **Create API key**.
3. (Optional) Restrict the key to specific IPs / referrers in the AI Studio console.
4. Copy the key.

Set the key via environment variable:

```bash
# Add to ~/.zshrc or ~/.bashrc
export GEMINI_API_KEY="your-api-key-here"

# Reload
source ~/.zshrc
```

Or use the CLI's built-in setup:

```bash
gemini auth login
# Follow prompts to paste the key
```

The CLI stores the key at `~/.config/gemini/credentials.json` with `0600` permissions.

### Option B: Vertex AI (service account)

For production workloads, regulated environments, or anyone who wants their usage tied to a Google Cloud billing account.

**Prerequisites:**

1. A Google Cloud project with billing enabled.
2. Vertex AI API enabled:

   ```bash
   gcloud services enable aiplatform.googleapis.com --project=YOUR_PROJECT
   ```

3. A service account with the `Vertex AI User` role (`roles/aiplatform.user`).

**Three sub-options for credentials:**

**B1. Application Default Credentials (recommended for dev)**

```bash
gcloud auth application-default login
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GEMINI_USE_VERTEX="true"
export GEMINI_LOCATION="us-central1"
```

**B2. Service account JSON key (CI, automation)**

Download a key:

```bash
gcloud iam service-accounts keys create ~/keys/gemini-sa.json \
  --iam-account=gemini-cli@YOUR_PROJECT.iam.gserviceaccount.com
```

Then:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/keys/gemini-sa.json"
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GEMINI_USE_VERTEX="true"
export GEMINI_LOCATION="us-central1"
```

**B3. Workload Identity (GKE / Cloud Run)**

When running on Google Cloud compute, prefer Workload Identity. No keys to manage:

```bash
export GEMINI_USE_VERTEX="true"
export GEMINI_LOCATION="us-central1"
# GOOGLE_CLOUD_PROJECT is auto-detected from the metadata server
```

### Choosing AI Studio vs Vertex AI

| Aspect | AI Studio | Vertex AI |
|--------|-----------|-----------|
| Setup time | 1 minute | 10–30 minutes |
| Billing | Optional, simple | Required GCP billing |
| Free tier | Yes | No (but credits often available) |
| Data residency / region pinning | Limited | Yes (`GEMINI_LOCATION`) |
| Per-request quota | Shared, lower | Per-project, higher |
| Audit logs | No | Yes (via Cloud Logging) |
| Best for | Personal use, prototypes | Production, regulated, multi-tenant |

You can have both configured and switch with `--auth vertex` / `--auth aistudio` at the CLI.

---

## Initial Configuration

The CLI reads configuration from (in order of precedence):

1. Command-line flags
2. Environment variables
3. `./.gemini/config.yaml` (per-project)
4. `~/.config/gemini/config.yaml` (per-user)

### Minimal user config

`~/.config/gemini/config.yaml`:

```yaml
default_model: gemini-2.5-flash
temperature: 0.4
max_output_tokens: 8192

# Where to keep session histories
session_dir: ~/.local/state/gemini/sessions

# Auto-load these files on every prompt (useful for repo-wide style guides)
context_files: []

# Pretty-print streamed Markdown in the terminal
render_markdown: true
```

### Per-project config

For a repo that wants its own defaults — model choice, context files, etc.:

`./.gemini/config.yaml`:

```yaml
default_model: gemini-2.5-pro

context_files:
  - ./CONTRIBUTING.md
  - ./docs/architecture.md

# Apply this system prompt to every interactive session
system_prompt: |
  You are assisting on a TypeScript backend.
  Prefer functional patterns, avoid classes except for entities.
  All HTTP calls use the project's `httpx` wrapper at src/lib/http.
```

Commit `.gemini/config.yaml` (minus secrets) so the whole team gets consistent defaults.

### Environment variables

| Variable | Purpose |
|----------|---------|
| `GEMINI_API_KEY` | AI Studio API key |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service-account JSON (Vertex) |
| `GOOGLE_CLOUD_PROJECT` | GCP project ID (Vertex) |
| `GEMINI_USE_VERTEX` | `true` to force Vertex AI auth |
| `GEMINI_LOCATION` | Vertex region (e.g. `us-central1`, `europe-west4`) |
| `GEMINI_DEFAULT_MODEL` | Override the configured default model |
| `GEMINI_HTTP_PROXY` | HTTP/HTTPS proxy URL |
| `GEMINI_LOG_LEVEL` | `debug`, `info`, `warn`, `error` |

---

## Verifying the Install

### Smoke test

```bash
gemini --version
# → @google/gemini-cli x.y.z

gemini auth status
# → Authenticated via AI Studio (or Vertex AI, project: ...)

gemini "say hello in five languages"
# → Streamed response
```

### Capability check

```bash
gemini models list
# Shows: gemini-2.5-pro, gemini-2.5-flash, gemini-2.5-flash-thinking, ...

gemini -m gemini-2.5-flash "what's 2+2"
# → 4
```

### Test image input

```bash
gemini -i ~/Desktop/screenshot.png "what's in this image?"
```

### Test file input

```bash
gemini -f README.md "summarize this in 3 bullets"
```

If all of these succeed, you're done.

---

## Upgrade and Uninstall

### Upgrade

```bash
# npm
npm update -g @google/gemini-cli

# Homebrew
brew upgrade gemini-cli

# asdf
asdf install gemini-cli latest
asdf global gemini-cli latest
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

# asdf
asdf uninstall gemini-cli
```

Remove config and credentials:

```bash
rm -rf ~/.config/gemini
rm -rf ~/.local/state/gemini
```

---

## Common Install Issues

### `command not found: gemini` after npm install

Your npm global `bin` directory isn't on `PATH`. Find it:

```bash
npm config get prefix
# → e.g. /Users/you/.npm-global
```

Add `<prefix>/bin` to your PATH:

```bash
echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### EACCES permission errors during npm install

Don't fix this with `sudo` — fix the permission model:

```bash
# Configure npm to use a user-owned prefix
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc

# Reinstall
npm install -g @google/gemini-cli
```

Or use a Node version manager (asdf, fnm, nvm) which sidesteps this entirely.

### Node version too old

```bash
gemini --version
# → Error: Node.js 18.x or newer required (you have 16.20.0)
```

Upgrade Node via your preferred manager:

```bash
# asdf
asdf install nodejs 20.11.0
asdf global nodejs 20.11.0

# nvm
nvm install 20
nvm use 20
```

### "Could not load the default credentials" (Vertex)

Three causes:

1. `GOOGLE_APPLICATION_CREDENTIALS` points at a file that doesn't exist or isn't readable.
2. You ran `gcloud auth login` instead of `gcloud auth application-default login` (different credential stores).
3. Workload Identity isn't set up on your cluster / runtime.

Diagnose:

```bash
gcloud auth application-default print-access-token
# Should print a token. If it doesn't, the ADC isn't there.

ls -la "$GOOGLE_APPLICATION_CREDENTIALS"
# Should exist and be readable
```

### API key works on AI Studio website but not CLI

The CLI looks for `GEMINI_API_KEY`. If you only set `GOOGLE_API_KEY` (older SDK convention), the CLI doesn't pick it up unless you alias:

```bash
export GEMINI_API_KEY="$GOOGLE_API_KEY"
```

Or set both.

### TLS errors behind a corporate proxy

Set the proxy variables:

```bash
export HTTPS_PROXY="http://proxy.corp:8080"
export HTTP_PROXY="http://proxy.corp:8080"
export NO_PROXY="localhost,127.0.0.1"
```

If your proxy uses a self-signed CA, add it to Node's trust store:

```bash
export NODE_EXTRA_CA_CERTS="/etc/ssl/certs/corp-ca.pem"
```

### Rate-limit errors immediately on first request

If you set up AI Studio billing and instantly get 429s, double-check the API key isn't restricted to a different application or IP. Restrictions are configured per-key at <https://aistudio.google.com/app/apikey>.

### "Project not authorized to use Vertex AI"

Enable the API:

```bash
gcloud services enable aiplatform.googleapis.com --project=YOUR_PROJECT
```

And grant the service account the right role:

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT \
  --member="serviceAccount:gemini-cli@YOUR_PROJECT.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

### Install hangs on `node-gyp`

The official npm package ships pre-built — `node-gyp` should not run. If it does, you may have a corrupted install. Clear and retry:

```bash
npm uninstall -g @google/gemini-cli
npm cache clean --force
npm install -g @google/gemini-cli
```

---

## Next Steps

- [Gemini CLI Usage](usage.md) — command reference, flags, modes
- [Gemini CLI Integration](integration.md) — scripting, pipes, CI, SDK comparison
- [Main Gemini CLI README](README.md)
