# Process

{{PROJECT}} follows a lightweight version of the [AI-native SDLC playbook](https://claude.com/resources/articles/the-ai-native-sdlc-playbook), adapted for one human owner working with Claude agents. See [ADR-0001](decisions/0001-lightweight-ai-native-sdlc.md) for why.

## Roles

| Who | Does |
|---|---|
| **Owner ({{OWNER}})** | Has the ideas and owns the product. Approves intent and specs, tries previews, merges PRs. Doesn't need to read code. |
| **Claude (lead session)** | Drafts intent, spec and plan. Implements, verifies, opens PRs, keeps the roadmap and `CLAUDE.md` current, and coordinates other agents. |
| **Claude (parallel sessions)** | Work on independent work items, each on its own branch and PR. |
| **Verifier subagent** | Reviews each diff independently against `REVIEW.md`. Code isn't approved by the agent that wrote it. |
| **CI** | Runs the objective checks: lint, typecheck, tests, build, e2e. |

## Lifecycle of a work item

Each work item has a folder `work/NNNN-slug/` (copied from `work/_templates/`), a branch `work/NNNN-slug`, and a single PR that moves through these stages:

1. **Intent.** Claude writes `intent.md`: the problem, the desired outcome, who it affects, constraints, and open questions. A draft PR is opened. **The owner approves** or asks for changes.
2. **Spec.** Claude writes `spec.md`: requirements, UX, and numbered acceptance criteria. **The owner approves.** A back-and-forth is expected here.
3. **Plan.** Claude writes `plan.md`: the files and areas to change, the order of work, the risks, and how each acceptance criterion will be proven. Claude proceeds unless the plan includes an ADR. In that case the owner approves the ADR (in chat or a PR comment, recorded in its Status line) before the build starts. Merging the PR never counts as approving an ADR.
4. **Build and verify.** Claude implements and meets the Definition of Done in `CLAUDE.md`. The verifier reviews the diff.
5. **Preview.** The PR is marked ready and has a preview deployment. Claude first clicks through the preview with a browser tool and fixes what it finds. Then the owner clicks through it and leaves feedback, which Claude works on in the same PR.
6. **Merge.** The owner squash-merges, but only when the PR shows a green ✓. Production deploys only run after the checks pass on `main`. Once the owner is happy with the preview, Claude sets the item to `Done` in `docs/roadmap.md` in the PR's final commit, so the roadmap on `main` is correct as soon as the PR merges. The in-between stages appear on the work branch and in the PR's **Stage** line.

### Small changes
Small changes such as typo fixes, copy tweaks or dependency bumps can skip intent and spec. They still need a PR, a roadmap entry and passing CI.

Bugs found after a merge become new work items, which start with a failing test.

### Design drops (optional)
If visual work happens in a design tool (for example Claude Design), the repo is where it is checked and connected to the app:

1. The owner finishes the work in the design tool and exports a **design drop**: a short intent (what changes and why) plus the files, already in the repo's layout.
2. The owner uploads the drop to a new work branch and tells Claude.
3. Claude turns it into a work item: checks the files, connects them to the app, and opens the PR with a preview.
4. Visual feedback goes back to the design tool, and an updated drop replaces the files in the same PR.

Claude doesn't make visual judgement calls on artwork. Problems get reported back to the design tool.

## Approvals

The owner can approve in chat or in a PR comment. Claude records the approval in the document's status line, for example `Status: Approved ({{OWNER}}, 2026-01-31, chat)`. That way the git history keeps the record of who asked for what, what was built, and who approved it.

## Decisions

- **Small and reversible** (naming, library internals, component structure): Claude decides and lists the decision in the PR under "Decisions made without you".
- **Cross-cutting or hard to reverse** (stack, hosting, data model, auth, paid services): an ADR in `docs/decisions/`, approved by the owner.
- **Product or UX ambiguity:** goes into the spec under "Open questions". Claude doesn't guess.

## Project knowledge for agents

- `CLAUDE.md` is loaded into every session: keep it short, and grow "Recurring mistakes" whenever an agent repeats one.
- Longer, topic-specific rules (design system, content model, domain rules) go into **project skills** in `.claude/skills/<name>/SKILL.md`, which agents load only when the task needs them. `CLAUDE.md` says when to read each one.

## Keeping Claude and CI usage low
- **No PR event subscriptions.** Each GitHub event (preview updated, CI finished) wakes Claude for a full turn that re-reads the conversation. Instead, after a push Claude waits for CI in one command and reports the result; the owner writes when they've merged or have feedback.
- **One verifier review per PR**, before it's marked ready, plus a short re-check only if blocking findings were fixed. Screenshots are taken and read only where the spec asks for them.
- **One push per meaningful step** (see `CLAUDE.md`). CI skips the build for document-only PRs, so they finish in seconds.
- **Whole work items at a time:** the owner approves intent and spec together where possible, and reviews the preview once with all comments.
- **A fresh session per work item.** Everything a new session needs is in the repo, so long conversations aren't needed.

## Parallel work

Work items run one at a time until the foundation (stack, CI, previews, design system) is merged. After that, two or three independent work items can run in parallel, each with its own branch and PR. The lead session keeps `docs/roadmap.md` up to date.

## Not adopted (yet)

Incident monitoring and control bands, continuous evals on config changes, managed settings and autonomy tiers. Revisit these once there are real users.
