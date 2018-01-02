/***+---------------------------------------------------------WPSGEN.CMD
 ********************************************************************
 *                                                                  *
 *           Copyright (c) 1992, Blue Bird Computing, Inc.          *
 *                                                                  *
 *  Permission is granted for this program to be used, copied,      *
 *  modified, and/or redistributed by anyone provided that no fee   *
 *  is charged and this notice and the change log are not removed.  *
 *                                                                  *
 ********************************************************************

              WPSGEN - Generate WPS Objects from a Script

  This Rexx program will create WPS objects from data in a script file.
  It allows for testing and easily re-doing work on re-installs.  It
  can also be used to easily set up multiple OS/2 workstations with the
  same or similar program groups and entries.

  Synopsis:        WPSGEN  <filename>

  Returns:         0  - always

  Input:           filename  - the name of script file (no default
                               assumption about extension) that
                               contains definitions for objects to
                               be created.

  Output:          Messages to the screen
                   Work Place Shell objects are created

  Calls:           REXXUTIL.DLL functions:
                      SysLoadFuncs
                      SysCls
                      SysCreateObject

  Called by:       People like you and me

  Environments:    OS/2 V2.0+

  Notes:           Input file has the format:

                     Class     classname
                     name      object name
                     location  place to put it
                     Attr      setup string data
                     attr      more setup string data
                     .
                     install

                   Case of the keywords is not significant, though
                   case in the data is.

                   Comments may be included by prefixing them with
                   an asterisk. Comments and blank lines are ignored.

                   Note that setup string elements must be terminated
                   by semicolons.  This program will put in the
                   semicolons after each Attr if needed but if more
                   than one string is give on each attr line, the
                   semicolons must be embedded.

  Version history:
   Revision 1.0  12Jun92 M.A. Stern (Blue Bird Computing, Inc.)
    New

   Revision 1.1  30Jul92 M.A. Stern (Blue Bird Computing, Inc.)
    Improve internal documentation.
****------------------------------------------------------------------*/

Arg Filename .
If Lines( filename ) < 1 Then Do
   Say 'Input file' Filename 'not found.'
   Exit
   End

/* Load REXXUTIL */
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs

call SysCls
Say '';Say 'Using REXXUTILs to Create WPS desktop Objects...'

Added = 0
Failed = 0

Call InitWps

Do While Lines( Filename ) > 0

   Rec = Strip( Linein( Filename ) )
   if Rec = '' | Left( Rec,1 ) = '*' Then Iterate
   Parse var Rec Keyword Data
   Data = Strip( Data )
   Keyword = Translate( Keyword )
   Select

      When Keyword = 'CLASS'    Then WpsClass = Data
      When Keyword = 'NAME'     Then WpsName = Data
      When Keyword = 'LOCATION' Then WpsLoc = Data

      When Keyword = 'ATTR' Then Do
         If Right( Data,1 ) <> ';' Then Data = Data';'
         WpsSetup = WpsSetup||Data
         End

      When Keyword = 'INSTALL' Then Call BldObj

      Otherwise Say 'Keyword' Keyword 'not recognized.'

      End /* Select */

   End /* Do While */

Call Lineout Filename

If WpsClass||WpsName||WpsLoc||WpsSetup <> '' Then ,
   Say 'Some data left over - input may be incomplete.'

Say Added 'objects successfully created.'
Say Failed 'objects could not be created.'
Exit

InitWps:

   WpsClass = ''
   WpsName  = ''
   WpsLoc   = ''
   WpsSetup = ''

Return;


/* Build Object */
BldObj:
call charout ,'Building: 'WpsName

result = SysCreateObject(WpsClass, WpsName, WpsLoc, WpsSetup)

If result=1 Then Do
   call charout ,'...   Object created!'
   Say ''
   Added = Added + 1
   End
Else  Do
   call charout ,'...   Not created! Return code='result
   Say ''
   Failed = Failed + 1
   End

Call InitWps

Return
