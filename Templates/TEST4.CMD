/* Test */
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
rc = trace('?r');
DrMap = SysDriveMap('C:', 'LOCAL');
Do while (DrMap \= '');
   Parse var DrMap Drive DrMap;
   Dir. = '';
   call SysFileTree Drive||'\MAX', 'Dir', 'D';
   Say 'Dir.0 =' Dir.0;
   If Dir.0 = 1 then do;
      Drive;
      'cd \max';
      DrMap = '';
   end  /* Do */

End;

CLEANUP:
Exit;
