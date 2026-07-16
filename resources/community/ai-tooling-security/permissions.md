---
description: Why Autopilot and bypass modes are disabled, and how to set permission defaults so you are not prompted for every safe action.
title: 'AI Tooling: Permission Defaults'
resourceType: Documentation
tags:
  - Developer Guide
  - AI
  - Security
personas:
  - Developer
pageOnly: true
---

## AI Tooling: Permission Defaults

!!! abstract "On this page"
    How to keep Default Approvals from prompting you on every safe action (auto-approve read-only commands, keep prompting for the risky ones), and why Bypass Approvals and Autopilot are disabled. For the short version, start with [AI Tooling Security Requirements](../AI-tooling-security-requirements.md).

## Why Autopilot and Bypass Approvals are turned off

VS Code offers three permission levels: Default Approvals, Bypass Approvals, and Autopilot. Bypass Approvals and Autopilot auto-approve *every* tool call (file edits, terminal commands, and external tool calls) without asking, and Autopilot also auto-answers the agent's own questions so it keeps running on its own. A single global bypass means the agent never pauses to let you catch a destructive command, a data leak, or a prompt-injection payload.

!!! danger "Enforced control"
    In B.C. government-managed environments, Bypass Approvals and Autopilot are disabled centrally; you cannot turn them on. Keep sessions on Default Approvals, which respects the finer-grained approval settings below. If you find you *can* enable them, your environment may not be managed yet, so report it rather than using them.

## Don't get prompted to death

Manual approval only works if you actually read the prompts. If everything asks, developers approve reflexively and the protection is lost. Rather than bypassing approvals globally, auto-approve the safe, read-only things and keep prompting for the risky ones.

Commit the block below as `.vscode/settings.json` in your repository so every contributor gets the same defaults:

```jsonc
// .vscode/settings.json — safe agent defaults for a development repository.
// Commit this file so every contributor inherits the same guardrails.
{
  // Start every session on Default Approvals. Never Bypass Approvals or Autopilot.
  "chat.permissions.default": "default",

  // Run agent terminal commands in the OS sandbox (macOS/Linux/WSL2). Sandboxed
  // commands are auto-approved because they are contained — fewer prompts, safely.
  "chat.agent.sandbox.enabled": "on",

  // Restrict what the fetch tool and integrated browser can reach.
  "chat.agent.networkFilter": true,
  "chat.agent.allowedNetworkDomains": ["github.com", "api.github.com", "registry.npmjs.org"],

  // Auto-approve only safe, read-only commands. Everything else still asks.
  // `false` entries are hard blocks and take precedence over `true` entries.
  "chat.tools.terminal.autoApprove": {
    "/^git (status|diff|log|show|branch|remote)\\b/": true,
    "/^(ls|pwd|cat|head|tail|wc|grep|rg|find|echo|which|tree)\\b/": true,
    "/^(npm|pnpm|yarn) (run )?(test|lint|build|typecheck|format)\\b/": true,
    "/^(pytest|go test|mvn test|gradle test)\\b/": true,

    "rm": false,
    "sudo": false,
    "curl": false,
    "wget": false,
    "/^git (push|reset|clean|checkout)\\b/": false,
    "/\\b(oc|kubectl|az|aws|gcloud|terraform|helm)\\b/": false,
    "/\\b(psql|mysql|mongosh|redis-cli)\\b/": false
  }
}
```

Adjust the allow list to your stack, but keep the deny (`false`) entries: package scripts, cloud and cluster tools, database clients, and network fetches are executable authority and should always prompt. Some related settings (`chat.agent.sandbox.enabled`, `chat.tools.terminal.enableAutoApprove`, `chat.tools.eligibleForAutoApproval`, and the network-filter settings) are managed centrally by the organization; your repository settings layer on top.

## Suggested permission baseline

| Permission class | Suggested treatment |
|---|---|
| Read and search files inside the current repository | Allow. |
| Edit files inside the current branch or worktree | Allow, with diff review before commit. |
| Run trusted formatters, linters, builds, and tests inside the sandbox | Allow once the repository and scripts are trusted. |
| Download or install dependencies | Require approval; use approved registries. |
| Access the network or fetch arbitrary URLs | Require approval; restrict destinations. |
| Run package scripts from a new or untrusted repository | Require approval; scripts are executable code. |
| Use `oc`, `kubectl`, `az`, `terraform`, database clients, or secrets clients | Require approval and a scoped non-production identity. |
| Push a branch or open a pull request | Require review of the resulting diff and destination. |
| Access files outside the workspace, keychains, credential caches, or SSH agents | Block by default. |
| Escalate privileges, disable security controls, or use bypass mode | Block. |
| Modify production, retrieve production secrets, merge, or deploy | Block in the local coding-agent environment. |

## References

- [VS Code: Manage approvals and permissions](https://code.visualstudio.com/docs/agents/approvals)
- [VS Code: Enterprise AI settings](https://code.visualstudio.com/docs/enterprise/ai-settings)
- [GitHub: Configure enterprise-managed Copilot settings](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/configure-enterprise-managed-settings)
