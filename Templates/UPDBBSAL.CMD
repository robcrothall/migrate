/* Create an index of all Maximus download directories... */
'echo off';
rc = 0;
trace ro;

Signal on failure name CLEANUP;
Signal on halt name CLEANUP;
Signal on syntax name CLEANUP;

Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
Call SysLoadFuncs;
/* Load utility functions */
Call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS';
Call PrxLoadFuncs;
/*Say 'PrxUtils function loaded';*/
/*Say PrxUtilsVersion();*/

Dir. = '';
DrMap = SysDriveMap('C:', 'USED');
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
MaxDr = Drive;
K = 0;
'CD \MAX';
retcd = PrxReadToStem('FILEAREA.CTL', 'FileArea');
If FileArea.0 = 'FILEAREA.0' then do;
    say 'No FILEAREA.CTL file found';
    signal End;
    end  /* Do */
  else do I = 1 to FileArea.0;
    parse upper var FileArea.I KeyWord Rest;
    If KeyWord = '%' then iterate;
    If KeyWord = '' then iterate;
    If Keyword = 'DOWNLOAD' then do;
      K = K + 1;
      Dr = MaxDr;
      Rest = space(Rest,0);
      If right(Rest,1) = '\' then Rest = left(Rest,length(Rest)-1);
      If substr(Rest,2,1) = ':' then do;
         parse var Rest Dr':'Rest;
         Dr = Dr||':';
      end  /* Do */
      If left(Rest,1) \= '\' then Rest = '\MAX\'||Rest;
      Say 'Now processing...' Rest;
      Dr;
      'cd' Rest;
      'del files.bbs';
      call BBS;
    end  /* Do */
  end  /* Do */

'cd \max';
'\max\fb';

CLEANUP:
  'cd \';
Exit;
