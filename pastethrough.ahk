#Requires AutoHotkey v2.0
; pastethrough.ahk
; PasteThrough — fixes multiline paste into the pi coding agent (and any
; zellij pane) on native-Windows zellij.
;
; THE BUG: native-Windows zellij mangles bracketed paste on the
; terminal->zellij INPUT path. Every newline in a paste becomes an Enter, so a
; TUI app like pi submits each line as a separate message ("multiple queues").
;
; THE FIX: this hotkey writes the clipboard to the focused pane on the
; zellij->PTY path (`zellij action write`), wrapping it in bracketed-paste
; markers (ESC[200~ ... ESC[201~) so the app sees ONE multiline draft. That
; output path is NOT affected by the input-path bug.
;
; It fires synchronously while the pane is still focused, so a bare write (no
; --pane-id) lands in exactly the pane you are in. One short-lived node process
; per keypress -- no background process, no polling, nothing that can runaway.
;
; KEY BINDINGS:
;   Ctrl+V        -> PasteThrough (primary)
;   Ctrl+Shift+V  -> PasteThrough (alias; WT's "paste as plain text" is replaced
;                   only inside WT, and only to guarantee one-draft paste)
; Both are scoped to Windows Terminal only (ahk_class
; CASCADIA_HOSTING_WINDOW_CLASS), so they behave normally in every other app.
;
; ---------------------------------------------------------------------------
; CONFIG: point SCRIPT at pastethrough.js. By default we assume it sits next to
; this .ahk file. NODE auto-resolves from PATH; override if node is not on the
; system PATH that AutoHotkey sees.
; ---------------------------------------------------------------------------

SCRIPT := A_ScriptDir "\pastethrough.js"

; Resolve node.exe. Try `where node.exe` first (PATH lookup); if that yields
; nothing, fall back to common install locations. Set NODE manually here if
; your node lives somewhere unusual.
NODE := ResolveNode()

ResolveNode() {
    ; 1) PATH lookup via `where`, capturing stdout to a temp file.
    tmp := A_Temp "\pastethrough-where-" A_TickCount ".txt"
    try {
        RunWait(A_ComSpec ' /c where node.exe > "' tmp '" 2>nul', , "Hide")
        if FileExist(tmp) {
            firstLine := ""
            for line in StrSplit(FileRead(tmp), "`n", "`r") {
                if (Trim(line) != "") {
                    firstLine := Trim(line)
                    break
                }
            }
            try FileDelete(tmp)
            if (firstLine != "" && FileExist(firstLine))
                return firstLine
        }
    } catch {
        try FileDelete(tmp)
    }
    ; 2) Common install paths.
    for candidate in [
        EnvGet("ProgramFiles") "\nodejs\node.exe",
        "C:\Program Files\nodejs\node.exe",
        "C:\nvm4w\nodejs\node.exe"
    ] {
        if FileExist(candidate)
            return candidate
    }
    ; 3) Last resort: bare name, rely on PATH at launch time.
    return "node.exe"
}

#HotIf WinActive("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")
^v::
^+v::
{
    DoPaste()
}

DoPaste() {
    global NODE, SCRIPT
    text := A_Clipboard
    if (text = "")
        return

    ; Window title carries the zellij session name (e.g. "session | pi").
    title := WinGetTitle("A")

    ; Write clipboard to a UTF-8 (no BOM) temp file; node reads & deletes it.
    tmp := A_Temp "\pastethrough-" A_TickCount ".txt"
    try FileDelete(tmp)
    FileAppend(text, tmp, "UTF-8-RAW")

    ; Launch node hidden and WAIT for its exit code. node extracts + validates
    ; the session from `title`, then writes the bracketed-paste block to the
    ; focused pane of that session.
    ;   exit 0 = handled (injected the bracketed paste)
    ;   exit 3 = could not resolve a zellij session for this tab
    ;   other  = error
    ; On anything but 0 we fall back to a normal paste (Shift+Insert, which
    ; Windows Terminal accepts) so Ctrl+V is never silently swallowed -- e.g.
    ; in a WT tab that is not a zellij session.
    exitCode := RunWait('"' NODE '" "' SCRIPT '" "' title '" "' tmp '"', , "Hide")
    if (exitCode != 0)
        SendInput("+{Insert}")
}
#HotIf
