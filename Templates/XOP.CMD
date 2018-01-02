/* DESCRIPTION: To provide extended command authorities to CSR staff.  */
/*                                                                     */
/* ARGUMENTS: 1. ? - Displays these comments                           */
/*               Any command string to be executed                     */
/*                                                                     */
/* RECORDS STACKED/ RETURN CODES/ ERROR CONDITIONS:                    */
/*                                                                     */
/* Rc=1 If arg1=? - Request for info.                                  */
/*                                                                     */
/* WRITTEN BY: Rob Crothall DATE: Jul 91                               */
/* CHANGED BY:              DATE:        TO:                           */

Parse source . . name .;
If arg(1)='?' then do
  /* Display comment info if 1st arg = ? and Exit */
   Say; Say name; Say;
   Do n=1
      line=sourceline(n); If left(line,2)^='/*' then exit 1; Say line;
      End
   End

Trace Off
Arg instr;
if instr ^= ' ' then 'msg zfabatch ' instr;
if instr ^= ' ' then say 'Waiting for a response for a few secs...';
if instr ^= ' ' then 'sleep 8 sec';
'rel w(det';
'cp link zfabatch 191 299 rr'
'acc 299 w';
'browse zlog log w';
'rel w (det';
