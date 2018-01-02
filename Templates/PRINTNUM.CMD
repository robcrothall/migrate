/* */
arg ProcOpts;
retcd = PrxReadToStem(ProcOpts, 'Records');
If Records.0 \= 'RECORDS.0' then do i = 1 to Records.0;
  Records.I = I Records.I;
End;
retcd = PrxWriteFromStem('PRINTNUM.TXT', 'Records', Records.0, 1, 'Append');
'start epm printnum.txt';
exit;
