# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-27

First public release.

### Added
- `pastethrough.js` — one-shot Node CLI that resolves the active zellij session
  from the Windows Terminal window title, validates it against
  `zellij list-sessions`, and injects the clipboard as a single bracketed paste
  (`ESC[200~ … ESC[201~`) on the zellij → PTY output path via
  `zellij action write`. Body is chunked under the Windows command-line limit;
  the brackets wrap the whole stream.
- `pastethrough.ahk` — AutoHotkey v2 hotkey scoped to Windows Terminal
  (`CASCADIA_HOSTING_WINDOW_CLASS`) that intercepts **Ctrl+V** and
  **Ctrl+Shift+V**, writes the clipboard to a UTF-8 temp file, runs the helper
  hidden with `RunWait`, and falls back to a normal `Shift+Insert` paste on any
  non-success exit code (so the keypress is never silently swallowed).
- Strict session targeting: the WT title candidate before `" | "` must be a live
  active session, otherwise the tool does nothing and AHK falls back to a normal
  paste. Never guesses; never fires bytes into an unseen session/tab.
- Auto-resolution of `node.exe` (PATH via `where`, then common install dirs) and
  of `pastethrough.js` (next to the `.ahk`).
- Debug log written next to the script (`pastethrough.log`); disable with
  `PASTETHROUGH_LOG=0`.
- Standalone CLI usage without AutoHotkey (pass `-` for the ambient session, or
  a title-like string for a named session; second arg is a file path or literal
  text).
- `README.md` documenting the problem, the discovery path, the mechanism, the
  design rationale (why AHK and not a plugin/exe/watcher), a re-evaluation
  against `zellij action paste`, key bindings, troubleshooting, and gotchas.

### Notes
- Workaround for upstream zellij native-Windows paste bug
  ([#4885](https://github.com/zellij-org/zellij/issues/4885),
  [#3865](https://github.com/zellij-org/zellij/issues/3865)). When zellij fixes
  the input path, this tool becomes unnecessary.
- Tested against zellij 0.44.3 on Windows Terminal.
