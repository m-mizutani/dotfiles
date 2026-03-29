#!/usr/bin/env node

// Claude Code status line - Node.js version

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

function fmtDuration(ms) {
  const s = Math.floor(ms / 1000);
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m${s % 60}s`;
  const h = Math.floor(m / 60);
  return `${h}h${m % 60}m`;
}
