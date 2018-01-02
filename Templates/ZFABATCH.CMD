/*=====================================================================*/
/* Prologue                                                            */
/*=====================================================================*/
/* DESCRIPTION: This exec allows ZFABATCH to operate in disconnected   */
/*   mode.  It will wake up when it receives a file in its reader,     */
/*   a SMSG, or at a specified time.                                   */
/*                                                                     */
/*   If you log on to this machine and press enter, this exec will     */
/*   terminate and give you control.                                   */
/*                                                                     */
/*   To return this machine to normal operating state, type "PROFILE"  */
/*   and "#CP DISC".                                                   */
/*                                                                     */
/* USAGE:                                                              */
/*  1. Reader - When a file arrives in the reader it is checked and,   */
/*     if acceptable, received. The previous version of the file is    */
/*     backed up on the D-disk (3 versions are kept, by default).      */
/*     If an exec exists on our A-disk with the same name as the file  */
/*     just received, then it is executed.  The file-type of the file  */
/*     just received is checked: if it is a valid VM-ID then the       */
/*     printer is spooled back to that ID; otherwise the printout      */
/*     is routed to the default printer. The above are default actions;*/
/*     the exec may re-route any output, if required.                  */
/*                                                                     */
/*     Note: It may be a better idea to find instuctions in the first  */
/*           record of the file received e.g. destination and          */
/*           distribution info.  It would be a bit more versatile...   */
/*                                                                     */
/*  2. Parms file - This works like VMUTIL.  Commands can be executed  */
/*     automatically depending on date, time, etc.                     */
/*                                                                     */
/*  3. SMSG or MSG - Are logged and, if they are sent by the "control" */
/*     ID then they are interpreted as a command and executed.         */
/*     Useful for things like setting the Rexx trace, closing the      */
/*     console log, etc without having to interrupt the m/c.           */
/*                                                                     */
/*  4. All significant events are logged, and the log is sent to the   */
/*     "control" ID at the start of each month for analysis.           */
/*                                                                     */
/* HOUSEKEEPING:                                                       */
/*                                                                     */
/*   ABENDs are detected, and automatic recovery is performed on       */
/*   restart.  The failing process is not restarted, and work files    */
/*   on the N-disk are deleted.  The controller and the Help Desk      */
/*   are informed that a problem had occurred, and are asked to        */
/*   investigate.                                                      */
/*                                                                     */
/* DISK ACCESS MODES:                                                  */
/*                                                                     */
/*   A - All programs and received files.                              */
/*   B,C - Free.                                                       */
/*   D - All file backups.                                             */
/*   E - Free.                                                         */
/*   F - SQL                                                           */
/*   G - Performance and trend data.                                   */
/*   J - Development PDB's.                                            */
/*   K - Production PDB's.                                             */
/*   L - Free.                                                         */
/*   M - VM PDB's.                                                     */
/*   N - Work disk - all files are deleted at end of current process.  */
/*   Q - Free.                                                         */
/*   T-W - Free.                                                       */
/*   Z - SAS                                                           */
/*                                                                     */
/* ARGUMENTS: 1. ? - will display these comments.                      */
/*                                                                     */
/* RECORDS STACKED/ RETURN CODES/ ERROR CONDITIONS: Error conditions   */
/*   will be reported using the ZERROR facility.                       */
/*                                                                     */
/*   Rc=1 If arg1=? - Request for info.                                */
/*                                                                     */
/* Dependencies:                                                       */
/*   DESBUF        - to clear the stack                                */
/*   ZERROR EXEC   - to issue and log error messages                   */
/*   ZLOG EXEC     - to log significant events.                        */
/*                                                                     */
/* WRITTEN BY: Rob Crothall DATE: Aug 90                               */
/* CHANGED BY:              DATE:        TO:                           */

Parse source . . name .;
If arg(1)='?' then do; /* Display comment info if 1st arg = ? and Exit */
   Say;
   Say name;
   Say;
   Do n=1 by 1;
      line=sourceline(n);
      If left(line,2)^='/*' then exit 1;
      Say line;
      End
   End

Trace on
/*=====================================================================*/
/* Initialisation                                                      */
/*=====================================================================*/
zconlog  = 'NO';       /* Change to YES for tracing purposes           */
zcontrol = 'XCSARJC';  /* Set to the ID responsible for this m/c       */
zclogid  = 'ZFAOYAH';  /* Set to the ID responsible for con logs       */
zprintid = 'ZFAOYAH';  /* Set to the ID responsible for printouts      */
zprinter = 'CSDNJEP';  /* Default printer destination                  */
zform    = 'STANDARD'; /* Default printer form name - RSCS             */
zform    = 'STD';      /* Default printer form name - JES              */
distad   = '224EDURA'; /* Default printout distribution code           */
/*                                                                     */
/* Find out who we are and the ID of RSCS...                           */
'id (stack lifo)';
if queued() > 0 then pull zvmid . znode . zrscs .;
/*                                                                     */
/* Set up the environment...                                           */
Say name 'starting at' time() 'on' date() 'on' zvmid 'at' znode 'via' zrscs;
'zlog sta1 -------- -------- -------- -------- --------- --------';
'zlog pro1 Start of' name 'exec on' zvmid 'at' znode 'via' zrscs;
'dtripf nopan';
'init3270';
'cp set smsg on';
'cp set emsg on';
'cp set imsg on';
'cp set run  on';
'set blip off';
'cp spool rdr class * nohold nocont';
'cp link sas 191 156 rr';
Call ACCESSIT;
/* ---                                                                 */
/* --- Check that the previous run went smoothly                       */
'state ' name ' ENDED A';
if rc > 0 then call RECOVERY;
/*=====================================================================*/
/* Wait for interrupt: Timer, Reader, SMSG, or Console                 */
/*=====================================================================*/
/* Do forever  */
Do kount = 1 by 1;
/* ---                                                                 */
/* --- Handle the spooling of the console and printer                  */
  'cp spool con start to ' zclogid;
  'cp spool prt close';
  'cp tag dev prt' zprinter;
  'cp spool prt cont to' zrscs 'dist' distad 'cl a copy 1 nohold form' zform;
  'cp spool pun nocont to *';
  'fi * clear';
/* ---                                                                 */
/* --- Show that we are busy...                                        */
  'rename' name ' ENDED A = STARTED A';
/* ---                                                                 */
/* --- Wait for an interrupt                                           */
  Call ACCESSIT;
  Call CHECKDSK;
  say;
  say 'Waiting for next interrupt - press ENTER to terminate this exec';
  'desbuf';
  'cp set EMSG off';
  'wakeup (SMSG IUCVMSG CONS RDR FILE (' name ' PARMS))';
  wretncd = rc;
  'cp set EMSG on';
  If zconlog = 'YES' then say 'WAKEUP return code = ' wretncd;
  Say 'Interrupt number' kount 'occurred at' time() 'on' date();
  Call ACCESSIT;
  If wretncd = 1 then call SMSG;
    else if wretncd = 2 then call TIMER;
      else if wretncd = 3 then call PARMS;
        else if wretncd = 4 then call READER;
          else if wretncd = 5 then call IUCVMSG;
            else if wretncd = 6 then call CONSOLE;
              else call UNKNOWN;
/* ---                                                                 */
/* --- End of main processing loop                                     */
End;
'ZERROR' 8 zcontrol 'Reached limit of iterations';
'zlog pro9 ' name ' stopped by counter';
'rename' name 'STARTED A = ENDED A';
Exit 8; /* In case we ever drop through the loop...                    */
/*=====================================================================*/
/* Handle console interrupt                                            */
/*=====================================================================*/
CONSOLE: Procedure expose name zcontrol zclogid zprintid zconlog;
  If zconlog = 'YES' then say 'Start of CONSOLE procedure';
  'spool prt nocont close';
  'spool pun nocont close';
  'zlog pro9 ' name ' stopped from CONSOLE';
  Say name 'ending normally at' time() 'on' date();
  Say;
  Say 'Type ' name ' and then #CP DISC to restart';
  'rename' name 'STARTED A = ENDED A';
  'spool con close';
  If zconlog = 'YES' then say 'End of CONSOLE procedure';
  Exit 0;
Return 0;
/*=====================================================================*/
/* Handle Timer interrupt                                              */
/*=====================================================================*/
TIMER: Procedure expose name zcontrol zclogid zprintid zconlog;
  If zconlog = 'YES' then say 'Start of TIMER procedure';
  say 'Timer interrupt handled successfully';
  'zlog tim0 Timer interrupt';
  'rename' name 'STARTED A = ENDED A';
  If zconlog = 'YES' then say 'End of TIMER procedure';
Return 0;
/*=====================================================================*/
/* Handle PARMS interrupt                                              */
/*=====================================================================*/
PARMS: Procedure expose name zcontrol zclogid zprintid zconlog zprinter;
  If zconlog = 'YES' then say 'Start of PARMS procedure';
  rest = 'say Invalid parm';
  Do while (queued() > 0);
    parse pull . line day tme dte rest;
    'zlog prm1 Started' line day tme dte rest;
    Say 'Parm =' line day tme dte rest;
    rest;
    'zlog prm9 Ended--' line day tme dte rest 'RC=' rc;
  end;
  'rename' name 'STARTED A = ENDED A';
  If zconlog = 'YES' then say 'End of PARMS procedure';
Return 0;
/*=====================================================================*/
/* Handle Reader interrupt                                             */
/*=====================================================================*/
READER: Procedure expose name distad zcontrol zclogid zprintid zconlog zprinter zrscs;
  If zconlog = 'YES' then say 'Start of READER procedure';
  'desbuf';
  'xrdr (stack)';
  xrdrrc = rc;
  parse pull . type fname ftype '(' spoolid ')' . origin;
  If xrdrrc = 3 /* file was DISK DUMPed  */
     then do;
          type = type ]] fname;
          fname = word(ftype, 1);
          ftype = word(ftype, 2);
          End;
  Say 'File in reader is' type fname ftype '(' spoolid ')' origin;
  'zlog rdr0' type fname ftype 'from' origin;
  If ftype = 'MACLIB' ] fname = name ] type = 'PRINTER'
     then do;
       'trans' name 'rdr' spoolid 'to' zprintid 'rdr';
       Signal Bypassit;
     end;
Receiveit:
  If xrdrrc = 3 ] xrdrrc = 4
     then do;
    'erase' fname 'zfaback8 d';
    'erase' fname 'zfaback7 d';
    'erase' fname 'zfaback6 d';
    'erase' fname 'zfaback5 d';
    'erase' fname 'zfaback4 d';
    'erase' fname 'zfaback3 d';
/*  'rename' fname 'zfaback7 d = zfaback8 d'; */
/*  'rename' fname 'zfaback6 d = zfaback7 d'; */
/*  'rename' fname 'zfaback5 d = zfaback6 d'; */
/*  'rename' fname 'zfaback4 d = zfaback5 d'; */
/*  'rename' fname 'zfaback3 d = zfaback4 d'; */
    'rename' fname 'zfaback2 d = zfaback3 d';
    'rename' fname 'zfaback1 d = zfaback2 d';
    If ftype ^= 'OUTPUT' then 'copy ' fname ftype 'a = zfaback1 d';
    'erase ' fname ftype 'a';
    'receive' spoolid '= = a';
    If rc ^= 0 then do;
       'trans rdr ' spoolid ' to' zprintid 'rdr';
       Signal Bypassit;
    End;
    If ftype ^= 'EXEC' then do;
      'state' fname 'exec a';
      If rc = 0 then do;
         'zlog rdr1 Start of' fname 'exec';
         'cp spool prt cont to' ftype;
         If rc ^= 0 then do;
           'cp tag dev prt' ftype;
           If ftype = 'OUTPUT' then 'cp tag dev prt' zprinter;
           If ftype = 'DATA' then 'cp tag dev prt' zprinter;
           'cp spool prt copy 1';
           'cp spool prt cont to' zrscs 'dist' distad 'cl a nohold';
         end;
         Say 'About to run' fname 'EXEC';
         fname;
         'zlog rdr2 End of' fname 'exec - RC =' rc;
         end;
      End;
      Else 'trans rdr ' spoolid ' to' zprintid 'rdr';
    End;
    Else do;
           rest = ' ';
           'receive' spoolid '= = a (replace noprompt stack)';
           rccc = rc;
           If queued() > 0 then parse pull rest;
           If rest ^= ' ' then 'zlog rdr1' rest;
           Else 'zlog rdr1 No response stacked by RECEIVE';
           If rccc ^= 0 then do;
             'trans rdr ' spoolid ' to' zprintid 'rdr';
              Signal Bypassit;
           End;
           End;
      /* Else 'trans rdr ' spoolid ' to' zprintid 'rdr'; */
Bypassit:
  'rename' name 'STARTED A = ENDED A';
  If zconlog = 'YES' then say 'End of READER procedure';
Return 0;
/*=====================================================================*/
/* Handle SMSG interrupt - If SMSG was from controller, then extract   */
/*   the message text (which should contain the name of an Xedit macro */
/*   RSTCHPR and date and time values), stack it, and call Xedit.      */
/*=====================================================================*/
SMSG: Procedure expose name zcontrol zclogid zprintid zconlog;
  If zconlog = 'YES' then say 'Start of SMSG procedure';
  Do while (queued() > 1);  /* Get rid of the rest of them */
    parse pull rest;
    Say 'Queued record ignored:' rest;
  end;
  If queued() > 0 then parse pull type who rest;
  Say 'SMSG received:' type who rest;
  'zlog sms0 ' type who rest;
  If who = zcontrol then rest;
  'rename' name 'STARTED A = ENDED A';
  If zconlog = 'YES' then say 'End of SMSG procedure';
Return 0;
/*=====================================================================*/
/* Handle IUCVMSG interrupt - If it was from controller, then extract  */
/*   the message text, log it, and respond appropriately.              */
/*=====================================================================*/
IUCVMSG: Procedure expose name zcontrol zclogid zprintid zconlog;
  If zconlog = 'YES' then say 'Start of IUCVMSG procedure';
  Do while (queued() > 0);
    parse pull type who rest;
    If type = '*' then iterate;
    Say 'MSG received:' type who rest;
    If rest ^= ' ' then 'zlog iuc0 ' type who rest;
    If rest ^= ' ' then If who = zcontrol then rest;
    If rest ^= ' ' then If left(who,1) = 'X' then rest;
  end;
  'rename' name 'STARTED A = ENDED A';
  If zconlog = 'YES' then say 'End of IUCVMSG procedure';
Return 0;
/*=====================================================================*/
/* Handle UNKNOWN interrupt                                            */
/*=====================================================================*/
UNKNOWN: Procedure expose name zcontrol zclogid zprintid zconlog;
  If zconlog = 'YES' then say 'Start of UNKNOWN procedure';
  'ZERROR' 999 zcontrol name 'ended by UNKNOWN procedure';
  'zlog pro9 ' name ' ended by UNKNOWN proc - RC = ' wretcd;
  Say name 'ending abnormally at' time() 'on' date();
  Say;
  Say 'Type ' name ' and then #CP DISC to restart';
  'rename' name 'STARTED A = ENDED A';
  'spool con close';
  Exit 999;
Return 0;
/*=====================================================================*/
/* Handle a previous ABEND                                             */
/*=====================================================================*/
RECOVERY: Procedure expose name zcontrol zclogid zprintid zconlog;
  Say 'Start of RECOVERY procedure';
  'zlog rec1 Recovery start';
  queue 'Do not delete this file';
  'EXECIO 1 DISKW ' name ' ENDED A 0 V 160 (FINIS';
  'erase ' name ' started a';
  'erase cms exec a';
  'l * * n (ex da';
  'sendfile cms exec a to' zcontrol;
  'l * * n (ex';
/*'cms erase';*/
  'erase cms exec a';
  'erase * saslog a';
  'erase * listing a';
  'erase * list a';
  'zlog rec9 Recovery end';
  Say 'End of RECOVERY procedure';
Return 0;
/*=====================================================================*/
/* General purpose routines                                            */
/*=====================================================================*/
/*---------------------------------------------------------------------*/
/* Access all necessary disks to ensure that we have current versions  */
/*---------------------------------------------------------------------*/
ACCESSIT: Procedure expose name zcontrol zclogid zprintid zconlog;
  If zconlog = 'YES' then say 'Start of ACCESSIT procedure';
  'notype acc 191 a';
  'notype acc 192 d';
  'notype acc 195 f';
  'notype acc 189 n';
  'notype acc 31a x';
  'notype acc 156 z';
  'notype rel r (det';
  If zconlog = 'YES' then say 'End of ACCESSIT procedure';
Return 0;
/*---------------------------------------------------------------------*/
/* CHECKDSK - Check that disks don't get too full and check controls   */
/*---------------------------------------------------------------------*/
CHECKDSK: Procedure expose name zcontrol zclogid zprintid zconlog;
  If zconlog = 'YES' then say 'Start of CHECKDSK procedure';
/* ---                                                                 */
/* --- Check that the A-disk is not getting too full                   */
  'QDISKFUL A 95';
  'ZERROR' rc zcontrol 'Disk A is too full';
  If rc > 0 then do;
    Say name 'ending abnormally at' time() 'on' date();
    Say;
    Say 'Type ' name ' and then #CP DISC to restart';
    'rename' name 'STARTED A = ENDED A';
    Exit 999;
  End;
/* ---                                                                 */
/* --- Check that the D-disk is not getting too full                   */
  'QDISKFUL D 80';
  'ZERROR' rc zcontrol 'Disk D is too full';
  If rc > 0 then do;
    Say name 'ending abnormally at' time() 'on' date();
    Say;
    Say 'Type ' name ' and then #CP DISC to restart';
    'rename' name 'STARTED A = ENDED A';
    Exit 999;
  End;
/* ---                                                                 */
/* --- Check that the N-disk is not getting too full                   */
  'QDISKFUL N 80';
  'ZERROR' rc zcontrol 'Disk N is too full';
/* ---                                                                 */
/* --- Check that the WAKEUP PARMS file is on the A-disk               */
  'state ' name ' PARMS A';
  'ZERROR' rc zcontrol name ' PARMS file is missing from A-disk'
  If rc > 0 then do;
    'rename' name 'STARTED A = ENDED A';
    Exit 999;
  End;
  If zconlog = 'YES' then say 'End of CHECKDSK procedure';
Return 0;
/*---------------------------------------------------------------------*/
/*                                                                     */
/*---------------------------------------------------------------------*/
