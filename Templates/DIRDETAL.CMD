/* Test Rexx functions */
Say 'Start of TEST.CMD';
trace o;
Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
Call SysLoadFuncs;
call SysFileTree '*.*','b','tds';
Say 'Result is:' rc;
Say 'Number returned:' b.0;
Say 'Examples are:';
do i = 1 to min(b.0, 130);
  Parse var b.i yy'/'mm'/'dd'/'hh'/'min size attr fullname;
  drive = filespec('d',fullname);
  path = filespec('p',fullname);
  fn = filespec('n',fullname);
  Say b.i;
  Say 'Date:' dd mm yy 'Time:' hh min 'Size:' size;
  Say 'Attr:' attr;
  Say 'Drive:' drive '  Path:' path '  FN:' fn;
  pull nix;
end /* do */
Exit;
