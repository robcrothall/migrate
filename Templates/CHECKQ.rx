/* CheckQ.CMD */
MyQ = 'MI01';
Delay = 10;

NewQ = RXQUEUE('create', MyQ);
Say 'New queue created called:' NewQ;

If NewQ \= MyQ then say 'Queue' NewQ 'will be deleted';
If NewQ \= MyQ then rc = RXQUEUE('delete', NewQ);

OldQ = RXQUEUE('set', MyQ);


/* Check if utility functions have been loaded; If not, load them...*/
If 0 < RxFuncQuery('SysLoadFuncs')
  then do;
         Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
         Call SysLoadFuncs;
         Say 'RexxUtils loaded...';
       End;

Call SysSleep Delay;

If queued() > 0 then do;
   Say;
   Say 'No action after' Delay 'seconds...';
   Say 'Starting the requested process...';

   QLine = LineIn('Queue:');
   Push QLine;

   Parse var QLine . Processor .;
   FileSpec = SysSearchPath('PATH', Processor);
   NewProcess = 'ReadQ';
   If FileSpec \= '' then NewProcess = Processor;

   'start "Read and Process Queues..." /B /I /C' NewProcess MyQ;
end;

Exit;
