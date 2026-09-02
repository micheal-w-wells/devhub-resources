---
description: How to review AI-assisted dependencies, stale docs and versions, tests, security requirements, and documentation, and how to require human review for sensitive code.
title: 'AI tooling: Reviewing AI-assisted work'
resourceType: Documentation
tags:
  - Developer Guide
  - AI
  - Security
personas:
  - Developer
pageOnly: true
---

## AI tooling: Reviewing AI-assisted work

Learn how to automate important checks when an agent generates code, including dependency and licence checks, documentation updates, testing, security requirements and human review for sensitive changes. For a shorter overview, start with [AI tooling security requirements](../AI-tooling-security-requirements.md).

When an agent generates code, automated checks can help developers identify problems without relying only on manual review.

Use automated controls where possible to check dependencies, test, security requirements and documentation. Human review is still required, particularly for sensitive or high-risk changes.

Many of these controls are available through the [AI Security Quickstart](https://github.com/bcgov-c/AI-security-quickstart).

## Check dependencies and licences

AI tools can suggest packages that are outdated, unnecessary, nonexistent, malicious or incompatible with your licence requirements. 

Do not trust the model to determine whether a dependency is safe. Catch problems with a deterministic scan. Use automated, repeatable checks that produce the same result when given the same input.

You can check for dependencies at different stages.

### Check dependencies when they are added

When an agent adds a dependency using a command such as `npm install`, `pip install`, `go get`, run a deterministic scan focused on what changed. 

For example: 

- A hook on the install/tool call can run the ecosystem's audit such as `npm audit`, `pip-audit`, `osv-scanner` and `govulncheck` against the new package and fail loudly if it is vulnerable
- Use the `dependency-vulnerability-check` skill to check whether the package exists, is maintained, is deprecated, has known CVEs and uses an appropriate pinned version
- Use the `dependency-review`workflow to prevent a pull request from merging when it introduces a dependency with a known vulnerability or disallowed licence: The authoritative server-side gate
- Use Dependabot to propose updates for dependencies with known vulnerabilities and use the fix and version-bump pull requests for known CVEs, and the `dependency-license-checker` hook to flag newly added copyleft or restrictive licences before they are committed

### Use continuous dependency scanning 

You can also use a linter or software composition analysis tool or an always-on scanner in the IDE to identify dependency problems while you work.  

These tools can publish findings to the editor's Problems panel. Agents that can then read IDE diagnostics and may use those findings to identify vulnerable or deprecated packages. As a result it course-corrects and pick a maintained version or a different package without a separate command.

Treat IDE scanning as an early warning rather than the final control. Keep pull request checks as the authoritative backstop and instruct the agent through `AGENTS.md` to review and resolve relevant diagnostics before reporting that the task is complete.

When reviewing dependencies manually:

- Confirm that the package exists and is correctly named
- Check its maintenance activity and security advisories
- Prefer an existing approved dependency when one meets the requirement
- Pin the version when required
- Review installation and lifecycle scripts

Complete these checks in the pull request that introduces the dependency rather than waiting until release.

## Check current documentation and versions

A model's built-in knowledge has a training cut-off. As a result, an agent left to its own memory will happily write code against deprecated APIs, removed functions, superseded best practices, or an old major version of a library, and it will look confident doing it. This is one of the most common sources of subtly wrong AI-generated code.

Give the agent current, version-specific information rather than relying only on its built-in knowledge.

### Provide current documentation 

Tools such as [Context7](https://github.com/upstash/context7) fetch up-to-date, version-pinned library docs into the agent's context so generated code matches the version you actually use. 

Context7 is an MCP server, so review it and pin it before adoption like any other MCP server. 

See [Extensions, skills, hooks, and MCP servers](extensions.md).

### Provide versions your application uses

Use your lockfile or other dependency configurations to identify the exact versions in the repository.

Provide the relevant official documentation for those versions rather than allowing the agent to assume that the project uses the latest release. 

### Verify version-sensitive code 

Check generated code carefully when it involves version-sensitive code:

- Framework upgrades
- New libraries
- Fast-moving SDKs

Confirm that generated calls, functions and configuration options  exist in the version installed by your application.

Builds, type-checking and run tests can identify many version-related problems.

## Treat agent-written tests as evidence, not proof

Agent-generated tests may reproduce the assumptions made by the implementation rather than test the actual requirement.

They may also:

- Rely too heavily on mocks
- Test only successful scenarios
- Miss authorization or tenant-boundary cases
- Verify that code runs without confirming that it behaves correctly

A passing test suite does not necessarily mean the implementation is correct.

Use a focused review of generated tests rather than relying only on the test results.

For example: 

- Run a reusable security and/or quality review such as a `/security-review` prompt or a `secure-change-review` skill over the the code changes and tests
- Check that important tests map to a requirement or previous defect
- Confirm that a test would fail if the expected behaviour stopped working
-  Include invalid input, boundary conditions, failure scenarios and authorization cases where relevant
- Confirm that tests do not contain real production or personal information
Confirm that tests produce consistent, repeatable results

Consider adding an approved test-review skill or prompt to the repository.

Code coverage can help identify code that tests do not execute, but coverage percentages do not replace risk-based test design.

### Use goal-driven testing as a complement

Goal-driven is a scenario testing that gives an agent an outcome to achieve in plain language instead of a predefined set of test steps.

For example: 

"Create an account and get a fishing license" 

The agent interacts with the running application and reports whether it can complete the goal and where it also encounters problems. It is good at exploratory testing and it can identify integration and usability gaps that scripted tests may miss.

However, goal-drive testing is non deterministic. The agent may follow a different path each time, so results may not be fully repeatable. It can also produce false positives or false negatives.

Use goal-driven testing to complement deterministic testing, not replace it.

- Keep deterministic unit/integration/e2e tests as the merge and regression gate; they must be repeatable to be trustworthy in CI
- Use goal-driven runs for exploratory testing during development and before release, and turn any real defect it finds into a deterministic regression test
- Do not rely on a non-deterministic test to be the only control before a chance reaches production

!!! warning "Goal-driven testing is not a merge gate"
    Do not use a goal-driven test as the only requirement for merging or releasing a change because its results may not be repeatable.
    
    Use it for exploratory testing and create a deterministic regression test for any valid defect it identifies in CI.

## Make security requirements specific 

Instructions like "follow security best practices" are too broad to guide either a developer or an agent.

Translate the requirements that apply to your system into:

- Acceptance criteria 
- Agent instructions
- Automated tests
- CI checks 

You can also use path-scoped instructions. For example a `security-and-owasp.instructions.md` file can provide secure coding requirements when an agent works with particular source files while `AGENTS.md` provides the repository's general requirements.

At minimum, review changes that affect:

- Authentication and sessions
- Authorization, object-level access and tenant separation
- Input validation and output handling 
- Secrets and credentials
- Logging without sensitive-data disclosure 
- Dependency and build-pipeline integrity 
- Encryption and data in transit 
- Personal-information handling 
- Data retention and deletion
- Administrative and deployment access
- Error and failure handling

## Keep documentation current

Documentation should be part of the change rather than a separate task completed later.

You can use agent-facing instructions and automation to help keep documentation current. 

For example: 

- Add a documentation required or docs-currency rule in `AGENTS.md` so changes to functionality include the required documentation updates
- Use a `docs-update` skill that identifies which documentation may need updating when behaviour, APIs, configuration, architecture, data handling or dependencies change
- Add documentation and architecture prompt to the pull request template
- Use a `docs-check` workflow to identify broken links or other documentation problems

Treat AI-generated documentation and diagrams as proposed content and always validate them against the implemented system before publishing and merging them.

## Require human review for sensitive code

Some changes require human review because errors could have a significant security, privacy, financial or operational consequences.

Examples include changes to: 

- Authentication and authorization
- Cryptography
- Payment or financial logic
- Privacy-sensitive data flows
- Infrastructure and deployment configuration

Identify the sensitive capabilities and files in your repository and enforce the review requirement through CI/CD and repository controls rather than relying only on the agent instructions.

For example, you can combine a `CODEOWNERS` file with a branch-protection ruleset that requires code-owner approval.

```text
# .github/CODEOWNERS — require the security team to review sensitive routes.
/src/auth/           @your-org/security-reviewers
/src/payments/       @your-org/security-reviewers
/infra/              @your-org/platform-reviewers
/.github/workflows/  @your-org/platform-reviewers
```
These server-side controls apply to pull requests independently of the agent's instructions and help prevent sensitive changes from being merged without the required human review.

## Use normal controls for AI-assisted changes

Apply the same engineering controls to AI-assisted code that you apply to human-authored code.

Before merging a change:

- Review the complete diff
- Confirm that the implementation meets the requirements
- Review new or changed dependencies and licences
- Run the required tests and security checks
- Confirm whether documentation needs to change
- Review generated files and configuration
- Confirm that the change does not introduce credentials or production data

AI code-review tools, security-review agents and automated fixes can provide an additional review, but they do not replace required human approval.

Do not allow an AI reviewer or automated fixer to:

- Approve its own changes
- Replace required human approval
- Bypass required checks
- Merge changes automatically
- Deploy directly to production

An automated fixer should suggest a patch or draft pull request for human review.

## References

- [GitHub: Review AI-generated code](https://docs.github.com/en/copilot/tutorials/review-ai-generated-code)
- [GitHub: Writing tests with GitHub Copilot](https://docs.github.com/en/copilot/tutorials/write-tests)
- [Context7: up-to-date library docs for agents](https://github.com/upstash/context7)
- [OWASP Application Security Verification Standard](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [AI Security Quickstart (bcgov-c, internal)](https://github.com/bcgov-c/AI-security-quickstart)
