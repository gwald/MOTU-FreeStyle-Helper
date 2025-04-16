Ahk2Exe.exe /in FS_Helper.ahk /base "ANSI 32-bit.bin" /icon 56.ico
dir FS_Helper.exe

echo killing FS_Helper.exe just in case it's running
taskkill /F /IM FS_Helper.exe

copy /Y FS_Helper.exe ..

echo running
start ..\FS_Helper.exe