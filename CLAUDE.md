# CLAUDE.md

Working agreement for agents on {{PROJECT}}. Keep this file under a page. When an agent repeats a mistake, add the correction under "Recurring mistakes".

## How we work
- The repo is the single source of truth. Specs, decisions and status live here; nothing important lives only in chat.
- Every change is a **work item** in `work/NNNN-slug/` with `intent.md`, `spec.md`, `plan.md`, and it is tracked in `docs/roadmap.md`.
- One work item = one branch (`work/NNNN-slug`) = one PR. The full flow is in `docs/process.md`.
- **Gates:** the owner ({{OWNER}}) approves `intent.md` and `spec.md` before code. `plan.md` needs approval only if it introduces an ADR. Otherwise proceed and record the decision.
- Record approvals in the doc's `Status:` line, with the date and where the approval was given (chat or PR comment).
- **Never** merge PRs, push to `main`, or deploy to production. The owner merges.
- Cross-cutting or hard-to-reverse choices (stack, hosting, data model, auth, paid services) need an ADR in `docs/decisions/`.

## Definition of Done (before marking a PR ready)
1. Acceptance criteria in `spec.md` are each verified, with evidence in the PR (test names, screenshots).
2. Lint, typecheck, tests and build pass locally and in CI.
3. UI changes are checked in a real browser (Playwright) and screenshots are attached.
4. The `verifier` subagent has reviewed the diff against `REVIEW.md`, and blocking findings are fixed.
5. `docs/roadmap.md` and the work item's docs reflect what was actually built.
6. The PR description lists "Decisions made without you" and has a preview link (once previews exist).

Never mark a PR ready while its checks are red. If `main` has no branch protection, this rule and the guard hook are what protect it.

## Commands
<!-- Filled in by the foundation work item, once the stack exists. Keep one "run everything" command. -->
- `TODO`: one command that runs format check, lint, typecheck and unit tests. Run it before every push.
- `bash .claude/hooks/test.sh`: test the guard hook

Hooks in `.claude/settings.json` block pushes to `main` and PR merges, and run Prettier on edited files (if Prettier is installed).

## Where things are
- Process: `docs/process.md`. Backlog and status: `docs/roadmap.md`. Decisions: `docs/decisions/`.
- Review checklist: `REVIEW.md`. Work items: `work/`.
<!-- Add product spec, design rules and project skills here as they appear. -->

## Conventions
- Docs: Markdown, short, plain language. Link to specs rather than duplicating them.
- Bug fixes start with a failing test. Don't weaken a test to make it pass.
- Don't subscribe to PR events: after a push, wait for CI in one command and report the result. Run the verifier once per PR. See `docs/process.md`, "Keeping Claude and CI usage low".
- Push in batches: one push per meaningful step (a doc and its fixes, a feature and its tests), not after every small commit. Every push runs the full CI.
- Start each work item in a fresh Claude session.

## Recurring mistakes
- Before telling the owner a PR is ready to merge, set its roadmap row to `Done` in the PR (when the owner has approved the preview).
- Don't `pkill -f` a pattern that also appears in your own command line: it kills your own shell. Stop processes by PID (`$!`) or exact name (`pgrep -x <name> | xargs -r kill`).
- Network in cloud agent sessions is limited by a policy set outside the repo (GitHub usually works; package registries can be denied). Before saying "no internet", check the proxy status (`curl -sS "$HTTPS_PROXY/__agentproxy/status"`). If a registry is denied, tell the owner to change the environment's network setting; don't retry in loops, and don't write the limit into specs or plans as a fact about the project.
