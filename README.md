# MOTU-FreeStyle-Helper

FS_Helper - Mark of the Unicorn - FreeStyle midi sequencer helper stuff.

From: [https://github.com/gwald/MOTU-FreeStyle-Helper](https://github.com/gwald/MOTU-FreeStyle-Helper)
 
 [Download](https://github.com/gwald/MOTU-FreeStyle-Helper/archive/refs/heads/main.zip) and extract all files into where your FreeStyle.exe is on your drive and run FS_Helper/build_deploy.bat before using.

This is a AutoHotKey v1.1 script to improve the user interface of FreeStyle, mostly mouse driven.
* When starting FS_Helper.exe it will also launch FS and when FS is closed it will self terminate.
* F1 launches the index.html single help file in the FreeStyle_extended_help folder if it's not found, it will try to launch the PDF version FreeStyle_extended_help.pdf, lastly if not found it will launch the normal windows help file, FreeStyle.hlp (Requires winhlp32 for Windows Vista or newer).
* Shift F1 downloads then launches the FreeStyle (v1 Mac only) manual PDF.
* Mouse interface only tested in Graphic (grid) view, with a single .FSL project open:
* * Scroll wheel moves the page forward and backwards (no shortcut available!).
* * Right mouse button with scroll wheel moves the page up and down (no shortcut available!).
* * Middle mouse button with scroll wheel zooms in (F9) and out (Shift F9).
* * Left mouse button with middle mouse button resets the view (F11), stops playing (ESC) and applies the "Tile Pallet Left" window setting.
* * Left mouse button with Right mouse button toggles note select and paint features, doing it twice launches the Brush/Cursor Settings window.


[Extended help HTML document](https://htmlpreview.github.io/?https://github.com/gwald/MOTU-FreeStyle-Helper/blob/main/FreeStyle_extended_help/index.html)

[Extended help PDF document](https://github.com/gwald/MOTU-FreeStyle-Helper/blob/main/FreeStyle_extended_help/FreeStyle_extended_help.pdf)

[FreeStyle V1 (Mac only) manual](https://archive.org/details/stx_Mark_of_the_Unicorn_FreeStyle_for_Macinotsh_manual)
