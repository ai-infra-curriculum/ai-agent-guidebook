# OpenAI Codex Installation

How to install the Codex CLI and IDE extension, sign in, and set up a sensible first configuration.

---

## Table of Contents

- [What You're Installing](#what-youre-installing)
- [System Requirements](#system-requirements)
- [Install the CLI](#install-the-cli)
- [Install the IDE Extension](#install-the-ide-extension)
- [Authentication](#authentication)
- [Initial Configuration](#initial-configuration)
- [Verifying the Install](#verifying-the-install)
- [Upgrade and Uninstall](#upgrade-and-uninstall)
- [Windows Notes](#windows-notes)
- [Common Install Issues](#common-install-issues)
- [Next Steps](#next-steps)

---

## What You're Installing

- **Codex CLI** — a single native binary (`codex`) built from the Rust workspace in [openai/codex](https://github.com/openai/codex). The npm package `@openai/codex` and the Homebrew cask are distribution wrappers around that binary.
- **Codex IDE extension** — the `openai.chatgpt` extension for VS Code and VS Code-compatible editors (Cursor, Windsurf). It shares configuration and login with the CLI.
- **ChatGPT desktop app** — optional; hosts Codex alongside ChatGPT Work. Run `codex app` to open (or install) it on macOS or Windows.

Codex Cloud and GitHub code review need no local install — they run from <https://chatgpt.com/codex> once you connect GitHub.

---

## System Requirements

From the repository's install docs:

| Requirement | Details |
|-------------|---------|
| Operating systems | macOS 12+, Ubuntu 20.04+/Debian 10+ |
| Git (optional, recommended) | 2.23+ for built-in PR helpers |
| RAM | 4 GB minimum (8 GB recommended) |

**Windows:** the repo's requirements table still lists Windows 11 via WSL2, while the current docs provide a native PowerShell installer and a native Windows sandbox. Both paths are supported; see [Windows Notes](#windows-notes).

Source: [docs/install.md](https://github.com/openai/codex/blob/main/docs/install.md).

---

## Install the CLI

### Standalone installer (recommended)

```bash
# macOS / Linux
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

```powershell
# Windows — run from a new PowerShell window
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
```

The standalone installers download from `https://releases.openai.com/codex` and fall back to GitHub Releases if a download is unavailable. To force GitHub Releases:

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_INSTALLER_USE_RELEASES_OPENAI_COM=false sh
```

The visible `codex` command is installed to `~/.local/bin` on macOS/Linux and `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin` on Windows; override with `CODEX_INSTALL_DIR`.

### npm

```bash
npm install -g @openai/codex
```

### Homebrew

```bash
brew install --cask codex
```

### Prebuilt binaries

Each [GitHub Release](https://github.com/openai/codex/releases/latest) ships per-platform archives, for example:

- macOS Apple Silicon: `codex-aarch64-apple-darwin.tar.gz`
- macOS x86_64: `codex-x86_64-apple-darwin.tar.gz`
- Linux x86_64: `codex-x86_64-unknown-linux-musl.tar.gz`
- Linux arm64: `codex-aarch64-unknown-linux-musl.tar.gz`

Each archive contains one binary with the platform in its name; rename it to `codex` after extracting. Releases also include a [DotSlash](https://dotslash-cli.com/) file named `codex`, which you can commit to a repo so every contributor runs the same pinned version.

### Release cadence

Codex ships frequently — several stable releases a month, with alpha pre-releases almost daily (stable `0.163.0` was released on 2026-10-15). Pin a version in CI (see the GitHub Action's `codex-version` input) rather than tracking latest blindly.

### Build from source

```bash
git clone https://github.com/openai/codex.git
cd codex/codex-rs
cargo build
cargo run --bin codex -- "explain this codebase to me"
```

The repo's [install docs](https://github.com/openai/codex/blob/main/docs/install.md) list the full toolchain (`rustfmt`, `clippy`, `just`, `dotslash`, `cargo-nextest`).

Sources: [openai/codex README](https://github.com/openai/codex), [Codex CLI](https://learn.chatgpt.com/docs/codex/cli), [Environment variables](https://learn.chatgpt.com/docs/config-file/environment-variables).

---

## Install the IDE Extension

| Editor | How |
|--------|-----|
| VS Code / VS Code Insiders | Install **Codex** (`openai.chatgpt`) from the [Marketplace](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) |
| Cursor, Windsurf | Install the same `openai.chatgpt` extension from the editor's extension view |
| Xcode | Use Xcode's coding intelligence settings and choose Codex as the agent |
| JetBrains IDEs | Open AI Chat and select Codex |

Open it with the Codex icon, or run **Codex: Open Codex Sidebar** from the Command Palette. To edit the shared config from the extension: gear icon → **Codex Settings → Open config.toml**.

On Windows, the extension can run the agent inside WSL2 — see [Windows Notes](#windows-notes).

Sources: [IDE extension](https://learn.chatgpt.com/docs/codex/ide), [Config basics](https://learn.chatgpt.com/docs/config-file/config-basic).

---

## Authentication

### Option A: Sign in with ChatGPT (recommended)

```bash
codex login
```

Or just run `codex` and choose **Sign in with ChatGPT**. This uses your ChatGPT plan's included Codex usage (see [pricing](README.md#plans-pricing-and-auth)) and unlocks cloud features. Tokens refresh automatically during use.

**Headless or remote machines:** use device-code auth (beta) — `codex login --device-auth`, or **Sign in with Device Code** in the login UI. It must first be enabled in your ChatGPT security settings (personal) or workspace permissions (admin). As a fallback, log in on a machine with a browser and copy `~/.codex/auth.json` to the headless machine.

### Option B: API key

```bash
printenv OPENAI_API_KEY | codex login --with-api-key
```

API-key usage is billed to your OpenAI Platform account, model access follows your API organization and project, and cloud features (GitHub review, Slack) aren't available. For a single non-interactive run, set `CODEX_API_KEY` inline instead of logging in:

```bash
CODEX_API_KEY=<api-key> codex exec --json "triage open bug reports"
```

### Option C: Access token

Workspaces can issue access tokens for programmatic workflows:

```bash
printenv CODEX_ACCESS_TOKEN | codex login --with-access-token
```

### Credential storage

Credentials are cached and shared by the CLI and IDE extension, either in `~/.codex/auth.json` (plaintext) or your OS credential store. Choose with `cli_auth_credentials_store` in `config.toml`:

```toml
# file | keyring | auto | ephemeral
cli_auth_credentials_store = "keyring"
```

Treat `~/.codex/auth.json` like a password — it contains access tokens. Never commit it.

Check what's active with `codex login status` (exits `0` when credentials are present — handy in scripts). Sign out with `codex logout` or `/logout`.

**Managed environments** can force a login method or workspace:

```toml
forced_login_method = "chatgpt"   # or "api"
forced_chatgpt_workspace_id = "00000000-0000-0000-0000-000000000000"
```

Source: [Authentication](https://learn.chatgpt.com/docs/auth).

---

## Initial Configuration

### config.toml

User config lives at `~/.codex/config.toml` (the directory is `$CODEX_HOME`, default `~/.codex`). Projects can add `.codex/config.toml`, which loads **only when you trust the project**. A minimal starting point:

```toml
# ~/.codex/config.toml
model = "gpt-6.1-sol"              # omit to use the recommended default
model_reasoning_effort = "medium"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
web_search = "cached"              # default; "live" = same as --search

[sandbox_workspace_write]
network_access = false             # default; set true to let commands reach the network
```

Only set `model` to a model your plan can use; otherwise leave it out. Full option coverage is in [usage.md](usage.md#configtoml).

### AGENTS.md

Generate a starter file for your repo with `/init` inside a session, and put personal working agreements in `~/.codex/AGENTS.md`. See [usage.md](usage.md#agentsmd).

### Key environment variables

| Variable | Purpose |
|----------|---------|
| `CODEX_HOME` | Root for config, auth, logs, sessions, and skills (default `~/.codex`; must already exist if set) |
| `CODEX_API_KEY` | API key for a non-interactive process (`codex exec`, `codex review`, TypeScript SDK) |
| `CODEX_INSTALL_DIR` | Where the standalone installer puts the `codex` command |
| `RUST_LOG` | Log verbosity (Codex is written in Rust) |

Sources: [Config basics](https://learn.chatgpt.com/docs/config-file/config-basic), [Environment variables](https://learn.chatgpt.com/docs/config-file/environment-variables).

---

## Verifying the Install

```bash
codex login status      # confirms credentials
codex doctor            # install, config, auth, runtime, Git, terminal, app-server health
codex exec "Say hello and name the model you are running as"   # end-to-end check
```

Inside a session, `/status` shows the active model, approval policy, writable roots, and remaining context. `/debug-config` prints config layers and requirements if a setting isn't taking effect.

---

## Upgrade and Uninstall

### Upgrade

```bash
codex update                          # self-update, when the installed release supports it

# or re-run the installer / package manager
curl -fsSL https://chatgpt.com/codex/install.sh | sh
npm install -g @openai/codex
brew upgrade --cask codex
```

### Uninstall

```bash
npm uninstall -g @openai/codex        # npm install
brew uninstall --cask codex           # Homebrew install
```

For the standalone installer, remove the `codex` command from its install directory. Delete `~/.codex` only if you also want to remove config, credentials, sessions, and skills.

---

## Windows Notes

- **Native:** the PowerShell installer plus the native Windows sandbox. Codex prefers **MXC** when the device and policy support it, with `elevated` / `unelevated` as legacy fallbacks (`[windows] sandbox = "elevated"` in `config.toml`). Run `/setup-default-sandbox` if Codex offers the elevated setup.
- **WSL2:** Codex runs inside Linux and uses the Linux sandbox. Choose it when your repos and tooling already live in WSL2. **WSL1 is no longer supported** as of Codex 0.115 (the Linux sandbox moved to bubblewrap).
- **IDE extension on Windows** supports WSL2 directly and can be configured to keep the agent inside WSL2 whenever available.

Sources: [WSL](https://learn.chatgpt.com/docs/windows/wsl), [Agent approvals & security](https://learn.chatgpt.com/docs/agent-approvals-security), [Config basics](https://learn.chatgpt.com/docs/config-file/config-basic).

---

## Common Install Issues

### `command not found: codex`

- Standalone install: add `~/.local/bin` (or your `CODEX_INSTALL_DIR`) to `PATH`.
- npm install: run `npm prefix -g` and add its `bin` directory to `PATH`.

### Browser login never completes

The OAuth flow returns to a localhost callback; remote shells, containers, or strict local firewalls can block it. Use `codex login --device-auth`, or copy `auth.json` from a machine where the browser flow works.

### Corporate proxy / custom CA errors

Codex honors custom CA settings for login, HTTPS, and secure WebSocket connections. Direct `codex login` runs write a dedicated `codex-login.log` in your log directory — check it, or run `codex doctor`.

### Linux sandbox errors

The Linux sandbox uses `bwrap` (bubblewrap) plus `seccomp`. Inside some containers the sandbox can't initialize; test with `codex sandbox linux <command>` and, if the container is already isolated, run with an explicit sandbox setting appropriate for that environment.

### Config keys "do nothing"

You may be running an older or newer build than the docs you're reading. Start with `codex --strict-config` to error on unrecognized keys, and check `/debug-config`.

---

## Next Steps

- [Usage](usage.md) — interactive mode, `codex exec`, sandbox and approvals, `AGENTS.md`, config, slash commands
- [MCP and integration](mcp-and-integration.md) — MCP servers, CI, the GitHub Action, SDKs
- [Main Codex README](README.md)

---

**Last Updated**: 2026-10-21
