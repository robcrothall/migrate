/*********************************************************************
   @ECHO OFF
   ECHO OS/2 Procedures Language 2/REXX not installed.
   ECHO Run Selective Installation from the Setup Folder to
   ECHO install REXX support.
   pause
   exit
 *********************************************************************
 *********************************************************************
 * INSTALL.CMD                                                       *
 *                                                                   *
 * Just a simple copyright front end that will call ISIT.            *
 *                                                                   *
 *  legal options: /N don't change the CONFIG.SYS                    *
 *                                                                   *
 *********************************************************************
 *            (C) Copyright IBM Corporation 1992                     *
 *********************************************************************/

'@ECHO OFF'
setlocal
trace 'o'
curdir = directory()

call Initialize
call directory CDr'install'
'@isit /fo=pdk.cat'

call directory  curdir
endlocal
exit



Initialize:
/************************************************
 * Find out where we are executing from.  The   *
 * CTL file should be in the same directory.    *
 ************************************************/
parse source . . exec
drive = left(exec,2)'\'
temp = reverse(exec)
parse var temp '\'CDr
CDr = reverse(CDr)'\'

catdir = CDr'install'
Path = value('PATH',,'OS2ENVIRONMENT')
DPath = value('DPATH',,'OS2ENVIRONMENT')
Help = value('HELP',,'OS2ENVIRONMENT')
BookShelf = value('BOOKSHELF',,'OS2ENVIRONMENT')
BookMgr   = value('BOOKMGR',,'OS2ENVIRONMENT')
ReadIBM   = value('READIBM',,'OS2ENVIRONMENT')

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
parse upper var Path BDr'\OS2;'.
BDr = right(BDr,2)

/************************************************
 * Update all paths in the environment          *
 ************************************************/
if pos(translate(CDr'INSTALL'), path) = 0
  then call value 'PATH', PATH||CDr'INSTALL;','OS2ENVIRONMENT'
if pos(translate(CDr'OS2BBS'), dpath) = 0
  then call value 'DPATH', DPATH||CDr'OS2BBS;','OS2ENVIRONMENT'
if pos(translate(CDr'INSTALL'), help) = 0
  then call value 'HELP', HELP||CDr'INSTALL;','OS2ENVIRONMENT'
call value 'CORE.DIR', CDr, 'OS2ENVIRONMENT'
call value 'USER.DIR', BDr, 'OS2ENVIRONMENT'

return  /* Initialize */


