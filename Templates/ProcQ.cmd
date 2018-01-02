/* CheckQ.CMD */
'mode 80, 99';
MyQ = 'MI01';
Delay = 120;

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

If 0 < RxFuncQuery('PrxLoadFuncs')
  then do;
         Call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS';
         Call PrxLoadFuncs;
         Say 'PrxUtils loaded...';
       End;
trace n;
Old_Hour = time('H');
Kount    = time('S')/Delay;
Kount    = trunc(Kount);
Do forever;
  /* Reset Kount after midnight */
  If Old_Hour > time('H') then do;
     Kount    = 0;
  end  /* Do */
  Old_Hour = time('H');
  Kount = Kount + 1;
  Say 'Kount is: ' Kount;

  Do while(queued() > 0);

   QLine = LineIn('Queue:');
   Parse var QLine . Processor Parms;

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
   Kount = 1;  /* Force the update of BBS file directorirs */

  end;

  Say 'Time is' time() 'on' date() ' - ' Kount;

  Day = Date(B)//7;

/*' start c:\tcpip\0dial\callback.cmd ' ;*/

  if Kount < 19 * (60*60/Delay) then call 'd:\cmd\star2lsr.cmd';

  select
     when Day < 5 then do;
        /* It is is a weekday */
        If Kount = 20 * (60*60/Delay) then 'start /B /I /pgm "d:\cmd\netbkup.cmd" userid=produser passwd=Nelson targetdir=/mnt/u1/modules/';

        /*If Kount = 8 * (60*60/Delay) then 'start /B /I /pgm "c:\os2\apps\epm.exe" c:\bill\billcurr.doc';*/
     end  /* Do */
  otherwise Say 'Happy Weekend!';
  end  /* select */

  If Kount // 60 = 51 then do;
/*     'cd \cmd'; */
/*     'start "Update file directories..." /B /I /C /pgm "updbbsal.cmd"'; */
  end  /* Do */

  Call SysSleep Delay;
end /* do */

EndIt:
Say 'QUIT command received - processing stopped';

Exit;
