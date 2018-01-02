&TRACE OFF
&CASE M
&IF &INDEX = 1 &IF &1 = ? &GOTO -TELL
&GOTO -RUN
-TELL &TYPE FORMAT:     &0 Return-code Controller-ID Message
&BEGTYPE -END
PURPOSE:    To advertise and log the occurrence of errors in production
            systems.

            When calling this routine, pass the following:-
            - Return code - If zero, this routine will exit immediately.
            - Controller  - The ID of the person responsible for problems
            - Message     - The text of an error message to log/send.
            and stack additional lines of message.

            The Stack is cleared by this exec.

            When called, this Exec does the following:-
            - checks for valid parameters
            - if the return code (Parm 1) is zero,
                - clear the Stack and exit
            - places error description in 'zerror error a1'
            - add contents of stack to 'zerror error a1'
            - appends error description to 'zerror errlog a1'
            - sends 'zerror error' to 'controller' and help desk
            - types 'zerror error a1'
            - returns the original completion code (parm 1)

AUTHOR:     Rob Crothall (based on Clive Loveday's FATAL EXEC)
CHANGED BY:
LAST CHANGE: 90/01/10
-END
&EXIT 1
-RUN
*---
*--- If first parameter is invalid, return 16
     &RETC = 16
     &IF .&1 ^= . &X = &DATATYPE OF &1
     &IF .&1 ^= . &IF &X = CHAR &STACK Invalid Return Code passed to ZERROR
     &IF .&1 ^= . &IF &X = NUM &RETC = &1
*--- If Return code (Parm 1) was zero, clear the stack and exit normally
     &IF &RETC = 0 DESBUF
     &IF &RETC = 0 &EXIT 0
*--- ESTABLISH CONTROLLER MACHINE - Use Help Desk as default
     &CONT = ZFAHELP
     &IF .&2 ^= . &CONT = &2
*--- Check that a message has been passed - if not, set up our own
     &IF .&3 = . &STACK LIFO No message passed - more details may be in the stack
     &IF .&3 ^= . &STACK LIFO &3 &4 &5 &6 &7 &8 &9 &10 &11 &12 &13 &14 &15 &16 &17
     EXEC ZLOG ERR0 &0 CALLED - &3 &4 &5 &6 &7 &8 &9 &10
*--- CREATE 'ZERROR ERROR A1'
     &STACK *ZERR*
    -LOOP
     &READ STRING &DATA
     &IF .&DATA = . &GOTO -LOOP
     &IF &DATA = *ZERR* &GOTO -FILE
     &STACK &DATA
     &GOTO -LOOP
    -FILE
     &STACK ---------------------------------------------------
     &STACK
     &STACK LIFO ***************************************************
     &STACK LIFO DATE (YY/MM/DD): &DATE TIME (HH:MM:SS): &TIME
     EXEC NOTYPE ERASE ZERROR ERROR A1
     EXECIO * DISKW ZERROR ERROR A1 1 F 80 (FINIS
*--- APPEND TO LOG.
     EXECIO * DISKR ZERROR ERROR A1        (FINIS
     &STACK
     EXECIO * DISKW ZERROR ERRLOG A1 0 F 80 (FINIS
*--- SEND MESSAGES.
    -MSG
     CP M OP      ZERROR - Ask &CONT to look into problem in this machine
     CP M ZFAHELP ZERROR - Ask &CONT to look into problem in this machine
     CP M &CONT ZERROR - Please look into problem in this machine
     EXEC SENDFILE ZERROR ERROR A &CONT
     EXEC SENDFILE ZERROR ERROR A ZFAHELP
     &TYPE THE FOLLOWING FATAL ERROR HAS BEEN ENCOUNTERED:
     &TYPE ( A COPY OF THE ERROR IS IN 'ZERROR ERROR A1' )
     TYPE ZERROR ERROR A1 * *
&EXIT &RETC
