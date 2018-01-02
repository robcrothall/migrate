/* Create an index of files in the current directory for Maximus */
rc = 0;
Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
Call SysLoadFuncs;
/* Load utility functions */
Call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS';
Call PrxLoadFuncs;
/*Say 'PrxUtils function loaded';*/
/*Say PrxUtilsVersion();*/
retcd = PrxReadToStem('FILES.BBS', 'OldFiles');
OldDesc. = '';
If OldFiles.0 = 'OLDFILES.0' then say 'No previous FILES.BBS file found';
  else do I = 1 to OldFiles.0;
     Parse var OldFiles.I OldFn OldDesc.OldFn;
  end  /* Do */
/*Say 'Result is:' rc;*/
Say 'Number of old files returned:' OldFiles.0;
Out. = '';
K = 0;
f. = 0;
TotSize = 0;
NewFiles. = '';
call SysFileTree '*.*','fil','ft';
do i = 1 to fil.0;
  Parse upper var fil.i yy'/'mm'/'dd'/'hh'/'min size attr fullname;
  Parse upper var fil.i datetm .;
  fn = filespec('n',fullname);
  fn = translate(fn);
  parse upper var fn nm '.' ext;
  if nm = 'FILES' then iterate;
/*  if left(nm,2) = 'MI' then iterate; */
  if (nm = 'MAX') & (ext = 'CMD') then iterate;
  NewFiles.fn = 'Y';
  K = K + 1;
  Out.K = fn OldDesc.fn;
end /* do */
/*call syssleep 1;*/
If K < 1 then do;
   Out.1 = ' ';
   K     = 1;
   end  /* Do */
retcd = PrxWriteFromStem('FILES.TMP', 'Out', K, 1, 'Replace');
rc = lineout('FILES.TMP');

Say 'Number of files found:    ' K;
Out. = '';
K = 0;

If (OldFiles.0 = 'OLDFILES.0') | (OldFiles.0 = 0) then say 'No offline files added';
  else do I = 1 to OldFiles.0;
     Parse upper var OldFiles.I OldFn .;
     OldFn = space(OldFn,0);
     If I//50=0 then call syssleep 1;
     If OldFn = '' then iterate;
     If NewFiles.OldFn = '' then iterate;
     If NewFiles.OldFn = 'Y' then iterate;
     else do;
        say 'OldFn =' OldFn 'NewFiles.OldFn =' NewFiles.OldFn;
        K = K + 1;
        Out.K = OldFiles.I;
     end  /* Do */
  end  /* Do */
If K > 0 then do;
  retcd = PrxWriteFromStem('FILES.TMP', 'Out', K, 1, 'Append');
  rc = lineout('FILES.TMP');
  end  /* Do */
'sort <FILES.TMP >FILES.BBS';
rc = lineout('FILES.TMP');
rc = lineout('FILES.BBS');
'del FILES.TMP';
/*call syssleep 1;*/
Drop fn f. fil.;
