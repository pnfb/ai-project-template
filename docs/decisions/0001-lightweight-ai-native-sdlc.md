# ADR-0001: Adopt a lightweight AI-native SDLC

Status: Proposed
<!-- Accept it when you adopt the template: Accepted ({{OWNER}}, YYYY-MM-DD, chat | PR comment) -->
Date: YYYY-MM-DD

## Context
{{PROJECT}} is built by one owner ({{OWNER}}) with Claude agents. The owner wants:
- every spec and decision kept in the repo history,
- no separate ticket system,
- to review mainly the intent and a working preview, not the code,
- PRs that are verified before review, so merging them is simple.

The [AI-native SDLC playbook](https://claude.com/resources/articles/the-ai-native-sdlc-playbook) describes a six-stage loop (plan, design, build, test, deploy, maintain) with committed artifacts (`intent.md`, `spec.md`, `plan.md`, `CLAUDE.md`, `REVIEW.md`) and human approval points. It is written for organizations with many roles.

## Options considered
1. **Ad hoc.** Chat-driven changes and PRs. This is fast at first, but decisions get lost between sessions and nothing records what was intended.
2. **The full playbook.** Separate approval at every stage, managed settings, autonomy tiers, monitoring bands. This is too much ceremony for one person.
3. **A lightweight playbook.** Keep the artifacts and the loop, give the owner every human role, and keep only the approval points that matter.

## Decision
Option 3, as described in [`docs/process.md`](../process.md):
- One work item corresponds to one folder (`work/NNNN-slug/`), one branch and one PR, which moves through intent, spec, plan, build, preview and merge.
- The owner approves intent and spec. A plan needs approval only if it includes an ADR.
- The Definition of Done is in `CLAUDE.md`. An independent verifier subagent reviews against `REVIEW.md`. CI and preview deploys are required once the stack exists.
- The backlog is `docs/roadmap.md`. GitHub Issues are not used.
- Claude never merges or deploys to production; a hook blocks pushes to `main` and PR merges.

## Consequences
- Spec quality now matters most, so back-and-forth on specs is expected and cheap.
- Because the owner doesn't read code, automated checks and the verifier have to be strong. CI and previews are early priorities.
- Revisit this if more people join, or once the product is in production (monitoring and incident work items).
