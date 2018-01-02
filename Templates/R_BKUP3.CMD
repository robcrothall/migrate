/* BKUP3.CMD */
'@echo off'
say 'Put a disk in drive A'
say 'and press Enter when ready'
pull .
'cd \work\docfiles'
'copy *.txt a:'
'cd \reports\xfiles\'
'copy *.txt a:'
say 'Backup is complete on drive A'
