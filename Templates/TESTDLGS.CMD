/* TESTDLGS.CMD */

'@echo off'
call RxFuncAdd 'VInit', 'VREXX', 'VINIT'
initcode = VInit()
if initcode = 'ERROR' then signal CLEANUP

signal on failure name CLEANUP
signal on halt name CLEANUP
signal on syntax name CLEANUP

/* example VMsgBox call */

msg.0 = 4
msg.1 = 'This is a 4 line message box dialog.'
msg.2 = 'This is the line 2.  Line 3 is blank.'
msg.3 = ''
msg.4 = 'Press YES or NO to continue...'

call VDialogPos 50, 50
rb = VMsgBox('TESTDLGS.CMD', msg, 6)
if rb = 'YES' then do
   msg.0 = 1
   msg.1 = 'You pressed YES'
end
else do
   msg.0 = 1
   msg.1 = 'You pressed NO'
end
call VMsgBox 'VMsgBox Result', msg, 1

/* VInputBox example */

prompt.0 = 2
prompt.1 = 'Enter your name:'
prompt.2 = '(Last name first, First name last)'
prompt.vstring = 'Doe John'
button = VInputBox('VInputBox example', prompt, 20, 3)

if button = 'OK' then do
   msg.0 = 3
   msg.1 = 'You entered the name:'
   msg.2 = prompt.vstring
   msg.3 = 'and you pressed OK'
end
else do
   msg.0 = 1
   msg.1 = 'You pressed CANCEL'
end
call VMsgBox 'VInputBox Result', msg, 1

/* VMultBox example */

prompt.0 = 2   /* 2 prompt lines */
prompt.1 = 'User ID'
prompt.2 = 'Password'

width.0 = 2
width.1 = 10   /* widths in character units */
width.2 = 8    /* for both entryfields */

hide.0 = 2
hide.1 = 0     /* echo the User ID input */
hide.2 = 1     /* don't echo the Password */

answer.0 = 2
answer.1 = ''  /* these are the default strings */
answer.2 = ''  /* which will contain the input */

button = VMultBox('VMultBox example', prompt, width, hide, answer, 3)

if button = 'OK' then do
   call VMsgBox 'VMultBox Result', answer, 1
end
else do
   msg.0 = 1
   msg.1 = 'You pressed CANCEL'
   call VMsgBox 'VMultBox Result', msg, 1
end

/* VListBox example */

list.0 = 17
list.1  = 'OS/2 2.0 Standard Edition'
list.2  = 'OS/2 2.0 Extended Edition'
list.3  = 'MMPM/2 Multimedia Extensions'
list.4  = 'Windows 3.0 Multimedia Extensions'
list.5  = 'Adobe Type Manager'
list.6  = 'C-Set/2 Compiler'
list.7  = 'OS/2 2.0 Programmer Toolkit'
list.8  = 'WorkFrame/2'
list.9  = 'Lan Server'
list.10 = 'Lan Requester'
list.11 = 'TCP/IP'
list.12 = 'PMGlobe Demo Program'
list.13 = 'ASYNC Terminal Emulator'
list.14 = 'IPFC Preprocessor'
list.15 = 'VREXX'
list.16 = 'OS/2 2.0 Corrective Service'
list.17 = 'IBM SAA CUA Controls Library'
list.vstring = list.15          /* default selection */

call VDialogPos 25, 25
call VListBox 'Select a Product and Press YES', list, 35, 8, 4
msg.0 = 1
msg.1 = list.vstring
call VMsgBox 'VListBox Selection', msg, 1

/* test of VTableBox */

table.rows = 5
table.cols = 3

table.label.1 = 'Name'
table.label.2 = 'Division'
table.label.3 = 'Serial Number'

table.width.1 = 25
table.width.2 = 10
table.width.3 = 15

table.1.1 = 'Mary Jacobs'
table.1.2 = 20
table.1.3 = '243611'

table.2.1 = 'Joe Johnson'
table.2.2 = 19
table.2.3 = '837462'

table.3.1 = 'Henry Hill'
table.3.2 = 79
table.3.3 = '832628'

table.4.1 = 'Ruby Potts'
table.4.2 = 11
table.4.3 = '937567'

table.5.1 = 'Gary Williams'
table.5.2 = 22
table.5.3 = '086203'

button = VTableBox('Employee List', table, 1, 40, 10, 1)

msg.0 = 2
msg.1 = 'Button pressed was' button
msg.2 = 'Selection number =' table.vstring
call VMsgBox 'VTableBox Result', msg, 1

/* VRadioBox example */

list.0 = 10
call VRadioBox 'Select 1 item', list, 1
msg.0 = 1
msg.1 = list.vstring
call VMsgBox 'Selected item', msg, 1

/* test of VCheckBox */

list.0 = 10
sel.0 = 2
sel.1 = list.2
sel.2 = list.3
call VCheckBox 'Select items', list, sel, 1
if sel.0 > 0 then do
   call VMsgBox 'Selected items', sel, 1
end

/* VColorBox example */

call VDialogPos 75, 75
color.fore = 'YELLOW'
color.back = 'BLUE'
call VColorBox color
msg.0 = 2
msg.1 = 'Foreground color is' color.fore
msg.2 = 'Background color is' color.back
call VMsgBox 'Color selections', msg, 1

/* VFontBox example */

font.type = 'HELVB'
font.size = 25
call VFontBox font
msg.0 = 2
msg.1 = 'Font type is' font.type
msg.2 = 'Font size is' font.size
call VMsgBox 'Font selection', msg, 1

/* test of VFileBox */

call VDialogPos 10, 50
button = VFileBox('Pick a file...', 'c:\os2\*.exe', 'file')
msg.0 = 3
msg.1 = 'File name picked was:'
msg.2 = file.vstring
msg.3 = 'Button pressed was' button
call VMsgBox 'VFileBox Result', msg, 1

/* end of CMD file */

CLEANUP:
   call VExit

exit
