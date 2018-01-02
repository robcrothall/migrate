Newsgroups: comp.lang.rexx
Path: hermes.is.co.za!news.sprintlink.net!dorite!pat
From: pat@iquest.net (Pat Shanahan)
Subject: Re: Inline Code for Rexx
Message-ID: <yQLTlKMw18o2079yn@iquest.net>
Lines: 430
Sender: pat@dorite.use.com (Pat Shanahan)
Reply-To: pat@iquest.net
Organization: South Avon Station, Indianapolis, IN
References: <3kbn2l$hhk@iconz.co.nz> <3kn8tm$1edf@watnews1.watson.ibm.com>
Distribution: inet
Date: Sun, 26 Mar 1995 11:57:48 GMT

In <3kbn2l$hhk@iconz.co.nz>, iboyes@iconz.co.nz (Ian Boyes) writes:
-:I am trying to find out if there is any way to include code segments
-:into rexx scripts in much the same way as C #defines. I would like to
-:have a set of modules that I can include without calling them

Yes, but it's a cludge.  See the following code I got from
        informatik.tu-muenchen.de  (I think <g>):


/********************** beginning of preproc.cmd *************************/
/**
*** ZDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD?
*** 3  PreProc.CMD -  Source code preprocessor v2.00                        3
*** 3                                                                       3
*** 3  This code will parse a source file for '#include' and '#define'      3
*** 3  statements and resolve them in a manner similar to the preprocessor  3
*** 3  found in many C compilers.  The support for 'define' is simple       3
*** 3  string substitution.  This will not handle macro expansion.          3
*** 3                                                                       3
*** 3  Those included files surrounded by double quotes (") must me in      3
*** 3  the current directory.  Those with angle brackets (<>) must be       3
*** 3  found in the INCLUDE environment variable.                           3
*** 3                                                                       3
*** 3  The syntax is:                                                       3
*** 3                                                                       3
*** 3      PREPROC infile outfile                                           3
*** 3                                                                       3
*** 3MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM3
*** 3              Copyright (c) 1993, 1994 Hilbert Computing               3
*** 3                    Released into the public domain                    3
*** @DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDY
**/

parse arg argstring

Opt.  = ''
call ParseOptions argstring
SrcFile = Opt.Parm.1
OutFile = Opt.Parm.2

/* Initialize values */

Symbol.       = ''

Lex.          = ''
Lex.SkipState = 'N'
Lex.SkipNest  = 0
Lex.Nest      = 0
Lex.LineCount = 0

if Opt.Flag.SYNTAX = '+' then
   call Syntax

if SrcFile = '' then
   do
   say 'Error: You must specify an input file.'
   call Syntax
   end

if OutFile = '' then
   do
   say 'Error: You must specify an output file.'
   call Syntax
   end

call LoadFunctions

/* Emit the header information */

say "Source file preprocessor.  Version 2.00"
say "Copyright (c) 1994, Hilbert Computing"
say

OutFile = open(OutFile, 'WRITE')
call time('Reset')
Lex.Indent = 1
call ProcessFile SrcFile
say
say  Lex.LineCount "lines processed in" format(time('Elapsed'),,2) "seconds."
exit


ProcessFile: procedure expose Symbol. Lex. OutFile
   /**
   *** This will handle the symbol resolution for a single file
   **/

   parse arg SrcFile

   say  "Processing file:"copies(" ", Lex.Indent) SrcFile

   if (\exists(SrcFile)) then
      do
      say
      say 'Error: Input file "'SrcFile'" doesn''t exist.'
      return
      end

   LineNo = 0
   Src = open(SrcFile, 'READ')
   do while(lines(Src) > 0)
      line = linein(Src)
      Lex.LineCount = Lex.LineCount + 1
      LineNo = LineNo + 1
      FirstWord = translate(word(line, 1))

      select
         when FirstWord = "#INCLUDE" then
            do

            if Lex.SkipState = 'N' then
               do
               Lex.Indent = Lex.Indent + 3
               call ProcessInclude line
               Lex.Indent = Lex.Indent - 3
               say "Processing file:"copies(" ", Lex.Indent) SrcFile
               end
            end
         when FirstWord = "#DEFINE" then
            do
            if Lex.SkipState = 'N' then
               do
               parse var line . SymName SymValue
               SymValue = strip(SymValue)

               /* Add this to the symbol table */

               Symbol.SymName = SymValue
               Lex.Tails = Lex.Tails SymName
               end
            end
         when FirstWord = "#IFDEF" then
            do
            parse var line . SymName
            if wordpos(SymName, Lex.Tails) = 0 then
               Lex.SkipState = 'Y'

            Lex.Nest = Lex.Nest + 1
            if Lex.SkipState = 'Y' then
               Lex.SkipNest = Lex.SkipNest + 1
            end
         when FirstWord = "#IFNDEF" then
            do
            parse var line . SymName
            if wordpos(SymName, Lex.Tails) <> 0 then
               Lex.SkipState = 'Y'

            Lex.Nest = Lex.Nest + 1
            if Lex.SkipState = 'Y' then
               Lex.SkipNest = Lex.SkipNest + 1
            end
         when FirstWord = "#ENDIF" then
            do
            if Lex.Nest = 0 then
               do
               say 'Error('SrcFile':'LineNo'): Too many #ENDIF statements'
               exit
               end
            else
               Lex.Nest = Lex.Nest - 1

            if Lex.SkipState = 'Y' then
               Lex.SkipNest = Lex.SkipNest - 1

            if Lex.SkipNest = 0 then
               Lex.SkipState = 'N'
            end
         otherwise
            do
            if Lex.SkipState = 'N' then
               do
               line = Resolve(line)
               call lineout OutFile,line
               end
            end
      end /* select */
   end /* while */
   call Close(SrcFile)
   return


ProcessInclude: procedure expose Symbol. Lex. OutFile
   /**
   ***  This will handle the processing for the '#include' keyword
   **/

   parse arg line


   if pos('"', line) > 0 then
      parse var line '"' IncludeFile '"'
   else
      do
      parse var line '<' SearchFile '>'
      IncludeFile = SysSearchPath('INCLUDE', SearchFile)
      if IncludeFile = "" then
         do
         say
         say 'Error: Include file "'SearchFile'" doesn''t exist.'
         return
         end
      end
   call ProcessFile IncludeFile
   return


Resolve: procedure expose Symbol.

   parse arg line

   do i = 1 to words(Lex.Tails)
      Sym = word(Lex.Tails, i)
      if pos(Sym, line) > 0 then
         do
         parse var line prefix (Sym) suffix
         line = prefix || Symbol.Sym || suffix
         end
   end
   return line

Syntax: procedure
   /**
   ***  Display syntax information and exit
   **/

   say
   say "Syntax:  PREPROC in out"
   say
   say "where 'in' is the input file and 'out' is the output file."
   exit


/* #include <io.rex> */

Close: procedure
   /**
   ***  Close a file I/O stream
   **/
   parse arg file
   message = stream(file,c,'CLOSE')
   if (message <> 'READY:') & (message <> '') then
      do
      say 'Error: Close failure on' file'.' message
      exit
      end
   return file


Exists: procedure
   /**
   *** Return a Boolean indicating whether the file exists or not
   **/
   arg file

   file = stream(file,c,'QUERY EXIST')
   if (file = '') then
      return 0
   else
      return 1


Open: procedure
   /**
   *** Open a file for READ, WRITE, APPEND or RANDOM (read/write)
   **/
   parse arg file, rw
   rw = translate(rw)

   select
      when rw = 'WRITE' then
         do
         file_ = stream(file,c,'QUERY EXIST')
         if file_ <> '' then
            '@erase "'file'" 2> NUL'
         end
      when rw = 'APPEND' then
         rw = 'WRITE'
      when rw = 'READ' then
         rw = 'READ'
      when rw = 'RANDOM' then
         rw = ''
      otherwise
         rw = 'READ'
   end /* select */

   message = stream(file,c,'OPEN' rw)
   if (message \= 'READY:') then
      do
      say 'Error: Open failure on' file'.' message
      return message
      end
   return file

/* #include LoadFunctions.rex */

LoadFunctions: procedure
   /**
   ***   This will load the DLL for the Rexx system functions supplied
   ***   with OS/2 v2.0
   **/
   call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
   call SysLoadFuncs
   return

/* #include <parseopt.rex> */

ParseOptions: procedure expose Opt.
   /**
   ***  This will parse the command line options.  Those parameters that
   ***  begin with a minus (-) or forward slash (/) are considered flags
   ***  and are placed in Opt.Flag.   The remaining options are placed
   ***  into Opt.parm.<x>.
   ***
   ***  NOTE:  This code does not clear out the 'Opt.' stem variable since
   ***         the caller may want to establish defaults prior to calling
   ***         this code.
   ***
   ***  LIMITATIONS:  The code currently only looks for the double quote
   ***         character (").  The apostrophe is treated like any other
   ***         character.  The way this is currently coded, multiple blanks
   ***         in a quoted string are compressed to a single blanks and
   ***         probably should not be.
   ***
   **/

   parse arg arguments

   Opt.Flag.List = ''
   Opt.State = 'Normal'
   j = 0
   do i = 1 to words(arguments)
      argument = word(arguments, i)

      select
         when Opt.State = 'Quoted Positional' then
            do
            /* Keep appending the words to this parm until an ending quote */
            /* is found.                                                   */

            Opt.Parm.j = Opt.Parm.j argument
            if right(argument,1) = '"' then
               do
               Opt.Parm.j = strip(Opt.Parm.j, 'Both', '"')
               Opt.State = 'Normal'
               end
            end
         when Opt.State = 'Quoted Flag' then
            do
            /* Keep appending until the terminating quote is found */

            Opt.Flag.Flagname = Opt.Flag.FlagName argument
            if right(argument,1) = '"' then
               do
               Opt.Flag.Flagname = strip(Opt.Flag.Flagname, 'Both', '"')
               Opt.State = 'Normal'
               end
            end
         when Opt.State = 'Normal' then
            do
            FirstChar = left(argument, 1)
            if ((FirstChar = '-') | (FirstChar = '/')) then
               do
               /*  This is a flag.  The value of the flag is the remainder of  */
               /*  the string.  If the remainder is the null string, then it   */
               /*  has an implicit value of '+' implying "on" or "true"        */

               FlagName = substr(argument, 2, 1)   /* Second character     */
               FlagName = translate(FlagName)      /* Convert to uppercase */

               /* See if this flag parm is quoted */

               if substr(argument, 3, 1) = '"' then
                  Opt.State = 'Quoted Flag'

               /* If any of the flag names are not a valid character for a REXX */
               /* variable, we have to translate into a mnemonic.               */

               if ((FlagName < 'A') | (FlagName > 'Z')) then
                  do
                  select
                     when FlagName = '?' then FlagName = 'SYNTAX'
                     when FlagName = '!' then FlagName = 'BANG'
                     when FlagName = '*' then FlagName = 'STAR'
                     when FlagName = '#' then FlagName = 'POUND'
                     when FlagName = '$' then FlagName = 'DOLLAR'
                     when FlagName = '%' then FlagName = 'PERCENT'
                     when FlagName = '^' then FlagName = 'HAT'
                     when FlagName = '&' then FlagName = 'AMP'
                     when FlagName = '(' then FlagName = 'LPAR'
                     when FlagName = ')' then FlagName = 'RPAR'
                     when FlagName = '-' then FlagName = 'DASH'
                     when FlagName = '=' then FlagName = 'EQUAL'
                     otherwise /* Force a syntax message */
                        FlagName = 'SYNTAX'
                  end /* select */
                  end /* if */

               FlagValue = substr(argument, 3)     /* Remainder of string */
               if FlagValue = '' then
                  FlagValue = '+'

               Opt.Flag.FlagName = FlagValue
               Opt.Flag.List = FlagName Opt.Flag.List
               end
            else /* it is a positional parameter */
               do
               j = j + 1
               Opt.Parm.j = argument
               if left(argument,1) = '"' then
                  Opt.State = 'Quoted Positional'
               end
         end /* 'Normal' */
      otherwise
         nop
      end /* select */
   end /* do i... */
   Opt.Parm.0 = j
   return

/********************** end of preproc.cmd *******************************/

DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
Based on integral subsystem considerations, initiation of critical
subsystem development requires considerable systems analysis and trade-off
studies to arrive at the philosophy of commonality and standardization.

Pat Shanahan <pat@iquest.net>               Wise is the man who has nothing
South Avon Station, Indianapolis, IN        to say, and doesn't.....
                                                                    UnKnown
DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
-- 