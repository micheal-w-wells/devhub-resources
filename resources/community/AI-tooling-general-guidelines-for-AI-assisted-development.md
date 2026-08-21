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

!!! info "These guidelines may change as tools evolve"
    AI development tools change quickly. If the approved-tools catalogue or standard setup differs from an example in this guide, follow the catalogue.

This page provides general workflow guidelines and human-in-the-loop (HITL) expectations for technical staff who use AI tools in B.C. government software development. For mandatory information security requirements, see [AI Tooling Security Guidelines and Requirements](AI-tooling-security-requirements.md).

---

## Human-in-the-Loop (HITL) expectations

### Core principle: People remain accountable

AI tools are assistants, not software engineers. In B.C. government development, **developers take full responsibility for the AI-generated code they accept and commit.**

- Review AI-generated code as carefully as you would review a pull request from a junior developer or a code snippet from a third-party source
- AI reviews do not replace human reviews. Automated AI code reviewers and security bots do not satisfy mandatory human peer review or `CODEOWNERS` approval requirements

See [AI Tooling: Reviewing AI-Assisted Work](ai-tooling-security/reviewing.md) for requirements related to reviewing and testing AI-generated output.

---

### Follow the "Comprehend, Verify, Validate, Refactor" loop

You are responsible for making sure your use of AI  does not reduce software or system quality. Complete these 4 steps before you accept and/or commit AI-generated code.

1. **Comprehend** the output. Read every line before accepting multiline suggestions or tab completions. Do not commit a generated block if you cannot explain to a peer how it works
2. **Verify** the output. AI models may rely on outdated training data or invent functions, endpoints or SKD methods that do not exist or are deprecated, also called "hallucinations". Give the model access to current documentation, sources and/or approved MCP servers to improve its output. Do not trust citations without checking them. Ask the model to link to or identify its documentation sources so you can verify them
3. **Validate** the output. AI models often fail to account for edge cases. **Do not** assume code is correct because it runs without errors. Run the generated code **and** write deterministic tests that verify its logic and expected behaviour
4. **Refactor** the final output. AI often produces working code that is verbose or does not follow established conventions. Refactor the code to improve readability and align it with B.C. government coding standards, design systems and your team's established patterns

---

### Review agent tool execution and action approvals

AI coding agents may try to complete tasks independently.

**Manually review and approve every action an agent tool requests**. Do not configure an agent to automatically approve shell commands, file changes or network requests. Before approving an action, confirm that is safe, target the correct environment and use legitimate dependencies.

---

### Maintain architectural and contextual alignment

AI models can solve focused, local problems but lack the context needed to understand the wider system.

#### Maintain architectural cohesion

Make sure AI suggestions do not introduce divergent patterns, such as conflicting database connection strategies or logging frameworks that break existing service design.

#### Verify accessibility

When generating front-end code or components, manually verify that output meets B.C. government web accessibility standards ([WCAG](https://digital.gov.bc.ca/design/wcag/)). AI tools may omit aria-labels, semantic HTML elements or keyboard navigation requirements. Include the applicable accessibility standard in your prompt and verify the output against it.

#### Check for bias and support inclusion

AI models may reproduce biases found in their training data. When generating user-facing content, user flows or demographic data structures, make sure the output follows public sector inclusion and plain language standards. 

Learn more about [writing for the web](https://www2.gov.bc.ca/gov/content/governments/services-for-government/service-experience-digital-delivery/web-content-development-guides/web-style-guide/writing-guide) guide.

---

### Know when to pause and seek guidance (HITL check-points)

**Do not** rely solely on AI when working in high-risk areas. You may use AI tools to brainstorm and draft solutions, but people must still complete rigorous human architectural design and peer review. 

The following list is not exhaustive and your team may identify other high risk areas to consider:

- Authentication, authorization and session management logic
- Financial transactions, billing or payment processing workflows
- Handling or modeling of Protected A personal information schemas
- Database migrations and data scripts, especially when they involve destructive operations
- Infrastructure as code and deployment pipelines

Always use synthetic data when verifying work involving personal information.

---

### Recognize common AI pitfalls and anti-patterns

#### Sanitize information before using it

HITL applies to your inputs as well as your outputs. Before including information in an AI prompt, you are responsible to remove all credentials, session tokens, internal IP addresses and personal information from error logs, stack traces, database schemas and API payloads. 

For complete guidelines on handling information for AI consumption, see the [Practical handling guide](ai-tooling-security/information.md#practical-handling-guide) in information and classification.

#### Verify dependencies (hallucinations)

Do not run installation commands for AI-suggested dependencies without checking them first. AI models frequently hallucinate dependencies that do not exist. Attackers actively monitor these hallucinations and register the fake names with malicious payloads a technique known as "slopsquatting". 

Confirm that the package:

- Exists in an official registry
- Is actively maintained
- Complies with B.C. government licensing requirements

#### Review pitfalls in AI-generated tests

Check that AI-generated tests cover the expected business logic and boundary conditions. AI often relies too heavily on mocks or tests that cover only successful scenarios. Watch for tautological tests. These tests repeat the code's logic and may confirm an incorrect implementation instead of testing the actual business requirement.

#### Check performance and scalability blindspots

Make sure AI-generated code and logic will work in the context of your production environment. AI models may lack the business domain context needed to design an appropriate outcome. Watch for performance issues such as:

- Nested loops that become significantly slower as data volumes grow
- Repeated database requests that could affect production performance

#### Verify documentation and Git history

AI will confidently hallucinate technical trade-offs or document features that were not included in your commit when generating PR summaries, commit messages and inline code documentation. This will gradually reduce the quality and precision of the repository's historical decisions and source code truth over time. Read and verify every word.

!!! note "Skills, instructions and MCP servers"
    Skills, instructions and MCP servers may reduce some of these risks. Follow the applicable security requirements and use B.C. government approved extensions.

    - See [AI tooling: extensions, skills, hooks, and MCP servers](ai-tooling-security/extensions.md) for security requirements
    - See [B.C. government approved extensions](https://github.com/bcgov) for a list of approved and standardized extensions

<!-- The link to B.C. government-approved extensions currently points to the general `bcgov` GitHub organization rather than a specific catalogue or list of approved extensions. If a dedicated catalogue exists, link directly to it. -->