---
description: Guidelines for general workflows and human-in-the-loop (HITL) expectations for developers using AI tooling and coding agents.
title: General guidelines for AI-assisted development
resourceType: Documentation
tags:
  - Developer Guide
  - AI
  - Best Practices
personas:
  - Developer
  - Product Owner
pageOnly: true
---

## General guidelines

!!! info "These guidelines can change with the tooling"
    AI development tools change quickly. When the approved-tool catalogue or the standard setup differs from an example in this guide, follow the catalogue.

This page lays out guidelines for general workflows and human-in-the-loop (HITL) expectations for technical staff using AI tools in BC Gov software development. For mandatory information security rules, see [AI Tooling Security Guidelines and Requirements](AI-tooling-security-requirements.md).

---

## Human-in-the-Loop (HITL) Expectations

### Core Principle: Accountability Remains Human

AI tools are assistants, not software engineers. In BC Gov development, **the developer who accepts and commits an AI suggestion assumes full responsibility for that code.**

- For any AI-generated code, treat it with the same scrutiny as a pull request from a junior developer or a code snippet found from a third party source.
- **AI reviews do not replace human review.** Automated AI code reviewers and security bots do not count toward mandatory human peer review or `CODEOWNERS` pull request approvals.

See [AI Tooling: Reviewing AI-Assisted Work](ai-tooling-security/reviewing.md) for more information on other requirements for reviewing and testing AI output.

---

### The "Comprehend, Verify, Validate, Refactor" Loop

You are responsible for ensuring that your AI usage does not degrade software or system quality. Loop through these four steps before accepting and/or committing AI-generated code.

1. **Comprehend** the output. Never accept multi-line suggestions or tab-completions without reading every line. If you cannot explain how the generated block works to a peer, do not commit it.
2. **Verify** the output. AI models suffer from training cut-offs and can hallucinate functions, endpoints, or SDK methods that do not exist or are deprecated. Provide the model with current documentation, sources, and/or MCP Servers to improve the AI's output. Do not blindly trust citations. Ask the model to link, provide, or direct you to the documentation source so you can verify it yourself.
3. **Validate** the output. AI models tend to fail at edge cases. **DO NOT** assume the provided code is correct because it runs with no errors. You must validate generated code through execution **AND** writing deterministic tests to verify the AI's code/logic.
4. **Refactor** the final output. AI often writes working but verbose or unconventional code. Refactor suggestions for readability and to align with BC Gov coding standards, design systems, and/or your team's established patterns.

---

### Agent Tool Execution & Action Approvals

When using AI coding agents, the AI may attempt to execute tasks autonomously.

**You must manually review and approve all agent tool invocations.** Never configure an agent to auto-approve shell commands, file modifications, or network requests. You are responsible for verifying that a terminal command is safe, targets the correct environment, and utilizes real dependencies before allowing the agent to execute it.

---

### Architectural and Contextual Alignment

AI models excel at tactical, local problem solving but usually lack overarching system context.

#### Architectural Cohesion

You must ensure AI suggestions do not introduce divergent patterns (such as conflicting database connection strategies or logging frameworks) that break existing service design.

#### Accessibility

When generating front end code/components, manually verify that output complies with B.C. government web accessibility standards ([WCAG](https://digital.gov.bc.ca/design/wcag/)). AI tools frequently omit ARIA labels, semantic HTML tags, or keyboard navigation requirements. You should explicitly ask the AI to comply with a given standard, as it is generally excellent at it when directed.

#### Bias and Inclusivity

AI models reflect biases present in their training data. When generating user facing copy, user flows, or demographic handling, ensure the output complies with public sector inclusivity and plain language standards ([Writing for the Web](https://www2.gov.bc.ca/gov/content/governments/services-for-government/service-experience-digital-delivery/web-content-development-guides/web-style-guide/writing-guide)).

---

### HITL Checkpoints (When to Pause and Elevate)

**DO NOT** rely solely on AI when working in high-stake areas. You can use AI tools to brainstorm and draft solutions, but ensure there is still a rigorous human architectural design and peer review process. This is not an exhaustive list, some teams may have other high stake areas of development:

- Authentication, authorization, and session management logic.
- Financial transactions, billing, or payment processing workflows.
- Handling or modeling of Protected A personal information schemas (always use synthetic data for verification).
- Database migrations and data scripts, especially those involving destructive operations.
- Infrastructure as code and deployment pipelines.

---

### Common AI Pitfalls & Anti-Patterns

#### Input Sanitization (Sanitize Before You Synthesize)

HITL applies to your inputs as much as your outputs. You are responsible for manually redacting all credentials, session tokens, internal IP addresses, and personal information prior to pasting error logs, stack traces, database schemas, or API payloads into an AI prompt. For full guidelines on handling information for AI consumption, see the [Practical handling guide](ai-tooling-security/information.md#practical-handling-guide) in Information and Classification.

#### Dependency Hallucinations

Never blindly run install commands for dependencies suggested by AI. AI models frequently hallucinate dependencies that do not exist. Attackers actively monitor these hallucinations and register the fake names with malicious payloads (a technique known as "slopsquatting"). Manually confirm the package name exists in official registries, is actively maintained, and complies with B.C. government licensing requirements.

#### Pitfalls in AI-Generated Tests

Inspect AI written tests to ensure they assert expected business logic and boundary conditions. AI tends to overuse mocks and/or only testing happy paths. Beware of tautological testing, where the AI writes tests that assert its own incorrect logic rather than testing the actual business requirement.

#### Performance and Scalability Blindspots

You are responsible for ensuring that the code and logic functions within the context of your production environment, as an AI model will not necessarily know the extra business domain context to properly design the appropriate outcome. Pay special attention to inefficiencies such as nested loops with polynomial slowdowns or making repetitive database requests that could cause issues in production.

#### Documentation and Git History

AI will confidently hallucinate technical trade-offs or document features that were not actually included in your commit when generating PR summaries, commit messages, and inline code documentation. This will gradually reduce the quality and precision of the repository's historical decisions and source code truth over time. Read and verify every word.

!!! note "Skills, Instructions, and MCP Servers"
    Some of these guidelines can be partially or fully mitigated with the use of skills, instructions, and MCP servers. Make sure to follow security guidelines and use BC gov approved extensions.
    - See [AI Tooling: Extensions, Skills, Hooks, and MCP Servers](ai-tooling-security/extensions.md) for security guidelines
    - See [BC Gov Approved Extensions](https://github.com/bcgov) for a list of approved and standardized extensions.
