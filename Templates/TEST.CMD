/* Test Rexx functions */
Say 'Start of TEST.CMD';
trace r;
rc = 0;
Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
Call SysLoadFuncs;
call SysFileTree '\cmd\test3.cmd','fil','fst';
Say 'Result is:' rc;
Say 'Number returned:' fil.0;
if fil.0 = 1 then 'start "Remote initiation!" /win /C /pgm "test3.cmd"';
else say 'Can not find command!';

