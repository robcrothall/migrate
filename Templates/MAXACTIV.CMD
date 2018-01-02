/* MAXACTIV.CMD file  */
trace r;
'@echo on'
call RxFuncAdd 'VInit', 'VREXX', 'VINIT'
initcode = VInit()
if initcode = 'ERROR' then signal CLEANUP

signal on failure name CLEANUP
signal on halt name CLEANUP
signal on syntax name CLEANUP

call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
call SysLoadFuncs;
'cd \max';

UlogFn = 'U'||substr(date(s),3);
/* Check that the Upload Log exists  */
UL.='';
retcd = PrxReadToStem('UL.LOG', 'UL');

If UL.0 \= 'UL.0' then do;
  Say 'We have some files to work with...';
  UL.vstring = UL.1;          /* default selection */
  call VDialogPos 5, 5;
  call VListBox 'Press YES to confirm that you have seen this', UL, 80, 10, 4;
  Parse Var UL.vstring UsrFName UsrLName Func FileNm '(' FileSize 'b),' LDate LTime;
  Say 'Extracted ' UsrFName UsrLName Func FileNm  FileSize LDate LTime;
End;
/*****************'rename UL.LOG' UlogFn||'.MAX';*/

LogFn = 'L'||substr(date(s),3);
/*******************************'Rename MAX.LOG' LogFn||'.MAX';*/
/*******************************'Copy MAX.LOG' LogFn||'.MAX';*/
/********************************start 'epm' LogFn||'MAX';*/
/* end of CMD file */

CLEANUP:
   call VExit;

/***********************'exit';
exit*/
