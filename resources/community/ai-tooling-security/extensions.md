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

!!! abstract "On this page"
    The risks of instructions, prompts, skills, hooks, tools, custom agents, and MCP servers, and how to adopt them safely with review, version pinning, and APM. Treat each one like a dependency. For the short version, start with [AI Tooling Security Requirements](../AI-tooling-security-requirements.md).

AI development can be extended with repository instructions, prompt files, custom agents, skills, hooks, plugins, browser tools, and MCP servers. They have different risk profiles: instructions and skills influence behaviour; hooks and tools can execute code; MCP servers and plugins can reach external systems and transmit context. All of them are code and content that your agent trusts, so treat them like dependencies: review before adoption, and pin versions.

Use [GitHub's Copilot customization reference](https://docs.github.com/en/copilot/reference/customization-cheat-sheet) to understand each component type. Do not treat a public collection as an organizational allowlist: [GitHub Awesome Copilot](https://github.com/github/awesome-copilot) and skill marketplaces are useful sources of examples, but each component still needs review before adoption.

## Instructions, prompts, and skills can carry hidden attacks

An instruction, prompt, or skill file is loaded straight into the agent's context, where the model follows it. A malicious or careless one can embed instructions that tell the agent to exfiltrate data, run destructive commands, insert a backdoor, or quietly weaken a security control the next time it is loaded.

The dangerous part is that these instructions can be obfuscated so a human reviewer misses them: hidden Unicode and zero-width characters, bidirectional-text overrides, white-on-white or off-screen text, HTML comments, or instructions buried deep in an otherwise reasonable file. A file that looks helpful can behave very differently once an agent reads it.

Because of this:

- Review every component like source code before adopting it, from a source you trust.
- Prefer tooling that scans for hidden content. [APM](https://github.com/microsoft/apm)'s `content-integrity` check blocks deployed files that contain critical hidden Unicode characters and verifies each file's SHA-256 against the lockfile.
- Watch tool and MCP *descriptions*, not just files: the text a tool advertises to the model is also an injection surface.
- Use a discovery-and-vetting skill. The [AI Security Quickstart](https://github.com/bcgov-c/AI-security-quickstart) ships a `find-skills` skill that searches allow-listed B.C. government sources, safety-reviews a candidate for these hidden-content and behavioural red flags, and proposes an APM install rather than adding anything unvetted.

## Pin versions

Reviewing a component once is not enough if it silently updates. Without version pinning, a new release of an instruction set, skill, hook, plugin, or MCP server can introduce hidden malicious instructions that were not in the version you reviewed.

- Pin each component to a specific tag or commit.
- Commit a lockfile so the exact resolved versions travel with the repository.
- Pin GitHub Actions to a full commit SHA, and let [Dependabot](https://docs.github.com/en/code-security/dependabot) propose reviewed version bumps.

APM can enforce this: set `require_pinned_constraint: true` in the policy to reject unbounded version ranges, so every component resolves to a bounded tag, semver range, or SHA.

## Let APM distribute the approved set

[Microsoft Agent Package Manager (APM)](https://github.com/microsoft/apm) distributes approved instructions, skills, prompts, hooks, and MCP declarations consistently across a team. It gives you:

- a source allow-list and deny-list for dependency and MCP sources (`apm install` fails closed when a dependency is not allowed);
- content integrity: a hidden-Unicode scan and SHA-256 hash verification of deployed files against the lockfile;
- version pinning via a lockfile and the optional `require_pinned_constraint` rule; and
- the same vetted set shared with every developer working on the repository, so one review protects the whole team.

APM is an install-time governance, provenance, and standardization layer. Its own documentation is explicit that it does not scan code semantics, behave like an antivirus, or provide runtime permissions or agent sandboxing; those must still be enforced by the agent client, the operating environment, identity platform, and CI/CD. See the [APM policy guidance](https://microsoft.github.io/apm/enterprise/apm-policy/). A B.C. government standard package catalogue (allow-listing `bcgov` and `bcgov-c` sources) is expected to build on this.

## Hooks can prevent risky behaviour: turn them on

Hooks are not just a risk to review; some hooks are one of the easiest ways to *stop* an agent from doing something dangerous, because they run automatically at defined points in a session. The [AI Security Quickstart](https://github.com/bcgov-c/AI-security-quickstart) enables four from the official `github/awesome-copilot` catalogue by default:

- `tool-guardian` blocks destructive tool calls (`rm -rf`, force-push to `main`, `DROP TABLE`, `curl | bash`) *before* the agent runs them.
- `secrets-scanner` scans modified files for secret patterns as a local backstop to GitHub secret-scanning push protection.
- `governance-audit` keeps an append-only audit trail and flags prompt-injection, exfiltration, and credential-exposure signals.
- `dependency-license-checker` flags newly added copyleft/restrictive licences (GPL/AGPL/SSPL) before they enter the codebase.

Enabling reviewed guardrail hooks is one of the simplest ways to make safe behaviour the default.

## Tools and custom agents define the capability surface

Tools are the concrete capabilities an agent can invoke: editing files, running terminal commands, fetching URLs, and anything added by an extension or MCP server. Every enabled tool is a standing grant of authority, so enable only the toolsets a task needs and turn the rest off, and remember that a tool's *description* is loaded into the model's context, so it is an injection surface as much as a capability (see [MCP servers](#mcp-servers-understand-the-real-risks) below).

Modes decide how much of that surface is live. Built-in chat modes differ in capability: an *ask* mode answers questions without changing anything, a *plan* mode analyses the task and proposes a reviewable plan before acting, and a full *agent* mode can edit files and run tools and terminal commands. Pick the least-powerful mode that can do the job; it is a simple, effective way to shrink the blast radius.

Custom agents go further. A custom agent is a saved definition (for example a `*.agent.md` or chat-mode file) that can pin a model and explicitly *allow or deny specific tools*, so you can build a read-only "reviewer" agent that can search and read but cannot run the terminal, or a delivery agent limited to a single toolset. Treat a custom agent's tool allowlist as a security boundary, and review a shared or third-party custom agent like any other component in this list. This is also the clean way to give an agent access to a privileged system without handing it a raw credential: expose a narrow, purpose-built tool or MCP server that holds its own scoped credential, and allow the agent only that tool (see [Contain the agent](containment.md#prefer-no-credential-then-a-mediated-tool-then-a-scoped-identity)).

## MCP servers: understand the risks

An MCP server does more than describe an API: it participates directly in a session, and that is what makes it a security concern.

An MCP setup has three parts: the host (your AI application), the client (which talks to the server), and the server (which provides tools, resources, and prompts). The server can be hosted locally (a process on your machine, usually over stdio) or hosted externally (a remote service over HTTP). Either way, the server sees whatever context and tool arguments the agent sends it, and whatever it returns flows back into the model's context.

That makes an MCP server a trusted, powerful intermediary, not a passive API. The concrete risks are:

- Data exfiltration: the server receives whatever the agent sends (arguments, and sometimes surrounding context) and can quietly harvest it.
- Tool poisoning: malicious instructions embedded in a tool's *description* or metadata, which the model reads and obeys even though a human skims past them.
- Prompt injection via results: tool responses are inserted into the model context and can carry instructions that steer the agent.
- Rug pulls: a remote server can change its tool definitions or behaviour after you approved it.
- Tool shadowing / name collisions in multi-server setups: one server overrides or intercepts another server's tools. This is where a genuine man-in-the-middle *between the agent and a legitimate tool* can occur.
- Network interception: for remote (HTTP) servers, a classic network man-in-the-middle is possible if TLS certificates are not validated.
- Over-broad credentials: a server handed a wide token can act well beyond the task.

Only network interception and tool shadowing are literally man-in-the-middle attacks. The more common danger is broader: a trusted endpoint that can both exfiltrate data and inject instructions.

Adopt an MCP server only when every box is checked:

- [ ] the server and publisher are approved, and you know where it is hosted (local vs. remote);
- [ ] its source and update mechanism are understood and pinned to a tag or commit;
- [ ] its required permissions and data flows are documented;
- [ ] only the toolsets the task needs are enabled;
- [ ] any credentials it uses are narrowly scoped and never committed;
- [ ] TLS is validated for remote (HTTP) servers; and
- [ ] transitively pulled servers are reviewed on their own before being trusted.

### What APM does and does not enforce for MCP

APM policy governs MCP declarations at install time; it is not a behavioural scanner of a running server. Verified against the current [APM policy reference](https://microsoft.github.io/apm/enterprise/policy-reference/):

- Server allow/deny lists (`mcp.allow` / `mcp.deny`) and transport allow-list (`mcp.transport.allow`) are enforced. The Quickstart's policy allows only `http` and `stdio`, which blocks `sse` and `streamable-http`.
- Self-defined servers (`mcp.self_defined`) can be set to `warn` or `deny`.
- Transitive MCP servers are denied by default, but via the `--trust-transitive-mcp` CLI flag (which defaults to deny), *not* the `mcp.trust_transitive` policy field, which is currently parsed but not enforced. A transitive server that slips past on transport or name is still blocked and its config is not written.

GitHub separately documents [limitations in MCP allowlist enforcement](https://docs.github.com/en/copilot/reference/mcp-allowlist-enforcement): a registry entry or matching name is not proof that a running server is trustworthy. For a thorough, prioritized set of controls, use the [MCP Security Checklist](https://github.com/slowmist/MCP-Security-Checklist).

## References

- [GitHub Copilot customization reference](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
- [GitHub Awesome Copilot](https://github.com/github/awesome-copilot)
- [Microsoft Agent Package Manager (APM)](https://github.com/microsoft/apm)
- [APM policy files](https://microsoft.github.io/apm/enterprise/apm-policy/)
- [APM policy reference](https://microsoft.github.io/apm/enterprise/policy-reference/)
- [GitHub MCP allowlist enforcement](https://docs.github.com/en/copilot/reference/mcp-allowlist-enforcement)
- [MCP Security Checklist (SlowMist)](https://github.com/slowmist/MCP-Security-Checklist)
- [AI Security Quickstart (bcgov-c, internal)](https://github.com/bcgov-c/AI-security-quickstart)
