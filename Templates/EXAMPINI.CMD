/*  */
trace o;
            /****  Type all OS2.INI file information to the screen  *****/
           call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
           call sysloadfuncs
              call SysIni 'USER', 'All:', 'Apps.'
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
           
           
say 'Press Enter to continue...';
pull ans;
 
           
             /* Code    */
              call SysQueryClassList "list."
              do i = 1 to list.0
                say 'Class' i 'is' list.i
              end
           
   

