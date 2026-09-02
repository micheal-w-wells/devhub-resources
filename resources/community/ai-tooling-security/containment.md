---
description: Two complementary ways to limit an agent's blast radius (least-privilege identities and process sandboxing), plus how to protect workstation credentials.
title: 'AI tooling: Contain the Agent'
resourceType: Documentation
tags:
  - Developer Guide
  - AI
  - Security
personas:
  - Developer
pageOnly: true
---

## AI tooling: Contain the agent

Learn how to limit an agent's potential impact, also known as its blasts radius, through two layers: least-privilege identities and workstation sandboxing. Least-privilege identities control what an agent may do in real systems. Workstation sandboxing controls what its process may access. Read this page before giving an agent access to a cluster, database or cloud environment. For a summary, see [AI tooling security requirements](../AI-tooling-security-requirements.md).

Two controls can reduce the chance that a coding agent turns a mistake or prompt injection into an incident. The controls complement each other, so use both:

1. **Least-privilege identity** limits what the agent is authorized to do against real systems through the tokens, roles and scopes it uses. Even a fully sandboxed agent can create serious risk if it holds a production administrator token
2. **Sandboxing** limits what the agent's process may access on your workstation, including files, networks and credential stores. Even a narrowly scoped identity can create serious risk if the agent can read every file and secret on your computer

This page provides guidance, not policy. It does not prohibit `oc`, `kubectl`, `az`, database clients or infrastructure tools. These tools are part of development work. You will be able to learn what can go wrong and how to reduce the blast radius.

## Part 1: Least-privilege identity

### Understand what can go wrong

A coding agent runs commands on your behalf through the identity active in your terminal. The agent does not receive special powers. Each command it runs is a child process of your shell, so it may inherit environment variables such as `KUBECONFIG`, `AWS_PROFILE` and tokens. It may also access the same credential caches as your user account, including `~/.kube/config`, `~/.azure`, `~/.aws` and operating system keychains.

As a result, an `oc`, `kubectl`, `az` or `psql` command may authenticate as if you had entered it yourself. GitHub describes similar behaviour for Copilot CLI: It can run any shell command that you can run. If you paste an `oc login` command from the web console or run an agent in a shell with an active Azure or database session, the agent and its commands may receive the same access as you.

An agent may lack important organizational context. It may take an action that appears technically reasonable but has serious operational consequences, such as:

- Deleting or scaling down a running production workload it believes is unused
- Running a destructive database statement such as `DROP`, `DELETE`, `UPDATE` without a `WHERE` clause while cleaning up
- Applying infrastructure changes directly to production instead of proposing them for review
- Reading a production secret or citizen data and exposing it in a log, commit or pull request
- Following a malicious instruction hidden in a web page, issue or tool output through prompt injection

Some of these actions may be difficult or impossible to reverse and may affect citizens as well as your team. The risk comes from the identity, environment and scope in which the command runs, not from the command name alone.

### Reduce the blast radius

| Instead of… | Do this… | Because… |
|---|---|---|
| Pasting your personal `oc login` token into the agent's shell | Use a namespace-scoped service account token in a separate kubeconfig as described below | Your personal token carries all your permissions across every project and cluster |
| Running the agent with your default `az` or production session is active | Use a development-scoped identity limited to a development resource group | An Owner, contributor or PIM-elevated session may allow the agent to change production resources |
| Letting the agent query a production database directly | Point it at a local or disposable development database with synthetic data | Read operations can expose data and write operations that can cause irreversible damage |
| Letting the agent deploy from your workstation | Ask it open a pull request, then deploy through protected CI/CD | Human review and a workload identity help keep a local mistakes out of production |
| Giving the agent a credential so it can reach a service directly | Put the credential behind a purpose-built tool or MCP server that exposes only the operations the task needs | The raw secret stays out of the agent's shell and model context while the tool limits what the agent can do |

Read-only access is safer than write access, but a reading production data can still expose information classified above Protected A. Use synthetic data wherever possible.

### Prefer no credential, then a mediated tool, then a scoped identity

When an agent needs to affect a real system such as a cluster, database or cloud environment, use the following options in order. Stop when an option meets the needs of the task:

1. **No standing credential, which is preferred.** The agent proposes a change. A reviewed CI/CD pipeline uses a short-lived [workload identity](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect) to perform the privileged action. The agent holds no credential that can access production
2. **Mediated access through a scoped tool or MCP server.** If the agent must interact with a service during development, place the service behind a purpose-built tool or MCP server. Give the tool its own least-privilege credential through a secrets store and never commit the credential. Expose only the operations required for the task. For example provide a tool that runs parameterized read queries instead of providing a raw database shell. The agent can call the tool but cannot see the underlying secret. This approach limits risk but does not remove it. A tool that allows arbitrary SQL creates the same blast radius as direct database access. Treat the tool or MCP server as a trusted intermediary that requires least-privilege access and security reviews. See [Extensions, skills, hooks, and MCP servers](extensions.md).
3. **A scoped, short-lived, non-production identity as fallback.** If the agent must run `oc`, `kubectl`, `az`, or a database client, give it a narrowly-scoped and time-boxed non-production token in an isolated configuration. Never use your personal login or a production session. The OpenShift example below shows this approach

Giving an agent a token should never be the *first* choice. Use one only when options 1 and 2 do not meet the needs of the task and scope as narrowly as possible.

### OpenShift: If the agent needs cluster access, scope the token tightly

When you copy an `oc login` command from the OpenShift web console, it uses your personal OAuth token (`oc whoami --show-token`). The token carries every permission that your account has, in every namespace and cluster that issued it. Pasting the command into an agent's terminal gives the agent those permissions.

Instead, create a short-lived token for a dedicated service account. Limit the service account to one single development namespace and give the agent a separate kubeconfig:

```sh
# 1. Create a dedicated service account in your development namespace
oc create serviceaccount agent-dev -n <your-dev-namespace>

# 2. Grant only the access required for the task in that namespace
#    Use "view" for read-only; "edit" to let it change objects in this namespace only.
oc create rolebinding agent-dev-binding \
  --clusterrole=edit \
  --serviceaccount=<your-dev-namespace>:agent-dev \
  -n <your-dev-namespace>

# 3. Create a short-lived token (OpenShift 4.11+ / Kubernetes 1.24+)
oc create token agent-dev -n <your-dev-namespace> --duration=1h

# 4. Store it in a separate kubeconfig instead of your personal ~/.kube/config
KUBECONFIG=~/.kube/agent-dev.config oc login \
  --token=<token-from-step-3> \
  --server=https://api.<cluster-domain>:6443
```

Then run the agent with `KUBECONFIG=~/.kube/agent-dev.config`. Before you start, confirm what the service account can do:

```sh
oc auth can-i --list --kubeconfig ~/.kube/agent-dev.config
```

A `RoleBinding` (not a `ClusterRoleBinding`) limits the built-in `edit`/`view` role to one namespace. Red Hat's [OpenShift RBAC guidance](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/authentication_and_authorization/using-rbac) explains project-scoped and cluster-wide roles. Keep your personal `~/.kube/config`, production contexts and cluster-admin credentials out of the agent's environment.

### Azure: Use a development-scoped identity

Give the agent an identity limited to the relevant development resource group. Do not give it subscription-wide Owner or User Access Administrator, a broad Contributor assignment, active Privileged Identity Management (PIM) elevation or cached credentials that can access production. 

Microsoft's [Azure RBAC best practices](https://learn.microsoft.com/en-us/azure/role-based-access-control/best-practices) recommend least privilege and narrow scopes. [Privileged Identity Management](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure) provides just-in-time privileged access. For deployments, use a reviewed pull request and a protected workflow using a workload identity. See [GitHub Actions authentication to Azure with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect).

If the agent must use `az` directly in development, assign a role for one development resource group instead of reusing your session:

```sh
# Grant a dedicated development identity Contributor access to one resource group (not the subscription).
az role assignment create \
  --assignee <agent-dev-identity-id> \
  --role Contributor \
  --scope /subscriptions/<sub-id>/resourceGroups/<your-dev-rg>
```

Use a workload identity and CI/CD for shared or production environments. A service-principal secret stored on your workstation is another credential that you must protect.

### Protect production databases

For routine development, use a local database, a disposable development database, synthetic test data or minimal sanitized reproduction. If you are working a real incident, an agent may help you draft a query or assess sanitized results. However, run the query yourself against a read-only and narrowly scoped connection. Ask a second person to review anything that affects production. 

Do not give the agent standing production access or allow it to write production records, alter schemas or execute unreviewed remediation.

## Part 2: Sandboxing and workstation credentials

### Understand why sandboxing matters

A local coding agent may run with your user account's permissions. Without a sandbox, the agent and any terminal commands it runs may read anything your account can read and use any credential your account can use. For example, it could:

- Read files anywhere on your workstation, including unrelated documents classified above Protected A 
- Use your credential stores such as `~/.ssh`, `~/.kube`, `~/.azure`, OS keychains and browser sessions to act as you against real systems
- Follow a prompt-injection payload hidden in a web page, issue, dependency or tool result and perform either of these actions

Sandboxing limits this access so a mistake or a malicious instructions are more likely to stay contained. Depending on the tool and its configuration, sandboxed commands may also require fewer approval prompts.

### Sandboxing in the IDE

Visual Studio Code (VS Code) can run agent terminal commands in an operating system-level sandbox that limits file system and network access on supported operating systems, including macOS, Linux and Windows Subsystem for Linux 2 (WSL2):

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

By default, the sandbox allows commands to write only to the working directory, denies reads from your home directory and blocks outbound network access unless you allow specific domains. See [manage approvals and permissions](https://code.visualstudio.com/docs/agents/approvals) and [agent sandboxing](https://code.visualstudio.com/docs/agents/concepts/trust-and-safety#_agent-sandboxing). Your organization manages some of these settings centrally.

### Sandboxing in the CLI

Command-line agents such as GitHub Copilot CLI run terminal commands, so apply the same containment principles. GitHub provides instructions for configuring [local sandbox configuration](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/configuring-local-sandbox-settings) to limit file-system and network access. If a Copilot CLI session uses the VS Code agent terminal integration, confirm whether the VS Code sandbox settings above apply to that session before relying on them.

### Sandboxing is defence in depth, not a complete boundary

Use sandboxing as one control, not as a complete security boundary:

- Some sandboxing features are in preview and continue to evolve
- A sandbox may apply only to specific tools or terminal processes
- Extensions, MCP servers, setup scripts, container mounts and forwarded credentials may provide other paths to sensitive resources
- A sandbox cannot compensate for an identity with excessive permissions as explained in: [Part 1: Least-privilege identity](#part-1-least-privilege-identity).

### Protect credential stores

Whether or not a sandbox is active, keep the following resources out of the agent's reach:

- SSH Keys and configuration in  `~/.ssh`
- Kubernetes configuration in `~/.kube`
- Azure confirmation in `~/.azure` and cloud credential caches
- OS keychains and password manager sockets
- Browser profiles and saved sessions
- Shell history that contain secrets

Follow these practices:

- Use separate non-production contexts, such as a dedicated `KUBECONFIG` or isolated Azure CLI configuration, as described in [Part 1: Least-privilege identify](#part-1-least-privilege-identity)
- Keep privileged work in a separate session. Do not activate PIM or log into a production cluster and continue using an agent session that can read the same credential cache
- Reset disposable environments. Rebuild or discard an agent workspace after installing dependencies or evaluating an unfamiliar repository.

For higher-risk work, such as evaluating an untrusted repository, use a dev container, disposable VM or remote development environment that does not forward host credentials. These options create a stronger security boundary. Use them for risky tasks, but you do not need them for everyday development. Keep in mind that dev containers do not automatically create a credential boundary. VS Code can forward Git credentials and SSH keys into a container, so configure credential forwarding deliberately. For more information see [developing inside a container](https://code.visualstudio.com/docs/devcontainers/containers).

### Secure cloud agents

A cloud coding agent does not inherit your local credential cache, which removes one source of risk. Its access depends on the repository, configured secrets, tools, MCP servers, network access, branch protection rules and workflow permissions. Do not store production credentials as cloud agent secrets. Keep required reviews and firewall protections enabled. Treat the agent's pull request as an untrusted proposed change until continuous integration (CI) checks pass and an independent person reviews it.

## References

- [VS Code: Manage approvals and permissions](https://code.visualstudio.com/docs/agents/approvals)
- [VS Code: Trust and safety (agent sandboxing)](https://code.visualstudio.com/docs/agents/concepts/trust-and-safety)
- [GitHub: Configure local sandbox settings](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/configuring-local-sandbox-settings)
- [VS Code: Developing inside a container](https://code.visualstudio.com/docs/devcontainers/containers)
- [OpenShift RBAC](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/authentication_and_authorization/using-rbac)
- [Azure RBAC best practices](https://learn.microsoft.com/en-us/azure/role-based-access-control/best-practices)
- [Microsoft Entra Privileged Identity Management](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure)
- [Authenticate GitHub Actions to Azure with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
