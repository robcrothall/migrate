@echo on
mode com2:9600,N,8,1,idsr=off,odsr=off,octs=off
rem * EPRWTOS2 120

cd \max
silt max -u

:MainLoop

cd \max
cd misc
\max\mecca *.mec -t
cd ..

/*call updbbsal;*/
start "Update file directories..." /win /I /C /pgm "updbbsal.cmd"
cd \max

MAXP max -w %1 %2 %3 %4

if errorlevel 255 goto Quit
if errorlevel  12 goto MainLoop
if errorlevel  11 goto MainLoop
if errorlevel   5 goto MainLoop
if errorlevel   4 goto MainLoop
if errorlevel   3 goto MainLoop
if errorlevel   2 goto MainLoop
if errorlevel   1 goto Quit

:Quit
