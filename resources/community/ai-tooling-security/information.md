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

Learn what information you may provide to an AI coding tool and how to stay within the approved Protected A classification. For a shorter overview, start with [AI tooling security requirements](../AI-tooling-security-requirements.md).

## The rule in one line

!!! info "The rule in one line"
    Use GitHub Copilot only with information classified as Protected A or lower. Give it only the information required for the task and do not give the agent credentials or authority it does not need.

GitHub Copilot is currently the approved AI coding assistant for developers and is approved for information classified as Protected A or lower. 

See the [B.C. Information Security Classification](https://www2.gov.bc.ca/gov/content/governments/services-for-government/information-management-technology/information-security/information-security-classification) standard for 4 classification levels: Public, Protected A, Protected B and Protected C.

This is not a ban on internal source code. Most internal application code is Protected A or lower, and developers already use GitHub Copilot on it every day. 

The important considerations are:

- The classification of the information you provide
- Whether the agent needs that information to complete the task
- What systems, tools or credentials the agent can access

Do not provide Protected B or Protected C information to an AI tool unless that use has been specifically approved.

This may include citizen, client, employee, case, health or financial personal information, production records, unpublished vulnerability or incident details and credentials.

!!! note "Protected A at a glance"
    Information classified as Protected A or lower may include internal source code, internal design and architecture documentation, non-sensitive configuration and synthetic or de-identified test data.
    
    Information classified as Protected B or Protected C may include citizen, client, employee, case, health or financial personal information, production records, credentials and unpublished vulnerability or incident details.
    
    This is a quick reference, not the authoritative classification guidance. See the [B.C. Information Security Classification](https://www2.gov.bc.ca/gov/content/governments/services-for-government/information-management-technology/information-security/information-security-classification) standard for the full definitions.


## Handle information carefully

Using an approved tool does not mean you should provide it with all available information. Consider how much information the agent needs and where that information could go.

### Model and feature boundaries can differ

Even inside an approved tool, a few things are worth keeping in mind:

GitHub Copilot uses models from several providers. Its [model-hosting documentation](https://docs.github.com/en/copilot/reference/ai-models/model-hosting) describes how different models are hosted and identifies differences that may apply to particular models or preview features.

Bring-your-own-key configurations follow the terms and controls of the selected provider.

### Extensions can send information outside GitHub Copilot

Extensions can move information beyond GitHub Copilot. MCP servers, plugins, browser tools and custom integrations may receive repository context, tool arguments or other information from the agent.

Approval to use GitHub Copilot does not automatically mean that every connected service is also approved.

Review documentation about [Extensions, skills, hooks, and MCP servers](extensions.md).

### Information can appear in generated outputs

Information you provide to an agent may appear in generated code, test fixtures, terminal output, logs, issue comments, pull request descriptions or committed files.

Provide only the information required for the task.

### Credentials provide authority 

Credentials are executable authority, not just sensitive text. 

A token, kubeconfig, certificate, connection string, or SSH key may allow the agent or a command it to act with the permissions associated to with that credential. 

Never paste credentials into prompts or expose them unnecessarily in the agent's workspace

Review [Contain the agent](containment.md) documentation for more details.

### Use the smallest useful amount of information

Less data means fewer mistakes. Provide only the context needed to complete the task.

When possible, use a small synthetic or de-identified example instead of a production data extract, complete log or other large data set. This reduces unnecessary information exposure and can make the task easier to understand and review.

Do not rely on GitHub Copilot content exclusion as your only protection. GitHub documents [surface-specific limitations](https://docs.github.com/en/copilot/concepts/context/content-exclusion) for some agent and edit experiences.

## Practical handling guide

| Information or capability | Default guidance |
|---|---|
| Public source code and public documentation | You may use it with GitHub Copilot |
| Internal source code in an approved private repository | You may use with GitHub Copilot when it is classified as Protected A or lower |
| Internal architecture and design documentation | Use when it is Protected A or lower and provide only the relevant portion |
| Citizen, client, employee, case, health, or financial personal information | Use synthetic or appropriately de-identified examples. Do not use real records into any AI tool |
| Production logs | Remove tokens, personal information, session identifiers, and unrelated records. Provide the smallest relevant excerpt |
| Unpublished vulnerability or incident details | Keep out of AI tools until they are approved for disclosure |
| Passwords, API keys, tokens, private keys, certificates, database credentials, kubeconfigs or cloud credential caches | Never paste them into prompts or expose them in the agent workspace. When a task require credentials, provide narrowly scoped access through an approved mechanism |
| Full database exports or large operational data sets | Do not use them. Create a minimal synthetic or sanitized reproduction instead |

## Before you provide context, ask

- [ ] Is this information classified as Protected A or lower?
- [ ] Does the agent actually need this information to complete task?
- [ ] Could I use synthetic, de-identified, or smaller example answer instead?
- [ ] Could this information appear in generated code, logs, commits, issues, or pull requests?
- [ ] Does this information give the agent authority to act? If so, can I provide that authority through a more controlled mechanism?

## References

- [B.C. Information Security Classification](https://www2.gov.bc.ca/gov/content/governments/services-for-government/information-management-technology/information-security/information-security-classification)
- [B.C. government policy on the use of generative AI](https://digital.gov.bc.ca/ai/gen-ai-policy/)
- [GitHub Copilot model hosting](https://docs.github.com/en/copilot/reference/ai-models/model-hosting)
- [GitHub Copilot content exclusion](https://docs.github.com/en/copilot/concepts/context/content-exclusion)
