---
description: How to review AI-assisted dependencies, stale docs and versions, tests, security requirements, and documentation, and how to require human review for sensitive code.
title: 'AI Tooling: Reviewing AI-Assisted Work'
resourceType: Documentation
tags:
  - Developer Guide
  - AI
  - Security
personas:
  - Developer
pageOnly: true
---

## AI Tooling: Reviewing AI-Assisted Work

> Detailed guidance for [AI Tooling Security Requirements](../AI-tooling-security-requirements.md). Start there for the short version.

When an agent writes most of the code, you will not read every line as closely as you would your own. The aim of this page is to make the important checks **automatic** wherever possible, so security does not depend on a developer manually crawling every diff, test, and dependency. Most of these controls ship ready to adopt in the [AI Security Quickstart](https://github.com/bcgov-c/AI-security-quickstart).

## Dependencies and licences — use a deterministic check

AI tools can suggest outdated, unnecessary, nonexistent, malicious, or licence-incompatible packages. Rather than trusting the model's judgement, catch problems with a deterministic scan. Two complementary approaches work well together:

**1. A scoped check when a dependency is added.** When the agent installs a new package (`npm install`, `pip install`, `go get`, etc.), run a deterministic scan focused on what changed:

- A **hook on the install/tool call** can run the ecosystem's audit (`npm audit`, `pip-audit`, `osv-scanner`, `govulncheck`) against the new package and fail loudly if it is vulnerable.
- The **`dependency-vulnerability-check` skill** gives the agent a repeatable "is this package safe" procedure (exists in the registry, maintained, not deprecated, no known CVEs, pinned) and tells it to fix the problem in the same change rather than suppress the finding.
- The **`dependency-review` workflow** fails a pull request that adds a dependency with a known vulnerability or a disallowed licence — the authoritative server-side gate.
- **Dependabot** opens fix and version-bump pull requests for known CVEs, and the **`dependency-license-checker` hook** flags new copyleft/restrictive licences before they are committed.

**2. An always-on scanner in the IDE.** Even easier than a per-install step: run a linter or software-composition-analysis extension continuously so it publishes findings to the editor's Problems panel. Agents can read IDE diagnostics, so a flagged vulnerable or deprecated package appears in the agent's context and it can course-correct — pick a maintained version or a different package — without a separate command. Treat this as a convenience that shortens the loop, not the gate: keep the pull-request check as the authoritative backstop, and instruct the agent (in `AGENTS.md`) to check and resolve diagnostics before reporting done.

When you do review by hand, confirm the package exists and is correctly named, check maintenance activity and advisories, prefer an approved existing dependency, pin the version, and review install/lifecycle scripts — in the pull request that introduces it, not at release.

## Guard against stale knowledge (docs and versions)

A model's built-in knowledge has a training cut-off, so an agent left to its own memory will happily write code against **deprecated APIs, removed functions, superseded best practices, or an old major version** of a library — and it will look confident doing it. This is one of the most common sources of subtly wrong AI-generated code.

Reduce it by giving the agent current, version-specific information instead of relying on recall:

- **Feed it live documentation.** Tools such as [Context7](https://github.com/upstash/context7) fetch up-to-date, version-pinned library docs into the agent's context so generated code matches the version you actually use. Context7 is itself an MCP server, so vet and pin it like any other (see [Extensions, skills, hooks, and MCP servers](extensions.md)).
- **Point at official docs and your lockfile.** Tell the agent the exact versions in use (from the lockfile) and link the relevant official documentation, rather than letting it assume "latest".
- **Verify version-sensitive code.** For framework upgrades, new libraries, or fast-moving SDKs, confirm the generated calls exist in the installed version — build, type-check, and run tests catch much of this deterministically.

## Agent-written tests — treat them as evidence, not proof

Agent-generated tests often mirror the implementation instead of the requirement, over-use mocks, cover only happy paths, skip authorization and tenant boundaries, or assert that code merely runs. A green suite is not automatically a trustworthy one.

You are unlikely to read every line of a generated test suite, so lean on a focused review pass rather than manual line-by-line reading:

- Run a reusable security/quality review such as a `/security-review` prompt or a `secure-change-review` skill over the diff, including tests.
- Spot-check that each material test maps to a requirement or prior defect, would fail if the behaviour regressed, and covers invalid, boundary, failure, and authorization cases.
- Confirm tests contain no real production or personal data and are deterministic.

A dedicated test-review skill or prompt is a good addition to your repository's approved component set. Coverage percentages can show unexecuted code but are not a substitute for risk-based test design.

### Goal-driven testing as a complement

An emerging approach is **goal-driven (scenario) testing**: instead of enumerating unit, integration, and end-to-end assertions, you give an agent a plain-language goal — for example, *"Create an account and get a fishing licence"* — and it drives the running application to accomplish it, reporting where it got stuck. It is good at exploratory testing and at surfacing integration and usability gaps that scripted tests miss.

Because the agent explores a different path each run, goal-driven testing is **non-deterministic**: a pass or failure is not perfectly repeatable, and it can produce false positives and negatives. Use it to **enhance, not replace** your deterministic suites:

- Keep deterministic unit/integration/e2e tests as the **merge and regression gate** — they must be repeatable to be trustworthy in CI.
- Use goal-driven runs as **exploratory testing** during development and before release, and turn any real defect it finds into a deterministic regression test.
- Never let a non-deterministic result be the only thing standing between a change and production.

## Security requirements — make them concrete

"Follow security best practices" is too vague for a developer or an agent. Translate the requirements that apply to your system into acceptance criteria, agent instructions, tests, and CI checks. Path-scoped instructions (for example a `security-and-owasp.instructions.md` that loads only for source files) put secure-coding mechanics in front of the agent exactly when it edits code, on top of an always-on baseline in `AGENTS.md`.

At minimum, review changes that affect authentication and sessions; authorization, object-level access, and tenant separation; input validation and output handling; secrets and credentials; logging without sensitive-data disclosure; dependency and build-pipeline integrity; encryption and transport; personal-information handling; retention and deletion; administrative and deployment access; and failure handling.

## Documentation — keep it current without extra effort

Documentation only stays current when it is part of the change, not a follow-up chore. Streamline it with agent-facing automation:

- A **docs-currency rule** in `AGENTS.md` — *no merged change may leave the documentation less true than the code* — so the agent updates docs in the same pull request.
- A **docs-update** skill that maps each kind of change (behaviour, API, config, architecture, data handling, dependencies) to the docs that must change.
- A **pull request template** with Docs / Architecture / Compliance prompts, and a **docs-check** workflow that catches broken links and documentation drift.

Treat AI-generated documentation and diagrams as proposed content and validate them against the implemented system.

## Require human review for sensitive code

Some code should never merge on an agent's say-so, no matter how confident it looks — authentication and authorization, cryptography, payment or financial logic, privacy-sensitive data flows, infrastructure, and deployment configuration.

Define those sensitive capabilities and files for your repository, then enforce human review **in CI/CD, not in the agent's instructions**. A `CODEOWNERS` file plus a branch-protection ruleset that requires code-owner approval is a server-side control: it applies when the pull request is opened, so the agent is not aware of it while it works and cannot be talked into bypassing it. This is stronger than asking the agent nicely to request review.

```text
# .github/CODEOWNERS — require the security team to review sensitive routes.
/src/auth/           @your-org/security-reviewers
/src/payments/       @your-org/security-reviewers
/infra/              @your-org/platform-reviewers
/.github/workflows/  @your-org/platform-reviewers
```

## Ship AI-assisted changes through normal controls

AI-assisted code follows the same engineering controls as human-authored code. Before merge: inspect the full diff, confirm it meets the specification, review dependencies and licences, run required tests and security checks, verify documentation impacts, inspect generated files and configuration, and confirm no credentials or production data were introduced.

AI code review, security-review agents, and auto-fixers can add a useful opinion, but they must not count as the required human approval, approve their own change, bypass required checks, merge automatically, or deploy to production. An auto-fixer should propose a patch or draft pull request for review.

## References

- [GitHub: Review AI-generated code](https://docs.github.com/en/copilot/tutorials/review-ai-generated-code)
- [GitHub: Writing tests with GitHub Copilot](https://docs.github.com/en/copilot/tutorials/write-tests)
- [Context7 — up-to-date library docs for agents](https://github.com/upstash/context7)
- [OWASP Application Security Verification Standard](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [AI Security Quickstart (bcgov-c, internal)](https://github.com/bcgov-c/AI-security-quickstart)
