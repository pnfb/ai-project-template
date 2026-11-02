#!/usr/bin/env node
// PostToolUse hook (Edit|Write): format the edited file with Prettier so formatting never fails CI.
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import path from "node:path";

const input = JSON.parse(
  await new Promise((resolve) => {
    let data = "";
    process.stdin.on("data", (chunk) => (data += chunk));
    process.stdin.on("end", () => resolve(data || "{}"));
  }),
);
const file = input?.tool_input?.file_path;
const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const prettier = path.join(root, "node_modules", ".bin", "prettier");

if (file && existsSync(file) && existsSync(prettier)) {
  // --ignore-unknown skips file types Prettier can't format; .prettierignore still applies.
  spawnSync(prettier, ["--write", "--ignore-unknown", "--log-level", "warn", file], {
    cwd: root,
    stdio: "inherit",
  });
}
