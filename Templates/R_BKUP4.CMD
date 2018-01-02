/* BKUP4.CMD
   Backup daily working files to diskette at the end of the day
*/
'@echo off'

/* Clear the screen and remind user to put a disk in */
'cls'
say 'Put a disk in drive A'
say 'and press Enter when ready'
pull .
'copy \work\docfiles\*.txt a:' /* Backup working doc files */
'copy '\reports\xfiles\*.txt a:' /* Backup daily report files */
say 'Backup is complete on drive A'
