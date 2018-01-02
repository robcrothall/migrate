/* */

RejectIndx = 0;
Reject. = '';
LineNo = 999;
CLine  = 'Test line in Rexx program';
call Err 'Unk', '001', 'W', 'Unknown keyword', LineNo, CLine;

do I = 1 to RejectIndx;
  Say '('||I||')' Reject.I;
end;

Exit;


/*------------------------------------------------------------*/

Err:

Parse arg ErrParms;
Say 'Parms =' ErrParms;

Parse arg ErrPrefix, ErrNumber, ErrSeverity, ErrMsg, ErrLineNo, ErrLine;

RejectIndx  = RejectIndx + 2;
Reject.RejectIndx = '('||ErrLineNo||')' ErrLine;
RejectIndx  = RejectIndx + 1;
Reject.RejectIndx = '     ' ErrPrefix||'-'||ErrNumber||'-'||ErrSeverity ErrMsg;
If ErrSeverity \= 'I' then GenOK = No;

Return;


