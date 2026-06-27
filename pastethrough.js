#!/usr/bin/env node
// pastethrough.js  (one-shot, no background process)
//
// PasteThrough — injects text into the CURRENTLY FOCUSED zellij pane as a
// SINGLE bracketed paste (ESC[200~ ... ESC[201~), so a TUI app (e.g. the pi
// coding agent) sees one multiline draft instead of N Enter-submitted lines.
//
// Why this works: native-Windows zellij mangles bracketed paste on the
// terminal->zellij INPUT path (newlines become Enter). We instead write on the
// zellij->PTY path via `zellij action write`, which is NOT affected by that bug.
//
// Targeting: AutoHotkey fires this synchronously while the target pane is still
// focused (nothing opens, nothing steals focus), so a bare `write` with no
// --pane-id lands in exactly the right pane. No watcher, no poller, no focus
// tracking -- this process runs once and exits.
//
// Args:
//   node pastethrough.js <titleOrSession> <tempfile>
//   <titleOrSession> : the raw Windows Terminal window title (AHK passes
//                WinGetTitle("A")). node extracts the session name (the part
//                before " | ") and VALIDATES it against the live active-session
//                list, so a stray title can never write to the wrong session.
//                Pass "-" to target the ambient session (when run inside zellij).
//   <tempfile> : path to a UTF-8 file holding the clipboard text (written by AHK).
//                If it is not an existing path, it is treated as literal text.
//
// Exit codes:
//   0 = handled (bracketed paste injected)
//   3 = could not resolve a zellij session / no input (AHK falls back to a
//       normal paste so Ctrl+V is never silently swallowed)
//   1 = unexpected error

const { execSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

// Log next to this script (portable -- no hardcoded user path). Disable with
// PASTETHROUGH_LOG=0.
const LOG =
  process.env.PASTETHROUGH_LOG === "0"
    ? null
    : path.join(__dirname, "pastethrough.log");
function log(m) {
  if (!LOG) return;
  try { fs.appendFileSync(LOG, `[${new Date().toISOString()}] ${m}\n`); } catch (_) {}
}

// Allow overriding the zellij binary via env; default to PATH lookup.
const ZELLIJ = process.env.ZELLIJ_BIN || "zellij";

function sh(cmd) {
  return execSync(cmd, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], windowsHide: true });
}

// Active (non-exited) zellij session names.
function activeSessions() {
  let out;
  try {
    out = sh(`${ZELLIJ} list-sessions -n`);
  } catch (e) {
    return [];
  }
  return out
    .split("\n")
    .map((l) => l.trim())
    .filter(Boolean)
    .filter((l) => !/\(EXITED/.test(l))
    .map((l) => l.replace(/\s*\[Created.*$/, "").replace(/\s*\(current\)\s*$/, "").trim())
    .filter(Boolean);
}

// Given the raw WT window title (e.g. "my-session | pi"), resolve a
// valid active session. STRICT: the candidate before " | " must be an active
// session. We deliberately do NOT fall back to "the only active session",
// because that could fire bytes into a zellij session living in a DIFFERENT
// terminal tab you cannot see. If it does not resolve, we do nothing.
function resolveSession(rawTitle) {
  const active = activeSessions();
  if (active.length === 0) return null;
  const candidate = String(rawTitle || "").split("|")[0].trim();
  if (candidate && active.includes(candidate)) return candidate;
  log(`session unresolved: title="${rawTitle}" candidate="${candidate}" active=[${active.join(", ")}]`);
  return null;
}

function readInput(arg) {
  if (!arg) return "";
  let text;
  if (fs.existsSync(arg)) {
    text = fs.readFileSync(arg, "utf8");
    // Strip a UTF-8 BOM if one slipped in, then delete the temp file.
    if (text.charCodeAt(0) === 0xfeff) text = text.slice(1);
    if (/[\\/]pastethrough-\d+\.txt$/i.test(arg)) {
      try { fs.unlinkSync(arg); } catch (_) {}
    }
  } else {
    text = arg; // treat as literal text (for manual testing)
  }
  // Normalize CRLF -> LF; drop a single trailing newline.
  text = text.replace(/\r\n/g, "\n").replace(/\r/g, "\n").replace(/\n$/, "");
  return text;
}

function bytesOf(str) {
  return Array.from(Buffer.from(str, "utf8"));
}

const PASTE_START = [27, 91, 50, 48, 48, 126]; // ESC [ 2 0 0 ~
const PASTE_END = [27, 91, 50, 48, 49, 126];   // ESC [ 2 0 1 ~

// Windows command line is capped (~32k). Keep each `write` arg list well under
// that by chunking the body. Brackets wrap the whole stream: 200~ first, 201~
// last; the focused program buffers everything between regardless of how many
// writes it took.
const MAX_BYTES_PER_WRITE = 1800;

function writeBytes(sessionPrefix, byteArr) {
  if (byteArr.length === 0) return;
  // No --pane-id: targets the currently focused pane of the session.
  sh(`${ZELLIJ} ${sessionPrefix}action write ${byteArr.join(" ")}`);
}

function main() {
  const titleOrSession = process.argv[2];
  const input = process.argv[3];

  // Resolve the session. "-" => ambient (run inside zellij, no prefix).
  let sessionPrefix = "";
  let resolved = "(ambient)";
  if (titleOrSession && titleOrSession !== "-") {
    const session = resolveSession(titleOrSession);
    if (!session) { log(`no resolvable active session from "${titleOrSession}", signalling fallback`); process.exit(3); }
    sessionPrefix = `--session ${session} `;
    resolved = session;
  }

  const text = readInput(input);
  if (!text) { log("no input text, nothing to do"); process.exit(3); }
  log(`session=${resolved} textLen=${text.length}`);

  const body = bytesOf(text);
  writeBytes(sessionPrefix, PASTE_START);
  for (let i = 0; i < body.length; i += MAX_BYTES_PER_WRITE) {
    writeBytes(sessionPrefix, body.slice(i, i + MAX_BYTES_PER_WRITE));
  }
  writeBytes(sessionPrefix, PASTE_END);
  log("done");
}

try { main(); process.exit(0); } catch (e) { log("ERROR: " + e.stack); process.exit(1); }
