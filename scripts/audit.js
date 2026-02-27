#!/usr/bin/env node
/* eslint-disable no-console */
const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

function hasLockOrModules(cwd) {
  const lock = path.join(cwd, "package-lock.json");
  const modules = path.join(cwd, "node_modules");
  return fs.existsSync(lock) || fs.existsSync(modules);
}

function parseAuditLevel(argv) {
  const levelIndex = argv.indexOf("--level");
  if (levelIndex !== -1 && argv[levelIndex + 1]) {
    return argv[levelIndex + 1];
  }
  return "high";
}

function main() {
  const cwd = process.cwd();
  const level = parseAuditLevel(process.argv.slice(2));

  if (!hasLockOrModules(cwd)) {
    console.warn(
      "[audit] Skipping npm audit: no package-lock.json or node_modules found."
    );
    process.exit(0);
  }

  const result = spawnSync(
    "npm",
    ["audit", "--audit-level", level],
    { stdio: "inherit", shell: process.platform === "win32" }
  );

  process.exit(result.status ?? 1);
}

main();
