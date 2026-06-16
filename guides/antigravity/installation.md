# Installing Google Antigravity

How to download, install, sign in to, and first-run Google Antigravity — Google's agent-first development platform built on Gemini 3.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Download](#download)
- [Install](#install)
- [Sign In](#sign-in)
- [First-Run Setup](#first-run-setup)
- [Creating Your First Project](#creating-your-first-project)
- [Account and Pricing](#account-and-pricing)
- [Browser Control Setup](#browser-control-setup)
- [Common Install Issues](#common-install-issues)

---

## Prerequisites

- A supported desktop OS: **macOS, Windows, or Linux**.
- A **Google account** to sign in. At launch the public preview was available for personal Gmail accounts with a free quota for premier models.
- Internet access (agents call hosted Gemini 3 and other models).

> Antigravity is a downloadable desktop application (a fork of Visual Studio Code), not a browser-only product or a CLI.

---

## Download

Download the installer for your operating system from the official download page:

- **Download page**: <https://antigravity.google/download>

Select your OS (macOS, Windows, or Linux) and grab the matching installer.

---

## Install

Run the downloaded installer for your platform and follow the prompts. Per Google's getting-started codelab, the high-level flow is:

1. **Download** the installer for your OS from the download page.
2. **Run the installer** application.
3. **Sign in** with your Google account and complete authentication.
4. **Review the security and data-use policy**, then continue.
5. **Pick a theme**.
6. **Review optional plugins** that integrate with Google developer tools (optional), then finish.

<!-- needs-research: confirm per-OS installer specifics (e.g., macOS .dmg vs Windows .exe, any package-manager install path) against official docs; the codelab describes a generic installer flow without per-OS file details. -->

---

## Sign In

Antigravity authenticates with **Login with Google**:

1. Launch Antigravity.
2. Choose **Login with Google** and complete the browser-based authentication flow.
3. Return to the app once authenticated.

This Google sign-in is what grants access to the Gemini 3 quota associated with your account/tier.

---

## First-Run Setup

After install and sign-in, you land in the main Antigravity interface. From the getting-started codelab, the initial setup covers:

- **Security and data-use policy** — review and accept.
- **Theme** — choose a color theme.
- **Optional plugins** — Google-developer-tools integrations you may install now or later.

You then see the main interface with a project-selection pane and options to create or open a project.

---

## Creating Your First Project

Per the codelab, projects are created and configured up front (each project gets its own isolated agent settings):

1. **New Project** — choose **Select Project → New Project**.
2. **Add folders** — click **Add Folder** and select the folder(s) to include. A project can contain one or multiple folders.
3. **Security settings** — choose a security preset (a default is provided). "All projects have their own isolated agent settings," so you can tune autonomy and permissions per project.
4. **Name and create** — name the project and click **Create**.

Once the project exists, greet the agent with a message to begin, or open the Editor to work hands-on. See [usage.md](usage.md) for day-to-day workflows.

Per-project settings (autonomy presets, agent behavior, local permissions, MCP tools) are reachable from the settings gear next to each project in the left navigation.
<!-- needs-research: confirm exact project-creation UI labels and the per-project settings options against official docs; sourced from a Google Cloud community tutorial. -->

---

## Account and Pricing

- **Account**: a Google account (personal Gmail supported in preview).
- **Public preview, free for individuals at launch.** Google's developer blog stated Antigravity was "available today in public preview, at no cost for individuals."
- **Tiers**: third-party trackers describe a **Free** tier plus paid **AI Pro** and **AI Ultra** plans (Google's standard AI subscription tiers). The free-tier agent-request allowance has been adjusted (reduced) more than once since the November 2025 launch.

> ⚠️ Exact free-tier daily limits and paid-plan prices have changed repeatedly during the preview and differ across sources. Verify current numbers on the [official site](https://antigravity.google/) before relying on them.
> <!-- needs-research: pin current Free/Pro/Ultra prices and the exact free-tier agent-request or credit allowance from an official Google source. -->

---

## Browser Control Setup

One of Antigravity's distinguishing features is that agents can drive a real browser to verify their work. Per Google Cloud community tutorials, browser control requires installing a **Chrome extension**, and browser access is gated by an allowlist:

- A **Browser URL Allowlist** restricts which URLs the agent may visit.
- The allowlist is described as living at `~/.gemini/antigravity/browserAllowlist.txt`.

<!-- needs-research: confirm the browser-extension requirement and the exact allowlist file path against official docs; sourced from a community tutorial, not primary docs. -->

See [agents.md](agents.md#browser-subagent) for how the browser subagent is used during agent runs.

---

## Common Install Issues

### Sign-in fails or loops

- Confirm you are using a supported Google account (personal Gmail is supported in preview).
- Complete the browser auth flow fully and return to the app.

### Model unavailable / quota errors

- Model availability depends on your account/tier; check the **Model Selection dropdown** for what your account can use.
- Free-tier quotas are limited and have changed during the preview — see [Account and Pricing](#account-and-pricing).

### Browser control not working

- Confirm the required browser extension is installed and the target URL is on the allowlist (see [Browser Control Setup](#browser-control-setup)).

### General

- Because Antigravity is a fast-moving public preview, when behavior diverges from this guide, the [official docs](https://antigravity.google/docs/home) are authoritative.

---

## Related Guides

- [Antigravity Overview](README.md)
- [Usage](usage.md) — Editor view, Agent Manager, running agents, Artifacts
- [Agents](agents.md) — the agent model, planning, autonomy, multi-agent work
- [Claude Code Guide](../claude-code/README.md)
- [Gemini CLI Guide](../gemini-cli/README.md)

---

**Last Updated**: 2026-06-16
