@echo off
if "%1"=="" goto USAGE
copy /b c:\cmd\se.exe+%1.lzh /b %1.exe && echo %1.EXE has been created.
goto end
:Usage
echo Usage: MSE [lzh file]
echo        Do NOT specify .lzh extension.
:end
