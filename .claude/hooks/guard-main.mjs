#!/usr/bin/env node
// PreToolUse hook (Bash): agents may not push to main or merge PRs. The owner merges (see CLAUDE.md).
// Best effort: it judges each simple command in the line by its command word, so text that only
// mentions these commands (commit messages, grep patterns) is allowed.
import { execSync } from "node:child_process";

let input;
try {
  input = JSON.parse(
    await new Promise((resolve) => {
      let data = "";
      process.stdin.on("data", (chunk) => (data += chunk));
      process.stdin.on("end", () => resolve(data));
    }),
  );
} catch {
  console.error("Blocked: guard-main could not read the command (fails closed).");
  process.exit(2);
}
const command = String(input?.tool_input?.command ?? "");

function currentBranch() {
  try {
    return execSync("git rev-parse --abbrev-ref HEAD", {
      cwd: input.cwd || process.cwd(),
      stdio: ["ignore", "pipe", "ignore"],
    })
      .toString()
      .trim();
  } catch {
    return "";
  }
}

const WRAPPERS = new Set(["sudo", "env", "command", "exec", "time", "nohup", "xargs"]);
const SHELLS = new Set(["bash", "sh", "zsh", "dash"]);
const GIT_OPTS_WITH_ARG = new Set(["-C", "-c", "--git-dir", "--work-tree", "--namespace"]);
const WRITE_METHOD = /^(PUT|POST|PATCH|DELETE)$/i;
const MERGE_PATH = /(pulls\/\d+\/merge|\/merges\b|git\/refs\/heads\/main\b|ccr\/auto_merge)/;
const MERGE_MUTATION = /(mergePullRequest|enablePullRequestAutoMerge|updateRef)/;

// Strip quotes so `bash -c "git push origin main"` and `'main'` are judged like plain words.
const flat = command.replace(/["'`]/g, " ");

function commandWords(segment) {
  let words = segment.trim().split(/\s+/).filter(Boolean);
  for (;;) {
    while (words.length && /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[0])) words = words.slice(1);
    if (words.length && WRAPPERS.has(words[0])) words = words.slice(1);
    else if (words.length > 1 && SHELLS.has(words[0]) && words[1] === "-c") words = words.slice(2);
    else return words;
  }
}

function checkGitPush(args) {
  let i = 0;
  while (i < args.length && args[i].startsWith("-")) i += GIT_OPTS_WITH_ARG.has(args[i]) ? 2 : 1;
  if (args[i] !== "push") return null;
  const rest = args.slice(i + 1);
  if (rest.some((a) => a === "--all" || a === "--mirror")) return "pushing all branches";
  const positional = rest.filter((a) => !a.startsWith("-"));
  const refspecs = positional.slice(1); // first positional is the remote
  const onMain = () => currentBranch() === "main";
  for (const raw of refspecs) {
    const ref = raw.replace(/^\+/, "");
    if (/(^|:)(refs\/heads\/)?main$/.test(ref)) return "pushing to main";
    if ((ref === "HEAD" || ref === "@") && onMain()) return "pushing to main";
  }
  if (refspecs.length === 0 && onMain()) return "pushing to main";
  return null;
}

function checkGh(args) {
  const positional = [];
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "-R" || args[i] === "--repo") i++;
    else if (!args[i].startsWith("-")) positional.push(args[i]);
  }
  if (positional[0] === "pr" && positional[1] === "merge") return "merging a PR with gh";
  if (positional[0] === "api") {
    const text = args.join(" ");
    if (MERGE_MUTATION.test(text)) return "merging a PR through the API";
    const methodAt = args.findIndex((a) => a === "-X" || a === "--method");
    const method = methodAt >= 0 ? args[methodAt + 1] : "";
    const sendsFields = args.some((a) => /^(-f|-F|--field|--raw-field|--input)$/.test(a));
    if (MERGE_PATH.test(text) && (WRITE_METHOD.test(method ?? "") || sendsFields)) {
      return "merging a PR through the API";
    }
  }
  return null;
}

function checkCurl(args) {
  const text = args.join(" ");
  if (!/api\.github\.com|\/graphql/.test(text)) return null;
  if (MERGE_MUTATION.test(text)) return "merging a PR through the API";
  const methodAt = args.findIndex((a) => a === "-X" || a === "--request");
  const method = methodAt >= 0 ? args[methodAt + 1] : "";
  const sendsData = args.some((a) => /^(-d|--data.*|--json|-F|--form)$/.test(a));
  if (MERGE_PATH.test(text) && (WRITE_METHOD.test(method ?? "") || sendsData)) {
    return "merging a PR through the API";
  }
  return null;
}

const reasons = new Set();
for (const segment of flat.split(/&&|\|\||;|\n|\||\$\(|\)/)) {
  const words = commandWords(segment);
  const [cmd, ...args] = words;
  const reason =
    cmd === "git"
      ? checkGitPush(args)
      : cmd === "gh"
        ? checkGh(args)
        : cmd === "curl"
          ? checkCurl(args)
          : null;
  if (reason) reasons.add(reason);
}

if (reasons.size > 0) {
  console.error(
    `Blocked: ${[...reasons].join(", ")}. Only the owner merges to main (CLAUDE.md). Push to a work/NNNN-* branch and open a PR instead.`,
  );
  process.exit(2);
}
