/*-- REXX ------------------------------------------------------------*/
/*                                                                    */
/* Module name: PRXTEST3.CMD                                          */
/*                                                                    */
/* Function:    Test program for REXX Macrospace functions.           */
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

/*--------------------------------------------------------------------*/
/*  User note: This is a fully functional program and provides useful */
/*             functions and services.  The test input file provided  */
/*             for this exec is 'TESTIN.TXT'.  To execute this        */
/*             example use the following at the OS/2 cmd prompt:      */
/*                                                                    */
/*                        PRXTEST3 TESTIN.TXT                         */
/*                                                                    */
/*             The files PRXT1.CMD and PRXT2.CMD are assumed to be in */
/*             the current directory when the exec starts.            */
/*--------------------------------------------------------------------*/

/* check for correct input arguments */
if arg() <> 1 then call syntax
if length(arg(1)) < 3 then call syntax

/* get input arguments */
arg file
file = strip(file)

/* add all PRXUTILS functions */
call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS'
call PrxLoadFuncs
say; say 'Functions loaded.'

/* read input file */
say 'Reading input file' file'.'
retc = PrxReadToStem(file, 'fline')
if retc <> 0 then do
   select
      when retc = 3 then do
         say 'Error: Cannot open input file' file'.'
         exit 1
         end
      when retc = 1 then do
         say 'Error: Out of memory or memory error.'
         exit 1
         end
      when retc = 2 then do
         say 'Error: Internal REXX variable pool error.'
         exit 1
         end
      otherwise do
         say 'Unknown Error.'
         exit 1
         end
      end
   end
if fline.0 = 0 then do
   say 'Input file is empty.'
   say 'Program ended.'
   exit 0
   end

/* save the current Rexx macrospace then clear it */
retc = PrxMacroSave('temp.rxl')
if retc > 0 then do
   temp_saved = 'NO'
   if retc > 2 then do
      say 'Error: Could not save current Macrospace.'
      exit 1
      end
   end
else temp_saved = 'YES'
call PrxMacroErase

/* we are now ready to process the input file */
cmd = ''
parm1 = ''
parm2 = ''
parm3 = ''
do i = 1 to fline.0
   /* process a line of the input file */
   say "Executing line" i": '"fline.i"'"
   parse upper value fline.i with cmd parm1 parm2 parm3
   select
      when cmd = 'LOAD' then    call loadfile parm1, parm2, parm3
      when cmd = 'DROP' then    call dropfunc parm1
      when cmd = 'REORDER' then call reorder parm1, parm2
      when cmd = 'SAVE' then    call savefile parm1
      when cmd = 'DIR' then     call dirfile parm1
      when cmd = 'REM' then     nop
      otherwise do
        say 'Error: Invalid command in input file' file'.'
        call Reload
        exit 1
        end
      end
   end

/* reset Rexx macrospace to original condition */
call Reload

/* exit function */
say 'Program ended.'
exit 0

/**********************************************************************/
/*                                                                    */
/*  Function Name:  Loadfile()                                        */
/*                                                                    */
/*  Description:    Load a Rexx Macrospace library into the Macrospace*/
/*                                                                    */
/**********************************************************************/

Loadfile: procedure expose i

   if arg() = 3 then do
      retc = PrxMacroLoad(arg(1), arg(2), arg(3))
      end
   else if arg() = 1 then do
      retc = PrxMacroLoad(arg(1))
      end
   else do
      say 'Error: Line 'i' of input file.'
      say '  Incorrect number of arguments to function Loadfile().'
      call Reload
      exit 1
      end
   select
      when retc = 0 then do
         if arg() = 3 then,
          say 'Function 'arg(2)' successfully loaded to macrospace.'
         else,
          say 'Library 'arg(1)' successfully loaded to macrospace.'
         end
      when retc = 1 then do
         say 'Error: Line 'i' of input file.'
         say '  No Macro storage space available.'
         call Reload
         exit 1
         end
      when retc = 2 then do
         say 'Warning: Line 'i' of input file.'
         say '  Function not found.'
         end
      when retc = 4 then do
         say 'Warning: Line 'i' of input file.'
         say '  Function(s) already exist in macrospace.'
         say '  Function(s) not loaded to macrospace.'
         end
      when retc = 5 then do
         say 'Error: Line 'i' of input file.'
         say '  Macro file error.'
         call Reload
         exit 1
         end
      when retc = 6 then do
         say 'Error: Line 'i' of input file.'
         say '  Macro library file signature error.'
         call Reload
         exit 1
         end
      when retc = 7 then do
         say 'Error: Line 'i' of input file.'
         say '  Function source not found.'
         call Reload
         exit 1
         end
      when retc = 8 then do
         say 'Error: Line 'i' of input file.'
         say '  Invalid search position.'
         call Reload
         exit 1
         end
      otherwise do
         say 'Error: Line 'i' of input file.'
         say '  Unknown error.'
         call Reload
         exit 1
         end
      end
   return

/**********************************************************************/
/*                                                                    */
/*  Function Name:  Savefile()                                        */
/*                                                                    */
/*  Description:    Save a Rexx Macrospace to a file                  */
/*                                                                    */
/**********************************************************************/

Savefile: procedure expose i

   retc = PrxMacroSave(arg(1))
   select
      when retc = 0 then do
         say 'Macrospace saved to library file' arg(1)'.'
         end
      when retc = 2 then do
         say 'Warning: Line 'i' of input file.'
         say '  Macro function(s) not found.'
         end
      when retc = 3 then do
         say 'Warning: Line 'i' of input file.'
         say '  Extension required on Macro Library filename.'
         say '  Macrospace not saved.'
         end
      when retc = 5 then do
         say 'Error: Line 'i' of input file.'
         say '  Macro file error.'
         call Reload
         exit 1
         end
      otherwise do
         say 'Error: Line 'i' of input file.'
         say '  Unknown error.'
         call Reload
         exit 1
         end
      end
   return

/**********************************************************************/
/*                                                                    */
/*  Function Name:  Dropfunc()                                        */
/*                                                                    */
/*  Description:    Drop a function from the Rexx macrospace          */
/*                                                                    */
/**********************************************************************/

Dropfunc: procedure expose i

   retc = PrxMacroDrop(arg(1))
   select
      when retc = 0 then do
         say 'Function' arg(1) 'successfully dropped.'
         end
      when retc = 2 then do
         say 'Warning: Line 'i' of input file.'
         say '  Macro function(s) not found.'
         end
      otherwise do
         say 'Error: Line 'i' of input file.'
         say '  Unknown error.'
         call Reload
         exit 1
         end
      end
   return

/**********************************************************************/
/*                                                                    */
/*  Function Name:  Reorder()                                         */
/*                                                                    */
/*  Description:    Reorder macrospace function                       */
/*                                                                    */
/**********************************************************************/

Reorder: procedure expose i

   retc = PrxMacroReOrder(arg(1), arg(2))
   select
      when retc = 0 then do
         say 'Function' arg(1) 'successfully reorderd.'
         end
      when retc = 2 then do
         say 'Warning: Line 'i' of input file.'
         say '  Macro function(s) not found.'
         end
      when retc = 8 then do
         say 'Error: Line 'i' of input file.'
         say '  Invalid search position.'
         call Reload
         exit 1
         end
      otherwise do
         say 'Error: Line 'i' of input file.'
         say '  Unknown error.'
         call Reload
         exit 1
         end
      end
   return

/**********************************************************************/
/*                                                                    */
/*  Function Name:  Dirfile()                                         */
/*                                                                    */
/*  Description:    Shows the function directory of a REXX macrospace */
/*                  library file.                                     */
/*                                                                    */
/**********************************************************************/

Dirfile: procedure expose i

   retc = PrxMacroLibDir(arg(1), 'func')
   if retc <> 0 then select
      when retc = 1 then do
         say 'Error: Line 'i' of input file.'
         say '  Out of memory or memory error.'
         call Reload
         exit 1
         end
      when retc = 2 then do
         say 'Error: Line 'i' of input file.'
         say '  REXX variable pool error.'
         call Reload
         exit 1
         end
      when retc = 3 then do
         say 'Error: Line 'i' of input file.'
         say '  File open or read error for file' arg(1)'.'
         call Reload
         exit 1
         end
      otherwise do
         say 'Error: Line 'i' of input file.'
         say '  Unknown error.'
         call Reload
         exit 1
         end
      end

   /* Output each function directory entry */
   if func.0 = 0 then say 'No functions found in file' arg(1)'.'
   else do
      say 'Directory of' arg(1)'.'
      say '  Size    Pos     Function Name'
      say '-------- ------ --------------------------------------------'
      do j = 1 to func.0
         say func.j
         end
      end
   return

/**********************************************************************/
/*                                                                    */
/*  Function Name:  Reload()                                          */
/*                                                                    */
/*  Description:    Reload macrospace from temporary file.            */
/*                                                                    */
/**********************************************************************/

Reload: procedure expose temp_saved
   call PrxMacroErase
   if temp_saved = 'YES' then do
      call PrxMacroLoad 'temp.rxl'
      call PrxDelete 'temp.rxl'
      end
   return

/**********************************************************************/
/*                                                                    */
/*  Function Name:  Syntax()                                          */
/*                                                                    */
/*  Description:    Show function syntax and exit.                    */
/*                                                                    */
/**********************************************************************/

Syntax: procedure
   say; say 'Error: Incorrect input arguments.'
   say; say 'Function syntax: PRXTEST3 [d:[path]]filename.ext'
   say
   exit 1
