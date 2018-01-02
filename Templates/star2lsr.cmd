/*********************************************************************
   @ECHO OFF
   ECHO OS/2 Procedures Language 2/REXX not installed.
   ECHO Run Selective Installation from the Setup Folder to
   ECHO install REXX support.
   pause
   exit
 *********************************************************************
 Purpose:       Copy a directory to another machine using FTP.
 
 Client:        Consolidated Share Registrars Limited
 Date written:  4 Feb 1997
 Author:        Rob Crothall & Associates - RJC
 Copyright:     Copyright (1994) by Rob Crothall & Associates, South Africa.
                All rights reserved.
 
 Arguments:     These are in the form KEYWORD=...  KEYWORD2=...
                Separate the end of one parameter from the next with a space.
   UserID=...       UserID on the remote system.
   Passwd=...      Password on the remote system.
   Target=...      The name of the remote system.  Default is 'csra'.
   TargetDir=...   The target directory on the remote system.
                      Default is '/oracle/data3/modules/'.
   LOCALDrive=... The LOCAL drive on the local system.  Default is 'D:';
   LOCALDir=...   The LOCAL directory on the local system.
                      Default is '\csrora\modules\'.
   QUIET=YES | NO  Suppresses copyright messages and other information displays.
                   Default is Yes.
   PRINT=YES | NO  The log of files transferred should be printed.
                   Default is No.
   DEBUG=YES | NO  Various sections are traced when this is set to Yes.
                   Default is NO.
   LINELEN=60      The line length at which output text should be wrapped.
   INDENT=5        Number of characters to indent in response to an "&IN" tag.

 Processing:    Initialise, including display of these comments if invoked
                  with a paramete of '?'.  Prepare to handle exception
                  conditions, if they arise.  Ensure that utility functions 
                  are loaded.
                Process keyword parameters passed to the program, validating
                  syntax.
                Display copyright information, if required, and
                  get acknowledgement.
                FTPSetUser()
                FTPSetBinary(A)
                FTPSite()
                FTPSys() - Get remote site operating system info
                Set up directory delimeter (\ or /)
                FTPChDir() - change to the correct local directory
                FTPChDir() - change to the correct remote directory
                For each file in the remote directory,
                    FTPGetUnique(Filename)
                    Move remote file to Archive directory
                End of transfer
                Write Log in local directory
                FTPPutUnique(Log) - copy Log to remote directory
                FTPLogoff()
                FTPDropFuncs()
                If PRINT=Yes then Print the Log
                Tidy up and return to caller.
                                                          
 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Written by:    Rob Crothall   Date: 4 Feb 1997
 Changed by:                   Date:
*/
/*********************************************************************
 *            (C) Copyright Rob Crothall & Associates 1997           *
 *********************************************************************/

/* Define some constants... */
Yes = 1;
No = 0;
/*'mode 80, 99';*/

/* Set options that help during debugging */
'@echo off';

Debug = No;
If Debug = Yes then say 'At beginning...';

rc = 0;
MI_RC = 0;
Warn. = '';
Warn.1 = 'V1.0 - Restricted - property of Rob Crothall';
FTPErrorStmt = 'None yet!';
RX_Condition  = 'No Value';
RX_Sigl       = 0;
RX_SourceLine = 'No Value';
RX_Cond_C     = 'No Value';
RX_Cond_I     = 'No Value';
RX_Cond_D     = 'No Value';
RX_Cond_S     = 'No Value';

parse arg ProcOpts;

/* Display comment info if 1st arg = ? and Exit */
DisplayUsage:
If arg(1)='?' then do;  
   Parse source . . name .;
   Say; Say name;
   Do n = 1 by 1;
      line=sourceline(n);
      If 0 < pos('*/',line) then exit 1;
      If n//20 = 0 then do;
         say; say 'Press <Enter> to continue...';
         pull ans;
      end;  /* Do */
      Say line;
   End;
End;

/* For those who start this from an OS/2 Full Screen session... */
/* say 'Use Ctrl-Esc to see the windows...';*/

/* Handle programming errors in a reasonable way... */
If Debug=No then do;
  Signal on failure  name RX_Failure;
  Signal on halt     name RX_Halt;
  Signal on syntax   name RX_Syntax;
  Signal on error    name RX_Error;
  Signal on novalue  name RX_NoValue;
  Signal on notready name RX_NotReady;
end  /* Do */
else say 'Debug = Yes - Failures will not be trapped!';

/* Check if utility functions have been loaded; If not, load them...*/
If 0 < RxFuncQuery('SysLoadFuncs')
  then do;
         Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
         Call SysLoadFuncs;
       End;

If 0 < RxFuncQuery('PrxLoadFuncs')
  then do;
/*         Call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS'; */
/*         Call PrxLoadFuncs; */
       End;
/* Say PrxUtilsVersion(); */

If 0 < RxFuncQuery('FTPLoadFuncs')
  then do;
         rc = RxFuncAdd('FtpLoadFuncs','rxFtp','FtpLoadFuncs');
         rc = FTPLoadFuncs();
       End;

OperSys = 'INVALID Operating System';
UserID = 'robc';
Passwd = 'Ila3TC';
Remote = '163.197.170.1';
WRemote = Remote;
RemoteDir = '/usr/spoolx/laser';
LOCALDrive = 'd:';
LOCALDir   = '\laserrm\stars\in';
OperSys = 'Unknown OperSys';
Direction = 1;
/*------------- Main processing ------------------------------*/

If Debug = Yes then say 'At Initialize...';
call Initialize

If Debug = Yes then say 'At Parameters...';
Call Parameters;

If Debug = Yes then say 'At Copyright...';
Call Copyright;
trace n;
/* ... Do the main processing ... */

FTPErrorStmt = 'FTPSetUser';
rc = FTPSetUser(Remote, UserID, Passwd)
If rc \= 1 then signal error;

FTPErrorStmt = 'FTPSetBinary';
rc = FTPSetBinary('ASCII')
If rc \= 1 then signal error;

/* FTPErrorStmt = 'FTPSite'; */
/* rc = FTPSite() */
/* If rc \= 0 then signal error; */

FTPErrorStmt = 'FTPSys';
OperSys = FTPSys(WRemote); /* - Get remote site operating system info */
If Debug = Yes then Say 'Remote Operating System =' OperSys;
OperSys = translate(OperSys);

/* Set up directory delimeter (\ or /) */
If pos('UNIX',OperSys) > 0 then RemoteDir = translate(RemoteDir,'/','\');

Say 'LOCAL Dir  =' LOCALDir;
Say 'Remote Dir =' RemoteDir;

If Debug = Yes then Say FTPERRNO;
FTPErrorStmt = 'FTPChDir';
rc = FTPChDir(RemoteDir);  /* - change to the correct directory */
If rc \= 0 then signal error;
if Debug = Yes then Say FTPERRNO;

RemoteNames. = '';
RemoteNames.0 = 0;
FTPErrorStmt = 'FTPDir';
rc = FTPls('*','RemoteNames.'); /* - get a listing of files in remote directory */
If rc \= 0 then do;
   Say 'FTPERRNO = ' FTPERRNO;
   Say 'No files to fetch...';
end  /* Do */
If Debug = Yes then Say FTPERRNO;

Do I = 1 to RemoteNames.0;
   If RemoteNames.I = 'lock' then do;
      Say 'Remote directory is locked';
      RemoteNames.0 = 0;
   end  /* Do */
end /* do */

GetFiles = 0;
FTPErrorStmt = 'FTPGetUnique';
Do I = 1 to RemoteNames.0;
   e_name = LOCALDir||'\'||RemoteNames.I;
   if pos('/',RemoteNames.I)=0 then do;
     say 'Getting' RemoteNames.I;
     rc = FTPGet(e_name, RemoteNames.I);
/*   If rc \= 0 then signal error;*/
     If Debug = Yes then Say FTPERRNO;
     GetFiles = GetFiles + 1;
/*   rc = FTPDelete(RemoteNames.I);*/
/*   If rc \= 0 then signal error;*/
     If Debug = Yes then Say FTPERRNO;
   end  /* Do */
/*   else say 'Ignoring' RemoteNames.I;*/
end /* do */

/* Compare our directory to that of remote machine, generating
                    error messages, if necessary */
if GetFiles = RemoteNames.0 then say 'Number of files transferred is:' RemoteNames.0;
else do;
   say 'Number of LOCAL files:' GetFiles;
   say 'Number of Remote files:' RemoteNames.0;
end  /* Do */
/*----------------------------------------------------------*/

If Debug = Yes then Say FTPERRNO;
FTPErrorStmt = 'FTPChDir2';

/*'cd certs'*/
rc = FTPChDir('certs1');  /* - change to the correct directory */
If rc \= 0 then signal error;
if Debug = Yes then Say FTPERRNO;

RemoteNames. = '';
RemoteNames.0 = 0;
FTPErrorStmt = 'FTPDir';
rc = FTPls('*','RemoteNames.'); /* - get a listing of files in remote directory */
If rc \= 0 then do;
   Say 'FTPERRNO = ' FTPERRNO;
   Say 'No files to fetch...';
end  /* Do */
If Debug = Yes then Say FTPERRNO;

Do I = 1 to RemoteNames.0;
   If RemoteNames.I = 'lock' then do;
      Say 'Remote directory is locked';
      RemoteNames.0 = 0;
   end  /* Do */
end /* do */

GetFiles = 0;
FTPErrorStmt = 'FTPGetUnique';
Do I = 1 to RemoteNames.0;
   e_name = LOCALDir||'\certs\'||RemoteNames.I;
   if pos('/',RemoteNames.I)=0 then do;
     say 'Getting' RemoteNames.I;
     rc = FTPGet(e_name, RemoteNames.I);
     If Debug = Yes then Say FTPERRNO;
     GetFiles = GetFiles + 1;
     rc = FTPDelete(RemoteNames.I);
     If rc \= 0 then signal error;
     If Debug = Yes then Say FTPERRNO;
   end  /* Do */
/*   else say 'Ignoring' RemoteNames.I;*/
end /* do */

/* Compare our directory to that of remote machine, generating
                    error messages, if necessary */
if GetFiles = RemoteNames.0 then say 'Number of files transferred is:' RemoteNames.0;
else do;
   say 'Number of LOCAL files:' GetFiles;
   say 'Number of Remote files:' RemoteNames.0;
end  /* Do */
/*'cd ..';*/

/*----------------------------------------------------------*/

If Debug = Yes then Say FTPERRNO;
FTPErrorStmt = 'FTPChDir2';

/*'cd certs'*/
rc = FTPChDir('../certs2');  /* - change to the correct directory */
If rc \= 0 then signal error;
if Debug = Yes then Say FTPERRNO;

RemoteNames. = '';
RemoteNames.0 = 0;
FTPErrorStmt = 'FTPDir';
rc = FTPls('*','RemoteNames.'); /* - get a listing of files in remote directory */
If rc \= 0 then do;
   Say 'FTPERRNO = ' FTPERRNO;
   Say 'No files to fetch...';
end  /* Do */
If Debug = Yes then Say FTPERRNO;

Do I = 1 to RemoteNames.0;
   If RemoteNames.I = 'lock' then do;
      Say 'Remote directory is locked';
      RemoteNames.0 = 0;
   end  /* Do */
end /* do */

GetFiles = 0;
FTPErrorStmt = 'FTPGetUnique';
Do I = 1 to RemoteNames.0;
   e_name = LOCALDir||'\certs\'||RemoteNames.I;
   if pos('/',RemoteNames.I)=0 then do;
     say 'Getting' RemoteNames.I;
     rc = FTPGet(e_name, RemoteNames.I);
     If Debug = Yes then Say FTPERRNO;
     GetFiles = GetFiles + 1;
     rc = FTPDelete(RemoteNames.I);
     If rc \= 0 then signal error;
     If Debug = Yes then Say FTPERRNO;
   end  /* Do */
/*   else say 'Ignoring' RemoteNames.I;*/
end /* do */

/* Compare our directory to that of remote machine, generating
                    error messages, if necessary */
if GetFiles = RemoteNames.0 then say 'Number of files transferred is:' RemoteNames.0;
else do;
   say 'Number of LOCAL files:' GetFiles;
   say 'Number of Remote files:' RemoteNames.0;
end  /* Do */
/*'cd ..';*/


/*----------------------------------------------------------*/

If Debug = Yes then Say FTPERRNO;
FTPErrorStmt = 'FTPChDir2';

/*'cd certs'*/
rc = FTPChDir('../certs3');  /* - change to the correct directory */
If rc \= 0 then signal error;
if Debug = Yes then Say FTPERRNO;

RemoteNames. = '';
RemoteNames.0 = 0;
FTPErrorStmt = 'FTPDir';
rc = FTPls('*','RemoteNames.'); /* - get a listing of files in remote directory */
If rc \= 0 then do;
   Say 'FTPERRNO = ' FTPERRNO;
   Say 'No files to fetch...';
end  /* Do */
If Debug = Yes then Say FTPERRNO;

Do I = 1 to RemoteNames.0;
   If RemoteNames.I = 'lock' then do;
      Say 'Remote directory is locked';
      RemoteNames.0 = 0;
   end  /* Do */
end /* do */

GetFiles = 0;
FTPErrorStmt = 'FTPGetUnique';
Do I = 1 to RemoteNames.0;
   e_name = LOCALDir||'\certs\'||RemoteNames.I;
   if pos('/',RemoteNames.I)=0 then do;
     say 'Getting' RemoteNames.I;
     rc = FTPGet(e_name, RemoteNames.I);
     If Debug = Yes then Say FTPERRNO;
     GetFiles = GetFiles + 1;
     rc = FTPDelete(RemoteNames.I);
     If rc \= 0 then signal error;
     If Debug = Yes then Say FTPERRNO;
   end  /* Do */
/*   else say 'Ignoring' RemoteNames.I;*/
end /* do */

/* Compare our directory to that of remote machine, generating
                    error messages, if necessary */
if GetFiles = RemoteNames.0 then say 'Number of files transferred is:' RemoteNames.0;
else do;
   say 'Number of LOCAL files:' GetFiles;
   say 'Number of Remote files:' RemoteNames.0;
end  /* Do */
/*'cd ..';*/

/*-----------------------------------------------------------------*/

If Debug = Yes then Say FTPERRNO;
FTPErrorStmt = 'FTPChDir3';

/*'cd newaccdd';*/
rc = FTPChDir('../newaccdd');  /* - change to the correct directory */
If rc \= 0 then signal error;
if Debug = Yes then Say FTPERRNO;

RemoteNames. = '';
RemoteNames.0 = 0;
FTPErrorStmt = 'FTPDir';
rc = FTPls('*','RemoteNames.'); /* - get a listing of files in remote directory */
If rc \= 0 then do;
   Say 'FTPERRNO = ' FTPERRNO;
   Say 'No files to fetch...';
end  /* Do */
If Debug = Yes then Say FTPERRNO;

Do I = 1 to RemoteNames.0;
   If RemoteNames.I = 'lock' then do;
      Say 'Remote directory is locked';
      RemoteNames.0 = 0;
   end  /* Do */
end /* do */

GetFiles = 0;
FTPErrorStmt = 'FTPGetUnique';
Do I = 1 to RemoteNames.0;
   e_name = LOCALDir||'\newaccdd\'||RemoteNames.I;
   if pos('/',RemoteNames.I)=0 then do;
     say 'Getting' RemoteNames.I;
     rc = FTPGet(e_name, RemoteNames.I);
     If Debug = Yes then Say FTPERRNO;
     GetFiles = GetFiles + 1;
     rc = FTPDelete(RemoteNames.I);
     If rc \= 0 then signal error;
     If Debug = Yes then Say FTPERRNO;
   end  /* Do */
/*   else say 'Ignoring' RemoteNames.I;*/
end /* do */

/* Compare our directory to that of remote machine, generating
                    error messages, if necessary */
if GetFiles = RemoteNames.0 then say 'Number of files transferred is:' RemoteNames.0;
else do;
   say 'Number of LOCAL files:' GetFiles;
   say 'Number of Remote files:' RemoteNames.0;
end  /* Do */
/*'cd ..';*/
/*-----------------------------------------------------------------*/
/* Write Log in our directory */
/* rc = PrxUtils(...); */
/* rc = FTPPutUnique(Log); */ /* - copy Log to remote directory */

FTPErrorStmt = 'FTPLogoff';
rc = FTPLogoff();
If Debug = Yes then Say FTPERRNO;

FTPErrorStmt = 'FTPDropFuncs';
/*rc = FTPDropFuncs();*/

/* If PRINT=Yes then Print the Log */
Signal CleanUp;
/*---------------- End of Main processing --------------------*/

CLEANUP:
  trace o;
  If Debug = Yes then say 'At Cleanup...';

EndIt:
  If Debug = Yes then say 'At EndIt...';
  call directory  curdir
  rc = endlocal();
/*  'exit'; */
Exit;

Error:
  trace o;
  Say 'FTP Error =' FTPERRNO 'at' FTPErrorStmt;
  Say 'We got here from line' RX_Sigl;
  Say '  That is:' RX_SourceLine;
  Say 'Debug values follow:-';
  Say 'Condition:      ' RX_Condition;
  Say 'Source line no: ' RX_Sigl;
  Say 'Source line:    ' RX_SourceLine;
  Say 'Condition(C):   ' RX_Cond_C;
  Say 'Condition(I):   ' RX_Cond_I;
  Say 'Condition(D):   ' RX_Cond_D;
  Say 'Condition(S):   ' RX_Cond_S;

  Signal CLEANUP;

/*========================================================*/
/* Start of internal subroutines, in alphabetical order   */
/*========================================================*/

/*------------------------------------------------------------*/
Copyright:
bQuiet = 1;
  If bQuiet > 0 then return;
  msg.0 = 4;
  msg.1 = '               This product is copyright by';
  msg.2 = '           Consolidated Share Registrars Limited';
  msg.3 = '                 All rights are reserved.';
  msg.4 = '';
  Do I = 1 to msg.0;
     Say msg.I;
  end /* do */
/*  parse pull upper I; */
/*  If I \= 'OK' then signal error; */
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
rc = setlocal();

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
  Print    = No;
  Compress = No;
  Indent   = 5;
  LineLen  = 60;
  Align    = No;
/*  UserID = 'INVALID UserID';*/
/*  Passwd = 'INVALID Passwd';*/
/*  Remote = 'csra';*/
/*  RemoteDir = '/oracle/data3/modules/';*/
/*  SourceDir   = '\csrora\modules\';*/

  Do I = 1 to words(ProcOpts);

    work = word(ProcOpts, I);
    parse var work Keyword '=' parm;
    parm = strip(parm);
    Keyword = translate(Keyword);
    If Debug = Yes then say Keyword '=' parm;
    Select
      when Keyword = 'PASSWD' then Passwd = parm;
      when Keyword = 'USERID' then UserID = parm;
      when Keyword = 'REMOTE' then Remote = parm;
      when Keyword = 'REMOTEDIR' then RemoteDir = parm;
      when Keyword = 'LOCALDRIVE' then LOCALDrive = parm;
      when Keyword = 'LOCALDIR' then LOCALDir = parm;
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
        Do j = 1 to msg.0;
           say msg.j;
        end /* do */
    end;  /* select */
  end; /* do */

Return;

/*------------------------------------------------------------*/

RX_Failure:
  trace o;
  RX_Condition  = 'Failure';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal Error;

/*------------------------------------------------------------*/

RX_Halt:
  trace o;
  RX_Condition  = 'Halt';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal Error;

/*------------------------------------------------------------*/

RX_Syntax:
  trace o;
  RX_Condition  = 'Syntax';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal Error;

/*------------------------------------------------------------*/

RX_Error:
  trace o;
  RX_Condition  = 'Error';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal Error;

/*------------------------------------------------------------*/

RX_NoValue:
  trace o;
  RX_Condition  = 'NoValue';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal Error;

/*------------------------------------------------------------*/

RX_NotReady:
  trace o;
  RX_Condition  = 'NotReady';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal Error;

/*------------------------------------------------------------*/

