/* FLDSHAD.CMD: Sample code using REXXUTIL's SysCreateObject function   */
/* Builds a folder on the DeskTop places a program object in it then    */
/* places a shadow of the program object on the DeskTop.                */
/* Mike Lamb: MIKELAMB/KGNVMC                                           */
/* Load REXXUTIL */
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs


result = RxMessageBox("Add a Test Folder to the Desktop", ,
               "Folder Demo", "EnterCancel", "Question")

if result = 2 then return 0

classname  ='WPFolder'
title      ='Test Folder'
location   ='<WP_DESKTOP>'
setup      ='OBJECTID=<TEST2_FOLDER>'
Call BldObj

result = RxMessageBox("Put a Program Object in the Folder", ,
               "Folder Demo", "EnterCancel", "Question")
if result = 2 then return 0

classname   ='WPProgram'
title       ='SYSLEVEL-VIO'
location    ='<TEST2_FOLDER>'
setup       ='OBJECTID=<TEST2_SYSLVIO>;'||,
             'EXENAME=\OS2\SYSLEVEL.EXE;'||,
             'PROGTYPE=WINDOWABLEVIO;'
Call BldObj

result = RxMessageBox("Put a Shadow Object on the Desktop" ,,
               "Folder Demo", "EnterCancel", "Question")
if result = 2 then return 0

classname   ='WPShadow'
title       ='SYSLEVEL-VIO'
location    ='<WP_DESKTOP>'
setup       ='SHADOWID=<TEST2_SYSLVIO>'
Call BldObj

Exit

/* Build Object */
BldObj:

/* Build object using REPLACE as duplicateflag */
result = SysCreateObject(classname, title, location, setup, 'R')

If result\=1 Then
     junk = RxMessageBox("Object failed to create" ,,
               "Demo Failure", "OK", "ERROR") ;

Return
