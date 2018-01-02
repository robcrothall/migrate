/* QueueQ.CMD */
MyQ = 'MI01';

NewQ = RXQUEUE('create', MyQ);

If NewQ  = MyQ then Say 'New queue created called:' NewQ;
/* If our queue already existed, delete the new one... */
If NewQ \= MyQ then rc = RXQUEUE('delete', NewQ);

OldQ = RXQUEUE('set', MyQ);

Stamp = 'Test' 'ReadQ.CMD' Date() Time();
Say 'Stamp is:' Stamp;
Queue Stamp;

'start "Checking Queue processes..." /B /I /C CheckQ.CMD' MyQ;

Exit;
