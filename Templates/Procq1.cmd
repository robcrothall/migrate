/* CheckQ.CMD */
'mode 80, 99';

MyQ = 'MI01';
Delay = 5;
Yes = 1;
No  = 0;
UpdBBS = No;

Say 'Starting PROCQ.CMD...  Queue =' MyQ;

NewQ = RXQUEUE('create', MyQ);

If NewQ  = MyQ then Say 'New queue created called:' NewQ;
If NewQ \= MyQ then rc = RXQUEUE('delete', NewQ);

OldQ = RXQUEUE('set', MyQ);


/* Check if utility functions have been loaded; If not, load them...*/
If 0 < RxFuncQuery('SysLoadFuncs')
  then do;
         Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
         Call SysLoadFuncs;
         Say 'RexxUtils loaded...';
       End;

If 0 < RxFuncQuery('FtpLoadFuncs')
  then do;
         Call RxFuncAdd "FtpLoadFuncs","rxFtp","FtpLoadFuncs";
         Call FtpLoadFuncs;
         Say 'FtpLoadFuncs loaded...';
       End;

If 0 < RxFuncQuery('PrxLoadFuncs')
  then do;
         Call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS';
         Call PrxLoadFuncs;
         Say 'PrxUtils loaded...';
       End;

Say 'Now we wait a bit to prevent startup congestion...';
call SysSleep 100;
'start /min /B /I /C /pgm "e:\oraos2\xbin\vdmsrv.exe"';

/* Handle programming errors in a reasonable way... */

Signal on failure name CLEANUP;
Signal on halt name EndIt;
Signal on syntax name CLEANUP;

trace r;
Old_Hour = time('H');
Kount    = time('S')/Delay;
Kount    = trunc(Kount);
/*'start "Daily Findvirus" /B /I /C /pgm "d:\toolkit\ofindvir" /local /pack /unzip /printout';*/


Do forever;
  /* Reset Kount after midnight */
  If Old_Hour > time('H') then do;
     Kount    = 0;
     Say 'Welcome to a new day!';
  end  /* Do */
  trace n;
  Old_Hour = time('H');
  Kount = Kount + 1;
  Do while(queued() > 0);

   QLine = LineIn('Queue:');
   Parse var QLine Filler Processor Parms;
   If Processor = '' then Processor = Filler;
   If Processor = '' then Processor = 'Empty';
   FileSpec = SysSearchPath('PATH', Processor);
   If FileSpec \= '' then Msg = FileSpec;
   Else Msg = 'Processor unknown!';
   If Processor = 'QUIT' then Msg = 'Normal termination';

   LogSpec = SysSearchPath('PATH', 'PROCQ.LOG');
   If LogSpec = '' then do;
      parse source . . myname;
      myname  = translate(myname);
      e_drive = left(myname,2);
      temp    = reverse(myname);
      parse var temp 'DMC.'e_name'\'e_path;
      e_path  = reverse(e_path);
      e_name  = reverse(e_name);
      LogSpec = e_path||'\'||e_name||'.LOG';
   end  /* Do */
   Out.       = '';
   Out.1      = date() time() QLine Msg;
   Out.0      = 1;
   mi_rc = PrxWriteFromStem(LogSpec,'Out',Out.0,1,'Append');

   If Processor = 'QUIT' then signal EndIt;

   If FileSpec \= '' then interpret('call' Processor ''''||Qline||'''');
   UpdBBS     = Yes;  /* Force the update of BBS file directories */

  end;

  Say 'Time is' time() 'on' date() ' - ' Kount;
  Day = Date(B)//7;

  If Kount = 6 then do;
     'start "Daily Findvirus" /B /I /C /pgm "d:\toolkit\ofindvir" /local /pack /unzip';
  end  /* Do */

  select
     when Day < 5 then do;
        /* It is is a weekday */
        If Kount = (7 * 60 * 60 / Delay) then 'start /B /I /pgm "epm.exe" d:\bill\billcurr.doc';
     end  /* Do */
  otherwise do;
              Say 'Happy Weekend!';
            end; /* do */
  end  /* select */

  If ((Kount // 100 = 51) | (UpdBBS = Yes)) then do;
     UpdBBS = No;
  /*   'd:'; */
  /*   'cd \cmd'; */
  /*   'start "Update file directories..." /min /B /I /C /pgm "updbbsal.cmd"';*/
     call "updbbsal.cmd";
  end  /* Do */

CLEANUP:

  Call SysSleep Delay;
end /* do */

EndIt:
Say 'QUIT command received - processing stopped';

Exit;
