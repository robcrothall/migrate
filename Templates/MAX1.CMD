@echo on
mode com1:9600,N,8,1,idsr=off,odsr=off,octs=off
rem * EPRWTOS2 120
:MainLoop

cd \barclays
call bbs
cd \max\file\pvt
call bbs
cd \max\file\laser
call bbs
cd \max\file\ind
call bbs
cd \max\file\copi
call bbs
cd \max\file\uncheck
call bbs
cd \max\file\gen
call bbs
cd \max\file\util
call bbs
cd \max\file\max
call bbs
cd \bat
call bbs
cd \cmd
call bbs
cd \wpfiles
call bbs
cd \barclays
call bbs
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
                               