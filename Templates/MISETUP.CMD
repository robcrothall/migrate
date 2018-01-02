/*********************************************************************
   @ECHO OFF
   ECHO OS/2 Procedures Language 2/REXX not installed.
   ECHO Run Selective Installation from the Setup Folder to
   ECHO install REXX support.
   pause
   exit
 *********************************************************************
 Purpose:       Install MI folders and programs on the OS/2 Desktop

 Client:        Management Insight CC
 Date written:  Oct 1994
 Author:        Rob Crothall & Associates - RJC
 Copyright:     Copyright (1994) by Rob Crothall & Associates, South Africa.
                All rights reserved.

 Arguments:     These are in the form KEYWORD=...  KEYWORD2=...
                Separate the end of one parameter from the next with a space.

   QUIET=YES | NO  Suppresses copyright messages and other information displays.

 Processing:    Initialise, including display of these comments if invoked
                  with a paramete of '?'.  Prepare to handle exception
                  conditions, if they arise.  Ensure that utility functions
                  are loaded.
                Process keyword parameters passed to the program.
                Display logo and copyright information and get acknowledgement.
                Find 'MISetup.fil', and process line by line
                  Locate the directories we need, and check disk space
                    Create them, if necessary
                  Find the files we need in the current directory
                  Copy files to destination directories
                  Execute commands
                  Create folders, programs, shadows as required
                  Modify settings
                  Display messages, and accept input
                Tidy up and return to the Workplace Shell.

 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Written by:    Rob Crothall   Date: Oct 1994
 Changed by:                   Date:
*/
/*********************************************************************
 *            (C) Copyright Rob Crothall & Associates 1994           *
 *********************************************************************/

/* Define some constants... */
Yes = 1;
No = 0;
VRexxActive = No;
CmdFileSpec = '';
RejectIndx  = 0;

/* Set options that help during debugging */
'@echo off';

Debug = No;
/*If Debug = Yes then call trace('?r');*/
If Debug = Yes then say 'At beginning...';

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

Signal on failure  name RX_Failure;
Signal on halt     name RX_Halt;
Signal on syntax   name RX_Syntax;
Signal on error    name RX_Error;
Signal on novalue  name RX_NoValue;
Signal on notready name RX_NotReady;

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

If Debug = Yes then Say 'Press Enter to continue..';
If Debug = Yes then pull nul;

Direction = 1;
/*------------- Main processing ------------------------------*/


If Debug = Yes then say 'At Initialize...';
call Initialize

/* Process parameters passed to the program, incl filename    */
If Debug = Yes then say 'At Parameters...';
Call Parameters;

Call Welcome;

/* Read the file and process it a line at a time              */
If Debug = Yes then Say 'CmdFileSpec =' CmdFileSpec;
CmdFile. = '';
retcd = PrxReadToStem(CmdFileSpec, 'CmdFile');
If retcd \= 0 then do;
   Say 'RetCd =' retcd 'CmdFileSpec =' CmdFileSpec;
   Signal error;
end  /* Do */

If Debug = Yes then do;
   Say CmdFile.0 'records read from the Command File';
end  /* Do */

Do LineNo = 1 to CmdFile.0;

   CLine = CmdFile.LineNo;
   If Debug = Yes then say LineNo CLine;
   CLKeyword = word(CLine, 1);
   CLKeyword = translate(CLKeyword);

/* Select parameters, Categories, and Drivers                 */
   Select;

     When left(CLine, 1) = '%' then Cline = '';

     When left(CLine, 1) = '*' then Cline = '';

     When left(CLine, 2) = '/*' then Cline = '';

     When CLine = '' then do;
        /* nothing...  */
     end  /* Do */

     When verify(CLine,' -_=') = 0 then do;
        /* nothing...  */
     end  /* Do */

     When CLKeyword = 'CHECKDIR' then do;
        Parse var CLine Instr ReqDir FreeSpace ';' .;
        ReqDir    = space(ReqDir);
        FreeSpace = space(FreeSpace);
        If Debug = Yes then Say 'Instr     =' Instr;
        If Debug = Yes then Say 'ReqDir    =' ReqDir;
        If Debug = Yes then Say 'FreeSpace =' FreeSpace;

     end  /* Do */

     Otherwise do;
       /***call Err 'Unk', '002', 'W', 'Line not recognised - ignored', LineNo, CLine;***/
       /* Interpret command as Rexx */
       If Debug = Yes then trace('R');
       interpret CLine;
       If Debug = Yes then trace('O');
       If Debug = Yes then do;
          Say 'Press Enter to continue...';
          Pull ans;
       end  /* Do */

     end  /* Do */

   End  /* Select */

/* When any category is found, save the information           */

/* When a driver is selected, then                            */
/*   If the category has not been read in, then               */
/*     read in the category.                                  */
/*   Find and process the driver                              */
End; /* do */
/* At end of the request file,                                */

GENERATE:
If Debug = Yes then say 'At Generate...';

/* Tidy up and return.                                        */
Signal EndIt;

/*---------------- End of Main processing --------------------*/

CLEANUP:

  If Debug = Yes then say 'At Cleanup...';
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


EndIt:

  Say 'Current Directory =' curdir;
  If Debug = Yes then say 'At EndIt...';
  if Debug = Yes then call SysSleep 5;
/*  'start "Read and Process Queues..." /B /I /C CheckQ.CMD' MyQ; */

  call directory(curdir);
  result = endlocal();

Exit;

/*========================================================*/
/* Start of internal subroutines, in alphabetical order   */
/*========================================================*/

/*------------------------------------------------------------*/
Copyright:

  If bQuiet > 0 then return;
  msg.0 = 6;
  msg.1 = '               This product is copyright by';
  msg.2 = '                  Management Insight CC.';
  msg.3 = '                    All rights are reserved.';
  msg.4 = '';
  msg.5 = '           Press OK to acknowledge the rights';
  msg.6 = '  of Management Insight CC.  Press Cancel to end.';
  do itemp = 1 to msg.0;
     call SysSay msg.itemp;
  end /* do */
  call SysPause;


Return;

/*------------------------------------------------------------*/

Err:

Parse arg ErrPrefix, ErrNumber, ErrSeverity, ErrMsg, ErrLineNo, ErrLine;

RejectIndx  = RejectIndx + 2;
Reject.RejectIndx = '('||ErrLineNo||')' ErrLine;
RejectIndx  = RejectIndx + 1;
Reject.RejectIndx = '    ' ErrPrefix||'-'||ErrNumber||'-'||ErrSeverity':' ErrMsg;
If pos(ErrSeverity, 'IW') = 0 then GenOK = No;

Return;

/*------------------------------------------------------------*/

FNumb:  /* Format a number, with commas  */
parse arg numb
call comma
call concat
arg=newnum
return


/*------------------------------------------------------------*/

getBOOT:
bootdrive = Value('Path',,'OS2ENVIRONMENT')
parse upper var bootdrive bootdrive
Driveis = Substr(bootdrive,Pos('\OS2\SYSTEM',bootdrive)-2,2)
return


/*------------------------------------------------------------*/
GetCategory:

  retcd = PrxReadToStem(miCat, 'OldFiles');
  OldDesc. = '';
  If OldFiles.0 \= 'OLDFILES.0' then do I = 1 to OldFiles.0;
    Parse var OldFiles.I OldFn OldDesc.OldFn;
  end  /* Do */
  Say 'Result is:' retcd;
  Say 'Number of old file descriptions returned:' OldFiles.0;
  'del' miCat;  /* Get rid of the old one... */
  Cat. = '';
  K = 0;
  NewFiles. = '';
  call SysFileTree '*.*','fil','ft';
  do i = 1 to fil.0;
    Parse var fil.i yy'/'mm'/'dd'/'hh'/'min size attr fullname;
    fn = filespec('n',fullname);
    parse var fn nm '.' ext;
    if nm = 'FILES' then iterate;
    NewFiles.fn = 'Y';
    K = K + 1;
    Cat.K = fn OldDesc.fn;
  end /* do */
  Cat.0 = K;
  /* Sort into alphabetic order by file name ... */
  Do I = 1 to Cat.0;
    Do J = I to Cat.0;
      If Cat.I > Cat.J then do;
        Temp = Cat.I;
        Cat.I = Cat.J;
        Cat.J = Temp;
      End;
    End;
  End;

  If K > 0 then retcd = PrxWriteFromStem(miCat, 'Cat', K, 1, 'Replace');
     else If OldFiles.0 \= 'OLDFILES.0' then 'del' miCat;
  K = 0;
  Do I = 1 to Cat.0;
    If Industry \= '$'
      then if left(Cat.I, 1) = '$'
             then nop;
             else if left(Cat.I, 1) = Industry
                    then nop;
                    else iterate;
      else nop;
    If Level \= '$'
      then if substr(Cat.I, 2, 1) = '$'
             then nop;
             else if substr(Cat.I, 2, 1) = Level
                    then nop;
                    else iterate;
      else nop;
    K = K + 1;
    If I \= K then do;
      Cat.K = Cat.I;
      Cat.I = '';
    end  /* Do */
  End;
  Cat.0 = K;
  If Debug = Yes then Say 'Number of files found:    ' K;
  If Debug = Yes then Say 'Cat.0 =' Cat.0;
  If Debug = Yes then Do K = 1 to Cat.0;
     Say 'Found:' Cat.K;
  end; /* do */
Return;

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

a = 1;
do a = 1 to 25;
  d.a = '';
end;

dmap  = SysDriveMap('c:', 'LOCAL');
parse value dmap with d.1 d.2 d.3 d.4 d.5 d.6 d.7 d.8 d.9 d.10 d.11 d.12 d.13 d.14 d.15 d.16 d.17 d.18 d.19 d.20 d.21 d.22 d.23 d.24 D.25;
FAT   = 'NO';
HPFS  = 'NO';
a     = 1;
drive = d.a;
do while (d.a \= '');
  rc        = SysMkDir(drive'\'muchtoolargeforFAT);
  if rc=206 then do;
    FAT     = 'YES';
    Type.a  = 'FAT';
  end;
  else do;
    if rc=19 then Type.a = 'CD-ROM';
    else do;
      HPFS   = 'YES';
      type.a = 'HPFS';
      call SysRmDir(drive'\'muchtoolargeforFAT);
    end;
  end;
  dinfo.a   = SysDriveInfo(d.a);
  parse var dinfo.a d.a ":" free.a total.a label.a;
  pfree.a   = free.a/total.a;
  pfree.a   = 100*pfree.a;
  pfree.a   = trunc(pfree.a,2);
  a         = a+1;
  drive     = d.a;
  If Debug = Yes then do;
     Say 'Drive =' d.a ' % Free =' pfree.a ' Total free =' free.a;
  end  /* Do */
  else
end;

return;


/*------------------------------------------------------------*/

Initialize:

'@ECHO OFF'
result = setlocal();

/*********************************************************************
 * Find what our home directory is, and where we are being           *
 * executed from.                                                    *
 * We will also save the value of various environmental variables.   *
 *********************************************************************/
curdir = directory();

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
MIPath     = value('MIPATH',,'OS2ENVIRONMENT')
Help       = value('HELP',,'OS2ENVIRONMENT')
BookShelf  = value('BOOKSHELF',,'OS2ENVIRONMENT')
BookMgr    = value('BOOKMGR',,'OS2ENVIRONMENT')
ReadIBM    = value('READIBM',,'OS2ENVIRONMENT')
MyEnv      = value(substr(e_name,1,5),,'OS2ENVIRONMENT');
/************************************************
 * Make sure that all paths end in a ;          *
 ************************************************/
if right(PATH,1) <> ';'
  then PATH = PATH';'
if right(DPATH,1) <> ';'
  then DPATH = DPATH';'
if right(MIPATH,1) <> ';'
  then MIPATH = MIPATH';'
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
if debug=Yes then say 'MIPath  =' MIPATH;

InitVariables:
getBOOT:
bootdrive     = Value('Path',,'OS2ENVIRONMENT')
parse upper var bootdrive bootdrive
BootDrive     = Substr(bootdrive,Pos('\OS2\SYSTEM',bootdrive)-2,2)

/************************************************
 * Find the Command file                        *
 ************************************************/
If Debug = Yes then trace('R');

temp. = '';
CmdFileSpec = e_name||'.fil';
result = SysFileTree(CmdFileSpec, 'temp', 'FO');
If temp.0 > 0 then CmdFileSpec = temp.1;
else do;
       result = SysFileTree(e_path||CmdFileSpec, 'temp', 'FO');
       If temp.0 > 0 then CmdFileSpec = temp.1;
       else do;
              result = SysFileTree('\'CmdFileSpec, 'temp', 'FSO');
              If temp.0 > 0 then CmdFileSpec = temp.1;
              else do;
                     Say 'Error: Can not find "'CmdFileSpec'" in Path or on this disk.';
                     Say 'Please investigate, fix, and rerun.';
                     Signal error;
              end  /* Do */
            end;
     end;
If Debug = Yes then trace('O');

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
MacroRep:  /* Replace symbolic parameters in the document     */
           /*   by the details (e.g. Name) captured earlier.  */

    ChangedCount = 0;
    If Debug = Yes then say 'Start of MacroRep';
    MacroOut = '';
    If MacroIn = '' then MacroIn = '&SP';
    Rest     = MacroIn;
    If Debug = Yes then say 'Rest =' Rest;
    KStart   = 1;
    WordLen  = 0;
    WordRep  = '';
    Changed  = No;
    J = 0;
    JMax = 0;
    Do while((J < words(Rest)) & (JMax < 100000));
      /* Find a target string starting with '&' */
      J = J + 1;
      JMax = JMax + 1;
      If Debug = Yes then do;
        say 'Rest =' Rest;
        say 'J =' J '    JMax =' JMax;
      end  /* Do */

      Target = word(Rest, J);
      If left(Target, 1) \= '&' then iterate;
      If length(Target) < 2 then iterate;
      parse var Target Keyword '=' Value;
      KStart = wordindex(Rest, J);
      KLength = length(Target);
      KeyWordUp = Translate(Target);
      WordLen = 0;
      Select;

        When abbrev(KeyWordUp,'&DRIVER') then do;
           WordLen = KLength;
           If Debug = Yes then do;
             WordRep = substr(Target,2);
             WordLen = KLength;
           End;
           Else WordRep = '';
        end; /* Do */

        When abbrev(KeyWordUp, '&SECTION') then do;
           WordLen = KLength;
           If Debug = Yes then do;
             WordRep = substr(Target,2);
             WordLen = KLength;
           End;
           Else WordRep = '';
        end; /* Do */

        When abbrev(KeyWordUp, '&TITLE') then do;
           WordLen = 6;
           WordRep = Title;
        end; /* Do */

        When abbrev(KeyWordUp, '&INITIALS') then do;
           WordLen = 9;
           WordRep = Initials;
        end; /* Do */

        When abbrev(KeyWordUp, '&SURNAME') then do;
           WordLen = 8;
           WordRep = Surname;
        end; /* Do */

        When abbrev(KeyWordUp, '&UTITLE') then do;
           WordLen = 7;
           WordRep = translate(Title);
        end; /* Do */

        When abbrev(KeyWordUp, '&UINITIALS') then do;
           WordLen = 10;
           WordRep = translate(Initials);
        end; /* Do */

        When abbrev(KeyWordUp, '&USURNAME') then do;
           WordLen = 9;
           WordRep = translate(Surname);
        end; /* Do */

        When abbrev(KeyWordUp, '&DATE') then do;
           WordLen = 5;
           WordRep = date('L');
        end; /* Do */

        Otherwise;

      End; /* select */

      Do L = 1 to NewWords.0 while(WordLen = 0);
         If Debug = Yes then say Keyword '=' TheWord.L Gender '=' WSex.L Level '=' WLevel.L Industry '=' WInd.L;
         If abbrev(KeyWord, TheWord.L) then if (Gender = WSex.L | WSex.L = '$') then if (pos(Level, WLevel.L)>0 | WLevel.L = '$') then if (pos(Industry, WInd.L)>0 | WInd.L  = '$') then do;
            WordLen = length(TheWord.L);
            WordRep = WRepl.L;
         end; /* do */
      end L; /* Do */
      If Debug = Yes then say 'WordLen =' WordLen;
      If Debug = Yes then nop;
      If WordLen > 0 then do;
         Changed = Yes;
         ChangedCount = ChangedCount + 1;
         If (WordRep = '') & (WordLen = Klength) then do;
            WordLen = WordLen + 1;
         End;

         If KStart > 1 then Rest = substr(Rest, 1, KStart-1) || WordRep || substr(Rest, KStart+WordLen);
           Else Rest = WordRep || substr(Rest, KStart+WordLen);
         If Debug = Yes then Say 'Rest =' Rest;
         If Debug = Yes then Say 'J =' J;
         J = max(0, J-10);
      end;  /* Do */
    End; /* do */
    MacroOut = Rest;
    If Debug = Yes then say 'End of MacroRep';

Return;


/*------------------------------------------------------------*/
Parameters:  /* Handle default options and parameters passed to us... */

  Do I = 1 to 0; /*words(ProcOpts);*/

    work = word(ProcOpts, I);
    parse var work Keyword '=' parm;
    parm = strip(parm);

    Select
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
        do itemp = 1 to msg.0;
           call SysPause msg.itemp;
        end /* do */
    end;  /* select */
  end; /* do */

Return;

/*------------------------------------------------------------*/
PrintDoc:

  If Print = Yes then 'Print' FileSpec;
Return;

/*------------------------------------------------------------*/

RX_Failure:
  RX_Condition  = 'Failure';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

RX_Halt:
  RX_Condition  = 'Halt';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

RX_Syntax:
  RX_Condition  = 'Syntax';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

RX_Error:
  RX_Condition  = 'Error';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

RX_NoValue:
  RX_Condition  = 'NoValue';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

RX_NotReady:
  RX_Condition  = 'NotReady';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

SelectDriver:

  DrNo = 0;
  Do L = 1 to Driver.0;
     If Driver.L = DrvName then do;
        DrNo = L;
        leave L;
     end  /* Do */
  end /* do */
  If DrNo = 0 then do;
     call err 'Req', '001', 'E', 'Driver name invalid', LineNo, CLine;
     return;
  end  /* Do */
  sel.  = '';
  sel.0 = 0;
  Section = 0;
  Do L = DrStart.DrNo to DrEnd.DrNo;
    Do J = 1 to words(In.L);
      work = word(In.L, J);
      work = Translate(work);
      If left(work, 1) = '&' then do;
        Parse var work Keyword '=' value;
        Select;
          When Keyword = '&SECTION' then do;
            Section = value;
            If Section > SectMax then SectMax = Section;
            If Debug = Yes then In.L = Category ':' Driver ':' In.L;
          End;
          Otherwise;
            Nop;
        End;
      End;
    End;
    Line.Section = Line.Section + 1;
    K = Line.Section;
    DocOut.Section.K = In.L;
    if Debug = Yes then do;
      Say 'In.L =' In.L;
      nop;
    End; /* do */
  End;

Return;

/*------------------------------------------------------------*/

SetUpDoc:  /* Set up the skeleton document */

  DocOut. = '';
  mirc = PrxReadToStem(Skel, 'In');
  If In.0 = 'IN.0' then do;
    msg.1 = 'File' Skel 'not found. Process abandoned.';
    msg.0 = 1;
    rb    = VMsgBox('Parameter error?', msg, 2);
    signal CLEANUP;
  End;
  If (In.1 \= Warn.1) & (In.1 \= Warn.2) then do;
      Say 'Wrong version of Category file';
      Signal EndIt;
  End;
  InSect  = 0;
  Sect    = 0;
  Section = 0;
  SectMax = 0;
  Line.   = 0;
  Do I = 2 to In.0;
    In.I = translate(In.I, b, a);
    In.I = reverse(In.I);
    Do J = 1 to words(In.I);
      work = word(In.I, J);
      If left(work, 1) = '&' then do;
        Parse var work Keyword '=' value;
        Select;
          When Keyword = '&SECTION' then do;
            Section = value;
            W1 = wordindex(In.I, J) - 1;
            W2 = wordindex(In.I, J+1);
            If Debug \= Yes then do;
              If W2 > W1 then In.I = substr(In.I, 1, W1) || substr(In.I, W2);
            End;
            If Section > SectMax then SectMax = Section;
          End;
          Otherwise;
            Nop;
        End;
      End;
    End;
    Line.Section = Line.Section + 1;
    K = Line.Section;
    DocOut.Section.K = In.I;
  End;
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
TailorDoc:  /* Format the lines                               */

  If Debug = Yes then say 'Start of TailorDoc';
  IndentSt= 0;
  NewOut. = '';
  Line    = 1;

  Do I = 1 to Out.0;
    Rest    = Out.I;
    If Debug = Yes then say 'Out.'||I '=' Rest;
    Do while Rest \= '';
      Parse var Rest Next Rest;
      NextU = translate(Next);
      If (NextU = '&SP') & (Align = Yes) then do;
         If translate(Prev) = '&SP' then Line = Line + 1;
         else Line = Line + 2;
         IndentSt = 0;
         Iterate;
      end  /* Do */
      If (NextU = '&BR') & (Align = Yes) then do;
         Line = Line + 1;
         IndentSt = 0;
         Iterate;
      end  /* Do */
      If (Next = '*') then do;
         If (Align = Yes) then do;
            Line = Line + 1;
            Next = Next || copies(' ',Indent-2);
            IndentSt = 1;
         end  /* Do */
         else Next = '&BR'||Next||'&IN';
      end /* do */
      If length(NewOut.Line) + length(Next) + 1 > LineLen then do;
         Call RightAlign;
         Line = Line + 1;
         If IndentSt > 0 then NewOut.Line = copies(' ',IndentSt * Indent - 1);
      end /* do */

      If length(NewOut.Line) = 0 then NewOut.Line = Next;
/*      else If (left(NextU,1) = '&')|(left(Prev,1) = '&') then NewOut.Line = NewOut.Line||Next;*/
           else NewOut.Line = NewOut.Line Next;

      Prev = Next;
    end /* do */
  end /* do */

  NewOut.0 = Line;
  If Debug = Yes then say 'End of TailorDoc';
Return;


/*------------------------------------------------------------*/
TailorDoc2:  /* Format the lines                               */

  If Debug = Yes then say 'Start of TailorDoc';

  NewOut. = '';
  Line = 1;
  Do I = 1 to Out.0;
    Rest    = Out.I;
    If Debug = Yes then say 'Out.'||I '=' Rest;
    Star = left(Rest, 1);
    J = LineLen;
    If translate(word(Rest,1)) = '&SP' then do;
       Line = Line + 1;
       Star = '';
       iterate;
    end  /* Do */
    Do LineSeg = 1 to 1000 while(length(Rest) > 0);
      If Lineseg = 1 then do;
        If length(Rest) <= LineLen then do;
          NewOut.Line = Rest;
          Rest = '';
        End;
        Else do;
          J = lastpos(' ', Rest, Linelen);
          NewOut.Line = left(Rest, J-1);
          Call RightAlign;
          Rest = substr(Rest, J+1);
        End;
      End;
      Else if Star = '*' then do;
             If length(Rest) <= (Linelen - Indent) then do;
               NewOut.Line = left(' ', Indent, ' ') || Rest;
               Rest = '';
             End;
             Else do;
               J = lastpos(' ', Rest, Linelen-Indent);
               NewOut.Line = left(' ', Indent, ' ') || left(Rest, J-1);
               Call RightAlign;
               Rest = substr(Rest, J+1);
             End;
           End;
           Else do;
             If length(Rest) <= Linelen then do;
               NewOut.Line = Rest;
               Rest = '';
             End;
             Else do;
               J = lastpos(' ', Rest, Linelen);
               NewOut.Line = left(Rest, J-1);
               Call RightAlign;
               Rest = substr(Rest, J+1);
             End;
           End;
      Line = Line + 1;
    End;
  End I; /* do */
  NewOut.0 = Line;
  If Debug = Yes then say 'End of TailorDoc';
Return;

/*------------------------------------------------------------*/
RightAlign:

  If Debug = Yes then do;
    Say 'Start of RightAlign. Direction =' Direction;
    Say 'NewOut' Line '=' NewOut.Line;
  End;
  MinWords = 4;
  If Direction > 0 then do;
    If word(NewOut.Line,1) = '*' then LStart = 3;
    Else LStart = 2;
    LEnd = words(NewOut.Line);
    LIncr = 1;
    Direction = -1;
  End;
  Else do;
    LStart = Words(NewOut.Line);
    If word(NewOut.Line,1) = '*' then LEnd = 3;
    Else LEnd = 2;
    LIncr = -1;
    Direction = 1;
  End;

  Do while((Align = Yes) & (length(NewOut.Line) < LineLen) & (words(NewOut.Line) > MinWords));
    If Debug = Yes then do;
      Say 'Line length =' length(NewOut.Line);
      Say 'Line =' NewOut.Line;
      Say 'Do L =' LStart 'to' LEnd 'by' LIncr;
    End;
    Do L = LStart to LEnd by LIncr while (LineLen > length(NewOut.Line));
      NewOut.Line = insert(' ',NewOut.Line,wordindex(NewOut.Line,L)-1);
    End;
  End;
Return; /* RightAlign */

/*------------------------------------------------------------*/

Welcome:
'echo on';
/*'prompt $p$E[0;'34';'47';'5';'5'm]'*/
'@echo off';
'cls'
call SysCurState 'OFF'
call sysCurPos '4', '0'

msg.0  =12
msg.1  = green;
msg.2  = cr5 cr5' ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿'
msg.3  = cr5 cr5' ³                                ³'
msg.4  = cr5 cr5' ³    OS/2 Workplace Shell Install³'
msg.5  = cr5 cr5' ³                                ³'
msg.6  = cr5 cr5' ³                                ³'
msg.7  = cr5 cr5' ³                                ³'
msg.8  = cr5 cr5' ³                                ³'
msg.9  = cr5 cr5' ³                                ³'
msg.10 = cr5 cr5' ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
msg.11 = hwhite
msg.12 = cr5 '     Copyright (c) 1994 Rob Crothall & Associates       '

msg.13 = '         If needed, please Maximize SCREEN SIZE then Press Enter to Continue    '
do i =1  to msg.0
       say msg.i
       end
call SysCurPos '19','0'

say red;
call sysCurPos '7', '23'
call syssay 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
call sysCurPos '8', '21'
call syssay 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'


say;
say yellow;
call sysCurPos '10', '31'
call syssay 'Operating '
call sysSleep 1;

call sysCurPos '10', '41'
call syssay 'at a'
call sysSleep 1

call sysCurPos '11', '37'
call syssay 'higher'
call sysSleep 1

call sysCurPos '11', '44'
call syssay 'level'

say red;
call sysCurPos '11', '49'
call syssay '!'

say white;
call sysCurPos '11', '50'
call syssay '!'

say hblue;
call sysCurPos '11', '51'
call syssay '!'
call sysSleep 1

say hblack;
call sysCurPos '17', '0'
SAY'   If needed, please Maximize SCREEN SIZE ...'
call sysSleep 1

say red;
call sysCurPos '14', '26'
CALL SYSPAUSE ObjectName
call SysCurState 'ON'

say white;
call sysCurPos '18', '0'

/*'cls'*/
'echo on';
/* 'prompt $p$E[0;'34';'47';'5';'5'm]'*/
'@echo off';
/*'cls'*/
return

/*------------------------------------------------------------*/

/* create program object for regfunc.cmd  */
classname = 'WPProgram';
title     = 'Register RexxUtil';
location  = '<WP_DESKTOP>';
setup     = 'OBJECTID=<REGUFUNC_CMD>;'||,
            'EXENAME=C:\CMD\RegUFunc.CMD;'||,
            'PROGTYPE=WINDOWABLEVIO;';
result    = SysCreateObject(classname, title, location, setup, 'U');

/* create a shadow in the STARTUP folder */
classname = 'WPShadow';
title     = 'Register RexxUtil';
location  = '<WP_START>';
setup     = 'SHADOWID=<REGUFUNC_CMD>;'||,
            'OBJECTID=<SHAD_REGUFUNC_CMD>;';
result    = SysCreateObject(classname, title, location, setup, 'U');

/* The Bulletin Board */
classname = 'WPProgram';
title     = 'Max BBS';
location  = '<WP_DESKTOP>';
setup     = 'OBJECTID=<MAX_BBS>;'||,
            'EXENAME=C:\CMD\MAX.CMD;'||,
            'PROGTYPE=WINDOWABLEVIO;';
result    = SysCreateObject(classname, title, location, setup, 'f');

classname = 'WPFolder';
title     = 'Management^Insight';
location  = '<WP_DESKTOP>';
setup     = 'OBJECTID=<MI_FOLDER>;';
result    = SysCreateObject(classname, title, location, setup, 'f');

classname = 'WPProgram';
title     = 'MI Program';
location  = '<MI_FOLDER>';
setup     = 'OBJECTID=<MI_PROG1>;'||,
            'EXENAME=C:\CMD\MIProg.CMD;'||,
            'PROGTYPE=WINDOWABLEVIO;';
result    = SysCreateObject(classname, title, location, setup, 'f');

classname = 'WPShadow';
title     = 'OS/2 Window^Shadow';
location  = '<MI_FOLDER>';
setup     = 'SHADOWID=<WP_OS2WIN>';
result    = SysCreateObject(classname, title, location, setup, 'f');

