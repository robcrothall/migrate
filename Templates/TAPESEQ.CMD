/*  */
/*********************************************************************
 Purpose:       Copy User files to tape from VM, and generate MVS JCL
                TO READ THE TAPE BACK AND CREATE MVS DATA SETS.
 Client:        IBM SA
 Date written:  20 Feb 1996
 Author:        Rob Crothall & Associates - RJC
 Copyright:     Copyright (1996) by Rob Crothall & Associates, South Africa.
                All rights reserved.

 Arguments:     These are in the form KEYWORD=...  KEYWORD2=...
                Separate the end of one parameter from the next with a space.

   QUIET=YES ³ NO  SUPPRESSES COPYRIGHT MESSAGES AND OTHER INFORMATION Displays.

   DEBUG=YES ³ NO  VARIOUS SECTIONS ARE TRACED WHEN THIS IS SET TO YES.
                   Default is NO.

   OLDUSER=xxxxxxx Where 'xxxxxxx' is the owner of the files on VM

   NEWUSER=xxxxxxx Where 'xxxxxxx' is the new owner of the files on MVS

   VOLSER=xxxxxx   Where 'xxxxxxx' is the new owner of the files on MVS

   SELECT=XXXXXXX  CREATES IEBUPDTE CONTROL CARDS

   TARGET=n        Where 'n' is the access letter of the disk you want to convert.

 Processing:    Initialise, including display of these comments if invoked
                  with a paramete of '?'.  Prepare to handle exception
                  conditions, if they arise.
                Process keyword parameters passed to the program.
                Display copyright information and get acknowledgement.

                Tidy up and return to the calling environment.


 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Written by:    Rob Crothall   Date: Feb 1996
 Changed by:                   Date:
*/
/*********************************************************************
 *            (C) Copyright Rob Crothall & Associates 1996           *
 *********************************************************************/

/* Define some constants... */
Yes = 1;
No = 0;
VRexxActive = No;

/* Set options that help during debugging */

DEBUG = NO;
If Debug = Yes then call trace('r');
If Debug = Yes then say 'At beginning...';

rc = 0;
MI_RC = 0;
Target = 'L';
OldUser = 'OLDUSER';
NewUser = 'NEWUSER';
VolSer  = 'VOLSER';
SELECT  = '*';
TStart = time();
Junk = time(r);
arg ProcOpts;
PARSE SOURCE . . NAME .;

/* Display comment info if 1st arg = ? and Exit */
DisplayUsage:
If arg(1)='?' then do;
   Parse source . . name .;
   Say; Say name;
   Do n = 1 by 1;
      line=sourceline(n);
      If 0 < pos('*/',line) then exit 1;
      Say line;
   End;
End;

/* Handle programming errors in a reasonable way... */

Signal on failure name CLEANUP;
Signal on halt name CLEANUP;
SIGNAL ON SYNTAX NAME CLEANUP;

/*------------- Main processing ------------------------------*/

If Debug = Yes then say 'At Initialize...';
call Initialize
If Debug = Yes then say 'At Parameters...';
Call Parameters;
If Debug = Yes then say 'At Copyright...';
Call Copyright;
/* ... Do the main processing ... */
'REL' TARGET '(DET';
'DETACH 201';
'CP LINK' OldUser '191 201 RR'
'ACC 201' Target;
'L *' SELECT TARGET '(FIFO AL))'
'SENTRIES'; RECS1=RC
Out. = '';
If RECS1 > 0 then do;
   ln = 0;
   ln = ln + 1;
   Out.ln = '//@@@@@@@R JOB (@@@@),''ROB CROTHALL'',CLASS=A,';
   Out.ln = Out.ln ³³'MSGCLASS=X,NOTIFY=@@@@@@@';
   ln = ln + 1;
   Out.ln = '//STEP0 EXEC PGM=IEFBR14';
   ln = ln + 1;
   Out.ln = '//DD1 DD DISP=SHR,UNIT=(3480,,DEFER),VOL=(SER='³³VolSer³³',RETAIN)'
end  /* Do */
else do;
   Say 'No files found - run abandoned!';
   Signal Cleanup;
end  /* Do */

OutFile. = '';
File_no = 1;
   Parse pull REC;
   Do kount = 2 to RECS1;
      parse var REC fn ft fm FormatI Lrecl NoRecs .;
      Blksize = trunc(16448/Lrecl)* Lrecl;
      If FormatI = 'V' then do;
        Format = 'VB';
        Lrecl = Lrecl + 4;
        Blksize = trunc(16448/Lrecl)* Lrecl +8;
      End;
      If FormatI = 'F' then Format = 'FB';
      BLOCKS = trunc(NORECS / (BLKSIZE / LRECL)) + 1;
/*    If left(ft,3) = 'DAS' then Say 'File' fn ft fm 'ignored';*/
      If left(ft,3) = 'DAS' then parse pull rec;
      If left(ft,3) = 'DAS' then iterate;
      File_no = File_no + 1;
      Label_no = File_no;
/*      SAY 'FILE NO =' FILE_NO;*/
      ln = ln + 1;
      OUT.LN = '//STEP'³³FILE_NO 'EXEC PGM=IEBGENER';
      ln = ln + 1;
      OUT.LN = '//SYSUT1 DD DSN=VMFILE.F'³³FILE_NO³³',DISP=OLD,UNIT=REF=STEP0.DD1,';
      ln = ln + 1;
      OUT.LN = '//          LABEL=('³³LABEL_NO',SL),';
      ln = ln + 1;
      OUT.LN = '//          DCB=(DSORG=PS,RECFM='³³Format³³',LRECL='³³LRecL³³',BLKSIZE='³³BLKSIZE³³')';
      ln = ln + 1;
      OUT.LN = '//SYSUT2 DD DSN='³³NewUser³³'.'³³FN³³'.'³³FT³³',DISP=(,CATLG,DELETE),';
      ln = ln + 1;
      Out.ln = '//          UNIT=3390,';
      ln = ln + 1;
      OUT.LN = '//          SPACE=(BLK,('³³BLOCKS³³','³³MAX(1,trunc(BLOCKS/10))³³'),RLSE),';
      ln = ln + 1;
      OUT.LN = '//          DCB=(DSORG=PS,RECFM='³³Format³³',LRECL='³³LReCL³³',BLKSIZE='³³BLKSIZE³³')';
      ln = ln + 1;
      Out.ln = '//SYSIN  DD DUMMY';
      OutFile.File_no = File_no fn ft fm FormatI Format Lrecl Blksize;
Ignoreit:
      PARSE PULL REC;
   End;
ln = ln + 1;
Out.ln = '//';
Out.0  = ln;
If File_no > 1 then do;
   Say 'We have selected' File_no 'files for conversion.';
end  /* Do */
else do;
   Say 'No files were selected for conversion - Please investigate!';
   Signal CLEANUP;
end  /* Do */
'DESBUF'
Do i = 1 to Out.0;
   queue Out.i;
end /* do */
'EXECIO' OUT.0 'DISKW' NAME '$TEMPJCL A 1 F 80 (FINIS'

'DESBUF';
Say 'Phone the Operator on extension 4272 and ask for a tape drive';
Say '  to be attached to this VM-ID as 181';
Say 'Also ask for tape' VolSer 'to be mounted, with write ring';
Say ' ';
Say 'Press Enter to continue...';
Pull junk;

'TAPE REW'
'FI INMOVE DISK' Name '$TEMPJCL A (recfm f lrecl 80'
'FI OUTMOVE TAP1 sl 1  volid elba99 (disp pass leave'
'MOVEFILE'
Do i = 1 to File_No;
  parse var Outfile.i j fn ft fm FormatI Format Lrecl Blksize .;
  if fn = '' then iterate;
  if i > 5 then trace n;
  'FI INMOVE CLEAR';
  'FI INMOVE DISK' fn ft fm '(RECFM' FormatI 'LRECL' Lrecl;
  'FI OUTMOVE TAP1 sL' j '(DISP PASS leave';
  'MOVEFILE';

Say 'Copying file' j 'to tape';
End;
'tape rew';
If Target \= 'A' then 'REL' Target '(DET';
If VRexxActive = Yes then Say 'Closing VRexx';
If VRexxActive = Yes then call VExit;
VRexxActive = No;
If Debug = Yes then say 'At WriteBilling...';
/*  Call WriteBilling;  */

/*---------------- End of Main processing --------------------*/

CLEANUP:
  Say 'Copy Started:' TStart;
  Say 'Copy Ended:  ' time();
  Say 'Elapsed secs:' time(e);
  If Debug = Yes then say 'At Cleanup...';
  Say 'That''s all, folks!';
  If VRexxActive = Yes then Say 'Closing VRexx';
  If VRexxActive = Yes then call VExit;
  VRexxActive = No;

EndIt:
  'DESBUF';
  If Debug = Yes then say 'At EndIt...';
  if debug = Yes then say 'Press Enter to continue...';
  if debug = Yes then pull nul;

Exit;

/*========================================================*/
/* Start of internal subroutines, in alphabetical order   */
/*========================================================*/

Copyright:

  If Debug = Yes then call trace('r');
  If bQuiet > 0 then return;
  msg.0 = 6;
  msg.1 = '               This product is copyright by';
  msg.2 = '                    IBM South Africa.';
  msg.3 = '                  All rights are reserved.';
  msg.4 = '';
  msg.5 = '           Press Enter to acknowledge the rights';
  msg.6 = '         of IBM South Africa, or cancel this task.';
  Do i = 1 to msg.0;
    Say msg.i;
  End;
  Pull junk;
Return;

/*------------------------------------------------------------*/
/*------------------------------------------------------------*/

Initialize:
If Debug = Yes then call trace('r');


parse source opsys invoked myname;
myname     = translate(myname);
e_drive    = left(myname,2)
temp       = reverse(myname);
ObjectName = myname;
parse var temp 'DMC.'e_name'\'e_path;
e_path     = reverse(e_path)'\'
e_name     = reverse(e_name)
HomeBase   = 'RobC';
Return;

/*------------------------------------------------------------*/
Parameters:  /* Handle default options and parameters passed to us... */

  If Debug = Yes then call trace('r');
  miCat    = 'MICAT.CTL';
  bQuiet   = No;
  Skel     = 'MIREP.TXT';
  miWords  = 'MIWORDS.TXT';
  Print    = No;
  Debug    = No;
  Compress = No;
  Indent   = 5;
  LineLen  = 60;
  Align    = No;
  Do I = 1 to words(ProcOpts);

    work = word(ProcOpts, I);
    parse var work Keyword '=' parm;
    parm = strip(parm);
    Select
      WHEN KEYWORD = 'SELECT' THEN SELECT = PARM;
      when Keyword = 'VOLSER' then VolSer = parm;
      when Keyword = 'OLDUSER' then OldUser = parm;
      when Keyword = 'NEWUSER' then NewUser = parm;
      when Keyword = 'TARGET' then Target = parm;
      when Keyword = 'MICAT' then miCat = parm;
      when Keyword = 'MIWORDS' then miWords = parm;
      when Keyword = 'QUIET' then If left(parm,1) = 'Y' then bQuiet = Yes;
      when Keyword = 'SKEL' then Skel = parm;
      when Keyword = 'PRINT' then If left(parm,1) = 'Y' then Print = Yes;
      when Keyword = 'DEBUG' then If left(parm,1) = 'Y' then Debug = Yes;
      when Keyword = 'INDENT' then Indent = parm;
      when Keyword = 'LINELEN' then LineLen = parm;
      when Keyword = 'ALIGN' then If left(Parm,1) = 'Y' then Align = Yes;
      otherwise;
        msg.1 = 'Parameter' word(ProcOpts, I) 'is not recognised';
        msg.2 = 'and has been ignored.';
        msg.0 = 2;
        do i = 1 to msg.0;
          Say msg.i;
        End;
    end;  /* select */
  end; /* do */

Return;

