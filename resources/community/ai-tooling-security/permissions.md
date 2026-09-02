---
description: Why Autopilot and bypass modes are disabled, and how to set permission defaults so you are not prompted for every safe action.
title: 'AI tooling: Permission defaults'
resourceType: Documentation
tags:
  - Developer Guide
  - AI
  - Security
personas:
  - Developer
pageOnly: true
---

## AI tooling: Permission defaults

Learn how to reduce unnecessary approval prompts while keeping approval requirements for higher-risk actions. This page also explains why Bypass Approvals and Autopilot are disabled. For a shorter overview, start with [AI tooling security requirements](../AI-tooling-security-requirements.md).


## Why Autopilot and Bypass Approvals are turned off

Virtual Studio Code (VS Code) provides controls that determine how much an agent can do without asking for your approval.

With **Default Approvals**, VS Code follows your configured approval settings and asks you to review actions that require approval.

**Bypass Approvals** automatically approves tool callls instead of showing confirmation prompts. 

**Autopilot** goes further. It automatically approves tool calls, retries when errors occur and can respond to blocking questions so the agent can continue working without waiting for you. 

Bypass Approvals and Autopilot can therefore allow file edits, terminal commands and external tool calls to run without manual review. Autopilot can also auto-answer the agent's own questions so it keeps running on its own. A single global bypass means the agent never pauses to let you catch a destructive command, a data leak or a prompt-injection payload.

!!! danger "Enforced control"
    In B.C. government-managed environments, Bypass Approvals and Autopilot are disabled centrally and must not be enabled. Keep sessions on Default Approvals so the configured approval controls remain in effect.
    
    If you can enable Bypass Approvals or Autopilot in a managed environment, report it immediately rather than using it.

## Reduce unnecessary approval prompts

Approval prompts are useful only when developers review them before allowing an action. 

If too many low-risk actions require approval, developers may start approving prompts without reviewing them carefully. Instead of bypassing approvals, use Default Approvals with sandboxing and narrowly scoped approval rules. Require approval for actions that can change repository state, access external systems or use privileged tools.

Where appropriate, commit repository specific settings in `.vscode/settings.json` so every contributor use consistent defaults.

For example: 

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

Adjust the allow list to your stack, but keep the deny (`false`) entries: package scripts, cloud and cluster tools, database clients and network fetches are executable authority and should always prompt. 

Some related settings like `chat.agent.sandbox.enabled`, `chat.tools.terminal.enableAutoApprove`, `chat.tools.eligibleForAutoApproval` and the network-filter settings are managed centrally by the organization. When an organizational policy manages a setting, it takes precedence over repository settings.

## Suggested permission baseline

| Permission class | Suggested treatment |
|---|---|
| Read and search files in the current repository | Allow when the repository and information are trusted |
| Edit files in the current branch or worktree | Allow, with diff review before commit |
| Run trusted formatters, linters, builds and tests in the sandbox | Allow after reviewing and trusting the repository and  its scripts |
| Download or install dependencies | Require approval and use approved registries |
| Access the network or fetch arbitrary URLs | Require approval, unless access is explicitly allowed for an approved destination |
| Run package scripts from a new or untrusted repository | Require approval because packaged scripts can execute code |
| Use `oc`, `kubectl`, `az`, `terraform`, database clients, or secrets clients | Require approval and use a narrowly scoped non-production identity |
| Push a branch or open a pull request | Review changes and destination before proceeding |
| Access files outside the workspace, keychains, credential caches or SSH agents | Block by default |
| Escalate privileges, disable security controls or use bypass mode | Block |
| Modify production, retrieve production secrets, merge or deploy | Block in the local coding-agent environment |

## References

- [VS Code: Manage approvals and permissions](https://code.visualstudio.com/docs/agents/approvals)
- [VS Code: Enterprise AI settings](https://code.visualstudio.com/docs/enterprise/ai-settings)
- [GitHub: Configure enterprise-managed Copilot settings](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/configure-enterprise-managed-settings)
