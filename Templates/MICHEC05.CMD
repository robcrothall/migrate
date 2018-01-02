/*********************************************************************
   @ECHO OFF
   ECHO OS/2 Procedures Language 2/REXX not installed.
   ECHO Run Selective Installation from the Setup Folder to
   ECHO install REXX support.
   pause
   exit
 *********************************************************************
 Purpose:       Create a personality profile based on clinical evaluation
 
 Client:        Management Insight CC
 Date written:  May 1994
 Author:        Rob Crothall & Associates - RJC
 Copyright:     Copyright (1994) by Rob Crothall & Associates, South Africa.
                All rights reserved.
 
 Arguments:     ? - Will display these comments.

 Processing:    Initialise, including display of these comments if invoked
                  with a paramete of '?'.  Prepare to handle exception
                  conditions, if they arise.  Ensure that utility functions 
                  are loaded.

                Tidy up and return to the Workplace Shell.
                                                          
 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Changed by:                   Date:
*/
/*********************************************************************
 *            (C) Copyright Rob Crothall & Associates 1994           *
 *********************************************************************/

/* Define some constants... */
Yes = 1;
No = 0;
VRexxActive = No;

/* Set options that help during debugging */
'@echo off';

Debug = No;

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

If Debug = Yes then call trace('?r');

Direction = 1;
/*------------- Main processing ------------------------------*/

If Debug = Yes then say 'At Initialize...';
call Initialize
If Debug = Yes then say 'At Parameters...';
Call Parameters;

/* ... Do the main processing ... */

Call ReadDriverDirectory;

Do I = 1 to CheckList.0;
   Out. = '';
   OutIndx = 1;
   Out.OutIndx = '% Management Insight Checklist generated on' date() 'at' time();
   Do until lines(CheckList.I) = 0;

      CLine = linein(CheckList.I);

      If ((words(CLine) = 1) & (Left(CLine,1) \= '%')) then do;
         Parse upper var CLine Category .;
         FileSpec = SysSearchPath('DPATH', Category);
         If FileSpec \= '' then do;
            OutIndx  = OutIndx + 2;
            Call GetDrivers;
            OutIndx  = OutIndx + 1;
            Category = '';
            FileSpec = '';
         end;  /* Do */
         else do;
            OutIndx = OutIndx + 1;
            Out.OutIndx = CLine;
         end  /* Do */
      end /* do */
      else do;
         OutIndx = OutIndx + 1;
         Out.OutIndx = CLine;
      end  /* Do */

   end /* do */
   Out.0 = OutIndx;
   Parse var CheckList.I fn '.' ext;
   OutFile = fn||'.CHK';
   If Out.0 > 0 then retcd = PrxWriteFromStem(OutFile, 'Out', Out.0, 1, 'Replace');
   If Out.0 > 0 then say 'File' OutFile 'written -' Out.0 'lines.';

end /* do */
Say 'Normal end of processing';
/*---------------- End of Main processing --------------------*/

CLEANUP:

  If Debug = Yes then say 'At Cleanup...';
  Say 'We got here from line' sigl;
  Say '  That is:' sourceline(sigl);
  if debug = Yes then pull nul;
  Say 'That''s all, folks!';

EndIt:
  
  Say 'Current Directory =' curdir;
  If Debug = Yes then say 'At EndIt...';
  if debug = Yes then say 'Press Enter to continue...';

  call directory  curdir
  endlocal

Exit;

/*========================================================*/
/* Start of internal subroutines, in alphabetical order   */
/*========================================================*/

/*------------------------------------------------------------*/
GetDrivers:

  DLine. = '';
  retcd = PrxReadToStem(Category, 'DLine');

  If Debug = Yes then Say 'RetCD =' retcd;
  If Debug = Yes then Say 'DLine.0 =' DLine.0;
  If Debug = Yes then Say 'DLine.1 =' DLine.1;
  If Debug = Yes then Say 'Category =' Category;

  If (retcd \= 0) | (DLine.0 = 'DLINE.0') then do;
     DLine.0 = 0;
     OutIndx = OutIndx + 1;
     Out.OutIndx = Category;
     Return;
  end  /* Do */

  Do ITemp = 1 to DLine.0;
     If ITemp = 1 then do;

        DLine.1 = strip(DLine.1);
        DLine.1 = Category '-' DLine.1;
        OutIndx = OutIndx + 1;
        Out.OutIndx = 'D....' DLine.1;
        OutIndx = OutIndx + 1;
        Out.OutIndx = '     ' substr('-',1,length(DLine.ITemp),'-');

     end  /* Do */

     Parse var DLine.ITemp . 'DRIVER=' Driver .;
     If Driver \= '' then do;
        Driver = translate(Driver, ' ', '_');
        OutIndx = OutIndx + 1;
        Out.OutIndx = '  <--' Driver;
     end  /* Do */

  end /* do */

Return;

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

  If Debug = Yes then call trace('?r');
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
    If Debug = Yes then nop;
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
        rb = VMsgBox('Parameter error?', msg, 3);
        If rb = 'CANCEL' then signal CLEANUP;
    end;  /* select */
  end; /* do */

Return;

/*------------------------------------------------------------*/
ReadDriverDirectory:
  DriverDir. = '';
  chk = 0;
  K = 0;
  call SysFileTree '*.*','fil','ft';
  do itemp = 1 to fil.0;
    Parse var fil.itemp yy'/'mm'/'dd'/'hh'/'min size attr fullname;
    fn = filespec('n',fullname);
    parse upper var fn nm '.' ext;
    if nm = 'FILES' then iterate;
    If ext = 'CH_' then do;
       chk = chk + 1;
       CheckList.chk = fn;
       iterate;
    end  /* Do */
    K = K + 1;
    DriverDir.K = fn;
  end /* do */
  DriverDir.0 = K;
  CheckList.0 = chk;

Return;


