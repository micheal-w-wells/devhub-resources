---
description: What information you can put into AI coding tools, and how to keep it within the approved classification.
title: 'AI Tooling: Information and Classification'
resourceType: Documentation
tags:
  - Developer Guide
  - AI
  - Security
personas:
  - Developer
pageOnly: true
---

## AI Tooling: Information and Classification

!!! abstract "On this page"
    What you may and may not put into an AI coding tool, and how to stay within the approved Protected A classification. For the short version, start with [AI Tooling Security Requirements](../AI-tooling-security-requirements.md).

## The rule in one line

!!! info "The rule in one line"
    Use GitHub Copilot for information classified up to and including Protected A. Give the task only the information it needs, and never give the agent credentials or authority it does not need.

Today the only approved AI coding assistant for developers is GitHub Copilot, and the highest information security classification approved for it is Protected A. See the [B.C. Information Security Classification](https://www2.gov.bc.ca/gov/content/governments/services-for-government/information-management-technology/information-security/information-security-classification) standard for the four levels (Public, Protected A, Protected B, Protected C).

This is not a ban on internal source code. Most internal application code is Protected A or lower, and developers already use GitHub Copilot on it every day. The rule is about the *classification* of what you share and the *authority* you hand over, not about avoiding internal code.

Do not put Protected B or higher information into any AI tool. That includes citizen, client, employee, case, health, or financial personal information; production records; unpublished vulnerability or incident details; and credentials.

!!! note "Protected A at a glance"
    Usually Protected A or lower (fine for GitHub Copilot): most internal source code, internal design and architecture notes, non-sensitive configuration, and synthetic or de-identified test data.

    Protected B or higher (keep out of any AI tool): citizen, client, employee, case, health, or financial personal information; production records; credentials; and unpublished vulnerability or incident details.

    This is a quick guide, not the authority. See the [B.C. Information Security Classification](https://www2.gov.bc.ca/gov/content/governments/services-for-government/information-management-technology/information-security/information-security-classification) standard for the full definitions.

## Why information still needs deliberate handling

Even inside an approved tool, a few things are worth keeping in mind:

1. The boundary changes by model and feature. GitHub Copilot uses several model providers. Its [model-hosting documentation](https://docs.github.com/en/copilot/reference/ai-models/model-hosting) describes strong protections for many models but also notes model- and preview-specific differences. Bring-your-own-key configurations follow the selected provider's terms.

2. Extensions can move information beyond GitHub Copilot. MCP servers, plugins, browser tools, and custom integrations can receive repository context or tool arguments. An approved Copilot subscription does not automatically approve every connected service. See [Extensions, skills, hooks, and MCP servers](extensions.md).

3. An agent may reproduce what you give it. Input can reappear in generated code, test fixtures, terminal output, logs, issue comments, pull-request descriptions, or committed files.

4. Credentials are executable authority, not just sensitive text. A token, kubeconfig, certificate, connection string, or SSH key lets the agent, or any command it runs, act as the credential holder. See [Contain the agent](containment.md).

5. Less data means fewer mistakes. A small, representative, synthetic example is usually easier for an agent to reason about than a production extract or a large unredacted log.

Do not rely on GitHub Copilot content exclusion as your only boundary. GitHub documents [surface-specific limitations](https://docs.github.com/en/copilot/concepts/context/content-exclusion) in some agent and edit experiences.

## Practical handling guide

| Information or capability | Default guidance |
|---|---|
| Public source code and public documentation | Use with GitHub Copilot. |
| Internal source code in an approved private repository | Use with GitHub Copilot (Protected A or lower). |
| Internal architecture and design documentation | Use when it is Protected A or lower; provide only the relevant portion. |
| Citizen, client, employee, case, health, or financial personal information | Use synthetic or de-identified examples. Do not paste real records into any AI tool. |
| Production logs | Remove tokens, personal information, session identifiers, and unrelated records; provide the smallest relevant excerpt. |
| Unpublished vulnerability or incident details | Keep out of AI tools until they are approved for disclosure. |
| Passwords, API keys, tokens, private keys, certificates, database credentials, kubeconfigs, or cloud credential caches | Never paste them into prompts or expose them to the agent workspace. Supply narrowly scoped credentials through an approved mechanism only when a task genuinely requires them. |
| Full database exports or large operational data sets | Do not use. Create a minimal synthetic or sanitized reproduction. |

## Before you provide context, ask

- [ ] Is this information Protected A or lower?
- [ ] Does the agent actually need it to do the task?
- [ ] Could a synthetic, de-identified, or smaller example answer the same question?
- [ ] Could it be copied into generated code, logs, commits, issues, or pull requests?
- [ ] Does it grant authority to act? If so, do not expose it as ordinary context.

## References

- [B.C. Information Security Classification](https://www2.gov.bc.ca/gov/content/governments/services-for-government/information-management-technology/information-security/information-security-classification)
- [B.C. government policy on the use of generative AI](https://digital.gov.bc.ca/ai/gen-ai-policy/)
- [GitHub Copilot model hosting](https://docs.github.com/en/copilot/reference/ai-models/model-hosting)
- [GitHub Copilot content exclusion](https://docs.github.com/en/copilot/concepts/context/content-exclusion)
