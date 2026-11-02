#!/usr/bin/env bash
# Checks that guard-main.mjs blocks pushes to main and merges, and allows normal work. Run: bash .claude/hooks/test.sh
set -u
cd "$(dirname "$0")/../.."
fail=0
check() {
  local expected="$1" cmd="$2"
  printf '{"tool_input":{"command":%s}}' "$(node -e 'console.log(JSON.stringify(process.argv[1]))' "$cmd")" \
    | node .claude/hooks/guard-main.mjs >/dev/null 2>&1
  local code=$?
  local got=allow; [ "$code" -eq 2 ] && got=block
  if [ "$got" = "$expected" ]; then echo "ok    $expected: $cmd"; else echo "FAIL  expected $expected, got $got: $cmd"; fail=1; fi
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
check allow "curl -s https://api.github.com/repos/example/repo/pulls/3"
check allow "git push origin work/0003-example"
check allow "git push --force-with-lease origin work/0004-example"
check allow "git fetch origin main"
check allow "git merge origin/main"
check allow "gh api repos/example/repo/pulls/3"
check allow "gh pr view 3"
if printf 'not json' | node .claude/hooks/guard-main.mjs >/dev/null 2>&1; then echo "FAIL  malformed input should block"; fail=1; else echo "ok    block: malformed hook input (fails closed)"; fi
exit $fail
