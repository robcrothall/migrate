/* PushQ.CMD */

MyQ = 'MI01';

NewQ = RXQUEUE('create', MyQ);
Say 'New queue created called:' NewQ;

If NewQ \= MyQ then rc = RXQUEUE('delete', NewQ);

OldQ = RXQUEUE('set', MyQ);

Stamp = Date() Time();
Say 'Stamp is:' Stamp;
Push Stamp;
Stamp = 'updbbsal.cmd';
Push Stamp;

Exit;
