@echo on
mode com2:9600,N,8,1,idsr=on,odsr=on,octs=on,xon=on,rts=on,dtr=on,buffer=auto
rem * EPRWTOS2 120
sleep 2
d:
cd \max
silt max -u

Rem Compile any changed bulletins, etc
cd misc
\max\mecca *.mec -t


:MainLoop

cd \cmd
start "Update file directories..." /B /I /C /pgm "updbbsal.cmd"

if exist \cmd\BackDoor.cmd start "Instructions from home..." /B /I /C /pgm "BackDoor.cmd"
if exist \cmd\BackDoor.cmd del BackDoor.005
if exist \cmd\BackDoor.cmd ren BackDoor.004 BackDoor.005
if exist \cmd\BackDoor.cmd ren BackDoor.003 BackDoor.004
if exist \cmd\BackDoor.cmd ren BackDoor.002 BackDoor.003
if exist \cmd\BackDoor.cmd ren BackDoor.001 BackDoor.002
if exist \cmd\BackDoor.cmd ren BackDoor.cmd BackDoor.001

cd \max

MAXP max -w %1 %2 %3 %4

if errorlevel 255 goto Quit
if errorlevel  12 goto MainLoop
if errorlevel  11 goto MainLoop
if errorlevel   5 goto MainLoop
if errorlevel   4 goto Mainloop
if errorlevel   3 goto MainLoop
if errorlevel   2 goto MainLoop
if errorlevel   1 goto Quit

:Quit
