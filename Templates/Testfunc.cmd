/* Code   */
 call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
 call sysloadfuncs

   /* Code    */
    if SysSetIcon('d:\mitest\test1.cmd', "e:\cmd\oracase.ICO") then
      say 'Icon "NEW.ICO" attached to' file'.'

pull ans;

/*    If  SysCreateObject("WPFolder","MI Folder","<WP_DESKTOP>")
        Say 'MI Folder successfully created' */

   /* Create a folder object, and then create a program object */
   /* in that folder.*/
    If SysCreateObject("WPFolder", "MI Folder", "<WP_DESKTOP>",,
        "OBJECTID=<MIFOLDER>") Then Do
    If SysCreateObject("WPProgram", "MI Program", "<MIFOLDER>",,
        "EXENAME=D:\MITEST\Test1.cmd")  Then
           Say 'Folder "MI Folder" and Program "MI Program" have been created'
        Else Say 'Could not create program "MI Program"'
        End
      Else Say 'Could not create folder "MI Folder"'
pull ans;

  /* Code */
  say 'Used drives include:'
  say SysDriveMap('C:', 'USED')
pull ans;
  
   /****<< Syntax Examples.>>***********************/

   /* Find all subdirectories on C: */
    call SysFileTree 'd:\*.*', 'file', 'SD'
    do i = 1 to file.0;
      say file.i
    end;
pull ans;
   /* Find all Read-Only files */
    call SysFileTree 'd:\*.*', 'file', 'S', '***+*'
    do i = 1 to file.0;
      say file.i
    end;
pull ans;

   /* Clear Archive and Read-Only bits of files which have them set */
/*    call SysFileTree 'c:\*.*', 'file', 'S', '+**+*', '-**-*'*/


   /****<< Sample Code and Output Example.>>********/

   /* Code */
    call SysFileTree 'd:\os2*.', 'file', 'B'
    do i=1 to file.0
      say file.i
    end
pull ans;


  /* Find DEVICE statements in CONFIG.SYS */
  call SysFileSearch 'DEVICE', 'D:\CONFIG.SYS', 'file.'
  do i=1 to file.0
   say file.i
  end
pull ans;


   /* Code    */
   if SysGetEA("D:\CONFIG.SYS", ".type", "TYPEINFO") = 0 then do
     parse var typeinfo 11 type
     say typeinfo ':' type
     end
pull ans;

 /* Sample code segments */

  /***  Save the user entered name under the key 'NAME' of *****
  ****  the application 'MYAPP'.       ****/
  Say 'Enter a test name:';
  pull name .
  call SysIni , 'MYAPP', 'NAME', name /* Save the value        */
  say  SysIni(, 'MYAPP', 'NAME')      /* Query the value       */
  call SysIni , 'MYAPP'               /* Delete all MYAPP info */
pull ans;

  /****  Type all OS2.INI file information to the screen  *****/
    call SysIni 'USER', 'All:', 'Apps.'
    if Apps.0 > 10 then Apps.0 = 10;
    if Result \= 'ERROR:' then
      do i = 1 to Apps.0
        call SysIni 'USER', Apps.i, 'All:', 'Keys'
        if Result \= 'ERROR:' then
         do j=1 to Keys.0
           val = SysIni('USER', Apps.i, Keys.j)
           say left(Apps.i, 20) left(Keys.j, 20),
                 'Len=x'''Left(d2x(length(val)),4) left(val, 20)
         end
      end

pull ans;


   /* Code    */
    call SysQueryClassList "list."
    do i = 1 to list.0
      say 'Class' i 'is' list.i
    end
pull ans;


  /* Code */
  say SysTempFileName('d:\TEMP\MYEXEC.???')
  say SysTempFileName('d:\TEMP\??MYEXEC.???')
  say SysTempFileName('d:\MYEXEC@.@@@', '@')

  
