# AI project template

A starting point for building a product as **one human owner working with Claude Code agents**. It packages a lightweight version of the [AI-native SDLC playbook](https://claude.com/resources/articles/the-ai-native-sdlc-playbook): the repo is the single source of truth, Claude does the drafting, building and verifying, and the owner approves *what* gets built and *whether it works*, without needing to read code.

## The ways of working in one page

- **Everything lives in the repo.** Specs, decisions, approvals and status are Markdown files in git. Chat is for talking; anything important gets written down. No ticket system: [`docs/roadmap.md`](docs/roadmap.md) is the backlog.
- **One work item = one folder = one branch = one PR.** `work/0007-dark-mode/` holds `intent.md`, `spec.md` and `plan.md`; the branch is `work/0007-dark-mode`; a single PR goes through all stages.
- **The stages:** Intent → Spec → Plan → Build → Preview → Merge.
  - The owner **approves the intent and the spec** (with numbered, testable acceptance criteria). That's where the owner's time goes.
  - The plan needs approval only if it introduces an **ADR** (an architecture decision record for anything hard to reverse: stack, hosting, data model, auth, paid services).
  - Approvals are recorded in each doc's `Status:` line, e.g. `Approved (alice, 2026-10-29, chat)`, so git history shows who asked for what and who approved it.
- **Claude doesn't mark its own work as done.** Before a PR is ready, a separate `verifier` subagent reviews the diff against [`REVIEW.md`](REVIEW.md) and the spec's acceptance criteria. CI runs the objective checks. Claude clicks through the preview itself before asking the owner to.
- **The owner reviews a working preview, not code.** Every PR gets a preview deploy. Feedback goes back into the same PR.
- **Only the owner merges.** A Claude Code hook blocks `git push` to `main` and PR merges, so this holds even without branch protection. Production deploys run only after the checks pass on `main`.
- **Small decisions are made without the owner and listed** in the PR under "Decisions made without you". Product ambiguity goes in the spec's "Open questions"; Claude doesn't guess.
- **Agents learn.** [`CLAUDE.md`](CLAUDE.md) stays under a page and has a "Recurring mistakes" section that grows whenever an agent repeats an error.
- **Usage is kept low.** A fresh session per work item, one push per meaningful step, one verifier run per PR, no PR event subscriptions, and CI that skips the build for doc-only PRs.

The details are in [`docs/process.md`](docs/process.md).

## What's in here

| Path | What it is |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | The agent working agreement: gates, Definition of Done, commands, conventions, recurring mistakes |
| [`REVIEW.md`](REVIEW.md) | Severity levels and review passes used by the verifier |
| [`docs/process.md`](docs/process.md) | Roles, the work item lifecycle, approvals, decisions, keeping usage low |
| [`docs/roadmap.md`](docs/roadmap.md) | The backlog and the single status tracker |
| [`docs/decisions/`](docs/decisions/) | ADRs, with a template and ADR-0001 (adopting this process) |
| [`work/_templates/`](work/_templates/) | `intent.md`, `spec.md`, `plan.md` templates |
| [`.claude/agents/verifier.md`](.claude/agents/verifier.md) | The independent reviewer subagent |
| [`.claude/settings.json`](.claude/settings.json), [`.claude/hooks/`](.claude/hooks/) | Hooks: block pushes to `main` and PR merges (with tests), format edited files with Prettier |
| [`.github/pull_request_template.md`](.github/pull_request_template.md) | PR layout: stage, preview, decisions made without you, evidence per acceptance criterion |
| [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | Starter CI that skips doc-only PRs; extended in the foundation work item |

The template is stack-agnostic. The hooks need Node.js (18+) on the machine running Claude Code.

## Starting a new project

1. On GitHub, click **Use this template** → **Create a new repository**, then open it in Claude Code.
2. Replace the placeholders:
   ```bash
   grep -rl --exclude-dir=.git -e '{{OWNER}}' -e '{{PROJECT}}' . | xargs sed -i -e 's/{{OWNER}}/your-github-handle/g' -e 's/{{PROJECT}}/Your Project/g'
   ```
   (On macOS use `sed -i ''`.) Then replace this README with one about your project.
3. Give Claude a first prompt like:
   > Read CLAUDE.md and docs/process.md. I'm the owner. Here's what I want to build: … Write the product spec in `docs/product/`, ask me what's unclear, then start work item 0001 Foundation with an intent.
4. Accept ADR-0001 by setting its `Status:` line once you're happy with the process.
5. Optional: if the repo allows it, also turn on branch protection for `main`. The hook protects against agents, and branch protection also covers people.

## Adapting it

Keep what works for you. Common changes are dropping the preview stage for a library or CLI, adding project skills in `.claude/skills/` for domain rules (design system, content model), and adding more checks to `REVIEW.md` and CI as the project grows.

## Licence

MIT. See [`LICENSE`](LICENSE).
