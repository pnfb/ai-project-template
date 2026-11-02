# REVIEW.md

The checklist the `verifier` subagent (and any reviewer) applies to every PR. The owner reviews intent and the preview. This review covers the code.

## Severity

| Level | Meaning | Action |
|---|---|---|
| **Blocking** | Wrong behaviour, a security issue, data loss, an acceptance criterion not met, or a broken build or tests | Must be fixed before the PR is marked ready |
| **Should fix** | A likely bug, a missing test for new logic, an accessibility failure, or a real deviation from conventions | Fix it in this PR, or record it as a follow-up in the PR with a reason |
| **Note** | Style, a naming nit, a simplification idea | Optional |

## Passes

1. **Spec conformance.** Every acceptance criterion in `spec.md` is implemented and has evidence. Nothing outside the spec's scope was added.
2. **Correctness.** Edge cases, error handling, empty, loading and failure states, and race conditions.
3. **Security.** No secrets in the code, user input is validated, authorization is checked on the server, no injection or XSS, and dependencies are reasonable.
4. **CI.** The PR's checks are green on its latest commit.
5. **Tests.** New logic has tests. Bug fixes include a test that fails without the fix. Existing tests weren't weakened.
6. **UI and accessibility.** The UI matches the project's design rules, works on mobile and desktop widths, is usable with a keyboard, has labels and sufficient contrast, and has no layout shift.
7. **Maintainability.** The code follows existing patterns, has no dead code, and introduces no unnecessary abstraction.
8. **Docs.** The roadmap, the work item's docs and `CLAUDE.md` (commands, recurring mistakes) are updated where needed.

## Output format

A list of findings, most severe first. Each finding gives the `file:line`, the severity, the problem, and a concrete failure scenario. If there are none, say so explicitly.
