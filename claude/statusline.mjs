#!/usr/bin/env node

// Claude Code status line - Node.js version

import { execFileSync, spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, renameSync, statSync, unlinkSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

// The cache lives under the home directory rather than the shared temporary
// directory so that another local user cannot plant files the status line reads.
const PR_CACHE_DIR = join(process.env.XDG_CACHE_HOME ?? join(homedir(), ".cache"), "claude-statusline-pr");
const PR_CACHE_TTL_MS = 60_000;
const PR_REFRESH_LOCK_TTL_MS = 30_000;

if (process.argv[2] === "--refresh-pr") {
  refreshPr(process.argv[3], process.argv[4]);
} else {
  renderStatusLine();
}

function renderStatusLine() {
  const chunks = [];
  process.stdin.on("data", (chunk) => chunks.push(chunk));
  process.stdin.on("end", () => {
    try {
      const data = JSON.parse(Buffer.concat(chunks).toString());
      const lines = [];

      // --- Line 1: Model | Context bar | Rate limits ---
      const parts1 = [];

      // Model
      const model = data.model?.display_name ?? "?";
      parts1.push(`\x1b[1;36m${model}\x1b[0m`);

      // Context usage with bar
      parts1.push(makeBar("ctx", data.context_window?.used_percentage));

      // 5h rate limit with reset time
      const rl5h = data.rate_limits?.five_hour;
      let label5h = "5h";
      if (rl5h?.resets_at) {
        const d = new Date(rl5h.resets_at * 1000);
        label5h = `5h→${d.getHours().toString().padStart(2, "0")}:${d.getMinutes().toString().padStart(2, "0")}`;
      }
      parts1.push(makeBar(label5h, rl5h?.used_percentage));

      // 7d rate limit
      parts1.push(makeBar("7d", data.rate_limits?.seven_day?.used_percentage));

      lines.push(parts1.join("  "));

      // --- Line 2: Directory / worktree / git branch / session stats ---
      const parts2 = [];

      // Worktree or cwd
      if (data.worktree?.name) {
        const wt = data.worktree;
        parts2.push(
          `\x1b[33m🌿 ${wt.name}\x1b[0m \x1b[2m(${wt.branch} ← ${wt.original_branch})\x1b[0m`
        );
      } else {
        // Show shortened cwd
        const cwd = data.cwd ?? data.workspace?.current_dir ?? "";
        const home = process.env.HOME ?? "";
        const short = home && cwd.startsWith(home) ? "~" + cwd.slice(home.length) : cwd;
        parts2.push(`\x1b[33m${short}\x1b[0m`);
      }

      // Pull request
      const pr = resolvePr(data);
      if (pr?.number) {
        parts2.push(fmtPr(pr));
      }

      // Session duration
      const dur = data.cost?.total_duration_ms;
      if (dur != null) {
        parts2.push(`\x1b[2m${fmtDuration(dur)}\x1b[0m`);
      }

      // Lines changed
      const added = data.cost?.total_lines_added ?? 0;
      const removed = data.cost?.total_lines_removed ?? 0;
      if (added || removed) {
        parts2.push(`\x1b[32m+${added}\x1b[0m/\x1b[31m-${removed}\x1b[0m`);
      }

      lines.push(parts2.join("  "));

      process.stdout.write(lines.join("\n"));
    } catch {
      process.stdout.write("statusline error");
    }
  });
}

// Claude Code's own `pr` field can keep pointing at the branch the session
// started on after the branch is switched inside the session, so the PR is
// looked up for the branch currently checked out. Claude Code's value is used
// only until that lookup has produced a result, or when the lookup fails.
function resolvePr(data) {
  const cwd = data.cwd ?? data.workspace?.current_dir;
  const branch = cwd ? currentBranch(cwd) : "";
  if (!branch) return data.pr;

  const cachePath = prCachePath(cwd, branch);
  const cached = readJson(cachePath);
  if (!cached || Date.now() - cached.checkedAt > PR_CACHE_TTL_MS) {
    startPrRefresh(cwd, cachePath);
  }
  if (!cached || cached.error) return data.pr;
  return Number.isInteger(cached.pr?.number) ? cached.pr : null;
}

function currentBranch(cwd) {
  try {
    return execFileSync("git", ["-C", cwd, "branch", "--show-current"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 1000,
    }).trim();
  } catch {
    return "";
  }
}

function prCachePath(cwd, branch) {
  const key = createHash("sha256").update(`${cwd}\0${branch}`).digest("hex");
  return join(PR_CACHE_DIR, `${key}.json`);
}

// `gh` takes up to a few seconds and Claude Code cancels a status line command
// that is still running when the next update arrives, so the lookup runs in a
// detached process and its result is shown on the next render.
function startPrRefresh(cwd, cachePath) {
  const lockPath = `${cachePath}.lock`;
  try {
    if (Date.now() - statSync(lockPath).mtimeMs < PR_REFRESH_LOCK_TTL_MS) return;
  } catch {
    // No lock file: no refresh is running.
  }
  try {
    mkdirSync(PR_CACHE_DIR, { recursive: true, mode: 0o700 });
    writeFileSync(lockPath, "", { mode: 0o600 });
    spawn(process.execPath, [fileURLToPath(import.meta.url), "--refresh-pr", cwd, cachePath], {
      detached: true,
      stdio: "ignore",
    }).unref();
  } catch {
    // The status line falls back to Claude Code's `pr` field.
  }
}

function refreshPr(cwd, cachePath) {
  let entry;
  try {
    const out = execFileSync("gh", ["pr", "view", "--json", "number,state,isDraft,reviewDecision"], {
      cwd,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
      timeout: 15_000,
    });
    const pr = JSON.parse(out);
    entry = { pr: pr.state === "OPEN" ? toStatusLinePr(pr) : null };
  } catch (err) {
    const noPr = String(err.stderr ?? "").includes("no pull requests found");
    entry = noPr ? { pr: null } : { error: true };
  }
  try {
    // Write then rename so that a concurrent render never reads a partial file.
    const tmpPath = `${cachePath}.${process.pid}.tmp`;
    writeFileSync(tmpPath, JSON.stringify({ ...entry, checkedAt: Date.now() }), { mode: 0o600 });
    renameSync(tmpPath, cachePath);
  } finally {
    try {
      unlinkSync(`${cachePath}.lock`);
    } catch {
      // Already removed.
    }
  }
}

// Converts `gh pr view` output to the shape of Claude Code's `pr` field.
function toStatusLinePr(pr) {
  const reviewStates = {
    APPROVED: "approved",
    CHANGES_REQUESTED: "changes_requested",
  };
  return {
    number: pr.number,
    review_state: pr.isDraft ? "draft" : reviewStates[pr.reviewDecision] ?? "pending",
  };
}

function readJson(path) {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return undefined;
  }
}

function makeBar(label, pct) {
  if (pct == null) return `\x1b[2m${label}:--\x1b[0m`;

  const width = 10;
  const filled = Math.round((pct / 100) * width);
  const empty = width - filled;

  // Color based on usage level
  let color;
  if (pct >= 80) color = "\x1b[31m"; // red
  else if (pct >= 50) color = "\x1b[33m"; // yellow
  else color = "\x1b[32m"; // green

  const bar = "█".repeat(filled) + "░".repeat(empty);
  const pctStr = pct.toFixed(0).padStart(3) + "%";

  return `${label} ${color}${bar}\x1b[0m ${pctStr}`;
}

function fmtPr(pr) {
  const marks = {
    approved: "\x1b[32m ✓\x1b[0m",
    changes_requested: "\x1b[31m ✗\x1b[0m",
    draft: "\x1b[2m draft\x1b[0m",
  };
  const mark = marks[pr.review_state] ?? "";
  return `\x1b[35mPR #${pr.number}\x1b[0m${mark}`;
}

function fmtDuration(ms) {
  const s = Math.floor(ms / 1000);
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m${s % 60}s`;
  const h = Math.floor(m / 60);
  return `${h}h${m % 60}m`;
}
