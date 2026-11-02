#!/usr/bin/env bash
# Checks that guard-main.mjs blocks pushes to main and merges, and allows normal work. Run: bash .claude/hooks/test.sh
set -u
cd "$(dirname "$0")/../.."
fail=0
# Some results depend on the current branch (`git push origin HEAD`), so every check runs in a scratch
# repo on a known branch, never in this checkout (CI runs it on main, agents on work branches).
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for branch in main work/0001-example; do
  dir="$tmp/${branch//\//-}"
  git init -q -b "$branch" "$dir"
  git -C "$dir" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m init
done
WORK_REPO="$tmp/work-0001-example"
MAIN_REPO="$tmp/main"
# check <expected> <command> [repo]: runs the hook as if Claude ran <command> in <repo> (default: on a work branch).
check() {
  local expected="$1" cmd="$2" repo="${3:-$WORK_REPO}"
  node -e 'console.log(JSON.stringify({ cwd: process.argv[2], tool_input: { command: process.argv[1] } }))' "$cmd" "$repo" \
    | node .claude/hooks/guard-main.mjs >/dev/null 2>&1
  local code=$?
  local got=allow; [ "$code" -eq 2 ] && got=block
  local where="${repo##*/}"
  if [ "$got" = "$expected" ]; then echo "ok    $expected ($where): $cmd"; else echo "FAIL  expected $expected, got $got ($where): $cmd"; fail=1; fi
}
check block "git push origin main"
check block "git push -u origin main"
check block "git push origin HEAD:main"
check block "git push origin +main"
check block "git push origin work/0003-example:refs/heads/main"
check block "npm test && git push origin main"
check block "gh pr merge 3 --squash"
check block "gh api -X PUT repos/example/repo/pulls/3/merge"
check block "gh api -X PUT repos/example/repo/pulls/3/ccr/auto_merge"
check block "git -C /path/to/repo push origin main"
check block "git -c user.name=x push origin main"
check block "git push origin 'main'"
check block 'git push origin "HEAD:main"'
check block "git push --all origin"
check block "git push --mirror origin"
check block 'bash -c "git push origin main"'
check block "FOO=1 git push origin main"
check block "gh pr -R example/repo merge 3"
check block "gh api graphql -f query='mutation { mergePullRequest(input: {pullRequestId: \"x\"}) { clientMutationId } }'"
check block "gh api graphql -f query='mutation { enablePullRequestAutoMerge(input: {}) { clientMutationId } }'"
check block "gh api -X POST repos/example/repo/merges -f base=main -f head=x"
check block "gh api -X PATCH repos/example/repo/git/refs/heads/main -f sha=abc"
check block "curl -X PUT https://api.github.com/repos/example/repo/pulls/3/merge"
check allow "git push -u origin work/0003-example"
check allow 'git commit -m "docs: never run gh pr merge or git push origin main"'
check allow 'grep -rn "gh pr merge" .claude'
check allow "gh api repos/example/repo/pulls/3/merge"
check allow "git push origin HEAD"
check block "git push origin HEAD" "$MAIN_REPO"
check block "git push" "$MAIN_REPO"
check allow "git push"
check allow "curl -s https://api.github.com/repos/example/repo/pulls/3"
check allow "git push origin work/0003-example"
check allow "git push --force-with-lease origin work/0004-example"
check allow "git fetch origin main"
check allow "git merge origin/main"
check allow "gh api repos/example/repo/pulls/3"
check allow "gh pr view 3"
if printf 'not json' | node .claude/hooks/guard-main.mjs >/dev/null 2>&1; then echo "FAIL  malformed input should block"; fail=1; else echo "ok    block: malformed hook input (fails closed)"; fi
exit $fail
