&TRACE OFF
&IF &INDEX = 1 &IF &1 = ? &GOTO -TELL
&GOTO -RUN
-TELL &TYPE FORMAT:     &0 ?1 ?2 ?3 ?4 ...
&BEGTYPE -END
PURPOSE:    TO SEND A REQUEST TO APPLIB TO CREATE A LISTING OF INFO ABOUT
            GIVEN MACHINE/S AVAILABLE TO A GEN USER.

USAGE:      ?1 - INFO REQD (OPTIONS: RDR IND OR *=EVERYTHING)
            ?2 - MACHINE ID 1
            ?3 - MACHINE ID 2
            ?4 - MACHINE ID 3
            ?5 - MACHINE ID 4
            ?6 - MACHINE ID 5
            ?7 - MACHINE ID 6
            ?8 - MACHINE ID 7
            ?9 - MACHINE ID 8
           ?10 - MACHINE ID 9

AUTHOR:     CRL APR 84
CHANGED BY:
LAST CHANGE: DD MMM YY.
-END
&EXIT 1
-RUN
      &IF .&1 = .IND &GOTO -OK
      &IF .&1 = .RDR &GOTO -OK
      &IF .&1 = .*   &GOTO -OK
      &TYPE FUNCTION MUST BE 'IND' 'RDR' OR '*'.
      &EXIT 99
     -OK
      &IF .&1 = .TAPEUTIL &CALL -MSG
      &IF .&2 = .TAPEUTIL &CALL -MSG
      &IF .&3 = .TAPEUTIL &CALL -MSG
      &IF .&4 = .TAPEUTIL &CALL -MSG
      &IF .&5 = .TAPEUTIL &CALL -MSG
      &IF .&6 = .TAPEUTIL &CALL -MSG
      &IF .&7 = .TAPEUTIL &CALL -MSG
      &IF .&8 = .TAPEUTIL &CALL -MSG
      &IF .&9 = .TAPEUTIL &CALL -MSG
      &IF .&10 = .TAPEUTIL &CALL -MSG
      &IF .&1 = .TAPEUTIL &1 = CARTUTIL
      &IF .&2 = .TAPEUTIL &2 = CARTUTIL
      &IF .&3 = .TAPEUTIL &3 = CARTUTIL
      &IF .&4 = .TAPEUTIL &4 = CARTUTIL
      &IF .&5 = .TAPEUTIL &5 = CARTUTIL
      &IF .&6 = .TAPEUTIL &6 = CARTUTIL
      &IF .&7 = .TAPEUTIL &7 = CARTUTIL
      &IF .&8 = .TAPEUTIL &8 = CARTUTIL
      &IF .&9 = .TAPEUTIL &9 = CARTUTIL
      &IF .&10 = .TAPEUTIL &10 = CARTUTIL
     *SEND REQUEST TO APPLIB VIA SMSG
      CP SET SMSG ON
      CP SLEEP 1 SEC
      CP SMSG APPLIB DBQ &1 &2 &3 &4 &5 &6 &7 &8 &9 &10
     *AWAIT SMSG FROM APPLIB WHEN INFO IS READY
      EXEC NOTYPE WAKEUP (NOEXT SMSG CONS
      &IF &RC = 6 &EXIT 6
      &READ VARS &AST &USER &TASK &MYMACH
      &IF &USER ª= APPLIB &GOTO -RUN
     *BROWSE INFO ON APPLIB X-DISK
      EXEC NOTYPE ACC 31A X
      BROWSE DBQ &MYMACH X
     *SEND MESSAGE TO APPLIB TO ERASE FILE
      CP SMSG APPLIB DBQERASE
      &EXIT
*
-MSG
  &BEGTYPE -MMM

       Please note that TAPEUTIL has been converted to CARTUTIL
       so as to use cartridges instead of open reel tapes.

       Your request has therefore been sent to CARTUTIL instead.

       Please specify CARTUTIL instead of TAPEUTIL in future.
-MMM
CP SLEEP 5 SEC
&RETURN
