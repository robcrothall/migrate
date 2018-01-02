/* Test Rexx functions */
/* Say 'Start of DUPFILES.CMD';*/
trace o;
rc = 0;
Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
Call SysLoadFuncs;
/* Load utility functions */
Call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS';
Call PrxLoadFuncs;
/*Say 'PrxUtils function loaded';*/
/*Say PrxUtilsVersion();*/
call SysFileTree '*.*','fil','fst';
/*Say 'Result is:' rc;*/
/*Say 'Number returned:' fil.0;*/
Out. = '';
K = 1;
Out.K = '/* File created by DUPFILES.CMD */';
f. = 0;
TotSize = 0;
NumDup = 0;
linecnt = 99;
/*If fil.0 > 750 then fil.0 = 750;*/
do i = 1 to fil.0;
  Parse var fil.i yy'/'mm'/'dd'/'hh'/'min size attr fullname;
  Parse var fil.i datetm .;
  fn = filespec('n',fullname);
  if f.fn = 0 then f.fn = i;
  else do;
         j = f.fn;
         Parse var fil.j datetm2 size2 attr2 fullnam2;
         if (datetm = datetm2) & (size = size2) then do;
            if linecnt > 60 then do;
               Say;
               say 'Listing of duplicate files';
               say:
               say;
               linecnt = 0;
            end;
            K = K + 1;
            Out.K = 'Say "DEL '||fullname||'";';
            say fil.i i;
            say fil.j j;
            say;
            linecnt = linecnt + 3;
            K = K + 1;
            Out.K = 'Say "DEL '||fullnam2||'";';
            TotSize = TotSize + size;
            NumDup = NumDup + 1;
          End;
       end;
end /* do */
retcd = PrxWriteFromStem('\CMD\DUPDEL.CMD', 'Out', K, 1, 'Replace');
Say 'Total size of duplicate files:' TotSize;
Say 'Number of duplicate files:    ' NumDup;
Drop fn f. fil.;
