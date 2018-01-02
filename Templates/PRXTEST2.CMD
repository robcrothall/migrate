/*-- REXX ------------------------------------------------------------*/
/*                                                                    */
/* Module name: PRXTEST2.CMD                                          */
/*                                                                    */
/* Function:    Test PRXUTILS date manipulation functions.            */
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


/* give greetings ***/
vers_string = PrxUtilsVersion()
parse var vers_string vers versdate
vers_string = 'This is a test cmd for PRXUTILS.DLL Version'
vers_string = vers_string vers 'dated' versdate'.'
say; say vers_string
call Pause

/* test PrxDateToBase() */
say; say "Testing PrxDateToBase():"
say "The current date('b') date is" date('b')
x = "The current PrxDateToBase("
say x || "date()) base date is" PrxDateToBase(date())
say x || "date('l'), 'l') base date is" PrxDateToBase(date('l'), 'l')
say x || "date('n'), 'n') base date is" PrxDateToBase(date('n'), 'n')
say x || "date('s'), 's') base date is" PrxDateToBase(date('s'), 's')
say
call Pause

/* test PrxBaseToDate() */
say; say "Testing PrxDateToBase():"
today = '1 January 1988'
base = PrxDateToBase(today, 'l')
say 'The base date for' today 'is' base
say "The PrxBaseToDate("base") date is" PrxBaseToDate(base)
say
today = '31 December 1988'
base = PrxDateToBase(today, 'l')
say 'The base date for' today 'is' base
say "The PrxBaseToDate("base",'l') date is" PrxBaseToDate(base, 'l')
say
today = '1 June 1989'
base = PrxDateToBase(today, 'l')
say 'The base date for' today 'is' base
say "The PrxBaseToDate("base",'s') date is" PrxBaseToDate(base, 's')
say
today = '15 November 1989'
base = PrxDateToBase(today, 'l')
say 'The base date for' today 'is' base
say "The PrxBaseToDate("base",'n') date is" PrxBaseToDate(base, 'n')
say
today = '29 Febuary 1992'
base = PrxDateToBase(today, 'l')
say 'The base date for' today 'is' base
say "The PrxBaseToDate("base") date is" PrxBaseToDate(base)
say
call Pause

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