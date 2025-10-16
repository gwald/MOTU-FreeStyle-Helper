; https://forums.steinberg.net/t/autohotkey-and-midi/916839/15
Global MIDI_DEVICE_STRUCT_LENGTH := 44
Global h_MIDI_IN, h_MIDI_OUT
Global MIDIHDR2

Global MIDI_OUT_CH := 1
Global MIDI_IN_CHANNEL_FILTER := -1

; MIDI event types
Global MIDI_OPEN := 0x3C1
Global MIDI_CLOSE := 0x3C2
Global MIDI_DATA := 0x3C3
Global MIDI_LONGDATA := 0x3C4
Global MIDI_ERROR := 0x3C5
Global MIDI_LONGERROR := 0x3C6
Global MIDI_MOREDATA := 0x3CC

Global SysexMessage := []
SysexMessage.setCapacity(1024)
Global SysexBuffer := []
Global bufferIndex := 0

Global midiEvent := {}
Global midiLabelPrefix := "Midi"

getMidiInDevices()
{
	_MidiDevices := []
	deviceCount := DllCall( "winmm.dll\midiInGetNumDevs" )
	Loop %deviceCount%
	{
		deviceNumber := A_Index - 1
		VarSetCapacity(midiStruct, MIDI_DEVICE_STRUCT_LENGTH, 0)
		result := DllCall("winmm.dll\midiInGetDevCapsA", "uint", deviceNumber, "ptr", &midiStruct, "uint", MIDI_DEVICE_STRUCT_LENGTH)
		If (result) {
			MsgBox, Failed to query MIDI in device. `nDevice number=%deviceNumber%
			return
		}
		deviceName := StrGet(&midiStruct + 8, MIDI_DEVICE_NAME_LENGTH, "CP0")
		_MidiDevices.Push(deviceName)
	}
	return _MidiDevices
}

getMidiOutDevices()
{
	_MidiDevices := []
	deviceCount := DllCall( "winmm.dll\midiOutGetNumDevs" )
	Loop %deviceCount%
	{
		deviceNumber := A_Index - 1
		VarSetCapacity(midiStruct, MIDI_DEVICE_STRUCT_LENGTH, 0)
		result := DllCall("winmm.dll\midiOutGetDevCapsA", "uint", deviceNumber, "ptr", &midiStruct, "uint", MIDI_DEVICE_STRUCT_LENGTH)
		If (result) {
			MsgBox, Failed to query MIDI out device. `nDevice number=%deviceNumber%
			return
		}
		deviceName := StrGet(&midiStruct + 8, MIDI_DEVICE_NAME_LENGTH, "CP0")
		_MidiDevices.Push(deviceName)
	}
	return _MidiDevices
}

closeMidiOut()
{
	if (h_MIDI_OUT) {
		result := DllCall("winmm.dll\midiOutStop", "uint", h_MIDI_OUT)
		If (result or ErrorLevel) {
			MsgBox, % "There was an Error stopping the MIDI Out port.`nError code: " . result . "`nErrorLevel = " . ErrorLevel
			return
		}
		result := DllCall("winmm.dll\midiOutClose", UINT, h_MIDI_OUT)
		If (result or ErrorLevel) {
			MsgBox, % "There was an Error closing the MIDI Out port.`nError code: " . result . "`nErrorLevel = " . ErrorLevel
			return
		}
		h_MIDI_OUT :=
	}
}

openMidiOut(devID)
{
	h_MIDI_OUT := 0000
	result := DllCall("winmm.dll\midiOutOpen", "ptr*", h_MIDI_OUT, "uint", devID, "ptr", 0, "ptr", 0, "uint", 0)
	If (result or ErrorLevel)
	{
		MsgBox, % "There was an Error opening the MIDI Out port with ID=" . devID . "`nError code: " . result . "`nErrorLevel = " . ErrorLevel
		return 1
	}
}

MIDI_CC(control, value, channel:=-1)
{
	If (channel = -1)
		channel:=MIDI_OUT_CH
	midiOutShortMsg(((value&0xff)<<16)|((control&0xff)<<8)|(channel|0xB0))
}

MIDI_NoteOn(noteValue, velocity:=127, channel:=-1)
{
	If (channel = -1)
		channel:=MIDI_OUT_CH
	midiOutShortMsg(((velocity&0xff)<<16)|((noteValue&0xff)<<8)|(channel|0x90))
}

MIDI_NoteOff(noteValue, velocity:=64, channel:=-1)
{
	If (channel = -1)
		channel:=MIDI_OUT_CH
	midiOutShortMsg(((velocity&0xff)<<16)|((noteValue&0xff)<<8)|(channel|0x80))
}

midiOutShortMsg(msg)
{ 
	result := DllCall("winmm.dll\midiOutShortMsg", "ptr", h_MIDI_OUT, "uint", msg)
	If (result or ErrorLevel)  {
		MsgBox, % "Error sending ShortMsg.`n" . result . "`n" . ErrorLevel
		return
	}
}

closeMidiIn() {
	if !(h_MIDI_IN)
		return
	result := _stopMidiIn()
	if (result = -1)
		return
	result := _resetMidiIn()
	Loop, 9 {
		result := DllCall("winmm.dll\midiInClose", UINT, h_MIDI_IN)
		If !(result or ErrorLevel) {
			h_MIDI_IN :=
			Return 0
		}
		Sleep 250
	}
	MsgBox, Failed to close midi in device`nresult=%result%`nErrorLevel=%nErrorLevel%
	return -1
}

_stopMidiIn() {	
	Loop, 9 {
		result := DllCall("winmm.dll\midiInStop", "uint", h_MIDI_IN)
		If !(result or ErrorLevel) {
			Return 0
		}
		Sleep 250
	}
	MsgBox, Failed to stop midi in device`nresult=%result%`nErrorLevel=%nErrorLevel%
	return -1
}

_resetMidiIn() {
	result := DllCall("winmm.dll\midiInReset", "uint", h_MIDI_IN)
	If (result or ErrorLevel)
	MsgBox, Failed to reset midi in device`nresult=%result%`nErrorLevel=%nErrorLevel%
}

openMidiIn(devID)
{
	Gui, +LastFound
	hWnd := WinExist()
	DllCall("LoadLibrary", "str", "winmm.dll", "ptr")
	result := DllCall("winmm.dll\midiInOpen", "ptr*", h_MIDI_IN, "uint", devID, "ptr", hWnd, "uint", 0, "uint", MIDI_CALLBACK_WINDOW := 0x10000)
	if (result or ErrorLevel)
	{
		msgbox % "There was an error opening the MIDI In port `nresult = " result "`nErrorLevel = " ErrorLevel
		return 1
		;exitapp
	}
	result := DllCall("winmm.dll\midiInStart", "ptr", h_MIDI_IN)
	if (result or ErrorLevel)
	{
		msgbox % "There was an error starting the MIDI In port  `nresult = " result "`nErrorLevel = " ErrorLevel
		return 2
		;exitapp
	}

	buffer_size := 64000   ; up to 64k
	VarSetCapacity(midiInBuffer, buffer_size, 0)
	VarSetCapacity(MIDIHDR2, 10*A_PtrSize+8, 0)
	NumPut(&midiInBuffer, MIDIHDR2, 0)
	NumPut(buffer_size, MIDIHDR2, A_PtrSize, "uint")
	NumPut(buffer_size, MIDIHDR2, A_PtrSize+4, "uint")
	result := DllCall("winmm.dll\midiInPrepareHeader", "ptr", h_MIDI_IN, "ptr", &MIDIHDR2, "uint", 10*A_PtrSize+8)
	if (result or ErrorLevel)
	{
		msgbox % "There was an error preparing a MIDI In header `nresult = " result "`nErrorLevel = " ErrorLevel
		return 3
		;exitapp
	}
	result := DllCall("winmm.dll\midiInAddBuffer", "ptr", h_MIDI_IN, "ptr", &MIDIHDR2, "uint", 10*A_PtrSize+8)
	if (result or ErrorLevel)
	{
		msgbox % "There was an error adding a MIDI In buffer `nresult = " result "`nErrorLevel = " ErrorLevel
		return 4
		;exitapp
	}
	;OnMessage(MIDI_OPEN, "midiInCallback")
	;OnMessage(MIDI_CLOSE, "midiInCallback")
	OnMessage(MIDI_DATA, "midiInCallback")
	OnMessage(MIDI_LONGDATA, "midiInSysExCallback")
	;OnMessage(MIDI_ERROR, "midiInCallback")
	;OnMessage(MIDI_LONGERROR, "midiInCallback")
	;OnMessage(MIDI_MOREDATA, "midiInCallback")
}

midiInCallback(wParam, lParam, msg)
{
	midiEvent := {}
	labelCallbacks := [midiLabel]

	highByte := lParam & 0xF0 
	lowByte := lParam & 0x0F	;MIDI channel
	data1 := (lParam >> 8) & 0xFF
	data2 := (lParam >> 16) & 0xFF
	if (MIDI_IN_CHANNEL_FILTER != -1 and lowByte != MIDI_IN_CHANNEL_FILTER)
		return
	
	if (highByte == 0x80)
	{
		midiEvent.status := "NoteOff"
		midiEvent.noteNumber := data1
		midiEvent.velocity := data2
		labelCallbacks.Push(midiLabelPrefix . midiEvent.status . midiEvent.noteNumber)	; Add label for the specific event. E.g. "MidiNoteOff60:"
	}
	else if (highByte == 0x90)
	{
		midiEvent.status := "NoteOn"
		midiEvent.noteNumber := data1
		midiEvent.velocity := data2
		labelCallbacks.Push(midiLabelPrefix . midiEvent.status . midiEvent.noteNumber)
	}
	else if (highByte == 0xA0)
	{
		midiEvent.status := "Aftertouch"
		midiEvent.noteNumber := data1
		midiEvent.aftertouch := data2
	}
	else if (highByte == 0xB0)
	{
		midiEvent.status := "ControlChange"
		midiEvent.controller := data1
		midiEvent.value := data2
		labelCallbacks.Push(midiLabelPrefix . midiEvent.status . midiEvent.controller)
	}
	else if (highByte == 0xC0)
	{
		midiEvent.status := "ProgramChange"
		midiEvent.program := data1
		labelCallbacks.Push(midiLabelPrefix . midiEvent.status . midiEvent.program)
	}
	else if (highByte == 0xD0)
	{
		midiEvent.status := "ChannelPressure"
		midiEvent.pressure := data1
	}
	else if (highByte == 0xE0)
	{
		midiEvent.status := "PitchBend"
		midiEvent.pitchBend := ( data2 << 7 ) + data1
	}
	
	labelCallbacks.Push(midiLabelPrefix . midiEvent.status)	; Add a label callback for the status, e.g. "MidiNoteOn:", "MidiControlChange:"
	
	; Jump to the event lables if they exist
	For labelIndex, labelName In labelCallbacks
   {
		If IsLabel(labelName)
			Gosub %labelName%
   }
}

midiInSysExCallback(wParam, lParam, msg)
{
   Critical
	SysexMessage := []
	SysexMessage.setCapacity(1024)
   Data := NumGet(lParam+0, 0, "ptr")
   BytesRecorded := NumGet(lParam+0, A_PtrSize+4, "uint")
   loop % BytesRecorded
      SysexMessage.Push(Format("{:02X}", NumGet(Data+0, A_Index-1, "uchar")))
   result := DllCall("winmm.dll\midiInAddBuffer", "ptr", h_MIDI_IN, "ptr", &MIDIHDR2, "uint", 10*A_PtrSize+8)
	if (result or ErrorLevel)
	{
		MsgBox, % "midiInAddBuffer from midiInSysExCallback failed!`n" . "Result: " . result . "`nErrorLevel = " . ErrorLevel
		return
	}
	SysexBuffer := SysexMessage
	labelName := midiLabelPrefix . "SysEx"
	If IsLabel(labelName)
		GoSub, %labelName%
}