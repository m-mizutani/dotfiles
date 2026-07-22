#!/usr/bin/env node
// PreToolUse guard enforcing the "Git Worktree Isolation" rule from CLAUDE.md.
//
// WHY NOT rely on the prose rule alone: text instructions are advisory and the
// model demonstrably forgets them when buried under large project contexts.
// A hook is executed by the harness, not the model, so it cannot be "forgotten".
//
// Behavior: when the session cwd is inside a *linked* worktree, any mutating
// file tool (Edit/Write/MultiEdit/NotebookEdit) whose target resolves outside
// the current worktree root is denied. Reading outside stays allowed.

import { execFileSync } from 'node:child_process';
import { resolve, relative, isAbsolute, sep } from 'node:path';
import { homedir } from 'node:os';

const GUARDED = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit']);

function readStdin() {
  return new Promise((res) => {
    let raw = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (c) => (raw += c));
    process.stdin.on('end', () => res(raw));
  });
}

function allow() {
  process.exit(0);
}

function deny(reason) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason: reason,
      },
    })
  );
  process.exit(0);
}

const raw = await readStdin();

let input;
try {
  input = JSON.parse(raw);
} catch {
  allow(); // malformed payload: never block on our own parsing failure
}

const toolName = input.tool_name;
const cwd = input.cwd || process.cwd();
const filePath = input.tool_input?.file_path || input.tool_input?.notebook_path;

if (!GUARDED.has(toolName) || !filePath) allow();

const git = (args) =>
  execFileSync('git', ['-C', cwd, ...args], { encoding: 'utf8' }).trim();

let gitDir, commonDir, topLevel;
try {
  gitDir = resolve(cwd, git(['rev-parse', '--git-dir']));
  commonDir = resolve(cwd, git(['rev-parse', '--git-common-dir']));
  topLevel = git(['rev-parse', '--show-toplevel']);
} catch {
  allow(); // not a git repo (or git unavailable): out of scope, don't interfere
}

// In a linked worktree, --git-dir (".git/worktrees/<name>") differs from the
// shared --git-common-dir. They are equal in the main working tree.
if (gitDir === commonDir) allow();

// Lexical resolve only (no realpath): keep symlinked dirs such as `tmp`, which
// physically live elsewhere but appear under the worktree, on the allowed side.
const abs = isAbsolute(filePath) ? resolve(filePath) : resolve(cwd, filePath);
const rel = relative(topLevel, abs);
const outside = rel === '..' || rel.startsWith(`..${sep}`) || isAbsolute(rel);

// Exception: Claude's persistent memory lives at ~/.claude/projects/<slug>/memory/,
// which is always outside a worktree. Writing memories must survive worktree
// isolation, so allow mutations under any such `memory` directory. The scope is
// kept narrow (projects/*/memory only) so the isolation guarantee stays intact
// for everything else under ~/.claude.
const memoryRoot = resolve(homedir(), '.claude', 'projects');
const memRel = relative(memoryRoot, abs);
const insideProjects =
  memRel !== '..' && !memRel.startsWith(`..${sep}`) && !isAbsolute(memRel);
const segments = memRel.split(sep);
// projects/<slug>/memory/... => segments[1] === 'memory'
const isMemory = insideProjects && segments.length >= 3 && segments[1] === 'memory';
if (isMemory) allow();

if (outside) {
  deny(
    `Git Worktree Isolation: refusing to ${toolName} a path outside the current worktree.\n` +
      `  worktree root: ${topLevel}\n` +
      `  target:        ${abs}\n` +
      `Reading outside the worktree is fine, but mutating files outside it is forbidden ` +
      `(CLAUDE.md › Git Worktree Isolation). If this change truly belongs in the main repo ` +
      `or another worktree, stop and ask the user.`
  );
}

allow();
