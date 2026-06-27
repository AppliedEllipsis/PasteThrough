# PasteThrough

**Push a multiline paste cleanly *through* native-Windows zellij and into the
app, as one draft.**

Fix multiline paste into [pi](https://github.com/earendil-works/pi-coding-agent)
(and any TUI app) running inside **native-Windows zellij**. On native Windows,
zellij's input path mangles bracketed paste, so every newline becomes an Enter
and a multiline paste fires as many separate submissions. PasteThrough
intercepts Ctrl+V (and Ctrl+Shift+V) in Windows Terminal and re-injects the
clipboard as a single bracketed paste on zellij's uncorrupted output path
(`zellij action write`), so the whole block lands as one clean draft.

A Ctrl+V hotkey that pastes a whole multiline block as **one draft** instead of
firing each line as a separate submission.

---

## Quick start (fresh Windows install)

New to this? Follow these steps in order. Each installs one piece. You only do
this once.

### What you'll end up with

```
Windows Terminal  ->  zellij (panes/tabs)  ->  pi (AI coding agent)
                                   ^
                          PasteThrough fixes pasting into here
```

### Step 1 — Install Windows Terminal

If you're on Windows 11 it's probably already installed. If not:

- **Microsoft Store:** search "Windows Terminal" → Install.
- Or download from <https://github.com/microsoft/terminal/releases>.

Open it once to confirm it runs. Close it.

### Step 2 — Install Node.js (via nvm-windows)

Node runs the `pastethrough.js` helper. The easiest way is **nvm-windows**
(Node Version Manager), which lets you install Node without admin pain later.

1. Download the latest **nvm-setup.exe** from
   <https://github.com/coreybutler/nvm-windows/releases>.
2. Run the installer (next → next → finish). It adds `nvm` to your PATH.
3. Open a **new** Windows Terminal window (so PATH updates) and run:

```powershell
nvm install lts
nvm use lts
node --version
```

The last command should print something like `v22.x.x`. If it does, Node is
ready. (If `node --version` says "not found", close and reopen Windows Terminal
so PATH refreshes.)

> Prefer not to use nvm? Grab the official LTS installer from
> <https://nodejs.org> instead. Either way you just need `node` on your PATH.

### Step 3 — Install zellij (native Windows)

zellij is the terminal multiplexer. As of v0.44 it runs natively on Windows —
no WSL needed.

1. Download the Windows build from
   <https://github.com/zellij-org/zellij/releases> (look for the
   `x86_64-pc-windows-gnu.zip` asset).
2. Unzip it. You'll get `zellij.exe`.
3. Put `zellij.exe` somewhere permanent, e.g. `C:\Tools\zellij\`.
4. Add that folder to your **PATH**:
   - Win key → type "env" → "Edit the system environment variables" →
     "Environment variables…" → under "User variables" edit `Path` → New →
     paste `C:\Tools\zellij` → OK all the way out.
5. Open a **new** Windows Terminal and verify:

```powershell
zellij --version
```

Should print `zellij 0.44.3` (or newer).

### Step 4 — Install AutoHotkey v2

AutoHotkey provides the Ctrl+V hotkey. You need **v2** (not v1).

1. Download **AutoHotkey v2** from <https://www.autohotkey.com/> (the green
   "Download" button gives the v2 installer).
2. Run the installer. Accept the defaults.
3. Verify: AutoHotkey is now associated with `.ahk` files.

### Step 5 — Install pi (the coding agent)

pi is the AI coding agent you'll actually be pasting into. Install it with npm
(which came with Node in Step 2):

```powershell
npm install -g @earendil-works/pi-coding-agent
```

Verify:

```powershell
pi --version
```

(See the [pi docs](https://github.com/earendil-works/pi-coding-agent) if you
need to set up an API key for your model provider — that's separate from
PasteThrough.)

### Step 6 — Get PasteThrough

Pick a permanent folder, e.g. `C:\Tools\PasteThrough`, and clone the repo:

```powershell
cd C:\Tools
git clone https://github.com/AppliedEllipsis/PasteThrough.git
```

No git? You can instead download the ZIP from the repo page (green "Code"
button → "Download ZIP") and unzip it to `C:\Tools\PasteThrough`.

You should now have these two key files in that folder:

```
C:\Tools\PasteThrough\
    pastethrough.js     # the helper (Node)
    pastethrough.ahk    # the hotkey (AutoHotkey)
```

### Step 7 — Start PasteThrough

Double-click `pastethrough.ahk`. A green "H" icon appears in your system tray
(bottom-right). It's running. That's it — there's no window.

> **Make it start with Windows (optional):** Win+R → type `shell:startup` →
> Enter → drop a shortcut to `pastethrough.ahk` in that folder. Now it auto-runs
> on every login.

### Step 8 — Use it: open zellij, start pi, paste

Open Windows Terminal and start a zellij session:

```powershell
zellij
```

You're now inside zellij. Split a pane or just use the first one, and start pi:

```powershell
pi
```

Pi's input prompt appears. Now copy any **multiline** text from anywhere — a
code snippet from a browser, a few paragraphs, a stack trace.

**Paste with Ctrl+V** (the normal way):

- Without PasteThrough: each line fires as a separate message. Disaster.
- With PasteThrough running: the **whole block lands as one draft** in pi's
  input box. You can edit it, then press **Enter** once to submit.

**Paste with Ctrl+Shift+V** (the "plain text" variant):

- PasteThrough binds this too, to the same handler. It also lands as one clean
  draft — useful when an app would otherwise paste formatted/rich text.

> Either key works. The difference is just habit: use Ctrl+V normally; use
> Ctrl+Shift+V when you want to be sure formatting is stripped. Both give you
> one draft, never N submissions.

### Step 9 — Verify it's working

1. Copy this exact three-line block:

```
line one
line two
line three
```

2. In the pi pane, press **Ctrl+V**.
3. You should see all three lines sitting in pi's input box as **one draft** —
   not three submitted messages.
4. Press **Esc** to clear the draft (or Enter to submit it).

If instead you see three separate submissions, PasteThrough isn't running
(check the tray for the green "H") or zellij's session name isn't at the front
of the Windows Terminal title. See [Gotchas](#gotchas) below.

### Step 10 — Stop or remove PasteThrough

- **Pause it:** right-click the tray "H" icon → **Suspend Hotkeys**. Ctrl+V
  reverts to Windows Terminal's normal paste.
- **Quit it:** right-click the tray "H" icon → **Exit**.
- **Stop auto-start:** delete the shortcut from `shell:startup`.

---

## One-command install (PowerShell + winget)

Prefer a script does Steps 1–6 for you? PasteThrough ships `install.ps1`, a
PowerShell bootstrap that uses **winget** for everything it can and downloads
the native-Windows zellij MSI from GitHub.

It installs (skipping anything already present):

- Windows Terminal (`Microsoft.WindowsTerminal`)
- Node.js LTS (`OpenJS.NodeJS.LTS`)
- AutoHotkey v2 (`AutoHotkey.AutoHotkey`)
- Git (`Git.Git`)
- zellij (native-Windows MSI, from the latest GitHub release)
- pi (`npm install -g @earendil-works/pi-coding-agent`)

…then clones PasteThrough to `C:\Tools\PasteThrough`.

Run it (right-click `install.ps1` → **Run with PowerShell**, or in a
PowerShell window):

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Override the install folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -InstallDir D:\Code\PasteThrough
```

> **winget missing?** It's called "App Installer" in the Microsoft Store
> (preinstalled on most Windows 11 boxes). Or grab it from
> <https://github.com/microsoft/winget-cli/releases>. After installing it,
> re-run `install.ps1`.

After it finishes, open a **new** Windows Terminal (so PATH updates),
double-click `C:\Tools\PasteThrough\pastethrough.ahk`, and you're at Step 7
of the Quick Start.

---

## Why the `.ahk` source (recommended) vs a compiled `.exe`

PasteThrough is distributed as the **plain `.ahk` script**, not a compiled
`.exe`. That's deliberate. Here's why, and when the `.exe` is still worth it.

### Why the source is recommended

1. **You can read it.** `pastethrough.ahk` is plain text. A tool that
   intercepts your keyboard and reads your clipboard should be auditable —
   you can open it in any editor and see exactly what it does before running
   it. A compiled `.exe` is opaque binary.
2. **No SmartScreen / Defender warnings.** Windows flags *unsigned* exes
   downloaded from the internet with a scary "protected your PC" dialog, and
   even many signed ones from unknown publishers. The `.ahk` runs through the
   **already-trusted** AutoHotkey interpreter you installed in Step 4 — no
   scary prompts, no reputation buildup needed.
3. **Easy to edit and reload.** Want to change Ctrl+V to Alt+V, or add a
   binding? Open the `.ahk` in a text editor, save, right-click the tray icon
   → **Reload Script**. Done. An `.exe` requires recompiling.
4. **Lighter.** The `.ahk` is ~4 KB and reuses your installed AutoHotkey. The
   compiled `.exe` is ~1.3 MB because it bundles the whole interpreter.
5. **It changes nothing about the other deps.** The `.exe` only replaces
   AutoHotkey itself — you **still need Node + zellij installed**, because the
   `.exe` shells out to `node pastethrough.js` and `zellij action write`. So
   the `.exe` is not a "single self-contained double-click app"; it just saves
   you the one AutoHotkey install.

### When the `.exe` is still worth it

- You can't or won't install AutoHotkey (e.g. a locked-down work machine where
  you can drop an `.exe` in a folder but not install software).
- You want a single double-clickable file in your Startup folder with zero
  other setup on the hotkey side.

In those cases, build the `.exe` from the source (next section) so it's
trustworthy-by-construction — you compile it yourself from the readable
script, rather than trusting a stranger's binary.

---

## Build the `.exe` yourself (optional)

If you want a compiled `pastethrough.exe`, build it from the source so you know
exactly what's inside. You need AutoHotkey v2 installed (Step 4 of the Quick
Start, or `install.ps1`).

**From cmd.exe / PowerShell** (recommended):

```cmd
cd C:\Tools\PasteThrough
build.cmd
```

`build.cmd` calls Ahk2Exe with the correct v2 base and writes
`pastethrough.exe` next to the script. Double-click that `.exe` instead of the
`.ahk`; behavior is identical.

**From Git Bash** (the `/in` `/out` `/base` flags get mangled by MSYS
path-translation, so prefix with the env vars):

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" ./build.cmd
```

**Manual one-liner** (any shell, after fixing quoting for that shell):

```cmd
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in pastethrough.ahk /out pastethrough.exe /base "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
```

The repo's `.gitignore` excludes `*.exe`, so your build artifact stays out of
version control. Ship prebuilt exes as **GitHub release assets** instead —
attach `pastethrough.exe` to a release on the Releases page.

---

## The projects involved

This tool sits at the intersection of a few pieces. Here's what each one is:

- **[zellij](https://github.com/zellij-org/zellij)** — A terminal workspace and
  multiplexer (think tmux, but with batteries included: layouts, panes, tabs, a
  plugin system, and a floating UI). As of v0.44 it runs natively on Windows. The
  paste bug this tool works around lives in zellij's native-Windows input path.

- **[pi (pi coding agent)](https://github.com/earendil-works/pi-coding-agent)** —
  A terminal-based AI coding agent. It's a TUI app that submits its input box on
  Enter, which is exactly why the mangled-newline paste bug hits it so hard: a
  10-line paste becomes 10 submitted messages. Any Enter-submitting TUI app has
  the same problem; pi is just the motivating case.

- **[AutoHotkey v2](https://www.autohotkey.com/)** — A Windows automation and
  hotkey scripting language. Here it owns the keyboard hook: it intercepts Ctrl+V
  *only* when Windows Terminal is focused and reroutes the paste, falling back to
  a normal paste everywhere else.

- **[Windows Terminal](https://github.com/microsoft/terminal)** — Microsoft's
  terminal emulator (window class `CASCADIA_HOSTING_WINDOW_CLASS`). It's the host
  the hotkey is scoped to, and its window title carries the zellij session name
  used for targeting.

- **[Node.js](https://nodejs.org/)** — Runtime for the one-shot `pastethrough.js`
  helper that resolves the session and writes the bracketed paste.

---

## The problem, exactly as it shows up

You're running the pi coding agent inside zellij, inside Windows Terminal, on
native Windows. You copy a multiline block — a code snippet, a stack trace, a
few paragraphs — and try to paste it into pi's input box.

- **Ctrl+V** does nothing. The paste is swallowed.
- **Ctrl+Shift+V** pastes, but pi sees each line as a **separate submission**.
  A 10-line paste fires 10 messages. The agent starts answering line one while
  you're still watching the rest of your paste detonate.

The tell that this is a zellij problem and not a pi problem: **run pi *without*
zellij** — straight in Windows Terminal — and paste works fine. You can even see
the bracketed-paste markers (`[200~ … [201~`, the `[]` blocks) behave correctly,
landing the whole thing as one draft. Put zellij back in the middle and it
breaks.

### Why

This is an upstream zellij bug on native Windows. zellij has two stdin paths,
and the **terminal → zellij input path** mangles bracketed paste: every newline
in the incoming paste is delivered to the program *inside* zellij as a separate
**Enter** keypress. A plain shell mostly shrugs this off. A TUI app like pi,
which submits on Enter, treats every line as its own message.

Tracked upstream (still open as of zellij 0.44.3):

- [#4885 — [Windows] Multi-line paste broken — newlines treated as Enter](https://github.com/zellij-org/zellij/issues/4885)
- [#3865 — copy/paste multiple lines broken from Windows Terminal](https://github.com/zellij-org/zellij/issues/3865)
- related: [crossterm #962 — bracketed paste interference on Windows](https://github.com/crossterm-rs/crossterm/issues/962)

---

## How I got here (the discovery path)

This is the part most write-ups skip, so here's the actual journey — it explains
why the final design looks the way it does.

**1. Confirming it wasn't pi.** First thing was to rule pi out. Pasting into pi
running directly in Windows Terminal works perfectly — the `[]` bracketed-paste
blocks come through and the text lands as one draft. So the breakage lives in
the zellij layer, not the app.

**2. The fresh-editor experiment.** Next I opened a fresh CLI editor pane (a
plain `$EDITOR` buffer) inside the same Windows Terminal and tried pasting into
*that*. Ctrl+V **and** Ctrl+Shift+V both pasted into the editor cleanly. I could
save and exit with the multiline text intact. That was the key signal: the bytes
*can* reach a program inside the terminal correctly — it's specifically the
interactive TUI-input path through zellij that rewrites newlines into Enters.

**3. Fighting Windows Terminal settings.** I spent a while playing with Windows
Terminal's key bindings — remapping paste, experimenting with "creative locks"
on Ctrl and Ctrl+Shift combos, changing some WT defaults to try to force a clean
paste. You can move the behavior around this way, but you can't fix it: WT is
faithfully sending the bytes; zellij's input path is what reinterprets them.
Re-binding keys in the terminal can't undo a transformation that happens one
layer deeper.

**4. "What if a plugin did it?"** Since the bug is on the *input* path, the
obvious idea was a zellij plugin that injects the paste from the *inside*, via
zellij's own API, bypassing the broken path entirely. While digging into how a
plugin would write into a pane, I found the mechanism that makes the plugin
unnecessary: **`zellij action write`** (and its sibling `zellij action paste`).
These write bytes on the **zellij → PTY output path**, which is *not* affected by
the input-path bug. A CLI call can do exactly what the plugin would do, with no
WASM toolchain. That's the whole fix.

---

## The fix

`zellij action write` injects bytes on the zellij → PTY **output** path. So
instead of letting the paste flow through the broken input path, this tool:

1. Intercepts Ctrl+V / Ctrl+Shift+V (via AutoHotkey, scoped to Windows Terminal
   only).
2. Reads the clipboard.
3. Writes it to the focused pane wrapped in bracketed-paste markers
   (`ESC[200~` … `ESC[201~`) using `zellij action write`.

The app inside the pane sees one clean bracketed paste — one multiline draft,
nothing auto-submitted.

```
You press Ctrl+V (or Ctrl+Shift+V) in Windows Terminal (pi pane focused)
   -> AHK hotkey fires synchronously; pane stays focused, nothing opens
   -> clipboard written to a UTF-8 temp file
   -> one hidden `node pastethrough.js` call:
        * reads the WT window title -> extracts + validates the zellij session
        * writes ESC[200~ <text> ESC[201~ to that session's focused pane
   -> node exits, temp file deleted
   -> pi shows ONE multiline draft
```

No background process. No polling. One short-lived `node` process per keypress.

---

## How it works, in detail

### Finding the right pane

The naive worry: with multiple sessions, multiple tabs, and multiple panes, how
does a bare `zellij action write` know where to land?

The answer is **timing, not tracking**. AutoHotkey's hotkey fires
*synchronously while the pane you pressed Ctrl+V in is still focused*. Nothing
opens, nothing steals focus. So at the instant `zellij action write` runs — with
no `--pane-id` — zellij's notion of "the focused pane" is still exactly the pane
you're looking at. The write lands there. We never have to discover or track the
pane, because we ride the keypress while the focus is already correct.

### Targeting the right session (multi-window safety)

Pane focus handles *which pane within a session*. But you can have several zellij
sessions living in different Windows Terminal tabs. Firing bytes blindly could
hit a session in a tab you can't even see. So session targeting is explicit and
strict:

1. AHK passes the active window title to `pastethrough.js`. Windows Terminal's
   title carries the session name (e.g. `my-session | pi`).
2. The script takes the candidate before `" | "`.
3. It validates that candidate against the live `zellij list-sessions` active
   set.
4. It writes **only** if it resolves to a real, active session.

If it doesn't resolve, the script does nothing and exits with code 3 — and AHK
falls back to a normal `Shift+Insert` paste. It will **never guess**. Worst case
you get an ordinary paste; you never get bytes fired into the wrong session.

### Why AutoHotkey — and why this can't just be a standalone .exe or script

This is the question that trips people up: if `pastethrough.js` does the actual
work, why is AutoHotkey in the picture at all? Why not ship a single `.exe` or a
script you run?

Because something has to satisfy three constraints *at the moment you press
Ctrl+V*, and only a window-scoped global hotkey can:

1. **Intercept Ctrl+V globally but conditionally.** The paste has to be caught
   and rerouted *only* when Windows Terminal is the focused window
   (`ahk_class CASCADIA_HOSTING_WINDOW_CLASS`), and behave 100% normally in every
   other app. A standalone script you launch can't hook the system keyboard and
   make that per-window decision; AHK's `#HotIf WinActive(...)` is exactly that
   mechanism.

2. **Run *while the pane is still focused*.** The entire pane-targeting trick
   depends on the write happening during the keypress, before focus moves. A
   double-clicked `.exe`, a scheduled task, or a watcher running out-of-band has
   already missed that window — focus is wherever it is, not guaranteed to be the
   pi pane. AHK fires inline with the keypress, which is what makes a bare,
   untargeted write safe.

3. **Fall back cleanly.** AHK runs the helper with `RunWait`, reads its exit
   code, and on anything but success sends a normal `Shift+Insert`. So Ctrl+V is
   never silently swallowed — in a non-zellij tab it just pastes normally.

In other words, the helper *can't write itself as a self-launching exe/script*
because the value isn't in the writing of bytes — `zellij action write` already
does that. The value is in **catching the right keypress, in the right window, at
the right instant, with a safe fallback**. That's a keyboard-hook responsibility,
and AutoHotkey is the lightest tool that owns it. The node helper stays a dumb,
one-shot CLI; AHK is the trigger that gives it correct context for free.

### Why not a background focus-watcher

An earlier design polled `zellij action list-clients` to track the focused pane
continuously. On native Windows, every poll spawns a `cmd.exe` → `zellij.exe`
that flashes a console window and steals focus. A persistent poller is unusable
here. The synchronous-hotkey approach removes the need for tracking entirely.

### Why not a zellij plugin (WASM)

The plugin idea is what led to the fix, but the plugin itself is unnecessary. A
plugin writing via the zellij API works, but requires a Rust/WASM toolchain and a
build step. A CLI-only approach using `zellij action write` needs no compilation
and is just as reliable, because it uses the same uncorrupted output path the
plugin would.

---

## Re-evaluation: is there anything better?

Honest pass over the design, including things worth changing.

### `zellij action paste` could replace the manual byte-wrapping

zellij 0.44.x ships a dedicated subcommand:

```
zellij action paste <CHARS>      # "Paste text to the terminal (using bracketed paste mode)"
```

This does the `ESC[200~ … ESC[201~` wrapping *for you*, on the same output path,
so in principle it could replace the hand-rolled marker bytes in
`pastethrough.js`. That would simplify the helper to roughly:

```js
sh(`${ZELLIJ} ${sessionPrefix}action paste ${shellQuote(text)}`);
```

**Why the current code still uses `action write` with manual markers:**

- **Chunking control.** Windows caps a command line near 32 KB. `action write`
  takes a byte list we can split across multiple calls while the brackets wrap
  the *whole* stream (start marker first, end marker last, body chunked between).
  `action paste` takes the text as a single `<CHARS>` argument with no chunking,
  so a large paste can blow the command-line limit.
- **Quoting.** Passing arbitrary clipboard text as one shell arg means robust
  cross-shell quoting/escaping of quotes, backticks, `%`, newlines, etc. The
  byte-list approach sidesteps shell quoting entirely — every byte is a plain
  integer argument.
- **Not verified on this build.** I have not confirmed `action paste`'s newline
  behavior against pi on 0.44.3 (no live session was available while writing
  this). It *should* be on the safe output path, but I'm not going to claim a
  fix I didn't test.

**Recommendation:** keep `action write` as the default for large/awkward pastes;
optionally try `action paste` for short single-shot pastes where quoting is
trivial. If a future zellij makes `action paste` accept stdin (avoiding the
arg-length limit), it becomes the clearly better primitive and the manual markers
can go.

### Other options considered

- **Upstream fix.** The real cure is zellij fixing the input path
  ([#4885](https://github.com/zellij-org/zellij/issues/4885)). When that lands,
  this whole tool becomes unnecessary. Until then, this is a userspace workaround.
- **Windows Terminal key bindings.** Already tried (see the discovery path).
  Re-binding paste in WT can't undo a transformation happening a layer deeper in
  zellij. Dead end.
- **Run pi outside zellij.** Works, but you lose the multiplexer. Not a fix, a
  surrender.
- **WSL / SSH instead of native Windows zellij.** Sidesteps the native-Windows
  input path, but changes your whole environment. Out of scope for "I want native
  Windows zellij to work."

---

## Requirements

- **Windows** with **Windows Terminal** (class `CASCADIA_HOSTING_WINDOW_CLASS`).
- **native-Windows zellij** on `PATH` (tested against v0.44.3).
- **Node.js** on `PATH` (any recent LTS).
- **AutoHotkey v2** (for the hotkey). The core script also works standalone
  without AHK — see "Use without AutoHotkey".

## Install

1. Put `pastethrough.js` and `pastethrough.ahk` in the same folder (any folder).
2. Double-click `pastethrough.ahk` to start it (requires AutoHotkey v2).
   - `SCRIPT` auto-resolves to `pastethrough.js` next to the `.ahk`.
   - `NODE` auto-resolves from `PATH`, with fallbacks for common install dirs.
3. Focus a pi pane in Windows Terminal, copy some multiline text, press Ctrl+V
   (or Ctrl+Shift+V). The whole block should land as one draft.

### Auto-start on login (optional)

Drop a shortcut to `pastethrough.ahk` into your Startup folder:

```
Win+R  ->  shell:startup  ->  paste a shortcut to pastethrough.ahk
```

---

## Key bindings

PasteThrough binds two keys, both scoped to Windows Terminal only:

| Key            | Action                                                                 |
|----------------|------------------------------------------------------------------------|
| `Ctrl+V`       | PasteThrough — inject clipboard as one bracketed paste (primary).      |
| `Ctrl+Shift+V` | PasteThrough — same handler (alias; overrides WT "paste as plaintext"). |

Both call the same handler, so they behave identically. Binding Ctrl+Shift+V
too means the "paste but splits into many submissions" behavior you'd normally
get from WT's Ctrl+Shift+V is replaced with a clean one-draft paste inside
Windows Terminal — and left untouched in every other app.

If you want to change the bindings, edit the hotkey labels near the bottom of
`pastethrough.ahk`:

```ahk
#HotIf WinActive("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")
^v::
^+v::
{
    DoPaste()
}
```

AHK key notation: `^` = Ctrl, `+` = Shift, `!` = Alt, `#` = Win. Add or remove
labels on the lines above `{` to change which keys trigger a paste. After
editing, right-click the AutoHotkey tray icon → **Reload Script**.

---

## Manage it (kill / restart)

The hotkey is just one AutoHotkey process. It only acts when you press Ctrl+V or
Ctrl+Shift+V in Windows Terminal — it does **not** poll or run anything in the
background.

**Check if it's running** (PowerShell):

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -like '*pastethrough.ahk*' } |
  Select-Object ProcessId, Name
```

**Kill it** (PowerShell):

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -like '*pastethrough.ahk*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

**Restart it:** kill as above, then double-click `pastethrough.ahk` again (or run
`AutoHotkey64.exe pastethrough.ahk`). After editing the `.ahk`, right-click the
tray icon -> Reload Script, or kill and relaunch.

**Disable temporarily:** right-click the AutoHotkey tray icon -> Suspend
Hotkeys. Ctrl+V reverts to Windows Terminal's normal paste.

---

## Use without AutoHotkey

`pastethrough.js` is a standalone CLI. From inside a zellij pane you can pipe or
pass text directly:

```bash
# Target the ambient session (run from inside zellij), literal text:
node pastethrough.js - "line one
line two
line three"

# Target a named session explicitly via a title-like string:
node pastethrough.js "my-session | pi" /path/to/text.txt
```

`-` means "ambient session" (no `--session` flag, uses the zellij env of the
calling pane). A second arg that is an existing file path is read as the text;
otherwise it's treated as literal text.

## Configuration

Environment variables (all optional):

- `PASTETHROUGH_LOG=0` — disable the debug log file (written next to the script
  by default).
- `ZELLIJ_BIN` — path to the zellij binary if it isn't on `PATH`.

In `pastethrough.ahk`, you can hard-set `NODE` or `SCRIPT` at the top if
auto-resolution doesn't find them.

---

## Gotchas

- **Multiple sessions in multiple tabs.** Targeting is strict: the WT tab title
  must start with the active session name (`session | …`). If you've renamed the
  tab so the title no longer leads with the session name, resolution fails and
  you get a normal paste instead. Keep the session name at the front of the
  title.
- **Wrong pane gets the paste.** The write targets the *focused* pane of the
  resolved session. Whatever pane is focused when you press Ctrl+V is the target
  — make sure it's the pi pane.
- **Paste works in shell but pi still splits lines.** Confirm pi honors bracketed
  paste: paste a block and check it lands as a draft. If it still submits per
  newline even via the output path, the app isn't honoring `ESC[200~`.
- **`node` not found.** Set `NODE` explicitly at the top of `pastethrough.ahk`.
- **Nothing happens / normal paste instead.** The session didn't resolve. Check
  the log next to `pastethrough.js` and confirm the tab title.
- **Console flashes.** Shouldn't happen — node is launched hidden
  (`RunWait(..., "Hide")`, `windowsHide: true`). If you see flashes, something is
  launching zellij outside this tool (e.g. an old poller).
- **Huge pastes.** Body is chunked under the Windows command-line limit
  (~1.8 KB per `write`, brackets wrap the whole stream). Multi-megabyte pastes
  mean many `write` calls and will be slower.

---

## Files

| File              | Purpose                                                                        |
|-------------------|--------------------------------------------------------------------------------|
| `pastethrough.js` | One-shot CLI: resolve session, write bracketed paste to focused pane.         |
| `pastethrough.ahk`| AutoHotkey v2 hotkey: intercept Ctrl+V/Ctrl+Shift+V in Windows Terminal, call the CLI, fall back to normal paste. |
| `install.ps1`     | One-command PowerShell bootstrap (winget + zellij MSI) for a fresh Windows box.|
| `build.cmd`       | Compile `pastethrough.ahk` → `pastethrough.exe` via Ahk2Exe (optional).        |
| `CHANGELOG.md`    | Release history.                                                               |
| `LICENSE`         | GLWTS Public License.                                                          |

---

## License

GLWTS (Good Luck With That Shit) Public License — See [LICENSE](LICENSE) for
details.

You can do whatever the fuck you want with this software at your OWN RISK. The
author has no fucking clue what the code does, and you can never track them down
to blame them.

---

## Co-vibe coded with AI

Built with human creativity enhanced by artificial intelligence.
