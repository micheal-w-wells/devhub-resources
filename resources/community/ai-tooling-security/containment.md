---
description: Two complementary ways to limit an agent's blast radius — least-privilege identities and process sandboxing — plus how to protect workstation credentials.
title: 'AI Tooling: Contain the Agent'
resourceType: Documentation
tags:
  - Developer Guide
  - AI
  - Security
personas:
  - Developer
pageOnly: true
---

## AI Tooling: Contain the Agent

> Detailed guidance for [AI Tooling Security Requirements](../AI-tooling-security-requirements.md). Start there for the short version.

Two different controls keep a coding agent from turning a mistake — or a prompt-injection payload — into an incident. They are complementary layers, and you want both:

1. **Least-privilege identity** — limit *what the agent is authorized to do* against real systems (the tokens, roles, and scopes it runs with). Even a perfectly sandboxed agent holding a production-admin token is dangerous.
2. **Sandboxing** — limit *what the agent's process can reach* on your workstation (files, network, credential stores). Even a narrowly scoped identity is dangerous if the agent can read every file and secret on your machine.

This is guidance, not policy. It does not forbid `oc`, `kubectl`, `az`, database clients, or infrastructure tooling — those are part of the job. It explains what can go wrong and how to reduce the blast radius.

## Part 1 — Least-privilege identity

### What can go wrong

A coding agent runs commands on your behalf using whatever identity is active in your terminal. When you paste an `oc login` command copied from the web console, or run the agent in a shell that already has your Azure or database sessions, the agent — and any command it decides to run — can do **everything you can do**.

An agent does not carry your organizational context. It may take a technically reasonable action that is operationally catastrophic:

- delete or scale down a running production workload it believes is unused;
- run a destructive database statement (`DROP`, `DELETE`, `UPDATE` without a `WHERE`) while "cleaning up";
- apply infrastructure changes directly to production instead of proposing them;
- read a production secret or citizen data and echo it into a log, commit, or pull request; or
- act on a poisoned instruction from a web page, issue, or tool output (prompt injection).

Many of these actions are **irreversible** and can affect citizens, not just your team. The risk is not the command name — it is the **identity, environment, and scope** the command runs with.

### Reduce the blast radius

| Instead of… | Do this… | Because… |
|---|---|---|
| Pasting your personal `oc login` token into the agent's shell | Use a namespace-scoped service-account token in a separate kubeconfig (below) | Your personal token carries all your access across every project and cluster you can reach. |
| Running the agent with your default `az` / production session active | Use a development-scoped identity limited to a dev resource group | A broad Owner/Contributor or PIM-elevated session lets the agent change production. |
| Letting the agent query a production database directly | Point it at a local or disposable dev database with synthetic data | Read-only mistakes still leak data; write mistakes are often unrecoverable. |
| Having the agent deploy from your laptop | Have it open a pull request; deploy through protected CI/CD | Review and a workload identity keep a local mistake out of production. |

Read-only is safer than write, but a read against production data can still expose information above Protected A. Prefer synthetic data first.

### OpenShift: give the agent a scoped token, not your login

When a developer copies an `oc login` command from the OpenShift web console, it uses their **personal OAuth token** (`oc whoami --show-token`) — which carries every permission that developer has, in every namespace and cluster they can reach. Pasting that into an agent's terminal hands all of it over.

Instead, mint a short-lived token for a dedicated service account scoped to a single development namespace, and give the agent its own kubeconfig:

```sh
# 1. Create a dedicated service account in YOUR development namespace.
oc create serviceaccount agent-dev -n <your-dev-namespace>

# 2. Grant it only what the task needs, scoped to that one namespace.
#    Use "view" for read-only; "edit" to let it change objects in this namespace only.
oc create rolebinding agent-dev-binding \
  --clusterrole=edit \
  --serviceaccount=<your-dev-namespace>:agent-dev \
  -n <your-dev-namespace>

# 3. Mint a short-lived token (OpenShift 4.11+ / Kubernetes 1.24+).
oc create token agent-dev -n <your-dev-namespace> --duration=1h

# 4. Put it in a SEPARATE kubeconfig — never the agent's copy of ~/.kube/config.
KUBECONFIG=~/.kube/agent-dev.config oc login \
  --token=<token-from-step-3> \
  --server=https://api.<cluster-domain>:6443
```

Then run the agent with `KUBECONFIG=~/.kube/agent-dev.config`, and confirm the scope before you start:

```sh
oc auth can-i --list --kubeconfig ~/.kube/agent-dev.config
```

A `RoleBinding` (not a `ClusterRoleBinding`) keeps even the built-in `edit`/`view` roles limited to the one namespace. Red Hat's [OpenShift RBAC guidance](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/authentication_and_authorization/using-rbac) explains project-scoped versus cluster-wide roles. Keep your personal `~/.kube/config`, production contexts, and cluster-admin credentials out of the agent environment.

### Azure: use a development-scoped identity

Give the agent an identity limited to the relevant development resource group — not subscription-wide Owner, User Access Administrator, a broad Contributor assignment, an active PIM elevation, or cached credentials that also reach production. Microsoft's [Azure RBAC best practices](https://learn.microsoft.com/en-us/azure/role-based-access-control/best-practices) recommend least privilege and narrow scopes, and [Privileged Identity Management](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure) keeps privileged access just-in-time. For deployment, prefer a reviewed pull request and a protected workflow using a workload identity — see [GitHub Actions authentication to Azure with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect).

### Production databases

Normal agent work should use a local database, a disposable dev database, synthetic test data, or a minimal sanitized reproduction. If you are working a real incident, an agent can help you *draft* a query or reason about sanitized results — but run it yourself against a read-only, narrowly scoped connection, and have a second person review anything that touches production. Do not let the agent hold standing production access, write production records, alter schemas, or execute unreviewed remediation.

## Part 2 — Sandboxing and workstation credentials

### Why this matters

By default, a coding agent runs as **you**. Without a sandbox, the agent — and any terminal command it runs — can read anything your user account can read and use any credential your account can use. In practice that means it could:

- read files anywhere on your workstation, including documents classified **above Protected A** that have nothing to do with the repository;
- use your credential stores (`~/.ssh`, `~/.kube`, `~/.azure`, OS keychains, browser sessions) to act as you against real systems; and
- be steered into doing any of the above by a **prompt-injection** payload hidden in a web page, issue, dependency, or tool result.

Sandboxing shrinks that reach so a mistake — or a malicious instruction — stays contained. It also **reduces approval prompts**, because commands that run inside the sandbox are auto-approved.

### Sandboxing in the IDE

VS Code can run agent terminal commands inside an OS-level sandbox that restricts file-system and network access (macOS and Linux, including WSL2):

```jsonc
{
  // Run agent terminal commands in the sandbox.
  "chat.agent.sandbox.enabled": "on",

  // Restrict which domains the fetch tool and browser can reach.
  "chat.agent.networkFilter": true,
  "chat.agent.allowedNetworkDomains": ["github.com", "api.github.com", "registry.npmjs.org"],

  // Grant read access to specific config paths, and block sensitive paths outright.
  "chat.agent.sandbox.fileSystem.mac": {
    "allowWrite": ["."],
    "denyRead": ["~/.ssh", "~/.aws", "~/.azure", "~/.kube"]
  }
}
```

By default, sandboxed commands can write only to the working directory, reads from your home directory are denied, and outbound network access is blocked unless you allow specific domains. See [Manage approvals and permissions](https://code.visualstudio.com/docs/agents/approvals) and [Agent sandboxing](https://code.visualstudio.com/docs/agents/concepts/trust-and-safety#_agent-sandboxing). Some of these settings are managed centrally by the organization.

### Sandboxing in the CLI

Command-line agents such as GitHub Copilot CLI run terminal commands too, so they need the same containment. GitHub documents [local sandbox configuration](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/configuring-local-sandbox-settings) for restricting file-system and network access. When a Copilot CLI session uses the VS Code agent terminal integration, the VS Code sandbox settings above apply to it as well.

### Sandboxing is defence in depth, not a complete boundary

Use it, but do not treat it as the only control:

- some sandboxing features are in preview and still evolving;
- a sandbox may cover only particular tools or terminal processes;
- extensions, MCP servers, setup scripts, container mounts, and forwarded credentials can create separate paths; and
- a sandbox cannot compensate for an identity that already has excessive permissions (Part 1).

### Protect your credential stores

Whether or not a sandbox is active, keep these out of the agent's reach: `~/.ssh`, `~/.kube`, `~/.azure`, and cloud credential caches; OS keychains and password-manager sockets; browser profiles and saved sessions; and shell history containing secrets.

Practical habits:

- **Use separate, non-production contexts** (a dedicated `KUBECONFIG` or isolated Azure CLI config), as in Part 1.
- **Keep privileged work in a separate session.** Do not activate PIM or log into a production cluster and then keep working in an agent session that can read the same credential cache.
- **Reset disposable environments.** Rebuild or discard an agent workspace after installing dependencies or evaluating an unfamiliar repository.

For higher-risk work — such as evaluating an untrusted repository — a dev container, disposable VM, or remote development environment with no host credential forwarding adds a stronger boundary. This is an option for risky tasks, not a requirement for everyday development. Dev containers are not automatically a credential boundary: VS Code can forward Git credentials and SSH keys into a container, so configure that deliberately. See [Developing inside a container](https://code.visualstudio.com/docs/devcontainers/containers).

### Cloud agents

A cloud coding agent does not inherit your local credential cache, which removes one class of risk. Its boundary is instead the repository, configured secrets, tools, MCP servers, network access, branch protections, and workflow permissions. Do not store production credentials as cloud-agent secrets, keep required reviews and firewall protections enabled, and treat the agent's pull request as an untrusted proposed change until CI and an independent human review are complete.

## References

- [VS Code: Manage approvals and permissions](https://code.visualstudio.com/docs/agents/approvals)
- [VS Code: Trust and safety (agent sandboxing)](https://code.visualstudio.com/docs/agents/concepts/trust-and-safety)
- [GitHub: Configure local sandbox settings](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/configuring-local-sandbox-settings)
- [VS Code: Developing inside a container](https://code.visualstudio.com/docs/devcontainers/containers)
- [OpenShift RBAC](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/authentication_and_authorization/using-rbac)
- [Azure RBAC best practices](https://learn.microsoft.com/en-us/azure/role-based-access-control/best-practices)
- [Microsoft Entra Privileged Identity Management](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure)
- [Authenticate GitHub Actions to Azure with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
