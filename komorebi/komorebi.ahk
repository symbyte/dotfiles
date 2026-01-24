#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook True
InstallKeybdHook

; Komorebi keybindings matching aerospace config
; Modifiers: # = Win, ! = Alt, + = Shift, ^ = Ctrl

; Helper function to run komorebic commands
Komorebic(cmd) {
    Run("komorebic.exe " cmd,, "Hide")
}

; Helper function to switch workspace and ensure focus
SwitchWorkspace(name) {
    Run("komorebic.exe focus-named-workspace " name,, "Hide")
    Sleep(50)
    Run("komorebic.exe cycle-focus next",, "Hide")
}

; ============================================
; Audio Focus Toggle
; ============================================
global AudioFocusedPID := 0
global AudioSavedMuteStates := Map()

ToggleAudioFocus() {
    global AudioFocusedPID, AudioSavedMuteStates

    currentPID := WinGetPID("A")

    if (AudioFocusedPID = 0) {
        ApplyAudioFocus(currentPID)
    } else if (AudioFocusedPID = currentPID) {
        RestoreAudio()
    } else {
        RestoreAudio()
        ApplyAudioFocus(currentPID)
    }
}

ApplyAudioFocus(targetPID) {
    global AudioFocusedPID, AudioSavedMuteStates

    windowTitle := WinGetTitle("A")
    AudioSavedMuteStates := Map()

    sessions := GetAudioSessions()

    for session in sessions {
        if (session.pid = targetPID)
            continue

        try {
            currentMute := GetSessionMute(session.volume)
            AudioSavedMuteStates[session.pid] := currentMute

            if (!currentMute)
                SetSessionMute(session.volume, true)
        }
    }

    AudioFocusedPID := targetPID
    TrayTip("Audio Focused", windowTitle, 1)
}

RestoreAudio() {
    global AudioFocusedPID, AudioSavedMuteStates

    sessions := GetAudioSessions()

    for session in sessions {
        if (AudioSavedMuteStates.Has(session.pid)) {
            try {
                wasMuted := AudioSavedMuteStates[session.pid]
                SetSessionMute(session.volume, wasMuted)
            }
        }
    }

    AudioSavedMuteStates := Map()
    AudioFocusedPID := 0
    TrayTip("Audio Restored", "All audio restored", 1)
}

GetAudioSessions() {
    sessions := []

    IMMDeviceEnumerator := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")

    ComCall(4, IMMDeviceEnumerator, "uint", 0, "uint", 1, "ptr*", &device := 0)
    IMMDevice := ComValue(13, device)

    GUID_IAudioSessionManager2 := Buffer(16)
    DllCall("ole32\CLSIDFromString", "str", "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}", "ptr", GUID_IAudioSessionManager2)
    ComCall(3, IMMDevice, "ptr", GUID_IAudioSessionManager2, "uint", 23, "ptr", 0, "ptr*", &manager := 0)
    IAudioSessionManager2 := ComValue(13, manager)

    ComCall(5, IAudioSessionManager2, "ptr*", &enumerator := 0)
    IAudioSessionEnumerator := ComValue(13, enumerator)

    ComCall(3, IAudioSessionEnumerator, "int*", &count := 0)

    Loop count {
        try {
            ComCall(4, IAudioSessionEnumerator, "int", A_Index - 1, "ptr*", &sessionControl := 0)
            IAudioSessionControl := ComValue(13, sessionControl)

            GUID_IAudioSessionControl2 := Buffer(16)
            DllCall("ole32\CLSIDFromString", "str", "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}", "ptr", GUID_IAudioSessionControl2)
            ComCall(0, IAudioSessionControl, "ptr", GUID_IAudioSessionControl2, "ptr*", &sessionControl2 := 0)
            IAudioSessionControl2 := ComValue(13, sessionControl2)

            ComCall(14, IAudioSessionControl2, "uint*", &pid := 0)

            if (pid = 0)
                continue

            GUID_ISimpleAudioVolume := Buffer(16)
            DllCall("ole32\CLSIDFromString", "str", "{87CE5498-68D6-44E5-9215-6DA47EF883D8}", "ptr", GUID_ISimpleAudioVolume)
            ComCall(0, IAudioSessionControl, "ptr", GUID_ISimpleAudioVolume, "ptr*", &volumePtr := 0)

            sessions.Push({pid: pid, volume: volumePtr})
        }
    }

    return sessions
}

GetSessionMute(volumePtr) {
    ComCall(4, volumePtr, "int*", &mute := 0)
    return mute
}

SetSessionMute(volumePtr, mute) {
    ComCall(5, volumePtr, "int", mute, "ptr", 0)
}

; ============================================
; Block Win key alone (Start menu)
; Use ~LWin to allow it to pass through for combos
; ============================================
~LWin Up::
{
    ; Block Start menu by sending a harmless key
    if (A_PriorKey = "LWin")
        Send("{Blind}{vkE8}")
}
~RWin Up::
{
    if (A_PriorKey = "RWin")
        Send("{Blind}{vkE8}")
}

; ============================================
; Block ALL Win+key combinations
; Letters
; ============================================
#a::ToggleAudioFocus()  ; EXCEPTION: Audio focus toggle
#b::return
#c::return
#d::return
#e::return
#f::return
#g::return
#h::return
#i::return
#j::return
#k::return
; #l - EXCEPTION: kept for Lock screen
#m::return
#n::return
#o::return
#p::return
#q::return
#r::return
#s::return
#t::return
#u::return
#v::return
#w::Komorebic("close")  ; EXCEPTION: Close focused window
#x::return
#y::return
#z::return

; ============================================
; Block Win+numbers
; ============================================
#0::return
#1::return
#2::return
#3::return
#4::return
#5::return
#6::return
#7::return
#8::return
#9::return

; ============================================
; Block Win+function keys
; ============================================
#F1::return
#F2::return
#F3::return
#F4::return
#F5::return
#F6::return
#F7::return
#F8::return
#F9::return
#F10::return
#F11::return
#F12::return

; ============================================
; Block Win+symbols and special keys
; ============================================
#Tab::return
#Enter::return
#Escape::return
#Backspace::return
#Delete::return
#Insert::return
#Home::return
#End::return
#PgUp::return
#PgDn::return
#Up::return
#Down::return
#Left::return
#Right::return
#PrintScreen::return
#Pause::return
#ScrollLock::return
#CapsLock::return
#NumLock::return
#,::return
#.::return
#/::return
#;::return
#'::return
#[::return
#]::return
#\::return
#`::return
#-::return
#=::return
; #Space - EXCEPTION: kept for input language switching

; ============================================
; Block Win+Shift combinations
; ============================================
#+a::return
#+b::return
#+c::return
#+d::return
#+e::return
#+f::return
#+g::return
#+h::return
#+i::return
#+j::return
#+k::return
#+l::return
#+m::return
#+n::return
#+o::return
#+p::return
#+q::return
#+r::return
#+s::return
#+t::return
#+u::return
#+v::return
#+w::return
#+x::return
#+y::return
#+z::return
#+0::return
#+1::return
#+2::return
#+3::return
#+4::return
#+5::return
#+6::return
#+7::return
#+8::return
#+9::return
#+Left::return
#+Right::return
#+Up::return
#+Down::return
#+Tab::return
#+Enter::return

; ============================================
; Block Win+Ctrl combinations
; ============================================
#^a::return
#^b::return
#^c::return
#^d::return
#^e::return
#^f::return
#^g::return
#^h::return
#^i::return
#^j::return
#^k::return
#^l::return
#^m::return
#^n::return
#^o::return
#^p::return
#^q::return
#^r::return
#^s::return
#^t::return
#^u::return
#^v::return
#^w::return
#^x::return
#^y::return
#^z::return
#^0::return
#^1::return
#^2::return
#^3::return
#^4::return
#^5::return
#^6::return
#^7::return
#^8::return
#^9::return
#^Left::return
#^Right::return
#^Up::return
#^Down::return
#^Tab::return

; ============================================
; Block Win+Alt combinations
; ============================================
#!a::return
#!b::return
#!c::return
#!d::return
#!e::return
#!f::return
#!g::return
#!h::return
#!i::return
#!j::return
#!k::return
#!l::return
#!m::return
#!n::return
#!o::return
#!p::return
#!q::return
#!r::return
#!s::return
#!t::return
#!u::return
#!v::return
#!w::return
#!x::return
#!y::return
#!z::return
#!0::return
#!1::return
#!2::return
#!3::return
#!4::return
#!5::return
#!6::return
#!7::return
#!8::return
#!9::return
#!Tab::return

; ============================================
; Block Win+Shift+Ctrl combinations
; ============================================
#+^a::return
#+^b::return
#+^c::return
#+^d::return
#+^e::return
#+^f::return
#+^g::return
#+^h::return
#+^i::return
#+^j::return
#+^k::return
#+^l::return
#+^m::return
#+^n::return
#+^o::return
#+^p::return
#+^q::return
#+^r::return
#+^s::return
#+^t::return
#+^u::return
#+^v::return
#+^w::return
#+^x::return
#+^y::return
#+^z::return
#+^0::return
#+^1::return
#+^2::return
#+^3::return
#+^4::return
#+^5::return
#+^6::return
#+^7::return
#+^8::return
#+^9::return

; ============================================
; Block Win+Shift+Alt combinations
; ============================================
#+!a::return
#+!b::return
#+!c::return
#+!d::return
#+!e::return
#+!f::return
#+!g::return
#+!h::return
#+!i::return
#+!j::return
#+!k::return
#+!l::return
#+!m::return
#+!n::return
#+!o::return
#+!p::return
#+!q::return
#+!r::return
#+!s::return
#+!t::return
#+!u::return
#+!v::return
#+!w::return
#+!x::return
#+!y::return
#+!z::return

; ============================================
; Block Win+Ctrl+Alt combinations
; ============================================
#^!a::return
#^!b::return
#^!c::return
#^!d::return
#^!e::return
#^!f::return
#^!g::return
#^!h::return
#^!i::return
#^!j::return
#^!k::return
#^!l::return
#^!m::return
#^!n::return
#^!o::return
#^!p::return
#^!q::return
#^!r::return
#^!s::return
#^!t::return
#^!u::return
#^!v::return
#^!w::return
#^!x::return
#^!y::return
#^!z::return

; ============================================
; Reload configs
; ============================================
!o::Reload  ; Alt+O = Reload this AHK script
!+o::Komorebic("reload-configuration")  ; Alt+Shift+O = Reload komorebi

; ============================================
; Layout toggles
; ============================================
!+^#vkBF::Komorebic("cycle-layout next")  ; vkBF = /
!+^#,::Komorebic("toggle-monocle")

; ============================================
; Focus windows (Alt+Shift+Ctrl+Win+HJKL)
; ============================================
!+^#h::Komorebic("focus left")
!+^#j::Komorebic("focus down")
!+^#k::Komorebic("focus up")
!+^#l::Komorebic("focus right")

; ============================================
; Move windows (Alt+Shift+Ctrl+HJKL)
; ============================================
!+^h::Komorebic("move left")
!+^j::Komorebic("move down")
!+^k::Komorebic("move up")
!+^l::Komorebic("move right")

; ============================================
; Resize (Alt+Shift+Ctrl+Minus/Plus)
; ============================================
!+^-::{
    Komorebic("resize-axis horizontal decrease")
    Komorebic("resize-axis vertical decrease")
}
!+^=::{
    Komorebic("resize-axis horizontal increase")
    Komorebic("resize-axis vertical increase")
}

; ============================================
; Workspace back and forth (Alt+`)
; ============================================
!+^#`::Komorebic("cycle-workspace previous")

; ============================================
; Move workspace to monitor (Alt+Shift+Ctrl+Win+Tab)
; ============================================
!+^#Tab::Komorebic("cycle-move-to-monitor next")

; ============================================
; Focus workspaces (Alt+Shift+Ctrl+Win+Number/Letter)
; ============================================
!+^#1::SwitchWorkspace("1")
!+^#2::SwitchWorkspace("2")
!+^#3::SwitchWorkspace("3")
!+^#4::SwitchWorkspace("4")
!+^#5::SwitchWorkspace("5")
!+^#6::SwitchWorkspace("6")
!+^#7::SwitchWorkspace("7")
!+^#8::SwitchWorkspace("8")
!+^#9::SwitchWorkspace("9")
!+^#b::SwitchWorkspace("B")
!+^#c::SwitchWorkspace("C")
!+^#d::SwitchWorkspace("D")
!+^#e::SwitchWorkspace("E")
!+^#i::SwitchWorkspace("I")
!+^#m::SwitchWorkspace("M")
!+^#n::SwitchWorkspace("N")
!+^#o::SwitchWorkspace("O")
!+^#p::SwitchWorkspace("P")
!+^#q::SwitchWorkspace("Q")
!+^#r::SwitchWorkspace("R")
!+^#s::SwitchWorkspace("S")
!+^#t::SwitchWorkspace("T")
!+^#u::SwitchWorkspace("U")
!+^#w::SwitchWorkspace("W")
!+^#y::SwitchWorkspace("Y")

; ============================================
; Move to workspaces (Alt+Shift+Ctrl+Number/Letter)
; ============================================
!+^1::Komorebic("move-to-named-workspace 1")
!+^2::Komorebic("move-to-named-workspace 2")
!+^3::Komorebic("move-to-named-workspace 3")
!+^4::Komorebic("move-to-named-workspace 4")
!+^5::Komorebic("move-to-named-workspace 5")
!+^6::Komorebic("move-to-named-workspace 6")
!+^7::Komorebic("move-to-named-workspace 7")
!+^8::Komorebic("move-to-named-workspace 8")
!+^9::Komorebic("move-to-named-workspace 9")
!+^b::Komorebic("move-to-named-workspace B")
!+^c::Komorebic("move-to-named-workspace C")
!+^d::Komorebic("move-to-named-workspace D")
!+^e::Komorebic("move-to-named-workspace E")
!+^i::Komorebic("move-to-named-workspace I")
!+^m::Komorebic("move-to-named-workspace M")
!+^n::Komorebic("move-to-named-workspace N")
!+^o::Komorebic("move-to-named-workspace O")
!+^p::Komorebic("move-to-named-workspace P")
!+^q::Komorebic("move-to-named-workspace Q")
!+^r::Komorebic("move-to-named-workspace R")
!+^s::Komorebic("move-to-named-workspace S")
!+^t::Komorebic("move-to-named-workspace T")
!+^u::Komorebic("move-to-named-workspace U")
!+^w::Komorebic("move-to-named-workspace W")
!+^y::Komorebic("move-to-named-workspace Y")

; ============================================
; Additional commands (service mode equivalents)
; ============================================
!+^#`;::Komorebic("toggle-float")  ; Alt+Shift+Ctrl+Win+; = Toggle float
!+^#f::Komorebic("retile")  ; Alt+Shift+Ctrl+Win+F = Retile
