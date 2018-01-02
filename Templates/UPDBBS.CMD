/* Create an index of files in the current directory for Maximus */
'echo off';
say 'Use Ctrl-Esc to see the windows...';
rc = 0;
trace o;

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
      Rest = space(Rest,0);
      If right(Rest,1) = '\' then Rest = left(Rest,length(Rest)-1);
      If left(Rest,1) \= '\' then Rest = '\MAX\'||Rest;
      Dir.K = Rest;
    end  /* Do */
  end  /* Do */

If K > 0 then Dir.0 = K;
else Dir.0 = 0;

Call RxFuncAdd 'VInit', 'VREXX', 'VINIT';
rc = VInit();
If rc = 'ERROR' then signal CLEANUP;

Call VDialogPos 20, 50;

sel. = '';
If Dir.0 > 0 then do forever;
/*  sel.0 = 0;*/
/*  sel.1 = Dir.1;*/
  rc = vlistbox('Select directory for update',Dir,35,10,3);
  if rc='CANCEL' then signal CLEANUP;
  else if rc\='OK' then signal CLEANUP;
  'cd' Dir.vstring;
/*  msg = 'Sel:' Dir.vstring;*/
/*  call VMsgBox msg, Dir, 1;*/
  call bbs
End /* do */


CLEANUP:
  call VExit;
  'cd \';
Exit;
