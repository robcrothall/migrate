/* Create archive of selected directories */
f:
back_no = 0;
Call Check;
"lh a f:\temp\back_lh  D:\HOBBES\*.* /s /e";
Call Check;
"lh a f:\temp\back_lh  D:\id\*.* /s /e";
Call Check;
"lh a f:\temp\back_lh  D:\MMOS2\*.* /s /e";
Call Check;
"lh a f:\temp\back_lh  D:\SBPRO\*.* /s /e";
Call Check;
"lh a f:\temp\back_lh  D:\STW_WIN\*.* /s /e";
Call Check;
"lh a f:\temp\back_lh  D:\TEST\*.* /s /e";
Call Check;
"lh a f:\temp\back_lh  D:\USERDATA\*.* /s /e";
Call Check;
"lh a f:\temp\back_lh  D:\VIEWER\*.* /s /e";
back_no = back_no + 1;
"backup f:\temp\back_lh.* a: /l:f:\temp\back_"||back_no||".log";
/*  "del f:\temp\back_lh.lzh";  */
exit;
Check:
"Dir f:\temp\*.*";
Say "Press <Y> to backup now, <Enter> to continue...";
Pull Answer;
If Answer = Y then do;
  back_no = back_no + 1;
  "backup f:\temp\back_lh.* a: /l:f:\back_"||back_no||".log";
pull ans;
/*  "del f:\temp\back_lh.lzh";  */
end;
return;
