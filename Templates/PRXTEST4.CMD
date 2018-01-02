/*-- REXX ------------------------------------------------------------*/
/*                                                                    */
/* Module name: PRXTEST4.CMD                                          */
/*                                                                    */
/* Function:    Test exec for PRXUTILS.DLL VIO functions.             */
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


/* get screen mode settings */
'@CLS'
mode = PrxGetMode()
parse var mode type colors cols rows hres vres
say 'The screen type is' type
say 'The number of colors is' colors
say 'The number of columns is' cols
say 'The number of rows is' rows
say 'The horizontal resolution is' hres
say 'The vertical resolution is' vres
call Pause


/* fill screen with characters */
'@CLS'
call PrxWrtNChar 'A', cols*(rows-3), 0, 0
call PrxWrtCharStr copies(' ', cols), rows-3, 0
call PrxWrtCharStr "Screen filled with 'A' characters.", rows-3, 0
call PrxWrtCharStr copies(' ', cols), rows-2, 0
call PrxSetCurPos rows-2, 0
call PrxWrtTTY 'Press any key to continue...'
newline = linein()


/* change the attribute */
call PrxWrtNAttr x2c('72'), cols*(rows-3), 0, 0
call PrxWrtCharStr copies(' ', cols), rows-3, 0
call PrxWrtCharStr "Attributes changed to green on white.", rows-3, 0
call PrxSetCurPos rows-2, 0
call PrxWrtTTY 'Press any key to continue...'
newline = linein()


/* scroll up */
fill = 'B' || x2c('72')
call PrxScrollUp 0, 0, rows-4, cols, 4, fill
call PrxWrtCharStr copies(' ', cols), rows-3, 0
call PrxWrtCharStr "Screen scrolled up 4 lines with 'B' fill.", rows-3, 0
call PrxSetCurPos rows-2, 0
call PrxWrtTTY 'Press any key to continue...'
newline = linein()


/* scroll down */
fill = 'C' || x2c('72')
call PrxScrollDn 0, 0, rows-4, cols, 2, fill
call PrxWrtCharStr copies(' ', cols), rows-3, 0
call PrxWrtCharStr "Screen scrolled down 2 lines with 'C' fill.", rows-3, 0
call PrxSetCurPos rows-2, 0
call PrxWrtTTY 'Press any key to continue...'
newline = linein()


/* scroll left */
fill = 'D' || x2c('72')
call PrxScrollLf 0, 0, rows-4, cols, 10, fill
call PrxWrtCharStr copies(' ', cols), rows-3, 0
call PrxWrtCharStr "Screen scrolled left 10 cols with 'D' fill.", rows-3, 0
call PrxSetCurPos rows-2, 0
call PrxWrtTTY 'Press any key to continue...'
newline = linein()


/* scroll right */
fill = 'E' || x2c('72')
call PrxScrollRt 0, 0, rows-4, cols, 5, fill
call PrxWrtCharStr copies(' ', cols), rows-3, 0
call PrxWrtCharStr "Screen scrolled right 5 cols with 'E' fill.", rows-3, 0
call PrxSetCurPos rows-2, 0
call PrxWrtTTY 'Press any key to continue...'
newline = linein()


/* give salutations */
say; say 'PrxUtils test complete.'
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