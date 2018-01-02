/*-- REXX ------------------------------------------------------------*/
/*                                                                    */
/* Module name: PRXTEST1.CMD                                          */
/*                                                                    */
/* Function:    Test PRXUTILS.DLL file functions.                     */
/*                                                                    */
/* Author:      W. David Ashley                                       */
/*                                                                    */
/* (C) Copyright Pedagogic Software 1992.  All rights reserved.       */
/*                                                                    */
/* Modifications:                                                     */
/* --------  ---  --------------------------------------------------- */
/* 06/28/92  WDA  Initial Release                                     */
/*                                                                    */
/*--------------------------------------------------------------------*/


/* get any input options */
if arg() = 1 then arg opt
else opt = ''

/* drop functions if necessary */
if opt = 'DELETE' then do
   if rxfuncquery('PrxDropFuncs') then ,
    call RxFuncAdd 'PrxDropFuncs', 'PRXUTILS', 'PRXDROPFUNCS'
   call PrxDropFuncs
   say; say 'Functions dropped.'
   exit 0
   end

/* add all PRXUTILS functions */
call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS'
call PrxLoadFuncs
say; say 'Functions loaded.'


/* give greetings */
vers_string = PrxUtilsVersion()
parse var vers_string vers versdate
vers_string = 'This is a test cmd for PRXUTILS.DLL Version'
vers_string = vers_string vers 'dated' versdate'.'
say; say vers_string
call Pause

/* test PrxCopyFile() */
say; say "Testing PrxCopyFile() by creating the file 'Rextemp1.fil':"
say "Copying 'c:\config.sys' to 'rextemp1.fil'."
retc = PrxCopyFile('c:\config.sys', 'Rextemp1.fil')
say 'The return code from PrxCopyFile() was' retc
call Pause

/* test PrxReadToStem */
say; say "Testing PrxReadToStem() by reading in 'C:\CONFIG.SYS':"
retc = PrxReadToStem('c:\config.sys', 'file')
say 'The return code from PrxReadToStem() was' retc
say 'The number of lines in the file is' file.0'.'
say 'The listing of the file follows:'
call Pause
do num = 1 to file.0
  say file.num
  end
call Pause

/* test PrxWriteFromStem */
say; say "Testing PrxWriteFromStem() by creating the file 'Rextemp.fil':"
retc = PrxWriteFromStem('Rextemp.fil', 'file', file.0, , 'r')
say 'The return code from PrxWriteFromStem() was' retc
call Pause

/* test PrxMoveFile */
say; say "Testing PrxMoveFile() by renaming 'Rextemp.fil' to 'Rextemp2.fil':"
retc = PrxMoveFile('Rextemp.fil', 'Rextemp2.fil')
say 'The return code from PrxMoveFile() was' retc
call Pause

/* give salutations */
say; say 'PrxUtils test complete.'
say 'Deleting temporary files.'
'@del Rextemp1.fil'
'@del Rextemp2.fil'
say 'Bye'
exit 0


/*--------------------------------------------------------------------*/
/* Subroutines are below:                                             */
/*--------------------------------------------------------------------*/

Pause: procedure
/* prompt user and pause */
say 'Press Return to continue'
newline = linein()
return

