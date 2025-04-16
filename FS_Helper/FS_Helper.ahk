; To compile download AutoHotKey v1.1 (https://www.autohotkey.com/download/1.1/AutoHotkey_1.1.37.02.zip)
; Extract the contents of the Compiler folder inside the zip file to where the FS_Helper.ahk file is.
; In a command line interface CD to that directory and run:
; Ahk2Exe.exe /in FS_Helper.ahk /base "ANSI 32-bit.bin" /icon 56.ico
;
; Made possible with Grok: https://x.com/i/grok
;
; V1 - Mostly working fine.

#NoEnv
SetWorkingDir %A_ScriptDir%
#SingleInstance Force


global isToggled := false

; Global click offset for scroll arrows
ClickOffset := 10




; Ensure FreeStyle.exe is running before hotkey
if !WinExist("ahk_class FreeStyleAppWind") {
; MsgBox, The full path of this script is: %A_ScriptDir%
    Run, %A_ScriptDir%\FreeStyle.exe
    WinWait, ahk_class FreeStyleAppWind, , 5 ; Wait up to 5 seconds for app to appear
}



; Start timer to check if FreeStyleAppWind is closed
SetTimer, CheckFreeStyleAppWind, 5000 ; Check every 5 seconds

; Timer subroutine to exit script if FreeStyleAppWind is closed
CheckFreeStyleAppWind:
if !WinExist("ahk_class FreeStyleAppWind") {
    ExitApp
}
return

; Only activate hotkeys when FreeStyleAppWind is active
#IfWinActive ahk_class FreeStyleAppWind

; F1: Open FreeStyle.hlp from the program's folder
F1::
WinGet, ProcessPath, ProcessPath, ahk_class FreeStyleAppWind
SplitPath, ProcessPath,, ProcessDir
HelpFile := ProcessDir "\FreeStyle_extended_help\index.html"
; MsgBox, The full path of this script is:%HelpFile%
if FileExist(HelpFile) {
    Run, %HelpFile%
} else {
	;	MsgBox, FreeStyle_extended_help HTML not found in %ProcessDir%

	; HTML not found, launch PDF help instead
	HelpFile := ProcessDir "\FreeStyle_extended_help.pdf"
	if FileExist(HelpFile) {
    Run, %HelpFile%
	} else {
	;	MsgBox, FreeStyle_extended_help.pdf not found in %ProcessDir%
		
			
		; pdf file not found, launch original help instead
		HelpFile := ProcessDir "\FreeStyle.hlp"
		if FileExist(HelpFile) {
		Run, %HelpFile%
		} else {
			MsgBox, FreeStyle.hlp not found in %ProcessDir%
		}
	}
	
	
}
return



; Shift F1: Open  Mark_of_the_Unicorn_FreeStyle_for_Macinotsh_manual.pdf
+F1::
WinGet, ProcessPath, ProcessPath, ahk_class FreeStyleAppWind
SplitPath, ProcessPath,, ProcessDir
HelpFile := ProcessDir "\FreeStyle_extended_help\Mark_of_the_Unicorn_FreeStyle_for_Macinotsh_manual.pdf"
 MsgBox, The full path of this script is:%HelpFile%
if FileExist(HelpFile) {
    Run, %HelpFile%
} else {
		MsgBox, File not found: %HelpFile%
	}
return


; Right mouse Up + WheelUp: Scroll ScrollBar2 up
~RButton & WheelUp::
ControlGet, ScrollBar2Hwnd, Hwnd,, ScrollBar2, ahk_class FreeStyleAppWind
if (ScrollBar2Hwnd != "") {
    VarSetCapacity(Rect, 16, 0)
    DllCall("GetWindowRect", "Ptr", ScrollBar2Hwnd, "Ptr", &Rect)
    ScrollBarX := NumGet(Rect, 0, "Int")
    ScrollBarY := NumGet(Rect, 4, "Int")
    ScrollBarWidth := NumGet(Rect, 8, "Int") - ScrollBarX
    ScrollBarHeight := NumGet(Rect, 12, "Int") - ScrollBarY
    VarSetCapacity(Point, 8, 0)
    NumPut(ScrollBarX, Point, 0, "Int")
    NumPut(ScrollBarY, Point, 4, "Int")
    DllCall("ScreenToClient", "Ptr", WinExist("ahk_class FreeStyleAppWind"), "Ptr", &Point)
    ScrollBarX := NumGet(Point, 0, "Int")
    ScrollBarY := NumGet(Point, 4, "Int")
    ClickX := ScrollBarWidth // 2
    ClickY := ClickOffset
    VarSetCapacity(ClickPoint, 8, 0)
    NumPut(ScrollBarX + ClickX, ClickPoint, 0, "Int")
    NumPut(ScrollBarY + ClickY, ClickPoint, 4, "Int")
    DllCall("ClientToScreen", "Ptr", WinExist("ahk_class FreeStyleAppWind"), "Ptr", &ClickPoint)
    ScreenClickX := NumGet(ClickPoint, 0, "Int")
    ScreenClickY := NumGet(ClickPoint, 4, "Int")
    ControlSend, ScrollBar2, {Up}, ahk_class FreeStyleAppWind
} else {
     MsgBox, Vertical scroll bar not visible!
}
return


; Right mouse button + WheelDown: Scroll ScrollBar2 down
~RButton & WheelDown::
ControlGet, ScrollBar2Hwnd, Hwnd,, ScrollBar2, ahk_class FreeStyleAppWind
if (ScrollBar2Hwnd != "") {
    VarSetCapacity(Rect, 16, 0)
    DllCall("GetWindowRect", "Ptr", ScrollBar2Hwnd, "Ptr", &Rect)
    ScrollBarX := NumGet(Rect, 0, "Int")
    ScrollBarY := NumGet(Rect, 4, "Int")
    ScrollBarWidth := NumGet(Rect, 8, "Int") - ScrollBarX
    ScrollBarHeight := NumGet(Rect, 12, "Int") - ScrollBarY
    VarSetCapacity(Point, 8, 0)
    NumPut(ScrollBarX, Point, 0, "Int")
    NumPut(ScrollBarY, Point, 4, "Int")
    DllCall("ScreenToClient", "Ptr", WinExist("ahk_class FreeStyleAppWind"), "Ptr", &Point)
    ScrollBarX := NumGet(Point, 0, "Int")
    ScrollBarY := NumGet(Point, 4, "Int")
    ClickX := ScrollBarWidth // 2
    ClickY := ScrollBarHeight - ClickOffset
    VarSetCapacity(ClickPoint, 8, 0)
    NumPut(ScrollBarX + ClickX, ClickPoint, 0, "Int")
    NumPut(ScrollBarY + ClickY, ClickPoint, 4, "Int")
    DllCall("ClientToScreen", "Ptr", WinExist("ahk_class FreeStyleAppWind"), "Ptr", &ClickPoint)
    ScreenClickX := NumGet(ClickPoint, 0, "Int")
    ScreenClickY := NumGet(ClickPoint, 4, "Int")
    ControlSend, ScrollBar2, {Down}, ahk_class FreeStyleAppWind
 
} else {
    MsgBox, Vertical scroll bar not visible!
}
return

 
 WheelDown::
ControlGet, ScrollBar1Hwnd, Hwnd,, ScrollBar1, ahk_class FreeStyleAppWind
if (ScrollBar1Hwnd != "") {
    VarSetCapacity(Rect, 16, 0)
    DllCall("GetWindowRect", "Ptr", ScrollBar1Hwnd, "Ptr", &Rect)
    ScrollBarX := NumGet(Rect, 0, "Int")
    ScrollBarY := NumGet(Rect, 4, "Int")
    ScrollBarWidth := NumGet(Rect, 8, "Int") - ScrollBarX
    ScrollBarHeight := NumGet(Rect, 12, "Int") - ScrollBarY
    VarSetCapacity(Point, 8, 0)
    NumPut(ScrollBarX, Point, 0, "Int")
    NumPut(ScrollBarY, Point, 4, "Int")
    DllCall("ScreenToClient", "Ptr", WinExist("ahk_class FreeStyleAppWind"), "Ptr", &Point)
    ScrollBarX := NumGet(Point, 0, "Int")
    ScrollBarY := NumGet(Point, 4, "Int")
    ClickX := ClickOffset
    ClickY := ScrollBarHeight // 2
    VarSetCapacity(ClickPoint, 8, 0)
    NumPut(ScrollBarX + ClickX, ClickPoint, 0, "Int")
    NumPut(ScrollBarY + ClickY, ClickPoint, 4, "Int")
    DllCall("ClientToScreen", "Ptr", WinExist("ahk_class FreeStyleAppWind"), "Ptr", &ClickPoint)
    ScreenClickX := NumGet(ClickPoint, 0, "Int")
    ScreenClickY := NumGet(ClickPoint, 4, "Int")
    ControlSend, ScrollBar1, {Left}, ahk_class FreeStyleAppWind

} else {
     MsgBox, Horrizontal scroll bar not visible!
}
return




; Mouse scroll down: Scroll ScrollBar2 down
 WheelUp::
ControlGet, ScrollBar1Hwnd, Hwnd,, ScrollBar1, ahk_class FreeStyleAppWind
if (ScrollBar1Hwnd != "") {
    VarSetCapacity(Rect, 16, 0)
    DllCall("GetWindowRect", "Ptr", ScrollBar1Hwnd, "Ptr", &Rect)
    ScrollBarX := NumGet(Rect, 0, "Int")
    ScrollBarY := NumGet(Rect, 4, "Int")
    ScrollBarWidth := NumGet(Rect, 8, "Int") - ScrollBarX
    ScrollBarHeight := NumGet(Rect, 12, "Int") - ScrollBarY
    VarSetCapacity(Point, 8, 0)
    NumPut(ScrollBarX, Point, 0, "Int")
    NumPut(ScrollBarY, Point, 4, "Int")
    DllCall("ScreenToClient", "Ptr", WinExist("ahk_class FreeStyleAppWind"), "Ptr", &Point)
    ScrollBarX := NumGet(Point, 0, "Int")
    ScrollBarY := NumGet(Point, 4, "Int")
    ClickX := ScrollBarWidth - ClickOffset
    ClickY := ScrollBarHeight // 2
    VarSetCapacity(ClickPoint, 8, 0)
    NumPut(ScrollBarX + ClickX, ClickPoint, 0, "Int")
    NumPut(ScrollBarY + ClickY, ClickPoint, 4, "Int")
    DllCall("ClientToScreen", "Ptr", WinExist("ahk_class FreeStyleAppWind"), "Ptr", &ClickPoint)
    ScreenClickX := NumGet(ClickPoint, 0, "Int")
    ScreenClickY := NumGet(ClickPoint, 4, "Int")
    ControlSend, ScrollBar1, {Right}, ahk_class FreeStyleAppWind
} else {
    MsgBox, Horrizontal scroll bar not visible!
}
return


; Right mouse button held + Middle mouse button press: Alt+W, 3rd item
~RButton & MButton::
WinActivate, ahk_class FreeStyleAppWind
Send {F11}
Sleep 10
Send {ESC}
Sleep 10
SendInput {Alt down}
Sleep 10
SendInput w
Sleep 10
SendInput {Alt up}
Sleep 20  ; Wait for menu to appear
SendInput {Down}
Sleep 5
SendInput {Down}
Sleep 5
SendInput {Enter}
return

; Left mouse button + WheelUp: Send F9
~MButton & WheelUp::
Send {F9}
return

; Left mouse button + WheelDown: Send Shift+F9
~MButton & WheelDown::
Send {Shift down}
Send {F9}
Send {Shift up}
return



RemoveTooltip:
    ToolTip
return

RButton & LButton::
global LastClickTime
CurrentTime := A_TickCount
TimeDelta := CurrentTime - LastClickTime
LastClickTime := CurrentTime

isToggled := !isToggled
WinGet, ActiveWinHwnd, ID, ahk_class FreeStyleAppWind
ControlGet, ZoomDocHwnd, Hwnd,, U_ZoomDocStyle1, ahk_class FreeStyleAppWind
if (ZoomDocHwnd != "") {
    ; Get U_ZoomDocStyle1 window rectangle in screen coordinates
    VarSetCapacity(Rect, 16, 0)
    DllCall("GetWindowRect", "Ptr", ZoomDocHwnd, "Ptr", &Rect)
    ZoomDocX := NumGet(Rect, 0, "Int")
    ZoomDocY := NumGet(Rect, 4, "Int")
    
    ; Set click position based on toggle state
    ClickX := isToggled ? 410 : 435
    ClickY := 45
    
    ; Convert click position to screen coordinates
    VarSetCapacity(ClickPoint, 8, 0)
    NumPut(ZoomDocX + ClickX, ClickPoint, 0, "Int")
    NumPut(ZoomDocY + ClickY, ClickPoint, 4, "Int")
    ScreenClickX := NumGet(ClickPoint, 0, "Int")
    ScreenClickY := NumGet(ClickPoint, 4, "Int")
    
    ; Perform single or double click based on time delta
    if (TimeDelta <= 500 && TimeDelta > 0) {
        MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
        Sleep, 10 ; Small delay for double-click recognition
        MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
    } else {
        MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
    }
} else {
    MsgBox, U_ZoomDocStyle1 not found!
}
return



#IfWinActive