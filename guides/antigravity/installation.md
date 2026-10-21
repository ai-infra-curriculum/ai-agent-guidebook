# Installing Google Antigravity

How to install and sign in to each Antigravity surface — the desktop App, the CLI (`agy`), the IDE extensions, the standalone Antigravity IDE, and the SDK — plus first-run setup.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Which Surface to Install](#which-surface-to-install)
- [Antigravity App](#antigravity-app)
- [Antigravity CLI](#antigravity-cli)
- [IDE Extensions](#ide-extensions)
- [Antigravity IDE (Standalone)](#antigravity-ide-standalone)
- [Antigravity SDK](#antigravity-sdk)
- [Sign In](#sign-in)
- [Creating Your First Project](#creating-your-first-project)
- [Account and Pricing](#account-and-pricing)
- [Browser Setup](#browser-setup)
- [Common Install Issues](#common-install-issues)

---

## Prerequisites

- A supported OS: **macOS 12+** (Apple Silicon or Intel), **Windows 10 (64-bit) or 11**, or **Linux** with glibc ≥ 2.28 and glibcxx ≥ 3.4.25.
- A **Google Account** (18+, in a supported region) on a Free, Google AI Plus, Pro, or Ultra plan — or a Gemini Enterprise / Google Cloud project for business use.
- Internet access (agents call hosted models).
- **Google Chrome** if you want the browser subagent (see [Browser Setup](#browser-setup)).

---

## Which Surface to Install

| You want… | Install |
|-----------|---------|
| A command center for many agents, Artifact review, browser verification | **Antigravity App** |
| A terminal agent, SSH/remote use, or scripting/CI | **Antigravity CLI** (`agy`) — see [cli.md](cli.md) |
| Antigravity agents inside your existing editor | An **IDE extension** |
| The original VS Code-fork editor with Tab completions | **Antigravity IDE** |
| Your own agents in Python | **Antigravity SDK** |

Google suggests pairing the App with an editor of your choice; the surfaces share settings under `~/.gemini/`.

---

## Antigravity App

Download the installer from <https://antigravity.google/download>:

- **macOS**: open `Antigravity.dmg` and drag **Antigravity** into **Applications** (choose **Replace** when upgrading).
- **Windows**: run the downloaded `.exe` and follow the setup wizard. WSL projects are supported (App v2.16.0+).
- **Linux**:

  ```bash
  tar -xzf Antigravity.tar.gz
  ./Antigravity
  ```

- **Googlebook**: pre-installed; update through Google Play.

Launch it, sign in (see [Sign In](#sign-in)), and create a project.

> If you used Antigravity 1.x: the 2.0 update installed the App as a **separate** application and asked whether to keep the IDE. The two coexist with different dock icons (App: logo on white; IDE: logo on a black grid).

---

## Antigravity CLI

```bash
# macOS / Linux / Googlebook
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

```powershell
# Windows (PowerShell)
irm https://antigravity.google/cli/install.ps1 | iex
```

```bat
:: Windows (CMD)
curl -fsSL https://antigravity.google/cli/install.cmd -o install.cmd && install.cmd && del install.cmd
```

The binary lands in `~/.local/bin/agy` (macOS/Linux) or `C:\Users\<username>\AppData\Local\agy\bin` (Windows). Verify with `agy --version`. As with any `curl | bash` installer, review the script first if your security policy requires it.

On first launch, `agy` asks for a color scheme, a rendering mode (**Alt-Screen** or **Inline**), and workspace trust. If it finds Gemini CLI configuration, it offers to migrate extensions, global config, and visual settings. See [cli.md](cli.md).

---

## IDE Extensions

| Editor | Minimum version | Install |
|--------|-----------------|---------|
| VS Code | 1.90 | Extensions sidebar → search **Google Antigravity** → Install |
| Visual Studio | Visual Studio 2026 (17.8+), Windows | Extensions → Manage Extensions → **Google Antigravity** → Download, restart |
| JetBrains (IntelliJ-based) | 2026.2.1 | JetBrains AI → Settings → Agents → **Antigravity** → Install |
| Zed | 0.140.0 (macOS/Linux) | Command Palette `agent: open settings` → External Agents → Add → Install from Registry → **Antigravity** |
| Xcode | Xcode 27 beta 6 (macOS) | Xcode → Settings → Intelligence → **Get** next to Antigravity |

VS Code and Visual Studio are GA; JetBrains, Zed, and Xcode are in Preview. Click the Antigravity icon and **Sign In** after installing.

---

## Antigravity IDE (Standalone)

1. Download the IDE installer from <https://antigravity.google/download> (same OS requirements as the App).
2. Install and launch it, then sign in when prompted.
3. Open the Agent Manager from the editor with `Cmd+E` (macOS) or `Ctrl+E` (Windows/Linux).

Google has said it plans to remove the Agent Manager from the IDE in a future release, making the IDE "a purely agent-powered IDE" while the App takes over orchestration. Gemini 4 Argon and the `/browser` subagent are not available in the standalone IDE.

---

## Antigravity SDK

The SDK is the `google-antigravity` Python package (Python 3.10+):

```bash
pip install google-antigravity
```

Authenticate with `GEMINI_API_KEY`, or with Gemini Enterprise via `vertex=True` in `LocalAgentConfig` (or `GOOGLE_GENAI_USE_VERTEXAI`, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_LOCATION` plus `gcloud auth application-default login`). Local models need no key. See the [SDK docs](https://antigravity.google/docs/sdk/overview).

---

## Sign In

### App (personal account)

Click **Sign in** and complete the browser OAuth flow with your Free, Pro, or Ultra Google Account. If a Google Workspace account fails, the FAQ suggests trying an @gmail.com address.

### App (enterprise)

Click **Sign in** → **Business account** → **Continue with Google Cloud** (or **Advanced WIF Configuration** for Workforce Identity Federation). Pick your license and project, or choose **Other** and enter a Project ID and location (`global`, `us`, or `eu`).

To use Application Default Credentials instead:

```bash
gcloud auth application-default login --project YOUR_PROJECT
export AGY_ADC_AUTH=true
```

or set `"enableAdc": true` under `userSettings` in `~/.gemini/config/config.json`.

### CLI

- **Local**: `agy` reuses a session from your OS keyring, otherwise opens your browser.
- **Remote / SSH**: `agy` prints an authorization URL; open it locally, sign in, and paste the code back.
- **Gemini API key**: set `"modelProvider": "gemini"` in `~/.gemini/antigravity-cli/settings.json` and export `GEMINI_API_KEY`.
- **Sign out**: `/logout`.

### IDE extensions

Click the Antigravity icon → **Sign In**. Enterprise users choose **Sign in with Gemini Enterprise**.

---

## Creating Your First Project

In the App, conversations live inside **projects**, each with its own agent settings and permissions:

1. Click the **New Project** icon in the left sidebar.
2. Click **Add Folder** and select one or more local Git repositories or working directories.
3. Click **Create**.
4. Type an instruction in the prompt box and press Enter.
5. Choose a **Mode** in the setup modal: **Local mode** (work directly in your folders) or **New worktree mode** (work in an isolated Git worktree).

You can also start one-off conversations outside any project; they run in an isolated local scratch folder. Per-project settings, including a permission preset that defaults to "Inherit General," live under **Settings → Projects** (see [agents.md](agents.md#autonomy-and-permissions)).

---

## Account and Pricing

- **Free or other plans**: a quota refreshed weekly, Gemini models (e.g., Gemini 3.8 Flash), unlimited Tab completions, and all product features including scheduled tasks and the CLI.
- **Google AI Pro / Ultra**: larger quotas refreshed every five hours up to a weekly limit, access to Gemini 4 Argon and Claude 5.5 models (not on Pro trials), and optional paid AI-credit overages.
- **Enterprise**: through Gemini Enterprise under Google Cloud terms.

See the [README](README.md#availability-and-pricing) for the May 2026 price changes, and confirm current numbers on the [plans page](https://antigravity.google/docs/plans).

---

## Browser Setup

The **browser subagent** (invoked with `/browser` in the App and CLI) controls **Google Chrome** through the Chrome DevTools MCP server, which Antigravity starts automatically. On first connection, Chrome asks you to allow remote debugging — accept it. Sessions are recorded as WebM videos in the conversation's Artifacts.

In the standalone **Antigravity IDE**, the browser runs in a separate Chrome profile and URL access is governed by a server-side **denylist** plus a local **allowlist** that starts with only `localhost`; unknown URLs prompt with **Always allow**. Disable browser tools entirely with the **Browser Tools** toggle in settings. An administrator can also disable browser access.

See [agents.md](agents.md#the-browser-subagent) for how agents use it.

---

## Common Install Issues

### `agy: command not found`

Add the install directory to `PATH` — `~/.local/bin` on macOS/Linux, `%LOCALAPPDATA%\agy\bin` on Windows — and open a new shell.

### Sign-in fails or loops

- Check that your account is a personal Google Account in a supported region and that you are 18+ (or verify your age in your Google Account).
- For Workspace accounts, use the **Business account** flow with a Google Cloud project, or try an @gmail.com account.
- In the CLI over SSH, use the printed URL-and-code flow rather than expecting a local browser.

### Model unavailable / quota errors

- Some models require a paid Pro or Ultra plan and are excluded from free trials. Check the model selector.
- Free plans refresh weekly; Pro/Ultra every five hours up to a weekly cap. Use `/usage` (CLI) or **View Usage** (App).

### Browser control not working

- Confirm Chrome is installed and that you accepted the remote-debugging prompt.
- `/browser` is not available in the standalone IDE — use the App or CLI.

### Linux binary won't start

Check `ldd --version` — the App, IDE, and CLI require glibc ≥ 2.28.

### General

Antigravity ships updates weekly; when behavior diverges from this guide, the [official docs](https://antigravity.google/docs/overview) are authoritative.

---

## Related Guides

- [Antigravity Overview](README.md)
- [Usage](usage.md) — projects, conversations, Artifacts, review, MCP, scheduling
- [Agents](agents.md) — planning, permissions, subagents, browser, rules and skills
- [Antigravity CLI](cli.md) — `agy` interactive and headless use
- [Claude Code Guide](../claude-code/README.md)
- [Gemini CLI Guide](../gemini-cli/README.md)

---

**Last Updated**: 2026-10-21
