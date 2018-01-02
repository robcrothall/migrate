/* TESTWIN.CMD */

'@echo off'
call RxFuncAdd 'VInit', 'VREXX', 'VINIT'
initcode = VInit()
if initcode = 'ERROR' then signal CLEANUP

signal on failure name CLEANUP
signal on halt name CLEANUP
signal on syntax name CLEANUP

/* display the version number of VREXX */

ver = VGetVersion()
msg.0 = 1
msg.1 = 'VREXX version # ' ver
call VMsgBox 'TESTWIN.CMD', msg, 1

/* open a window and draw some text */

win.left   = 20
win.right  = 70
win.top    = 80
win.bottom = 40
id = VOpenWindow('My VREXX Window', 'RED', win)

text.1 = 'This is a VREXX window, created with a call to VOpenWindow.'
text.2 = 'The window currently has a title = My VREXX Window, and it'
text.3 = 'has a red background, which can be changed by a call to the'
text.4 = 'VBackColor function.  The font is 12 point Times Roman.'

call VForeColor id, 'WHITE'
call VSetFont id, 'TIME', 12

x = 10
y = 900
do i = 1 to 4
   call VSay id, x, y, text.i
   y = y - 50
end

/* now display a message box */

msg.0 = 2
msg.1 = 'Press OK to change the window title, the'
msg.2 = 'window background color, and the font...'
call VMsgBox 'TESTWIN.CMD', msg, 1

/* change the title and background color */

call VSetTitle id, 'A New Title!'
text.2 = 'The new window title = A New Title!, and it'

call VClearWindow id
call VBackColor id, 'BLUE'
text.3 = 'has a blue background, which can be changed by a call to the'
call VForeColor id, 'WHITE'

/* change the font */

call VSetFont id, 'HELVB', 15
text.4 = 'VBackColor function.  The font is now 15 point Helvetica Bold.'

/* redraw the text in the window */

x = 10
y = 900
do i = 1 to 4
   call VSay id, x, y, text.i
   y = y - 60
end

/* now move and resize the window */

msg.0 = 3
msg.1 = 'Now the window will be cleared and moved around'
msg.2 = 'and resized using the VResize function.  Press'
msg.3 = 'OK to continue...'
call VMsgBox 'TESTWIN.CMD', msg, 1

call VClearWindow id

win.left   = 5
win.right  = 15
win.bottom = 80
win.top    = 95
call VResize id, win

do 8
   win.left   = win.left   + 5
   win.right  = win.right  + 10
   win.top    = win.top    - 5
   win.bottom = win.bottom - 10
   call VResize id, win
end

/* put up a message box */

msg.0 = 1
msg.1 = 'Press Cancel to end...'
call VMsgBox 'TESTWIN.CMD', msg, 2

call VCloseWindow id

/* end of CMD file */

CLEANUP:
   call VExit

exit
