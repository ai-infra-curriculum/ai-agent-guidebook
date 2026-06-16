# Installing Cursor

How to install Cursor on macOS, Windows, and Linux, import your VS Code setup, sign in, and choose a pricing tier.

---

## Table of Contents

- [System Requirements](#system-requirements)
- [Download and Install](#download-and-install)
- [First Run: Import from VS Code](#first-run-import-from-vs-code)
- [Sign-In and Account Creation](#sign-in-and-account-creation)
- [Pricing Tiers](#pricing-tiers)
- [Extensions and the Open VSX Registry](#extensions-and-the-open-vsx-registry)
- [Updating and Channels](#updating-and-channels)
- [Common Install Issues](#common-install-issues)
- [Next Steps](#next-steps)

---

## System Requirements

Cursor is a fork of VS Code, so its requirements mirror VS Code's. It runs on:

| Platform | Notes |
|----------|-------|
| macOS | Intel and Apple Silicon (universal build) |
| Windows | Windows 10/11, 64-bit |
| Linux | Debian/Ubuntu (`.deb`), Fedora/RHEL (`.rpm`), and `.AppImage` |

<!-- needs-research: Cursor does not publish a single authoritative minimum-OS-version table; the values above follow VS Code's baselines. Verify exact minimums at https://cursor.com/docs before quoting them. -->

A network connection is required: Cursor's AI features (Tab, Agent, indexing) run against Cursor's cloud backend.

---

## Download and Install

Download the installer for your platform from <https://cursor.com>.

### macOS

1. Open the downloaded `.dmg`.
2. Drag **Cursor** into **Applications**.
3. Launch it from Applications (you may need to approve it in System Settings → Privacy & Security on first open).

### Windows

1. Run the downloaded `.exe` installer.
2. Follow the wizard.
3. Launch Cursor from the Start menu.

### Linux

Use the package for your distribution, or the portable AppImage:

```bash
# AppImage (portable)
chmod +x Cursor-*.AppImage
./Cursor-*.AppImage

# Debian/Ubuntu
sudo dpkg -i cursor_*.deb

# Fedora/RHEL
sudo rpm -i cursor-*.rpm
```

---

## First Run: Import from VS Code

On first launch, Cursor offers to import your VS Code configuration in one step — **extensions, settings, themes, and keybindings**. If you skip it, you can run the import later:

1. Open Cursor Settings (`Cmd/Ctrl+Shift+J`).
2. Go to **General → Account**.
3. Under **VS Code Import**, click **Import**.

This makes the transition seamless for existing VS Code users. Note the caveat in [Extensions and the Open VSX Registry](#extensions-and-the-open-vsx-registry) below: a small number of proprietary Microsoft extensions are not available.

Source: [Migrate from VS Code](https://cursor.com/docs/configuration/migrations/vscode).

---

## Sign-In and Account Creation

1. Click the account icon (or the **Sign In** button on the welcome screen).
2. Choose an authentication method:
   - **Email** — create or log into a Cursor account.
   - **GitHub** — OAuth; a browser opens, you authorize, and you're redirected back.
   - **Google** — OAuth; same flow.
   - **SAML/OIDC SSO** — for Team/Enterprise members, redirected to your organization's identity provider.
3. After authorizing, you're returned to the editor and signed in. One account works across macOS, Windows, and Linux.

Subscription, usage, and team settings are managed in your account dashboard at <https://cursor.com>.

---

## Pricing Tiers

Cursor moved to a usage-based model in 2025: every paid plan includes a pool of model usage, and **on-demand (usage-based) billing** lets you continue past the included amount, billed in arrears. The **Auto** model and Cursor's first-party **Composer** model draw from a separate, more generous pool than frontier third-party models.

Current plans (verify exact figures at <https://cursor.com/pricing>):

| Plan | Price | Includes |
|------|-------|----------|
| **Hobby** | Free | Limited Agent requests, limited Tab completions; no credit card required |
| **Pro** | $20/mo | Extended Agent limits, access to frontier models, MCPs/skills/hooks, cloud agents, Bugbot (on usage-based billing) |
| **Pro+** | $60/mo | Everything in Pro with a larger included usage allowance |
| **Ultra** | $200/mo | Everything in Pro with the largest allowance — includes API agent usage plus generous Auto and Composer usage |
| **Teams** | $40/user/mo | Centralized billing/admin, team rule/skill/plugin marketplace, agentic code review with Bugbot, shared team context, usage analytics, team-wide privacy mode, SAML/OIDC SSO |
| **Enterprise** | Custom | Everything in Teams plus pooled usage, invoice/PO billing, SCIM, access controls (repo/model/MCP), auto-run/browser/network controls, audit logs, AI code tracking API, priority support |

<!-- needs-research: The exact included-usage dollar amounts per tier (beyond Ultra's stated API agent usage) and the Pro+ allowance multiple are not consistently documented on the public pricing page. Confirm current included amounts at https://cursor.com/pricing before quoting specifics. -->

Sources: [Pricing](https://cursor.com/pricing), [Models & pricing](https://cursor.com/docs/models-and-pricing), [Clarifying our pricing (June 2025)](https://cursor.com/blog/june-2025-pricing).

---

## Extensions and the Open VSX Registry

Cursor installs extensions from the **Open VSX** registry, not the Microsoft VS Code Marketplace. Most popular open-source extensions are available, but some proprietary Microsoft-published extensions (and a few that are Marketplace-exclusive) are not, or behave differently.

Open the Extensions panel with `Cmd/Ctrl+Shift+X`. If an extension you need is missing, you can sometimes sideload it from a `.vsix` file, subject to its license.

Source: [Extensions](https://cursor.com/docs/configuration/extensions).

---

## Updating and Channels

Cursor updates itself in the background and prompts you to restart when a new version is ready. You can also check manually:

- macOS/Windows: the application menu offers **Check for Updates**.
- The current version is shown in **About Cursor**.

<!-- needs-research: Cursor does not document named release channels (stable/latest) the way some tools do. If you need a specific pinned version, check the changelog at https://cursor.com/changelog and the download page. -->

---

## Common Install Issues

### A VS Code extension is missing

Cursor uses Open VSX. If the extension is Marketplace-exclusive, it will not appear in search. See [Extensions and the Open VSX Registry](#extensions-and-the-open-vsx-registry).

### Import from VS Code didn't bring my settings

Re-run it from Settings (`Cmd/Ctrl+Shift+J`) → **General → Account → VS Code Import**. If it still fails, copy your VS Code `settings.json` and keybindings manually — Cursor reads the same files in its own config directory.

### Linux AppImage won't launch

Ensure it is executable (`chmod +x Cursor-*.AppImage`) and that FUSE is installed (`sudo apt install libfuse2` on recent Ubuntu). For desktop integration, prefer the `.deb`/`.rpm`.

### Sign-in browser loop

If the OAuth redirect doesn't return to Cursor, make sure the editor is allowed to register its URL handler, or use email sign-in as a fallback. Behind a corporate proxy, ensure outbound HTTPS to Cursor's domains is permitted.

### AI features fail but the editor works

Tab, Agent, and indexing require network access to Cursor's backend. Check your firewall/proxy allows outbound HTTPS to `cursor.com` and its API hosts; the plain editor works offline but the AI does not.

---

## Next Steps

- Learn the four core surfaces in [usage.md](usage.md): Tab, Inline Edit, Agent, and Chat.
- Set up project conventions in [rules-and-context.md](rules-and-context.md).
- Wire up external tools in [mcp-servers.md](mcp-servers.md).
- Read [best-practices.md](best-practices.md) before turning the agent loose on a real repo.

---

## Related Guides

- [Cursor Guide (README)](README.md)
- [Cursor Usage](usage.md)
- [Cursor Rules and Context](rules-and-context.md)
- [Cursor MCP Servers](mcp-servers.md)
- [Cursor Best Practices](best-practices.md)
- [Claude Code Installation](../claude-code/installation.md)
- [GitHub Copilot Guide](../github-copilot/README.md)

---

**Last Updated**: 2026-06-16
</content>
