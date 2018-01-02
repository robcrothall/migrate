/* ReadQ.CMD */
trace n;
Signal on syntax name CLEANUP;
Signal on error name CLEANUP;

MyQ = 'MI01';

Parse upper arg ParmQ Rest;
If ParmQ \= '' then MyQ = ParmQ;

NewQ = RXQUEUE('create', MyQ);

If NewQ \= MyQ then do;
   rc = RXQUEUE('delete', NewQ);
   Say MyQ 'exists - ' NewQ 'is not required.';
end  /* Do */

OldQ = RXQUEUE('set', MyQ);

Count = 0;

Do until Count > 10;
   Count = Count + 1;
   Do while Queued() > 0;
     Count = 0;
     Say 'Start reading from queue:' Date() Time();
     qDate_Time = LineIn('Queue:');
     Say 'Date and time from Queue is:' qDate_Time;

     call SysSleep 15;
   end /* do */
   Call SysSleep 1;
end /* do */

If Queued() = 0 then Call RXQUEUE 'Delete', MyQ;

Exit;

CLEANUP:
Call SysSleep 20;
Exit;
