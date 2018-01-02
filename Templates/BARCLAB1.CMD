/*********************************************************************
   @ECHO OFF
   ECHO OS/2 Procedures Language 2/REXX not installed.
   ECHO Run Selective Installation from the Setup Folder to
   ECHO install REXX support.
   pause
   exit
 *********************************************************************
 Purpose:       Reformat label files from Barclays so that they are useful
 
 Client:        Consolidated Share Registrars Limited
 Date written:  3 October 1994
 Author:        Rob Crothall & Associates - RJC
 Copyright:     Copyright (1994) by Rob Crothall & Associates, South Africa.
                All rights reserved.
 
 Arguments:     These are in the form KEYWORD=...  KEYWORD2=...
                Separate the end of one parameter from the next with a space.
                                                                  
   DEBUG=YES | NO   Various sections are traced when this is set to Yes.
                    Default is NO.

   LINELEN=39       The line length at which output text should be wrapped.

   INDENT=1         Number of characters to indent.

   LINES=11         Align the right side of the report

   COPIES=L | R     No of copies is on the left | right of the constant

 Processing:    Initialise, including display of these comments if invoked
                  with a paramete of '?'.  Prepare to handle exception
                  conditions, if they arise.  Ensure that utility functions 
                  are loaded.
                Process keyword parameters passed to the program.
                Display copyright information and get acknowledgement.
                Tidy up and return to the Workplace Shell.
                                                          
 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Written by:    Rob Crothall   Date: 3 October 1994
 Changed by:                   Date:
*/
/*********************************************************************
 *            (C) Copyright Rob Crothall & Associates 1994           *
 *********************************************************************/

setlocal;
/* Define some constants... */
Yes = 1;
No = 0;
VRexxActive = No;

/* Set options that help during debugging */
'@echo off';

Debug = No;
If Debug = Yes then say 'At beginning...';

LineLen = 39;
Indent  = 1;
Lines   = 7;
Copies  = 'R';
Drive    = 'C:';
Directory= '\';
FileName = '';
FileInName = '';
FileInExt  = '';
Lines    = '';
LineLen  = '';
Indent   = '';
CopyPos  = '';
FileOut  = '';
FileOutName = '';
FileOutExt  = '';
Heading = '';
FileOutExt = 'CSR';
Compress = No;
Directory = '';
FileSpec = '';

rc = 0;
MI_RC = 0;
Warn. = '';
Warn.1 = 'V1.0 - Restricted - property of Rob Crothall';
arg ProcOpts;

/* Display comment info if 1st arg = ? and Exit */
DisplayUsage:
If arg(1)='?' then do;  
   Parse source . . name .;
   Say; Say name;
   Do n = 1 by 1;
      line=sourceline(n);
      If 0 < pos('*/',line) then exit 1;
      If n//15 = 0 then do;
         say; say 'Press <Enter> to continue...';
         pull ans;
      end;  /* Do */
      Say line;
   End;
End;

/* For those who start this from an OS/2 Full Screen session... */
say 'Use Ctrl-Esc to see the windows...';

/* Handle programming errors in a reasonable way... */

Signal on failure name CLEANUP;
Signal on halt name CLEANUP;
Signal on syntax name CLEANUP;

/* Check if utility functions have been loaded; If not, load them...*/
If 0 < RxFuncQuery('SysLoadFuncs')
  then do;
         Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
         Call SysLoadFuncs;
         Say 'RexxUtils loaded...';
       End;

If 0 < RxFuncQuery('PrxLoadFuncs')
  then do;
         Call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS';
         Call PrxLoadFuncs;
         Say 'PrxUtils loaded...';
       End;
Say PrxUtilsVersion();

If Debug = Yes then say 'Loading VRexx...';

Call RxFuncAdd 'VInit', 'VREXX', 'VINIT';
mi_rc = VInit();
VRexxActive = Yes;
Say 'VRexx initialisation =' mi_rc;

Say 'VRexx version' VGetVersion();
If Debug = Yes then Say 'Press Enter to continue..';
If Debug = Yes then pull nul;

Direction = 1;
/*------------- Main processing ------------------------------*/

If Debug = Yes then say 'At Initialize...';
call Initialize
If Debug = Yes then say 'At Parameters...';
Call Parameters;
/*If Debug = Yes then call trace('?r');*/
Call GetDetails;
/* ... Do the main processing ... */
NAccross = 2;
LabOutN  = 0;

/* Read the file */
Rec. = '';
InFile = Drive || Directory || FileName;
retcd = PrxReadToStem(InFile, 'Rec');
If Rec.0 > 0 then do RecNo = 1 to Rec.0 by Lines;
  /* Get each label... */
  LabLine. = '';
  I = 0;
  Copies. = 1;
  Country. = '   ';
  Do LineNo = RecNo to RecNo + Lines - 1;
     I = I + 1;
     Do Lab = 1 to NAccross;
        Work = substr(Rec.LineNo,(Lab-1)*LineLen+(Lab*Indent)+1,LineLen);
        Work = strip(Work, Trailing);
        J = pos('COPIES',translate(Work));
        If J > 0 then do;
           If CopyPos = 'R' then do;
              parse upper var Work . 'COPIES' Copies.Lab .;
              Work = '';
           end  /* Do */
           else do;
                  parse upper var Work Copies.Lab 'COPIES' .;
                  Work = '';
           end  /* Do */
        end  /* Do */
        else If Work \= '' then do;
                If (length(Work) = 3) & (I = 1) then Country.Lab = Work;
                else LabLine.Lab.I = Work;
             end  /* Do */
     end /* do */
  end /* do */
  /* Create two records */
  Do Lab = 1 to NAccross;
     LabOutN = LabOutN + 1;
     If datatype(Copies.Lab) \= 'NUM' then Copies.Lab = 1;
     LabOut.LabOutN = left(FileName,12);
     LabOut.LabOutN = LabOut.LabOutN || left(Country.Lab,3);
     LabOut.LabOutN = LabOut.LabOutN || format(Copies.Lab,3);
     Do I = 1 to Lines;
        If LabLine.Lab.I \= '' then LabOut.LabOutN = LabOut.LabOutN || left(LabLine.Lab.I, 35);
     end /* do */
     if LabOutN < 5 then say length(LabOut.LabOutN) LabOut.LabOutN;
  end /* do */
/* Do it again */
End;
/* Write the output file */
retcd = PrxWriteFromStem(FileOut, LabOut, LabOutN, 1, 'Replace');

If VRexxActive = Yes then Say 'Closing VRexx';
If VRexxActive = Yes then call VExit;
VRexxActive = No;

/*---------------- End of Main processing --------------------*/

CLEANUP:

  If Debug = Yes then say 'At Cleanup...';
  Say 'That''s all, folks!';
  If VRexxActive = Yes then Say 'Closing VRexx';
  If VRexxActive = Yes then call VExit;
  VRexxActive = No;

EndIt:
  Say 'Current Directory =' curdir;
  If Debug = Yes then say 'At EndIt...';
  if debug = Yes then say 'Press Enter to continue...';
  if debug = Yes then pull nul;
  call directory  curdir
  endlocal

Exit;

/*========================================================*/
/* Start of internal subroutines, in alphabetical order   */
/*========================================================*/
/*------------------------------------------------------------*/
Copyright:

  If bQuiet > 0 then return;
  msg.0 = 6;
  msg.1 = '               This product is copyright by';
  msg.2 = '                 Rob Crothall & Associates';
  msg.3 = '                    All rights are reserved.';
  msg.4 = '';
  msg.5 = '           Press OK to acknowledge the rights';
  msg.6 = 'of Rob Crothall & Associates.  Press Cancel to end.';

  call VDialogPos 50, 50;

  rb = VMsgBox('Copyright Message', msg, 3);
  if rb = 'OK' then nop;
  else signal CLEANUP;

Return;

/*------------------------------------------------------------*/

getBOOT:
bootdrive = Value('Path',,'OS2ENVIRONMENT')
parse upper var bootdrive bootdrive
Driveis = Substr(bootdrive,Pos('\OS2\SYSTEM',bootdrive)-2,2)
return


/*------------------------------------------------------------*/

GetConfigSys:

FATC=0; HPFSC=0; TIMESLICE ='Dynamic'; buffers=''; pridiskio=''; fcbs=''; files=''; rmsize='';
iopl=''; maxwait=''; memman=''; swploc=''; warnsize=''; swpisize=''; threads=''; pmonbufsize='';
tracebuf=''; protect=''; acvalues=''; setac=''; v1=''; v2=''; v3=''; v4=''; fatCachesize=0; FatLW='';
Fatt=''; cache='0'; crecl=''; auto=''; ifs=driveis'\OS2\HPFS.IFS'; file=''; sys=''; acheckl=''; acheckval='';

do until lines(driveis"\"configsys) = 0
  fline=linein(driveis"\"configsys)
  parse var fline parm "=" values
  if parm = "BUFFERS" then buffers = values
  else if parm = "PRIORITY_DISK_IO" then pridiskio = values
     else if parm = "FCBS" then fcbs = values
     else if parm = "FILES" then files = values
     else if parm = "RMSIZE" then rmsize = values
     else if parm = "IOPL" then iopl = values
     else if parm = "MAXWAIT" then maxwait = values
     else if parm = "MEMMAN" then memman = values
     else if parm = "SWAPPATH" then parse var fline "=" swploc warnsize swpisize
     else if parm = "THREADS" then threads = values
     else if parm = "PRINTMONBUFSIZE" then pmonbsiz = values
     else if parm = "TRACEBUF" then tracebuf = values
     else if parm = "PROTECTONLY" then protect = values
     else if parm = "TIMESLICE" then timeslice = values
     else if parm = "DISKCACHE" then do      /* DISKCACHE */
              FATC=1
              parse var values any "AC:" acvalues
              if acvalues = ''  then setac = ''
               else setac = ",AC:"acvalues
                 parse var values v1 "," v2 "," v3 "," v4
                 fatCacheSize = v1
                 dskcache = 'Yes'
               if v2 = "LW" then  FatLW = 'LW'
                else if v3 = 'LW' then fatlw = 'LW'
                else if v4 = 'LW' then fatlw = 'LW'
                else if verify(v2,'1234567890') then  NOP
                else fatt = v2
                if \verify(v2,'1234567890') then fatt = v2
                else if \verify(v3,'1234567890') then fatt = v3
                else if  \verify(v4,'1234567890') then fatt = v4
                end
                 else if parm = "IFS" then do
                   parse var fline parm "=" ifs cache1 crecl1 auto1
                   parse var ifs fileSys"."sys
                   if IFS = driveis"\OS2\HPFS.IFS" then do; HPFSC=1;parse upper var values  '/CACHE:' cache '/CRECL:' crecl '/AUTOCHECK:'Acheckval; end;
                   else nop
                   if acheckval = '' then acheckl=''
                   else acheckl = " /AUTOCHECK:"Acheckval
                   end
END
return


/*------------------------------------------------------------*/
GetDetails:

  /* Ask for details of this profile, and set up variables... */
  prompt. = '';
  prompt.0 = 9;
  prompt.1 = 'Drive:';
  prompt.2 = 'Directory:';
  prompt.3 = 'File name:';
  prompt.4 = 'Lines per address:';
  prompt.5 = 'Line length:';
  prompt.6 = 'Indent:';
  prompt.7 = 'Copies (L/R):';
  prompt.8 = 'Output file:';
  prompt.9 = 'Debug (Y/N):';

  width.  = 10;
  width.0 = prompt.0;
  width.1 = 3;
  width.2 = 30;
  width.3 = 12;
  width.4 = 3;
  width.5 = 3;
  width.6 = 3;
  width.7 = 3;
  width.8 = 12;
  width.9 = 3;

  hide.  = 0;
  hide.0 = prompt.0;
  hide.1 = 0;
  hide.2 = 0;
  hide.3 = 0;
  hide.4 = 0;
  hide.5 = 0;
  hide.6 = 0;
  hide.7 = 0;
  hide.8 = 0;
  hide.9 = 0;

  answer.  = '';
  answer.0 = prompt.0;
  answer.1 = 'C:';
  answer.2 = '\BARCLAYS\';
  answer.3 = '';
  answer.4 = Lines;
  answer.5 = LineLen;
  answer.6 = Indent;
  answer.7 = CopyPos;
  answer.8 = '';
  If Debug = Yes then answer.9 = 'Y';
  else answer.9 = 'N';

  Heading = 'Please enter details of file';
  Correct = No;
  Do until (Correct = Yes);
    mirc = VMultBox(Heading, prompt, width, hide, answer, 3);
    If mirc \= 'OK' then signal CLEANUP;
    Heading = 'Please enter ALL details';
    Do I = 1 to answer.0 - 2;
      If (answer.I = '') then signal TryAgain;
    End;
    Drive    = Translate(answer.1);
    Directory= Translate(answer.2);
    FileName = Translate(answer.3);
    Parse upper var FileName FileInName '.' FileInExt;
    FileInName = space(FileInName);
    FileInExt  = space(FileInExt);
    Lines    = answer.4;
    LineLen  = answer.5;
    Indent   = answer.6;
    CopyPos  = Translate(answer.7);
    If Translate(answer.9) = 'Y' then Debug = Yes;
    else Debug = No;
    FileOut  = Translate(answer.8);
    If FileOut = '' then FileOut = FileInName || '.CSR';
    Parse upper var FileOut FileOutName '.' FileOutExt;
    FileOutName = space(FileOutName,0);
    FileOutExt  = space(FileOutExt,0);
    Heading = 'File Name is more than 8 characters';
    If length(FileOutName) > 8 then iterate;
    Heading = 'File Extension is more than 3 chars';
    If length(FileOutExt)  > 3 then iterate;
    If FileOutExt = '' then FileOutExt = 'CSR';
    If FileOutExt = 'ZIP' then do;
      FileOutExt = 'CSR';
      Compress = Yes;
    End;
    If left(Directory,1) \= '\' then Directory = '\' || Directory;
    If right(Directory,1) \= '\' then Directory = Directory || '\';
    FileSpec = Drive || Directory || FileOutName || '.' || FileOutExt;
    /* Check existence of Directory */
    /* Check existence of miWords file */
    /* If Directory\FILES.BBS does not exist, ensure that \MAX\FILEAREAS.CTL
         is updated.  Run SILT in another session. */
    /* Check that FileOut does not exist in Directory */
    /* Check that Billing is valid */
    Correct = Yes;

TryAgain:
  End;

Return;

/*------------------------------------------------------------*/

getDriveInfo:
a=1
do a = 1 to 25
d.a=''
end

dmap = SysDriveMap('c:', 'LOCAL')
parse value dmap with d.1 d.2 d.3 d.4 d.5 d.6 d.7 d.8 d.9 d.10 d.11 d.12 d.13 d.14 d.15 d.16 d.17 d.18 d.19 d.20 d.21 d.22 d.23 d.24 D.25
FAT= 'NO'
HPFS= 'NO'
a=1
drive=d.a
do while d.a\=''
rc=SysMkDir(drive'\'muchtoolargeforFAT)
if rc=206  then do
    FAT = 'YES'
    Type.a = 'FAT'
    end
else do
        if rc=19 then Type.a = 'CD-ROM'
        else do;
        HPFS = 'YES'
        type.a = 'HPFS'
        call SysRmDir(drive'\'muchtoolargeforfat)
        end;end
dinfo.a=SysDriveInfo(d.a)
parse var dinfo.a d.a ":" free.a total.a label.a
pfree.a=free.a/total.a
pfree.a=100*pfree.a
pfree.a=trunc(pfree.a,2)
a=a+1
drive=d.a
end
return

/*------------------------------------------------------------*/

Initialize:

'@ECHO OFF'
setlocal

/*********************************************************************
 * Find what our home directory is, and where we are being           *
 * executed from.                                                    *
 * We will also save the value of various environmental variables.   *
 *********************************************************************/
curdir = directory()

parse source opsys invoked myname;
myname     = translate(myname);
e_drive    = left(myname,2)
temp       = reverse(myname);
ObjectName = myname;
parse var temp 'DMC.'e_name'\'e_path;
e_path     = reverse(e_path)'\'
e_name     = reverse(e_name)
HomeBase   = 'RobC';
Path       = value('PATH',,'OS2ENVIRONMENT')
DPath      = value('DPATH',,'OS2ENVIRONMENT')
Help       = value('HELP',,'OS2ENVIRONMENT')
BookShelf  = value('BOOKSHELF',,'OS2ENVIRONMENT')
BookMgr    = value('BOOKMGR',,'OS2ENVIRONMENT')
ReadIBM    = value('READIBM',,'OS2ENVIRONMENT')
MyEnv      = value(e_name,,   'OS2ENVIRONMENT');
/************************************************
 * Make sure that all paths end in a ;          *
 ************************************************/
if right(PATH,1) <> ';'
  then PATH = PATH';'
if right(DPATH,1) <> ';'
  then DPATH = DPATH';'
if right(HELP,1) <> ';'
  then HELP = HELP';'

/************************************************
 * Find Boot Drive for OS2.                     *
 ************************************************/
parse upper var Path b_drive'\OS2;'.
b_drive = right(b_drive,2)
if debug=Yes then say 'Op Sys  =' opsys;
if debug=Yes then say 'Invoked =' invoked;
if debug=Yes then say 'My name =' myname;
if debug=Yes then say 'E drive =' e_drive;
if debug=Yes then say 'E path  =' e_path;
if debug=Yes then say 'E name  =' e_name;
if debug=Yes then say 'B drive =' b_drive;
if debug=Yes then say 'My env  =' MyEnv;

InitVariables:
getBOOT:
bootdrive     = Value('Path',,'OS2ENVIRONMENT')
parse upper var bootdrive bootdrive
BootDrive     = Substr(bootdrive,Pos('\OS2\SYSTEM',bootdrive)-2,2)

CharSet:
/* Foreground colors, not highlighted*/
black         ='[30m[1A';
red           ='[31m[1A';
green         ='[32m[1A';
yellow        ='[33m[1A';
blue          ='[34m[1A';
white         ='[37m[1A';
/* Foreground colors, highlighted*/
hblack        ='[1;30m[1A';
hred          ='[1;31m[1A';
hgreen        ='[1;32m[1A';
hyellow       ='[1;33m[1A';
hblue         ='[1;34m[1A';
hwhite        ='[1;37m[1A';
blue_o_white  ='[34;47m[1A';
white_o_blue  ='[37;44m[1A';
white_o_red   ='[37;41m[1A';
/* Cursor movement */
cursor_up     ='[1A';      /* Cursor up 1 line*/
cursor_up2    ='[2A';      /* Cursor up 2 lines*/
cursor_down   ='[1B';      /* Cursor down 1 line*/
cursor_right  ='[1C';      /* Cursor right 1 space*/
cr5           ='[9C';      /* Cursor right 5 spaces*/

normal        ='[0m[1A';  /* Restore default attrib. and color    */
reverse       ='[7m[1A';  /* Reverse video*/
highlight     ='[1m[1A';  /* Highlight*/
invisible     ='[8m[1A';  /* Invisible*/

return;


/*------------------------------------------------------------*/
Parameters:  /* Handle default options and parameters passed to us... */

  bQuiet   = No;
  Lines    = 7;
  CopyPos  = 'R';
  Indent   = 1;
  LineLen  = 39;
  Align    = No;
  Do I = 1 to words(ProcOpts);

    work = word(ProcOpts, I);
    parse var work Keyword '=' parm;
    parm = strip(parm);
    If Debug = Yes then nop;
    Select
      when Keyword = 'QUIET' then If left(parm,1) = 'Y' then bQuiet = Yes;
      when Keyword = 'DEBUG' then If left(parm,1) = 'Y' then Debug = Yes;
      when Keyword = 'INDENT' then Indent = parm;
      when Keyword = 'LINELEN' then LineLen = parm;
      when Keyword = 'LINES' then Lines = parm;
      when Keyword = 'COPIES' then CopyPos = parm;
      when Keyword = 'ALIGN' then If left(Parm,1) = 'Y' then Align = Yes;
      otherwise;
        msg.1 = 'Parameter' word(ProcOpts, I) 'is not recognised';
        msg.2 = 'and has been ignored.';
        msg.0 = 2;
        rb = VMsgBox('Parameter error?', msg, 3);
        If rb = 'CANCEL' then signal CLEANUP;
    end;  /* select */
  end; /* do */

Return;

/*------------------------------------------------------------*/

SysPause:
  parse arg prompt;
  if prompt='' then prompt='Press Enter key when ready . . .';
  call SysSay prompt;
  call syssleep 5;
  say
return

/*------------------------------------------------------------*/
SysSay:
  parse arg string
  call charout 'STDOUT', string
return;

/*------------------------------------------------------------*/

Welcome:
echo on
'prompt $p$E[0;'34';'47';'5';'5'm]'
echo off
'cls'
call SysCurState 'OFF'
call sysCurPos '4', '0'

msg.0  =12
msg.1  = blue
msg.2  = cr5 cr5' ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿'
msg.3  = cr5 cr5' ³                                ³ '
msg.4  = cr5 cr5' ³  D o c U G e n   1.0           ³'
msg.5  = cr5 cr5' ³                                ³      '
msg.6  = cr5 cr5' ³                                ³'
msg.7  = cr5 cr5' ³                                ³'
msg.8  = cr5 cr5' ³                                ³'
msg.9  = cr5 cr5' ³                                ³'
msg.10 = cr5 cr5' ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
msg.11 = hblue
msg.12 = cr5 '        Copyright (c) 1994 Rob Crothall & Associates       '

msg.13 = '         If needed, please Maximize SCREEN SIZE then Press Enter to Continue    '
do i =1  to msg.0
       say msg.i
       end
call SysCurPos '19','0'

say red;
call sysCurPos '7', '22'
call syssay 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
call sysCurPos '8', '21'
call syssay 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'


say;
say red;
call sysCurPos '9', '21'
call syssay 'Go'
call sysCurPos '9', '23'
call syssay ' as fast as'
call sysSleep 1


call sysCurPos '9', '35'
call syssay '32 bits'
call sysSleep 1


call sysCurPos '11', '30'
call syssay ' will'
call sysSleep 1


call sysCurPos '11', '35'
call syssay ' take'
call sysSleep 1


say blue;
call sysCurPos '11', '41'
call syssay 'you!'
call sysSleep 1

say hblack;
call sysCurPos '15', '0'

SAY'         If needed, please Maximize SCREEN SIZE ...'

call sysSleep 1
say red;
call sysCurPos '14', '26'

CALL SYSPAUSE ObjectName
call SysCurState 'ON'


'cls'
echo on
'prompt $p$E[0;'34';'47';'5';'5'm]'
echo off
'cls'
return

/*------------------------------------------------------------*/

WriteDoc:

  'cd' Directory;
  If NewOut.0 > 0 then mi_rc = PrxWriteFromStem(FileSpec,'NewOut',NewOut.0,1,'Replace');
/*  If NewOut.0 > 0 then 'command /k c:\wp51\wp.exe' FileSpec;*/

Return;

/*------------------------------------------------------------*/
ZipDoc:
  'cd' Directory;
  'PKZip' FileOutName FileSpec;
Return;

