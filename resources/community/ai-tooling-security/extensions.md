---
description: The risks of instructions, prompts, skills, hooks, plugins, and MCP servers, and how to adopt them safely with review, version pinning, and APM.
title: 'AI Tooling: Extensions, Skills, Hooks, and MCP Servers'
resourceType: Documentation
tags:
  - Developer Guide
  - AI
  - Security
personas:
  - Developer
pageOnly: true
---

## AI Tooling: Extensions, Skills, Hooks, and MCP Servers

Learn about the risks of instructions, prompts, skills, hooks, tools, custom agents and MCP servers and how to adopt them safely through review, version pinning and APM. Treat each component like a dependency. For a shorter overview, start with [AI tooling security requirements](../AI-tooling-security-requirements.md).

You can extend AI development tools with repository instructions, prompt files, custom agents, skills, hooks, plugins, browser tools and MCP servers. Each has different risks:

- Instructions and skills influence the agent's behaviour
- Hooks and tools can execute code
- MCP servers and plugins can connect to external systems and transmit context. 

Your agents trusts these components and their convent, so always treat them like dependencies. Review them before adoption and pin their versions.

Use [GitHub's Copilot customization reference](https://docs.github.com/en/copilot/reference/customization-cheat-sheet) to understand each component type. 

Do not treat a public collection as an organizational allowlist. [GitHub Awesome Copilot](https://github.com/github/awesome-copilot) and skill marketplaces can provide useful examples, but you still need to review each component before adopting it. 

## Instructions, prompts and skills can contain hidden malicious instructions

The agent loads instruction, prompt and skill files directly into its context and can follow the instructions they contain. A malicious or poorly designed file could tell the agent to exfiltrate data, run destructive commands, insert a backdoor or weaken a security control.

The dangerous part is that these instructions can be difficult for a human reviewer to detect. They can be hidden Unicode or zero-width characters, bidirectional-text overrides, white-on-white or off-screen text, HTML comments or instructions buried deep in an otherwise reasonable file. 

A file that appears safe and helpful could behave differently when an agent reads it.

Because of this:

- Review every component like source code before adopting it and only use sources you trust
- Prefer tooling that scans for hidden content. [APM](https://github.com/microsoft/apm)'s `content-integrity` check blocks deployed files that contain critical hidden Unicode characters and verifies each file's SHA-256 against the lockfile
- Review tool and MCP descriptions, not just files. The descriptions that tools provide to the model can also contain prompt injections
- Use a discovery-and-vetting skill. The [AI Security Quickstart](https://github.com/bcgov-c/AI-security-quickstart) includes a `find-skills` skill that searches allowlisted B.C. government sources, safety-reviews a candidate for hidden content and behavioural risks and proposes an APM installation rather than adding unvetted components

## Pin versions

Reviewing a component once is not enough if it can update without further review. A new version of an instruction set, skill, hook, plugin or MCP server could introduce hidden malicious or unsafe instructions that were not present in the version you originally reviewed.

- Pin each component to a specific tag or commit
- Commit a lockfile so the repository uses the same resolved versions
- Pin GitHub Actions to a full commit SHA, and let [Dependabot](https://docs.github.com/en/code-security/dependabot) propose version updates for review

APM can enforce version constraints. Set `require_pinned_constraint: true` in the policy to reject unbounded version ranges. This requires earch component to resolve to a bounded tag, semantic version (semver) range or SHA.

## Use APM distribute the approved set

[Microsoft Agent Package Manager (APM)](https://github.com/microsoft/apm) can distribute approved instructions, skills, prompts, hooks and MCP declarations consistently across a team. 

It provides:

- Source allowlists and denylists for dependencies and MCP sources. `apm install` fails closed when a dependency is not allowed
- Content integrity checks that scan for hidden Unicode and verify deployed files SHA-256 hashes stored in the lockfile
- Version pinning through a lockfile and the optional `require_pinned_constraint` rule
- A consistent set of vetted components for everyone working on the repository, allowing one review to protect the whole team

APM provides governance, provenance and standardization at installation time. It does not scan the behaviour or meaning of code, work like antivirus software or provide runtime permissions or agent sandboxing. The agent client, operating environment, identity platform and CI/CD pipeline must provide those protections. 

Review the [APM policy guidance](https://microsoft.github.io/apm/enterprise/apm-policy/). A B.C. government standard package catalogue that allowlists `bcgov` and `bcgov-c` sources is expected to build on this approach.

## Hooks can prevent risky behaviour: Turn them on

Hooks are not only components that require review. Reviewed guardrail hooks can also help prevent dangerous actions because they run automatically at defined points during an agent session. 

The [AI Security Quickstart](https://github.com/bcgov-c/AI-security-quickstart) enables 4 hooks from official `github/awesome-copilot` catalogue by default:

- `tool-guardian` blocks destructive tool calls such as `rm -rf`, force pushes to `main`, `DROP TABLE` and `curl | bash` before the agent runs them
- `secrets-scanner` scans modified files for secret patterns as a local backstop to GitHub secret scanning push protection
- `governance-audit` keeps an append-only audit trail and flags signals related to prompt-injection, exfiltration and credential-exposure
- `dependency-license-checker` flags newly added copyleft or restrictive licences such as GPL, AGPL and SSPL before they enter the codebase

Enabling reviewed guardrail hooks is one of the simplest ways to make safer behaviour the default.

## Tools and custom agents define what an agent can do

Tools give an agent specific capabilities. Depending on the tool, an agent may be able to edit files, run terminal commands, fetch URLs or use capabilities provided by extensions and MCP servers. 

Every enabled tool gives the agent additional authority. Enable only the tools required for the task and turn off the ones that are not needed. 

Also review each tool's description. The model reads tool descriptions as part of its context, which means they can also become promp-injection surface. See [MCP servers](#mcp-servers-understand-the-real-risks) below.

Modes also affect what an agent can do:

- **Ask mode** answers questions without making changes
- **Plan mode** analyses the task and proposes a plan for review before taking action
- **Agent mode** can edit files and use tools such as terminal commands

Use the least powerful mode that can complete the task. This reduces the potential impact if something goes wrong.

Custom agents provide more control. A custom agent is a saved definition for example a `*.agent.md` or chat-mode file, that can specify a model and explicitly allow or deny specific tools.

For example, you could build a read-only review agent that can search and read files but cannot access the terminal. You could also create a delivery agent limited to a single toolset. 

Treat a custom agent's tool allowlist as an important security control. Review shared or third-party custom agents before using them. 

A custom agent can also provide controlled access to a privileged system without giving the agent a raw credential. Instead, expose narrowly scoped tool or MCP server that holds its own scoped credential and allow the agent to use only that tool.

See [Contain the agent](containment.md#prefer-no-credential-then-a-mediated-tool-then-a-scoped-identity) for more information.

## MCP servers: Understand the risks

An MCP server does more than describe an API. It participates directly in an agent session, which introduces security concerns and risks.

An MCP setup has 3 parts: 

- **Host:** The AI application
- **Client:** The component that communicates with the server
- **Server:** The component that provides the tools, resources and prompts 

The server can be hosted locally such as process on your machine using standard input/output (stdio) or remotely over HTTP.
 
Either way, the server receives the context and tool arguments the agent sends to it. Information returned by the server can also enter the model's context.

That makes an MCP server a trusted, powerful intermediary, not a passive API. The concrete risks are:

- **Data exfiltration:** The server receives information sent by the agent, including tool arguments and sometimes surrounding context and could collect that information
- **Tool poisoning:** A malicious tool description or other metadata can contain instructions that influence the model
- **Prompt injection through results:** Tool responses enter the model's context and can contain instructions that steer the agent
- **Rug pulls:** A remote server can change its tool definitions or behaviour after you approved it
- **Tool shadowing or name collisions:** In multi-server setups, one server may override or intercept another server's tools. This is where a genuine human-in-the-middle *between the agent and a legitimate tool* can occur
- **Network interception:** For remote HTTP servers, a classic network human-in-the-middle is possible if TLS certificates are not properly validated
- **Overly broad credentials:** A server with a broadly scoped credential may be able to perform actions beyond what the task requires.

Network interception and tool shadowing can involve human-in-the-middle attacks. However, the broader and more common concern is that a trusted endpoint may be able to both receive sensitive information and inject instructions into the agent's context.

Before adopting an MCP server confirm that:

- [ ] The server and publisher are approved and you know whether the server runs locally or remotely
- [ ] You understand the server's source and update mechanism and have pinned it to a tag or commit
- [ ] You have documented its required permissions and data flows
- [ ] You have enabled only the tool sets required for the task
- [ ] Any credentials it uses are narrowly scoped and never committed to the repository
- [ ] TLS certificates are validated for remote (HTTP) servers
- [ ] You review any transitive MCP servers separately before trusting them

### What APM does and does not enforce for MCP

APM policy governs MCP declarations when components are installed. It does not analyse the behaviour of a running MCP server.

According to the current [APM policy reference](https://microsoft.github.io/apm/enterprise/policy-reference/):

- APM enforces server allowlists and denylists through `mcp.allow` and `mcp.deny` 
- APM enforces allowed transport types through `mcp.transport.allow`. The Quickstart policy allows only `http` and `stdio`, which blocks `sse` and `streamable-http`
- You can configure self-defined servers through `mcp.self_defined` as `warn` or `deny`
- APM denies transitive MCP servers by default through the `--trust-transitive-mcp` CLI flag, which defaults to deny. It does not currently enforce the `mcp.trust_transitive` policy field even though that field is parsed
- A transitive server that slips past on transport or name is remains blocked and its configuration is not written

GitHub also documents [limitations in MCP allowlist enforcement](https://docs.github.com/en/copilot/reference/mcp-allowlist-enforcement). A registry entry or matching server name does not prove that a running server is trustworthy. 

For a more detailed and prioritized set of controls, see the [MCP Security Checklist](https://github.com/slowmist/MCP-Security-Checklist).

## References

- [GitHub Copilot customization reference](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
- [GitHub Awesome Copilot](https://github.com/github/awesome-copilot)
- [Microsoft Agent Package Manager (APM)](https://github.com/microsoft/apm)
- [APM policy files](https://microsoft.github.io/apm/enterprise/apm-policy/)
- [APM policy reference](https://microsoft.github.io/apm/enterprise/policy-reference/)
- [GitHub MCP allowlist enforcement](https://docs.github.com/en/copilot/reference/mcp-allowlist-enforcement)
- [MCP Security Checklist (SlowMist)](https://github.com/slowmist/MCP-Security-Checklist)
- [AI Security Quickstart (bcgov-c, internal)](https://github.com/bcgov-c/AI-security-quickstart)
