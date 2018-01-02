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
 Date written:  April 1994
 Author:        Rob Crothall & Associates - RJC
 Copyright:     Copyright (1994) by Rob Crothall & Associates, South Africa.
                All rights reserved.

 Arguments:     These are in the form KEYWORD=...  KEYWORD2=...
                Separate the end of one parameter from the next with a space.

   MICAT=filespec  Use this file to associate industry classifications and
                   descriptions with the files in the current directory for
                   selecting categories.  If this file is not specified, the
                   default will be 'MICAT.CTL' in the current directory.  If the
                   file is not found, it is created.

   QUIET=YES | NO  Suppresses copyright messages and other information displays.

   SKEL=MIREP.TXT  Skeleton file that will be used as a base on which to build
                   the report.  Default is MIREP.TXT.

   MIWORDS=MIWORDS.TXT  File containing User-defined keywords which are
                        replaced by a word or a phrase.

   PRINT=YES | NO  The generated report should be printed as soon as it is ready.
                   Default is YES.

   DEBUG=YES | NO  Various sections are traced when this is set to Yes.
                   Default is NO.

   LINELEN=65      The line length at which output text should be wrapped.

   INDENT=5        Number of characters to indent.

   ALIGN=YES | NO  Align the right side of the report

 Processing:    Initialise, including display of these comments if invoked
                  with a paramete of '?'.  Prepare to handle exception
                  conditions, if they arise.  Ensure that utility functions
                  are loaded.
                Process keyword parameters passed to the program.
                Display copyright information and get acknowledgement.
                Get details of the Client and the Subject.
                Read in the document skeleton selected by parameter.
                Read the current directory and descriptions of the files
                  (Categories) found.  Ignore those which do not belong to
                  the specified Industry or 'All Industries'.
                Offer the Categories for selection until CANCEL button
                  is pressed.  For each Category selected, offer 'Drivers'
                  for selection.  For each Driver selected, save the associated
                  text in the appropriate Section of the final document.
                Assemble the selected text into the correct sequence.
                Tailor the document by replacing keywords in the text by
                  Subject-specific details (e.g. name, title, etc).
                Write the completed document as ASCII text to the directory
                  specified.
                Print a copy of the text, if required.
                Compress the file using PKZIP, if required.
                Add a description to the FILES.BBS bulletin board index.
                Tidy up and return to the Workplace Shell.

 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Written by:    Rob Crothall   Date: May 1993
 Changed by:    Rob Crothall   Date: Sep 1993 To: Add replaceably words
                                                  which depend on industry
*/
/*********************************************************************
 *            (C) Copyright Rob Crothall & Associates 1994           *
 *********************************************************************/

/* Set options that help during debugging */
'@echo off';

Debug = Yes;
call trace('?r');

rc = 0;
MI_RC = 0;
Warn. = '';
Warn.1 = 'Restricted - property of Rob Crothall';
arg ProcOpts;

/* Define some constants... */
Yes = 1;
No = 0;
VRexxActive = No;

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

Call RxFuncAdd 'VInit', 'VREXX', 'VINIT';
mi_rc = VInit();
VRexxActive = Yes;
If Debug = Yes then Say 'VRexx initialisation =' mi_rc;

If Debug = Yes then Say 'VRexx version' VGetVersion();
If Debug = Yes then Say 'Press Enter to continue..';
If Debug = Yes then pull nul;

/*------------- Main processing ------------------------------*/

call Initialize
Call Parameters;
Call Copyright;
/*         Call GetWords;       */
/*         Call GetDetails;     */
/*         Call SetUpDoc;       */
/*         Call GetCategory;    */

if debug = Yes then say 'Press Enter to continue...';
if debug = Yes then pull nul;
call directory  curdir
endlocal
exit



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
myname = translate(myname);
e_drive = left(myname,2)
temp = reverse(myname)
parse var temp 'DMC.'e_name'\'e_path;
e_path = reverse(e_path)'\'
e_name = reverse(e_name)

Path = value('PATH',,'OS2ENVIRONMENT')
DPath = value('DPATH',,'OS2ENVIRONMENT')
Help = value('HELP',,'OS2ENVIRONMENT')
BookShelf = value('BOOKSHELF',,'OS2ENVIRONMENT')
BookMgr   = value('BOOKMGR',,'OS2ENVIRONMENT')
ReadIBM   = value('READIBM',,'OS2ENVIRONMENT')
MyEnv     = value(e_name,,   'OS2ENVIRONMENT');
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

/************************************************
 * Update all paths in the environment          *
 ************************************************/
/*if pos(translate(e_drive'\INSTALL'), path) = 0
  then call value 'PATH', PATH||CDr'INSTALL;','OS2ENVIRONMENT'
if pos(translate(CDr'OS2BBS'), dpath) = 0
  then call value 'DPATH', DPATH||CDr'OS2BBS;','OS2ENVIRONMENT'
if pos(translate(CDr'INSTALL'), help) = 0
  then call value 'HELP', HELP||CDr'INSTALL;','OS2ENVIRONMENT'
call value 'CORE.DIR', CDr, 'OS2ENVIRONMENT'
call value 'USER.DIR', BDr, 'OS2ENVIRONMENT'
*******************************************************************/
return  /* Initialize */


