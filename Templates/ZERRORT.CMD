&TRACE OFF
&IF &INDEX = 1 &IF &1 = ? &GOTO -TELL
&GOTO -RUN
-TELL &TYPE FORMAT:     &0
&BEGTYPE
PURPOSE:    To test the ZERROR EXEC.
USAGE:      Read through the comments of this exec, and then run it.
AUTHOR:     R. CROTHALL
Written:    16 MAR 82.
CHANGED BY: R. Crothall
Last change: 21 Mar 90
&END
&EXIT 1
-RUN
&TYPE Test ZERROR EXEC
EXEC ZERROR ?
&READ VARS *
CLRSCRN
CP M ZFAHELP An error routine is being tested - please ignore messages which follow ...
CP M OP      An error routine is being tested - please ignore messages which follow ...
DESBUF
&TYPE ----- ---- ----- ----- ----- ------ ----- ----- -----
&TYPE Test No 1 - No Parms
&STACK First line of stack
&STACK Second line of stack
&STACK Parms missing
EXEC ZERROR
&READ VARS *
CLRSCRN
&TYPE ----- ---- ----- ----- ----- ------ ----- ----- -----
&TYPE Test No 2 - Parm 1 invalid - no other parms
&STACK First line of stack
&STACK Second line of stack
&STACK Parm 1 = AAA - no other parms
&RETCD = AAA
EXEC ZERROR &RETCD
&READ VARS *
CLRSCRN
&TYPE ----- ---- ----- ----- ----- ------ ----- ----- -----
&TYPE Test No 3 - Invalid Parm 2
&STACK First line of stack
&STACK Second line of stack
&STACK Parm 1 = 1 - invalid parm 2 - parm 3 missing
&RETCD = 1
EXEC ZERROR &RETCD JJJJJJJ
&READ VARS *
CLRSCRN
&TYPE ----- ---- ----- ----- ----- ------ ----- ----- -----
&TYPE Test No 4 - Zero return code
&STACK First line of stack
&STACK Second line of stack
&STACK Parm 1 = 0
&RETCD = 0
EXEC ZERROR &RETCD ZFAERJC This is the passed message
&READ VARS *
CLRSCRN
&TYPE ----- ---- ----- ----- ----- ------ ----- ----- -----
&TYPE Test No 5 - Non-zero return code
&STACK First line of stack
&STACK Second line of stack
&STACK Parm 1 = 1 - other parms valid
&RETCD = 1
EXEC ZERROR &RETCD ZFAERJC This is the passed message
&READ VARS *
CLRSCRN
&TYPE ----- ---- ----- ----- ----- ------ ----- ----- -----
&TYPE Test No 6 - Negative return code
&STACK First line of stack
&STACK Second line of stack
&STACK Parm 1 = -2
&RETCD = -2
EXEC ZERROR &RETCD ZFAERJC This is the passed message
BROWSE ZERROR ERROR A
BROWSE ZERROR ERRLOG A
&EXIT
