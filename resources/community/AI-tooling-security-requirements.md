---
description: Security guidelines and requirements for developers using AI tooling and coding agents.
title: AI Tooling Security Guidelines and Requirements
resourceType: Documentation
tags:
  - Developer Guide
  - AI
  - Security
personas:
  - Developer
  - Product Owner
pageOnly: true
---

## AI Tooling Security Guidelines and Requirements

!!! info "This guide changes with the tooling"
    AI development tools change quickly. When the approved-tool catalogue or the standard setup differs from an example in this guide, follow the catalogue.

This page is the concise source of truth for using AI coding tools safely in B.C. government development. Each section gives the short recommendation and links to a companion page with the detail.

!!! note "What is mandatory here"
    This guidance mixes three kinds of items, and the text flags which is which. Hard controls are enforced for you in B.C. government-managed environments; for example, Bypass Approvals and Autopilot are disabled (see [Permission defaults](ai-tooling-security/permissions.md)). Policy requirements must be followed even where nothing stops you technically, such as keeping AI tools to Protected A information or lower. Recommended practices are the rest: strong defaults you apply to your own repositories, credentials, and workstation. When unsure, choose the stricter option.

### What is approved today

- Approved coding assistant: GitHub Copilot, for developers. Other "Copilot"-branded products, preview features, models, and third-party extensions are not automatically approved by extension.
- Approved information classification: up to and including Protected A. Do not put Protected B or higher information (citizen personal information, health or financial records, production data, credentials, or unpublished vulnerability details) into any AI tool. See the [B.C. Information Security Classification](https://www2.gov.bc.ca/gov/content/governments/services-for-government/information-management-technology/information-security/information-security-classification) standard.

Coding agents are more capable than autocomplete: depending on configuration they can read repositories, edit files, run terminal commands, reach the network, call external tools, and act through authenticated command-line clients. Different chat modes expose different amounts of that capability: an ask mode that only reads, a plan mode that proposes before acting, and a full agent mode that can edit files and run commands. Choosing the least-powerful mode for the task is itself a containment control. The goal is to give agents enough context and access to be useful while keeping mistakes out of unrelated and production systems, information inside approved tools, and normal review and release controls in force. You remain responsible for the code you commit and the systems you operate.

## Start with the standard setup

A wizard or standard repository setup does not exist yet. Until it does, the closest foundation is the internal [AI Security Quickstart](https://github.com/bcgov-c/AI-security-quickstart) template (private, `bcgov-c`). Copy from it today: a secure-by-default `AGENTS.md`, path-scoped security instructions, a reusable `/security-review`, review/dependency/documentation skills, APM-managed guardrail hooks, and GitHub security automation (Dependabot, CodeQL, dependency review, secret-scanning push protection, and a `CODEOWNERS` + branch-protection ruleset).

See [AI Tooling for Developers](AI-tooling-for-developers.md) for access, licensing, and training links.

## Give agents the context they need

An agent only knows what is in its current invocation: the task, repository, instructions, conversation, and connected tools. It lacks the tacit knowledge your team built through incidents, support calls, and design decisions, so it can make a technically coherent change that is obviously wrong to someone with that context. For example, it might remove an "unused" database migration that an external service still depends on.

Before a material task, give it the intended outcome, relevant architecture and constraints, non-goals, components that must not change, acceptance criteria, security and privacy requirements, and test and documentation expectations. Repository instructions, specifications, and architecture decision records close this gap for agents and future contributors alike. Its training data also has a cut-off, so supply current, version-specific documentation rather than trusting recall (see [Reviewing AI-assisted work](ai-tooling-security/reviewing.md)).

## Keep information in the approved tool and classification

Use GitHub Copilot for information classified Protected A or lower. This includes most internal source code, which developers already use GitHub Copilot on every day. Provide only what the task needs, use synthetic or de-identified data instead of real records, and never hand over credentials or authority the task does not require.

→ [Information and classification](ai-tooling-security/information.md)

## Contain the agent: least privilege and sandboxing

Two complementary layers keep a mistake or a prompt-injection payload contained, and you want both:

- Least privilege limits what the agent is authorized to do against real systems. It runs commands with whatever identity is active in your terminal, so a copied `oc login` token or an active production session lets it do everything you can, including irreversible actions. Prefer to hand it no credential at all (have it propose changes and deploy through reviewed CI/CD), and fall back to a mediated tool or MCP server, or a narrowly scoped non-production identity, only when the task genuinely needs it.
- Sandboxing limits what the agent's process can reach on your workstation. Without it, an agent can read anything your account can, including files above Protected A, and use your credential stores (`~/.ssh`, `~/.kube`, `~/.azure`, keychains) to act as you. Turn on IDE and CLI sandboxing and keep credential stores out of reach.

→ [Contain the agent](ai-tooling-security/containment.md)

## Set safe permission defaults

B.C. government-managed environments disable Bypass Approvals and Autopilot, because a single global bypass lets an agent run destructive tools without review. To avoid being prompted for every safe action, auto-approve read-only commands and keep prompting for the risky ones. A copy-paste `.vscode/settings.json` is provided.

→ [Permission defaults](ai-tooling-security/permissions.md)

## Vet extensions, skills, hooks, and MCP servers

Instructions, prompts, skills, custom agents, tools, hooks, plugins, and MCP servers are code and content your agent trusts. They can carry malicious instructions, sometimes obfuscated so a human reviewer misses them, and a new version can introduce them silently. Review each one like a dependency, pin versions, prefer APM to distribute a vetted set, enable guardrail hooks, and treat an MCP server as a potential man-in-the-middle rather than a simple API definition.

→ [Extensions, skills, hooks, and MCP servers](ai-tooling-security/extensions.md)

## Give agents clear, bounded work

A useful request pairs the context above with clear boundaries: acceptance criteria, non-goals, dependency and version constraints, the tests to add or preserve, documentation impacts, and the commands the agent may run.

=== "Prefer: bounded and specific"

    > Implement the validation described in issue 123. Preserve the existing API contract, do not change the database schema, add negative authorization tests, run the repository's standard checks, and update the API documentation.

=== "Avoid: vague"

    > Fix validation.

For large changes, ask the agent to inspect and propose a plan, review its assumptions and missing context, implement in small reviewable increments, run deterministic checks, and inspect the final diff and generated artifacts.

## Review AI-assisted work before it ships

When an agent writes most of the code, make the important checks automatic: automated dependency and licence scanning, a reusable security-review pass over the diff and tests, concrete security requirements wired into CI, and a docs-currency rule so documentation updates ship with the change. Require human review for sensitive code (authentication, authorization, cryptography, payments, privacy-sensitive flows, infrastructure) through `CODEOWNERS` and branch protection, a CI/CD control the agent cannot bypass. AI reviewers never count as the required human approval.

→ [Reviewing AI-assisted work](ai-tooling-security/reviewing.md)

## Use extra care in public repositories

B.C. government publishes software to support reuse, transparency, and community contribution. Continue to design code for public release where appropriate.

Before publishing or moving a change to a public repository, confirm none of the following is present:

- [ ] secrets or credentials;
- [ ] real production or personal information;
- [ ] private incident or vulnerability details that are not ready for disclosure;
- [ ] internal-only operational endpoints;
- [ ] privileged configuration;
- [ ] information from a private repository that is not approved for release; or
- [ ] generated fixtures, logs, issue text, or documentation containing sensitive values.

See the [Digital Code of Practice: Work in the open](https://digital.gov.bc.ca/policies-standards/dcop/open/). Public repositories should also provide a `SECURITY.md` with a private vulnerability-reporting route.

## Report problems early

Report:

- sensitive information sent to the wrong service, model, extension, or repository;
- a credential exposed to an agent or committed to source control;
- unexpected access to a cluster, cloud environment, database, or external service;
- an agent action with production or financial impact;
- suspicious or misrepresented extensions, plugins, skills, or MCP servers;
- unsafe generated code that reached a shared branch; or
- a bypass of required permission or review controls.

Where to report:

- Security or privacy incident, for example a credential exposed to an agent, real data sent to the wrong service, or unexpected production impact: call 250 387 7000 and choose option 3.
- Developer platform and tooling help: <Developer.Experience@gov.bc.ca>.

!!! note "AI initiative intake: link coming"
    A single intake form for AI initiatives is being finalized; this guide will link to it for registering and reviewing new AI tooling. Until then, use the developer platform contact above.

Report early: a prompt report lets credentials be revoked, access reviewed, generated artifacts removed, and protections improved for other teams. Reports are used to improve safeguards, not to assign blame, so a near-miss is still worth raising.

## Glossary

APM (Microsoft Agent Package Manager)
:   A package manager that distributes and governs approved agent components (instructions, skills, prompts, hooks, and MCP declarations) with source allow-lists, content-integrity checks, and version pinning.

MCP (Model Context Protocol)
:   A protocol that lets an agent connect to external "servers" which expose tools, resources, and prompts. An MCP server can run locally on your machine or as a remote service.

Prompt injection
:   An attack where untrusted content the agent reads (a web page, issue, dependency, or tool result) carries hidden instructions that steer the agent into doing something you did not ask for.

RBAC (Role-Based Access Control)
:   Granting permissions through roles scoped to a namespace, project, or resource group, rather than to a person's broad standing access.

PIM (Privileged Identity Management)
:   A Microsoft Entra feature that grants privileged roles just-in-time and time-limited, instead of leaving them always on.

OIDC (OpenID Connect)
:   An identity protocol used here so CI/CD can authenticate to a cloud with short-lived, workload-scoped tokens instead of stored long-lived credentials.

OWASP
:   The Open Worldwide Application Security Project, source of the widely used Top 10 and application-security verification standards referenced below.

## Reference index

### This guide

- [Information and classification](ai-tooling-security/information.md)
- [Contain the agent](ai-tooling-security/containment.md)
- [Permission defaults](ai-tooling-security/permissions.md)
- [Extensions, skills, hooks, and MCP servers](ai-tooling-security/extensions.md)
- [Reviewing AI-assisted work](ai-tooling-security/reviewing.md)
- [AI Tooling for Developers](AI-tooling-for-developers.md)
- [AI Security Quickstart (bcgov-c, internal)](https://github.com/bcgov-c/AI-security-quickstart)

### B.C. government

- [Information Security Classification](https://www2.gov.bc.ca/gov/content/governments/services-for-government/information-management-technology/information-security/information-security-classification)
- [Policy on the use of generative AI](https://digital.gov.bc.ca/ai/gen-ai-policy/)
- [Digital Code of Practice: Work in the open](https://digital.gov.bc.ca/policies-standards/dcop/open/)
- [B.C. Developer Guide: Security best practices for applications](https://developer.gov.bc.ca/docs/default/component/bc-developer-guide/security/best-practices-for-apps/)

### GitHub and VS Code

- [GitHub Copilot model hosting](https://docs.github.com/en/copilot/reference/ai-models/model-hosting)
- [GitHub Copilot content exclusion](https://docs.github.com/en/copilot/concepts/context/content-exclusion)
- [GitHub Copilot customization reference](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
- [GitHub MCP allowlist enforcement](https://docs.github.com/en/copilot/reference/mcp-allowlist-enforcement)
- [GitHub local sandbox configuration](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/configuring-local-sandbox-settings)
- [GitHub enterprise-managed Copilot settings](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/configure-enterprise-managed-settings)
- [VS Code approvals and permissions](https://code.visualstudio.com/docs/agents/approvals)
- [VS Code trust and safety](https://code.visualstudio.com/docs/agents/concepts/trust-and-safety)
- [VS Code enterprise AI settings](https://code.visualstudio.com/docs/enterprise/ai-settings)
- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)

### Platform access

- [OpenShift RBAC](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/authentication_and_authorization/using-rbac)
- [Azure RBAC best practices](https://learn.microsoft.com/en-us/azure/role-based-access-control/best-practices)
- [Microsoft Entra Privileged Identity Management](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure)
- [Authenticate GitHub Actions to Azure with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)

### Standards and supporting guidance

- [Microsoft Agent Package Manager](https://github.com/microsoft/apm)
- [APM policy guidance](https://microsoft.github.io/apm/enterprise/apm-policy/)
- [MCP Security Checklist (SlowMist)](https://github.com/slowmist/MCP-Security-Checklist)
- [OWASP Application Security Verification Standard](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP GenAI Security Project](https://genai.owasp.org/)
- [NIST Secure Software Development Framework](https://csrc.nist.gov/pubs/sp/800/218/final)
- [NIST AI RMF Generative AI Profile](https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-generative-artificial-intelligence)
