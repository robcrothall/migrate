/* Test Rexx functions */
Say 'Start of TEST2.CMD';
trace r;
rc = 0;
Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
Call SysLoadFuncs;
Rest = 'F G H';
   Say 'Extra parameter "'||Rest||'" ignored!';
   Msg = "Extra parameter ="||Rest||'; Shall we continue?';
   If RxMessageBox("Msg",,"YesNo","QUERY") = 7 then signal RX_Halt;
   If RxMessageBox('Msg','Title','OKCancel','Query') = 2 then signal RX_Halt;
   If RxMessageBox('Msg','Title','OKCancel','Query') = 2 then signal RX_Halt;
Say 'Fall thru...';
RX_Halt;
Exit;
