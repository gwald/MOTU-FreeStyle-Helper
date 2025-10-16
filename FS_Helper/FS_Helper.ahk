; To compile download AutoHotKey v1.1 (https://www.autohotkey.com/download/1.1/AutoHotkey_1.1.37.02.zip)
; Extract the contents of the Compiler folder inside the zip file to where the FS_Helper.ahk file is.
; In a command line interface CD to that directory and run:
; Ahk2Exe.exe /in FS_Helper.ahk /base "ANSI 32-bit.bin" /icon 56.ico
;
; To run use:
; build_deploy.bat
;
;
; Made possible with Grok: https://x.com/i/grok
;
; v4 - changed F1 and Shift F1 to F10 and Alt F2 to avoid conflicting.
; V1 - Mostly working fine.
;
;
; https://www.autohotkey.com/docs/v1/Hotkeys.htm
;
;

; CHANGES REQUIRE RECOMIPLATION! SEE ABOVE.

; MIDI SET UP ---------------------------------------
; ONLY reads controller CC# (momentory or range) messages on channel 1, then autohotkey FS-Helper actions it based on settings below.


; Use MIDI In device#, if -1 MIDI is disabled.
midiInDeviceId := -1


;MIDI devices, note and CC info - helpful if you can't see your keyboards CC# set 0 = turn off or 1 = turn on
midiInDeviceDebug := 0


; configure controller CC#


; -- channel modifiers - these effect the feature for the player (track) button.
;Tab Solo/unSolo + channel 
MIDI_Tab := 45

;Alt mute/unmute + channel 
MIDI_Alt := 47

; 10 shift + channel 
MIDI_SHIFT := 50
; -- channel modifiers - these effect the feature for the player (track) button.




; -- features


;Q hide/display while mute/unmute all players 
MIDI_CLEAR := 46


;W key sends MIDI Panic
MIDI_PANIC := 36


; place_rewind_marker()
MIDI_REWIND_MARKER := 114		

; duplicate the current take (Alt F7).
MIDI_DUP_TAKE := 99				
							
MIDI_PAUSE := 42						
							

; do_metronome()
MIDI_METRONOME := 38		



; do_EnsembleToggle()
MIDI_Ensemble := 0 ;				
						

MIDI_TRANSPORT_BACK := 112
MIDI_TRANSPORT_FORWARD := 113 
MIDI_TRANSPORT_STOP := 36
MIDI_TRANSPORT_PLAY := 115
MIDI_TRANSPORT_LOOP := 116
MIDI_TRANSPORT_REC := 117							
							
							
; Play (track/channel) buttons: hide and mute on/off (with Tab, Alt or Shift held down it does functionality as above).
MIDI_PLAYER_1 := 51
MIDI_PLAYER_2 := 52
MIDI_PLAYER_3 := 53
MIDI_PLAYER_4 := 54
MIDI_PLAYER_5 := 55
MIDI_PLAYER_6 := 56
MIDI_PLAYER_7 := 57
MIDI_PLAYER_8 := 58
MIDI_PLAYER_9 := 59
MIDI_PLAYER_10 := 46


; -- MIDI features




; MIDI SET UP ---------------------------------------



; Q key clear/enable all
; 1 to disable all on press
; 0 to enable all on press
clear_all_disable := 0


; Loop set back to the start (Shift Loop), end bar
RESET_LOOP_END_BAR := 8



;---------------------------------------


MIDI_IN_CHANNEL_FILTER := 0	; 0 = MIDI channel 1
MIDI_OUT_CH := 1	; MIDI channel 2

; Open MIDI Out - not used
midiOutDeviceId := -1


MIDI_ALT := 0
MIDI_SHIFT := 0
MIDI_TAB := 0
solo_mute_toggle := 0



SendMode Input
setbatchlines -1	; Never sleep

#Persistent
#include %A_ScriptDir%\MIDI.ahk	;Path to the library


SetKeyDelay, 10, 10  ; Add slight delay to ensure reliable key sending


#NoEnv
SetWorkingDir %A_ScriptDir%
#SingleInstance Force


MouseX := 0         ; Store mouse X position
MouseY := 0         ; Store mouse Y position
isToggled := false

; Global click offset for scroll arrows
ClickOffset := 10


If(midiInDeviceId>=0)
{
	; Get all MIDI ports
					midiInDevices := getMidiInDevices()
					midiOutDevices := getMidiOutDevices()

					; Display all MIDI ports
					for index, device in midiInDevices
					{
						portName := index-1 . ": " . device
						strInPorts .= portName . "`n"
					}
					for index, device in midiOutDevices
					{
						strOutPorts .= index-1 . ": " . device . "`n"
					}
					
					if(midiInDeviceDebug = 1)
					{
					MsgBox, % "MIDI In`n" strInPorts "`nMIDI Out`n" strOutPorts
					}



					retOut := 0
					retIn := 0
					
					if(midiOutDeviceId >=0)
						retOut := openMidiOut(midiOutDeviceId)
					
					
					retIn := openMidiIn(midiInDeviceId)

					
					If retIn = 0
					{
						;MsgBox, ok.
					}
					Else
					{
						MsgBox, 4, Error opening input device!, Your configured input device failed to open! `nDo you you want to continue?
						IfMsgBox, Yes
						{
							
							;MsgBox, Starting
						}
						Else
						{
							;MsgBox, Exiting script.
							ExitApp
						}
					}

}		
					



; Ensure FreeStyle.exe is running before hotkey
if !WinExist("ahk_class FreeStyleAppWind") {

	IfExist, FS_Helper\fs_start.bat
	{
		RunWait, FS_Helper\fs_start.bat, ,  Hide
		sleep 222
	}
	Else
	{
	   ; MsgBox, The file FS_Helper\fs_helper.bat does not exist.
	}

; ;MsgBox, The full path of this script is: %A_ScriptDir%
    Run, %A_ScriptDir%\FreeStyle.exe
    WinWait, ahk_class FreeStyleAppWind, , 5 ; Wait up to 5 seconds for app to appear
}
else
{



}






; Start timer to check if FreeStyleAppWind is closed
SetTimer, CheckFreeStyleAppWind, 5000 ; Check every 5 seconds

; Timer subroutine to exit script if FreeStyleAppWind is closed
CheckFreeStyleAppWind:
if !WinExist("ahk_class FreeStyleAppWind") {


		IfExist, FS_Helper\fs_exit.bat
		{
			RunWait, FS_Helper\fs_exit.bat, , Hide
			sleep 10
		}
		Else
		{
		   ; MsgBox, The file FS_Helper\fs_helper.bat does not exist.
		}



    ExitApp
}
return

Do_MIDI(src)
{
					
					
					;  ;MsgBox, % "z src#" src
					
					; =====  PROCESS MODIFIERS ==================
					 if(MIDI_SHIFT = midiEvent.controller)
					{
						 ;MsgBox, % "MIDI_SHIFT " MIDI_SHIFT ", midiEvent.controller=" midiEvent.controller " MIDI_SHIFT: " MIDI_SHIFT "  midiEvent.value: "  midiEvent.value 
									
					
						if( midiEvent.value < 50 and MIDI_SHIFT = 1)
						{
							MIDI_SHIFT := 0
							 ;MsgBox, % " Send {LShift up} " midiEvent.controller ", value=" midiEvent.value
							 	  
				
					
						}						
						else if(MIDI_SHIFT = 0) ; if ( midiEvent.value > 120  and MIDI_SHIFT = 0)
						{
							MIDI_SHIFT := 1
							;MsgBox, % "  Send {LShift down} " midiEvent.controller ", value=" midiEvent.value
						
							
						}
					return
					}
					
					
						
					 if(MIDI_Tab = midiEvent.controller)
					{
						 ;MsgBox, % "MIDI_Tab " MIDI_Tab ", midiEvent.controller=" midiEvent.controller " MIDI_SHIFT: " MIDI_SHIFT "  midiEvent.value: "  midiEvent.value 
									
					
						if( midiEvent.value  < 50  and MIDI_TAB = 1)
						{
							MIDI_TAB := 0
							 ;MsgBox, % " Send {LShift up} " midiEvent.controller ", value=" midiEvent.value
							 	  
				
					
						}						
						else if( MIDI_TAB = 0) ; midiEvent.value > 120  and MIDI_TAB = 0)
						{
							MIDI_TAB := 1
							 ;MsgBox, % "  Send {LShift down} " midiEvent.controller ", value=" midiEvent.value
						
							
						}
					return
					}


					if(MIDI_Alt = midiEvent.controller)
					{
					 ;MsgBox, % "MIDI_Alt " MIDI_Alt ", midiEvent.controller=" midiEvent.controller " MIDI_ALT: " MIDI_ALT "  midiEvent.value:  "  midiEvent.value 
					
					
						if( midiEvent.value < 50  and MIDI_ALT = 1)
						{
							MIDI_ALT := 0
							;MsgBox, % "Send {LAlt up} " midiEvent.controller ", value=" midiEvent.value
						
							
							
						}
						else if(MIDI_ALT = 0) ;	if( midiEvent.value > 100  and MIDI_ALT = 0)
						{
							MIDI_ALT := 1
							;MsgBox, % " Send {LAlt down} " midiEvent.controller ", value=" midiEvent.value
			

						}
					return
					}
					
					; =====  PROCESS MODIFIERS ==================
					
					
					; something pressed and released - check buttons!
					if(  midiEvent.value =0)  ; if(  midiEvent.value < 128)  ; my keyboard sends button press as 0 and 127, so this works.
					{				
							
							Switch  midiEvent.controller
							{
				
				
				
				
							Case MIDI_TRANSPORT_BACK:	
							do_transport(1)
							
							Case MIDI_TRANSPORT_FORWARD:	
							do_transport(2)
				
							Case MIDI_TRANSPORT_STOP:	
							place_rewind_marker()
							
							Case MIDI_TRANSPORT_PLAY:	
							do_transport(4)
							
				
							Case MIDI_TRANSPORT_LOOP:	
							do_transport(5)
							
							Case MIDI_TRANSPORT_REC:	
							do_transport(6)
							
							
							
							
							Case MIDI_Ensemble:
							do_EnsembleToggle()
				
							Case MIDI_METRONOME:	
							do_metronome()
						
							Case MIDI_REWIND_MARKER:							
							place_rewind_marker()
						
						
							Case MIDI_DUP_TAKE:
							do_dup_take()
						
							Case MIDI_PAUSE:							
							do_transport(3)
						
						
							Case MIDI_PANIC:
							Do_Panic() 
						    
							
							Case MIDI_CLEAR:
							clear_all() 
						    				
							
							Case MIDI_PLAYER_1:
							solo_mute(1)
							
							Case MIDI_PLAYER_2:
							solo_mute(2)
							
							Case MIDI_PLAYER_3:
							solo_mute(3)
							
							Case MIDI_PLAYER_4:
							solo_mute(4)
							
							Case MIDI_PLAYER_5:
							solo_mute(5)
							
							Case MIDI_PLAYER_6:
							solo_mute(6)
							
							Case MIDI_PLAYER_7:
							solo_mute(7)
							
							Case MIDI_PLAYER_8:
							solo_mute(8)
							
							Case MIDI_PLAYER_9:
							solo_mute(9)
							
							Case MIDI_PLAYER_10:
							solo_mute(10)
								
								
								Default:
								
								if(midiInDeviceDebug = 1)
								{
									MsgBox, % " MIDICC feature not found: " midiEvent.controller
								}
								
							}



					} ; something pressed and released - check buttons!
				
					
}

; Only activate hotkeys when FreeStyleAppWind is active
#IfWinActive ahk_class FreeStyleAppWind


					; MIDI IN -------------------------------------
					MidiControlChange:
					

					if(midiInDeviceDebug = 1)
					{
					MsgBox, % "CC#" midiEvent.controller ", value=" midiEvent.value
					}
					
					Do_MIDI(1)
					return

					
					

					MidiNoteOn:
					
					
					if(midiInDeviceDebug = 1)
					{
					MsgBox, % "Note (not mappable)#" midiEvent.noteNumber ", velocity=" midiEvent.velocity
					}
					
					Do_MIDI(0)
					return

										
					MidiSysEx:
					Msg :=
					raw :=
					loopMax := SysexMessage.MaxIndex() - 2
					raw := SysexMessage[1] . " "
					Loop, %loopMax%
					{
						raw .= SysexMessage[A_Index+1] . " "
						dec := Format("{:i}", "0x" SysexMessage[A_Index+1])
						ansi := Chr(dec)
						Msg .= ansi
						OutputDebug, % "A_Index=" . A_Index . ", element=" . SysexMessage[A_Index+1]
					}
					raw .= SysexMessage[SysexMessage.MaxIndex()]	
					
					if(midiInDeviceDebug = 1)
					{
						MsgBox, % "SysEx`n`nRaw hex:`n" . raw . "`n`nASCII:`n" . Msg
					}
					
					return





; F10: Open FreeStyle.hlp from the program's folder
F10::
WinGet, ProcessPath, ProcessPath, ahk_class FreeStyleAppWind
SplitPath, ProcessPath,, ProcessDir
HelpFile := ProcessDir "\FreeStyle_extended_help\index.html"
; ;MsgBox, The full path of this script is:%HelpFile%
if FileExist(HelpFile) {
    Run, %HelpFile%
} else {
	;	;MsgBox, FreeStyle_extended_help HTML not found in %ProcessDir%

	; HTML not found, launch PDF help instead
	HelpFile := ProcessDir "\FreeStyle_extended_help\FreeStyle_extended_help.pdf"
	if FileExist(HelpFile) {
    Run, %HelpFile%
	} else {
	;	;MsgBox, FreeStyle_extended_help.pdf not found in %ProcessDir%
		
			
		; pdf file not found, launch original help instead
		HelpFile := ProcessDir "\FreeStyle.hlp"
		if FileExist(HelpFile) {
		Run, %HelpFile%
		} else {
			;MsgBox, FreeStyle.hlp not found in %ProcessDir%
		}
	}
	
	
}
return



; Shift F1: Open  Mark_of_the_Unicorn_FreeStyle_for_Macinotsh_manual.pdf
!F2::
WinGet, ProcessPath, ProcessPath, ahk_class FreeStyleAppWind
SplitPath, ProcessPath,, ProcessDir
HelpFile := ProcessDir "\FreeStyle_extended_help\Mark_of_the_Unicorn_FreeStyle_for_Macinotsh_manual.pdf"
; ;MsgBox, The full path of this script is:%HelpFile%

if FileExist(HelpFile) {
    Run, %HelpFile%
} else {
		;MsgBox, File not found: %HelpFile% going to download from archive.org now!
		
		UrlDownloadToFile, https://archive.org/download/stx_Mark_of_the_Unicorn_FreeStyle_for_Macinotsh_manual/Mark_of_the_Unicorn_FreeStyle_for_Macinotsh_manual.pdf , %HelpFile%
		

		if FileExist(HelpFile) {
		Run, %HelpFile%
		} else {
		;MsgBox, Download from archive.org failed!
		
		;MsgBox, https://archive.org/download/stx_Mark_of_the_Unicorn_FreeStyle_for_Macinotsh_manual/Mark_of_the_Unicorn_FreeStyle_for_Macinotsh_manual.pdf

		}



	}
return



; Change the URL link below to which ever video you like best!

; MOTU FREESTYLE VIDEO by LANCE ABAIR, uploaded by the video instructor!
; https://www.youtube.com/watch?v=j0xYfv_hF1E

; or

; high quality VHS rip, with a weird reverb in the audio: Getting into FreeStyle (1994) by mrjazzycharon2.

; https://www.youtube.com/watch?v=KKTYyXPGotc 

; or

; Best mix of both https://archive.org/upload/?identifier=mark-of-the-unicorn-motu-freestyle-v2.31-windows?autoplay=1 

; Alt F5: Open FS VHS video
!F5::
WinGet, ProcessPath, ProcessPath, ahk_class FreeStyleAppWind
SplitPath, ProcessPath,, ProcessDir
    Run, "https://www.youtube.com/watch?v=KKTYyXPGotc"	
return





; Vertical scroll Up
; Right mouse Up + WheelUp: Scroll ScrollBar2 up
;~RButton & WheelUp::
WheelUp::

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
     ;MsgBox, Vertical scroll bar not visible!
}
return

; Vertical scroll Down 
; Right mouse button + WheelDown: Scroll ScrollBar2 down
; ~RButton & WheelDown::
WheelDown::

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
    ;MsgBox, Vertical scroll bar not visible!
}
return




; LEFT 
; Shift + Scroll Wheel Down
RButton & WheelDown::
; Horrizontal scroll Left

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
     ;MsgBox, Horrizontal scroll bar not visible!
}
return


;RIGHT
; Horrizontal scroll Right
; Mouse scroll down: Scroll ScrollBar2 down

; Shift + Scroll Wheel Up
RButton & WheelUp::
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
    ;MsgBox, Horrizontal scroll bar not visible!
}
return

; -----------------------------------


; SHIFT horz scrolling


; LEFT 
; Shift + Scroll Wheel Down
+WheelDown::
; Horrizontal scroll Left

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
     ;MsgBox, Horrizontal scroll bar not visible!
}
return


;RIGHT
; Horrizontal scroll Right
; Mouse scroll down: Scroll ScrollBar2 down

; Shift + Scroll Wheel Up
+WheelUp::
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
    ;MsgBox, Horrizontal scroll bar not visible!
}
return

; -----------------------------------








;------------- H L/R

; LEFT 
; Shift + Scroll Wheel Down
WheelLeft::
; Horrizontal scroll Left

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
     ;MsgBox, Horrizontal scroll bar not visible!
}
return


;RIGHT
; Horrizontal scroll Right
; Mouse scroll down: Scroll ScrollBar2 down

; Shift + Scroll Wheel Up
WheelRight::
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
    ;MsgBox, Horrizontal scroll bar not visible!
}
return

; ----------------------------------

   
   


; NOTE: don't display ShowYellowRect before picking the color!!!
ShowYellowRect(x, y) {

; Ensure consistent coordinate mode
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
x++
y++
x++
y++

x++
y++
x++
y++

    Gui, YellowRect:New, +AlwaysOnTop -Caption +ToolWindow
    Gui, Color, FFFF00 ; Yellow color
    Gui, Show, x%x% y%y% w18 h18, YellowRect
}


CheckGBZero(hexColor) {
    ; Remove "0x" prefix if present
    hexColor := StrReplace(hexColor, "0x", "")
    ; Ensure the HEX string is 6 characters long
    if (StrLen(hexColor) != 6)
        return "Invalid HEX format"
    
    ; Extract Green (3rd and 4th characters) and Blue (5th and 6th characters)
    green := SubStr(hexColor, 3, 2)
    blue := SubStr(hexColor, 5, 2)
    
    ; Check if Green and Blue are "00"
    if (green = "00" && blue = "00")
        return 1 ; True, both G and B are zero
    else
        return 0 ; False, either G or B is non-zero
}



do_EnsembleToggle()
{
				
				
								
		; Ensure consistent coordinate mode
		CoordMode, Pixel, Screen
		CoordMode, Mouse, Screen

; MsgBox, do_metronome

			MouseGetPos, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)

			ScreenClickX := 132
			ScreenClickY := 252

		    MouseMove, ScreenClickX, ScreenClickY  
			PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
			 
			 ;ShowYellowRect( ScreenClickX, ScreenClickY  )

			if(Color = 0xEEEEEE) ; max window box
			{

				MouseMove, %ScreenClickX%, %ScreenClickY%, 10  ; Move to position (speed 10 for realism)
				DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0, "UInt", 0, "Int", 0)  ; Left down
				Sleep 50
				DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0, "UInt", 0, "Int", 0)  ; Left up
				Sleep 200
    	
				;MsgBox, To Max window - The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
			
			}
			else ; window title color is #99b4d1
			{
				ScreenClickX := 351
				;ScreenClickX := 132
	
		; needs to loop to find the min button if extended, Window Spy doesn't report a class??
				while(1)
				{
					MouseMove, %ScreenClickX%, %ScreenClickY%, 10  ; Move to position (speed 10 for realism)
					PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
				
					if(Color = 0xEEEEEE) ; max window box
					{
						ScreenClickX++
						ScreenClickX++
					
						; MsgBox, found Max window - The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
						MouseMove, %ScreenClickX%, %ScreenClickY%, 10  ; Move to position (speed 10 for realism)
						
						Sleep 100
						DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0, "UInt", 0, "Int", 0)  ; Left down
						Sleep 150
						DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0, "UInt", 0, "Int", 0)  ; Left up
						Sleep 400
							
						break
						
					}
						
					ScreenClickX++
					ScreenClickX++
					ScreenClickX++
					
					if(ScreenClickX > 1020)
						break ;not found
						
						
					;	MsgBox, To Max window - The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%

					; ShowYellowRect( ScreenClickX, ScreenClickY+1  )

						
				
				}
			
				
				;MsgBox, To Min window - The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
			
			}
			
	MouseMove, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
			
	Send {LButton up} ; Releases the left mouse button	
	Sleep 11
	Send {LButton up} ; Releases the left mouse button		
}

do_metronome()
{				
		; Ensure consistent coordinate mode
		CoordMode, Pixel, Screen
		CoordMode, Mouse, Screen

; MsgBox, do_metronome

			MouseGetPos, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)

			ScreenClickX := 136
			ScreenClickY := 155
		

		;	MouseMove, ScreenClickX, ScreenClickY 
					
		;	MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0

		; MsgBox,  (%ScreenClickX%, %ScreenClickY%) click
		;	ShowYellowRect( ScreenClickX, ScreenClickY  )
		;	MouseMove, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
					
		
}


do_dup_take()
{
 Send !{F7}
 return					
}

; 1 rewind
; 2 forward
; 3 stop
; 4 play
; 5 loop
; 6 record


do_transport(but) 
{				
		; Ensure consistent coordinate mode
		CoordMode, Pixel, Screen
		CoordMode, Mouse, Screen
		
		
		
				
global MIDI_ALT
global MIDI_SHIFT
global RESET_LOOP_END_BAR



			
			

			Switch  but
			{

				;back
				Case 1:		
			
				Send {Enter}	
				return
				
				
				
				
				;forward  ??? Move forward the loop markers
				Case 2:	
						Send ^{F3}
						
						
						;toggle hide/remove rewind marker
						;confusing!
						;	Sleep 10
						;	Send !V
						;	Sleep 10
						;	Send {Down 3} 
						;	Send {Enter}	
						
						return
				
				; Pause = This is FS's pause button (audiably holds the current instruments played ). For stop (and stop all audio), hit the play button
				Case 3:	
				
							
								
							; MsgBox, do_transport# %but%

							MouseGetPos, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)

							ScreenClickX := 0
							ScreenClickY := 0
							
							
							
							ScreenClickX := 102
							ScreenClickY := 98
								
								

						;	MouseMove, ScreenClickX, ScreenClickY 
									
							MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0

						;  MsgBox,  (%ScreenClickX%, %ScreenClickY%) click
						;	ShowYellowRect( ScreenClickX, ScreenClickY  )
							MouseMove, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
									
				return		
									
						
				; play - toggles play and stop -  space bar
				Case 4:			
					Send {SPACE}
				return
				
				;loop and resets loop back to start of track
				Case 5:	
						
						shiftHeld := GetKeyState("Shift", "P") || GetKeyState("LShift", "P") || GetKeyState("RShift", "P") || MIDI_SHIFT
						
						if(shiftHeld) ; do a reset back to first bar
						{
							Send {ESC}
							Sleep 10
							
							SendInput {Shift up}

							Send !C
							Sleep 10
							Send {Down 12}  ; Presses the down key 4 times.
							Send {Enter}			
							
							Send 1
							Send {Tab}
							Send %RESET_LOOP_END_BAR%
							Send {Enter}	
							
							; hide rewind marker - ie reset or clear it.
							
							Send !V
							Sleep 10
							Send {Down 3} 
							Send {Enter}	
							
						
						}
						else ; send toggle loop
						{		
							Send ^l				
						}
						
				return
				
				;record
				Case 6:	
						
						shiftHeld := GetKeyState("Shift", "P") || GetKeyState("LShift", "P") || GetKeyState("RShift", "P") || MIDI_SHIFT
						
						if(shiftHeld) ; do a reset back to first bar
						{
							Send {ESC}
							Sleep 10
							
							SendInput {Shift up}

							
							Sleep 100
							Send {F2}
							
						
						}
						else ; send toggle loop
						{	
							Send {``} ; record short cut						
										
						}
						
				return
			

				Default:
					MsgBox, % " Bad transport # feature not found: " but
				

				
			
			}
		
		
}





place_rewind_marker()
{

				
				shiftHeld := GetKeyState("Shift", "P") || GetKeyState("LShift", "P") || GetKeyState("RShift", "P") || MIDI_SHIFT
				
				if(shiftHeld) ; toggles show/hide rewind marker
				{
				
					SendInput {Shift up}
					
					Send !V
					Sleep 10
					Send {Down 3} 
					Send {Enter}	
					
				}
				else
				{
					Send {ESC}
					Sleep 10
					SendInput {Shift down}
					Sleep 10
					Send {F2}
					Sleep 10
					SendInput {Shift up}
					sleep 10
					; continue playing
					Send {SPACE}
				}



}

Do_Panic() 
{


WinActivate, ahk_class FreeStyleAppWind
Send {ESC}
Sleep 10
Send {Alt}
Sleep 10
SendInput p
Sleep 10
SendInput o
Sleep 10


return

}




shift_left_right(left, CTRL_key)
{
; Ensure consistent coordinate mode
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen



				newChan := 1
				chan :=1

				solo_mute_toggle := 1
			   startX := 56 ;32 solo 48 mute
				startY := 308 ; 298
				incY := 18
				
				
				ScreenClickX := 0
				ScreenClickY := startY
								

				ScreenClickX := 10 ; offset to check there's a record active red circle first
				
				TotalTracks :=0 ; start at -1 to increament to 1 on first track
				SelectedTrack :=0
				
		
							
				MouseGetPos, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
				
				
	;	MsgBox, ScreenClickX %ScreenClickX%  ScreenClickY %ScreenClickY%			
				
			
	  while (1) 
	  { 

				; red circle check for no more tracks
				
			
			  MouseMove, ScreenClickX, ScreenClickY  
				PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
			 
			 ;ShowYellowRect( ScreenClickX, ScreenClickY  )

				;MsgBox, red circle - chan %chan% The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
					


				if(CheckGBZero(Color) or Color = 0xFFAA00  or Color = 0xB60000 )
				{
						
						 ; It's red
						 ;MsgBox, The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
									

						
						 
						 
						 if( Color = 0xFFAA00) ; bright red
						 {
						   ;MsgBox, Found selected!
						  SelectedTrack := TotalTracks
						   
						 }
				 
				  TotalTracks++
				 
				}
				else
				{
				
	
					 ;MsgBox, finished - no red circle 	 TotalTracks %TotalTracks%  SelectedTrack %SelectedTrack%			
					
						TotalTracks--
				
					break  ; Exit the loop immediately, then continue below				
				}
				
				ScreenClickY := startY + ( (chan-1) * incY)
				chan++
						
				
				
				
	 }
 
  ; --- 1st get track count and active tract
 
 
 
 
 
 if(CTRL_key) ;hide current
 {
 ; re select the correct record enabled track
	ScreenClickX := 56 ; name show/hide
	ScreenClickY := startY + ( (SelectedTrack-1) * incY)

	
	MouseClick, Left, ScreenClickX, ScreenClickY, 1, 0
	
	
	;	MsgBox, CTRL_key pressed = SelectedTrack %SelectedTrack%  ScreenClickX %ScreenClickX%  ScreenClickY %ScreenClickY%			
		
	; MsgBox, click (%ScreenClickX%, %ScreenClickY%) 
	
 
 
 }
 
 
	;MsgBox, TotalTracks %TotalTracks%  SelectedTrack %SelectedTrack%			
					
		
		if(left)
		{
			newChan := SelectedTrack
			newChan--
			
			if( newChan < 1)
				newChan := TotalTracks ; loop to last
		
		
		}
		else
		{
			newChan := SelectedTrack
			newChan++
			
			if( newChan > TotalTracks)
				newChan := 1 ; loop to first
		}



	; re select the correct record enabled track
	ScreenClickX := 10 ; offset to check there's a record active red circle first
	ScreenClickY := startY + ( (newChan-1) * incY)

	
		;MsgBox, newChan %newChan%  ScreenClickX %ScreenClickX%  ScreenClickY %ScreenClickY%			
			
			
			
	; shift not needed clicking the red circles
	; Send {Shift down}
	;Sleep, 5
	MouseClick, Left, ScreenClickX, ScreenClickY, 1, 0
	;Send {Shift up}
		
	; MsgBox, click (%ScreenClickX%, %ScreenClickY%) 
						  
	MouseMove, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
			




}





clear_all() {

; Ensure consistent coordinate mode
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen


global solo_mute_toggle


if(solo_mute_toggle = 0)
{

global MIDI_ALT
global MIDI_SHIFT
global clear_all_disable



 
				chan :=1

				solo_mute_toggle := 1
			   startX := 56 ;32 solo 48 mute
				startY := 308 ; 298
				incY := 18
				
				
				ScreenClickX := 0
				ScreenClickY := 0
								
								
				MouseGetPos, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
				
				
				
			
				
				AltHeld := GetKeyState("Alt", "P") || GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P") || MIDI_ALT
				shiftHeld := GetKeyState("Shift", "P") || GetKeyState("LShift", "P") || GetKeyState("RShift", "P") || MIDI_SHIFT
					

			  ;  ;MsgBox, RAlt is not shiftHeld! %shiftHeld%

			 ;   ;MsgBox, RAlt is not AltHeld! %AltHeld%
				

				if (shiftHeld) {						
				   Send {Shift up}
				} 
				
				
				
				if (AltHeld) {						
				   Send {Alt up}
				} 
				
				
				
					
								; Set click position based on toggle state
								ClickX := startX 
								ClickY := startY + ( (chan-1) * incY)
								
								ScreenClickX := ClickX
								ScreenClickY := ClickY
					
					
					
					
		



  
 ; --- 1st get track count and active tract
 
 startY := 308 ; 298
    ScreenClickX := 10 ; offset to check there's a record active red circle first
	
	TotalTracks :=0 ; start at -1 to increament to 1 on first track
	SelectedTrack :=0
		chan := 1
		
		
  while (1) 
  { 

			; red circle check for no more tracks
			
		
		  MouseMove, ScreenClickX, ScreenClickY  
			PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
		 
		 ;ShowYellowRect( ScreenClickX, ScreenClickY  )

			;MsgBox, red circle - chan %chan% The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
				


			if(CheckGBZero(Color) or Color = 0xFFAA00  or Color = 0xB60000 )
			{
			
			 ; It's red
			 ;MsgBox, The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
						

			 
			 if( Color = 0xFFAA00) ; bright red
			 {
			   ;MsgBox, Found selected!
			  SelectedTrack := TotalTracks
			   
			 }
			 
			 
			 TotalTracks++
			 
			 
			}
			else
			{
			
				;MsgBox, finished - no red circle 	
				
				; MsgBox, TotalTracks %TotalTracks%  SelectedTrack %SelectedTrack%			
				
				if(SelectedTrack = 0) ; nothing record enable, set it to first track
					SelectedTrack :=1
			
				break  ; Exit the loop immediately, then continue below				
			}
			
			ScreenClickY := startY + ( (chan-1) * incY)
			chan++
					
			
			
			
 }
 
  ; --- 1st get track count and active tract
 

		

; --- 2nd remove Solo

 chan := 1
  ScreenClickX := 30 ; solo
	ScreenClickY := startY

  MouseMove, ScreenClickX, ScreenClickY  
	PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
 
; ShowYellowRect( ScreenClickX, ScreenClickY  )

;	 MsgBox, Solo - chan %chan% The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
		


		if(Color = 0x222222) ; or Color = 0xBBBBBB ) ; Solo is on - turn it off or Solo'ed
		{
		; MsgBox, Solo fixing 1
		
		MouseClick, Left, ScreenClickX, ScreenClickY, 1, 0
		 Sleep, 10  ; Small delay to allow UI to update
							
		}
		else
		{
		;	 MsgBox, Solo fixing 2
		
		MouseClick, Left, ScreenClickX, ScreenClickY, 1, 0
		 Sleep, 10  ; Small delay to allow UI to update		 MsgBox, Solo fixing 2
		
		MouseClick, Left, ScreenClickX, ScreenClickY, 1, 0
		 Sleep, 10  ; Small delay to allow UI to update
				
		
		}





; --- remove Solo 





								; Set click position based on toggle state
								ClickX := startX 
								ClickY := startY + ( (chan-1) * incY)
								
								ScreenClickX := ClickX
								ScreenClickY := ClickY
					



								; get color first
								  MouseMove, ScreenClickX, ScreenClickY  
									PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position

								 ;MsgBox, The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
							
								;ShowYellowRect( ScreenClickX, ScreenClickY  )
							
								; ctrl is always used
								 Send {LCtrl down}
								 
								 
								 
								; needs to be  selected first
								if( Color =  0x424242 ) ; dark_selected_color
								{
								
								}
								else
								{
								
								; select all 
								
									MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
									Sleep, 155  ; Small delay for double-click recognition
									;		Sleep,155  ; Small delay for double-click recognition
							
								; mouse MUST be moved down to avoid double clicking the same field!
									ScreenClickY := ScreenClickY +incY



								}
						
							;	PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
							;   MsgBox, The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
							
							
									
								Sleep,55  ; Small delay for double-click recognition
										
							MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
							
								
							if(clear_all_disable = 0) ; do again to enable all 
								{
								Sleep,55  ; Small delay for double-click recognition
									ScreenClickY := ScreenClickY +incY
	
							MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
							
								}
								
							;  PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
 						;	MsgBox, The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
						


	Send {LCtrl up}
	
		ScreenClickY := startY
		ScreenClickX := 48 ;mute

	PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
 	; MsgBox, The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
						





  while (chan < TotalTracks) 
  { 

		

					
			ScreenClickX := 48 ;mute
			
			 MouseMove, ScreenClickX, ScreenClickY  

					PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
					 ; MsgBox, Is speaker?  (%ScreenClickX%, %ScreenClickY%) is %Color%
				
				if(Color = 0x009999) ; or Color = 0xBBBBBB ) ; speaker is on - turn it off or Solo'ed
				{
				
				if(clear_all_disable = 1)
				{
					MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
					 Sleep, 10  ; Small delay to allow UI to update
				 }
				 
				}
				else
				{
					if(clear_all_disable = 0)
					{
						MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
						 Sleep, 10  ; Small delay to allow UI to update
					 }
										
				}


				   ;	MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
					
					chan := chan+1
					
					ScreenClickY := startY + ( (chan-1) * incY)
					PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
					 ; MsgBox, The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
					
			
					
					
					if(Color = 0x000000)
					{
						
					; MsgBox, finished black
					
							  
						MouseMove, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
					
					solo_mute_toggle := 0	
					break
					
					
					}
					
					
					
					if(Color = 0xCACACA)
					{
						
					; MsgBox, finished 0xCACACA
					
							  
						MouseMove, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
					
					solo_mute_toggle := 0	
					break

					
					
					}
					
							
					
					if(Color = 0x777777)
					{
						
					; MsgBox, finished 0xCACACA
					
							  
						MouseMove, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
					
					solo_mute_toggle := 0	
					break

					
					
					}
				
	 } ; while loop
		
		
	
	
	; re select the correct record enabled track
	ScreenClickX := 10 ; offset to check there's a record active red circle first
	ScreenClickY := startY + ( (SelectedTrack-1) * incY)

	; shift not needed clicking the red circles
	; Send {Shift down}
	;Sleep, 5
	MouseClick, Left, ScreenClickX, ScreenClickY, 1, 0
	;Send {Shift up}
		
	; MsgBox, click (%ScreenClickX%, %ScreenClickY%) 
						  
	MouseMove, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
			
	solo_mute_toggle := 0	
	return
	
  } ;if(solo_mute_toggle = 0)

}



solo_mute(chan) {

; Ensure consistent coordinate mode
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen


global MIDI_TAB
global MIDI_ALT
global MIDI_SHIFT
global solo_mute_toggle

if(solo_mute_toggle = 0)
{

				solo_mute_toggle := 1
			   startX := 56 ;32 solo 48 mute
				startY := 308   ; 319
				incY := 18
				
				
				ScreenClickX := 0
				ScreenClickY := 0
								
								
				MouseGetPos, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
				

 
				TabHeld := GetKeyState("Tab", "P") || MIDI_TAB
			
				
				AltHeld := GetKeyState("Alt", "P") || GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P") || MIDI_ALT
				shiftHeld := GetKeyState("Shift", "P") || GetKeyState("LShift", "P") || GetKeyState("RShift", "P") || MIDI_SHIFT
					

			  ;  ;MsgBox, RAlt is not shiftHeld! %shiftHeld%

			 ;   ;MsgBox, RAlt is not AltHeld! %AltHeld%
				
				
				
				
				

				
				
				
	 if (!TabHeld) {			
; --- remove Solo 



	; Set click position based on toggle state
	ClickX := startX 
	ClickY := startY + ( (chan-1) * incY)

	ScreenClickX := ClickX
	ScreenClickY := ClickY

  ScreenClickX := 30 ; offset to check there's a record active red circle first

  MouseMove, ScreenClickX, ScreenClickY  
	PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
 
 ;ShowYellowRect( ScreenClickX, ScreenClickY  )

	 ;MsgBox, Solo - chan %chan% The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
		


		if(Color = 0x222222) ; or Color = 0xBBBBBB ) ; Solo is on - turn it off or Solo'ed
		{
		 ;MsgBox, Solo fixing 1
		
		MouseClick, Left, ScreenClickX, ScreenClickY, 1, 0
		 Sleep, 10  ; Small delay to allow UI to update
							
		}
		else
		{
			 ;MsgBox, Solo fixing 2
		
		MouseClick, Left, ScreenClickX, ScreenClickY, 1, 0
		 Sleep, 10  ; Small delay to allow UI to update		 
		 
		 
		MouseClick, Left, ScreenClickX, ScreenClickY, 1, 0
		 Sleep, 10  ; Small delay to allow UI to update
				
		
		}

; --- remove Solo 
}



			   startX := 56 ;32 solo 48 mute
				startY := 308   ; 319
				incY := 18
				
				
				ScreenClickX := 0
				ScreenClickY := 0


				if (shiftHeld) {
				; Shift is down - next 10
				chan := chan + 10
				} 
				
				
				if (AltHeld) {
				; Alt is down - mute only
				startX := 48 ; mute only
				} 
				else if (TabHeld) {						
				 ;  MsgBox, TabHeld
				   
				   startX := 30 ; sole only
				} 
				

				
					
								; Set click position based on toggle state
								ClickX := startX 
								ClickY := startY + ( (chan-1) * incY)
								
								ScreenClickX := ClickX
								ScreenClickY := ClickY
								
					; Perform single or double click with Shift held
					Send {Shift down}
					Sleep, 15
				   
				   
						MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
						Sleep, 55  ; Small delay for double-click recognition
					
							
				   Send {Shift up}
					
					
				   
								; get color first
								;  MouseMove, ScreenClickX, ScreenClickY  
									PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position

								NewchangeColor  := Color 
								
														
														
							;MsgBox, The RGB color at (%ScreenClickX%, %ScreenClickY%) is %Color%
							
				;   ShowYellowRect( ScreenClickX, ScreenClickY  )

				   
						if (AltHeld or TabHeld) {
						; Alt is down -  mute or solo only
						 ; do nothing, no more clicking
						 
						 ;MsgBox, AltHeld or TabHeld nothing
						} 
						else{
						
						
											

								; next action, chck to (un)mute clicks
								ScreenClickX := 48

								
									MouseMove, ScreenClickX, ScreenClickY  

									PixelGetColor, Color, %ScreenClickX%, %ScreenClickY%, RGB  ; Get RGB color at mouse position
									;MsgBox, Is speaker?  (%ScreenClickX%, %ScreenClickY%) is %Color%
									
						
							;	ShowYellowRect( ScreenClickX, ScreenClickY  )
								
								if(NewchangeColor = 0x424242) ; was set on
								{
									
									 ;MsgBox, was set to on (%ScreenClickX%, %ScreenClickY%) is %Color%
						
									if(Color = 0x009999) ; or Color = 0xBBBBBB ) ; speaker is on - turn it off or Solo'ed
									{

										 ;MsgBox, nothing1 (%ScreenClickX%, %ScreenClickY%) is %Color%
						
									}
									else
									{
									
									
										 ;MsgBox, was set to on - setting speaker to on, click here (%ScreenClickX%, %ScreenClickY%) is %Color%
						
										MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
										Sleep, 55  ; Small delay for double-click recognition
					
									}
									
									
								}
								else ;was  set off								
								{
								 ;MsgBox, was set to off (%ScreenClickX%, %ScreenClickY%) is %Color%
						
								
									if(Color = 0x009999) ; or Color = 0xBBBBBB ) ; speaker is on - turn it off or Solo'ed
									{
									
										 ;MsgBox, was set to off - setting speaker to off - click here (%ScreenClickX%, %ScreenClickY%) is %Color%
						
										MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
										Sleep, 55  ; Small delay for double-click recognition
									}
									else
									{
										
					
										 ;MsgBox, nothing2 (%ScreenClickX%, %ScreenClickY%) is %Color%
						
									}
								
								}
								
						}
					  
				MouseMove, MouseX, MouseY  ; Store in global MouseX, MouseY (screen coordinates)
				
					
				Sleep, 55  
		solo_mute_toggle := 0	
	Sleep, 55  		

	}


		;	;MsgBox, muting chan:  %chan% 
				return
	
}

; ------------------- Horrible code! - sorry!


; --------------------- zoom
; Left mouse button + WheelUp: Send F9
MButton & WheelUp::
Send {F9}
return

; Left mouse button + WheelDown: Send Shift+F9
MButton & WheelDown::
Send {Shift down}
Send {F9}
Send {Shift up}
return

; ----------------- ~Ctrl and zoom



; Left mouse button + WheelUp: Send F9
Ctrl  & WheelUp::
Send {F9}
return

; Left mouse button + WheelDown: Send Shift+F9
Ctrl & WheelDown::
Send {Shift down}
Send {F9}
Send {Shift up}
return



; ------------------------- zoom

RemoveTooltip:
    ToolTip
return



; Right mouse button held + Middle mouse button press: Alt+W, 3rd item
RButton & MButton::
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





; Right mouse button held + Middle mouse button press: Alt+W, 3rd item
;  Alr + CTRL Right Mouse Button
!^RButton::
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



; Holding Alt toggles between note select and paint features, pressing Alt with right mouse commits the toggles , doing this twice quickly launches the Brush/Cursor Settings window.

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
    if (TimeDelta <= 32 && TimeDelta > 0) {
        MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
        Sleep, 55 ; Small delay for double-click recognition
     Sleep, 55
 MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
  Sleep, 55
    } else {
      MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
	   Sleep, 55
    }
} else {
    ;MsgBox, U_ZoomDocStyle1 not found!
}
return


; Holding Alt toggles between note select and paint features, pressing Alt with right mouse commits the toggles , doing this twice quickly launches the Brush/Cursor Settings window.
;  Alt  Right Mouse Button
!RButton::

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
    if (TimeDelta <= 32 && TimeDelta > 0) {
        MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
        Sleep, 55 ; Small delay for double-click recognition
        MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
	  Sleep, 55
    } else {
        MouseClick, Left, %ScreenClickX%, %ScreenClickY%, 1, 0
		 Sleep, 55
    }
} else {
    ;MsgBox, U_ZoomDocStyle1 not found!
}
return



!1:: ;Alt
+1:: ;shift
+!1:: ;shift Alt
Tab & 1::
1::
solo_mute(1)  ; solo_mutes sound
   return

+!2::  
!2::   
+2::
Tab & 2::
2::
solo_mute(2)  ; solo_mutes sound
   return
+!3:: 
!3::
+3::
Tab & 3::
3::
solo_mute(3)  ; solo_mutes sound
   return


+!4:: 
!4::
+4::
Tab & 4::
4::
solo_mute(4)  ; solo_mutes sound
   return


+!5:: 
!5::
+5::
Tab & 5::
5::
solo_mute(5)  ; solo_mutes sound
   return



+!6:: 
!6::
+6::
Tab & 6::  
6::
solo_mute(6)  ; solo_mutes sound
   return


+!7:: 
!7::
+7::
Tab & 7::
7::
solo_mute(7)  ; solo_mutes sound
   return


+!8:: 
!8::
+8::
Tab & 8:: 
8::
solo_mute(8)  ; solo_mutes sound
   return


+!9:: 
!9::
+9::
Tab & 9::
9::
solo_mute(9)  ; solo_mutes sound
   return


+!0:: 
!0::
+0::
Tab & 0::
0::
solo_mute(10)  ; solo_mutes sound
   return





; --- PC Keyboard button mapping - Change at your own Risk!
; see for info on shortcut keys https://www.autohotkey.com/docs/v1/Hotkeys.htm


; WASD

w::
;Toggle Metronome     W key toggles metronome (CTRL Y) - double hit for metronome settings.
do_metronome() 
return
   
   
+a::
a::
; Set Rewind Marker       A  Key,  place rewind marker ( remapped from Shift F2). 	
place_rewind_marker()
return


+s::   
s::
;Loop toggle                S key,  toggles loop, With shift  key it enables and resets the loop back to the start - Default length 
do_transport(5) 
return
   
!d::   
d::
;Forward loop:             D Key, Moves forward the loop markers, see Advance Record Loop (Ctrl F3)
do_transport(2) 
return
   
; WASD


q::
; MIDI Panic           Q key MIDI Panic - sends off for everything MIDI.
Do_Panic() 
return
   
e::
; Reset players      E Key will hide and mute or show and unmute and unsolo (resest) ALL players (tracks) - Configurable via the script (clear_all_disable).
clear_all() 
return

 
  

+b::
b::
; Record:       B Key, toggles record (` shortcut)
do_transport(6)
return


n::
; Pause          N key mapped to FreeStyle's pause button which holds the current position, without sending note off's etc so it is audible.
do_transport(3)
return

m::
;   M key mapped to duplicate the current take (Alt F7).
do_dup_take()
return
 
v::
do_EnsembleToggle()
return 


;shift
+Right::
; MsgBox,  shift_left_right 0
shift_left_right(0, 1)
return

+Left::
; MsgBox,  shift_left_right 1
shift_left_right(1, 1)
return
;shift


; CTRL
+Down::
; MsgBox,  shift_left_right 0
shift_left_right(0, 0)
return


+Up::
; MsgBox,  shift_left_right 1
shift_left_right(1, 0)
return
; CTRL



   
; --- PC Keyboard button mapping - Change at your own Risk!
; see for info on shortcut keys https://www.autohotkey.com/docs/v1/Hotkeys.htm



#IfWinActive

LAlt & Tab::AltTab
RAlt & Tab::AltTab