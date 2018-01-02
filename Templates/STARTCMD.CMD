 /* */
 /*Purpose:     Start a separate process in which to run the task
                  named in the parameter.
exit
 Client:        Consolidated Share Registrars Limited
 Date written:  August 1993
 Author:        Rob Crothall & Associates
 Copyright:     Copyright (1993) by Rob Crothall & Associates.
                All rights reserved.

 Arguments:     A program or command file name, optionally followed by
                parameters.

 Return codes:  Rc=1   If arg1=? - Request for info.

 Written by:    Rob Crothall   Date: Aug 1993
 Changed by:                   Date:          To:
*/

/* Set options that help during debugging */
'@echo off';

trace o;

arg Program ProcOpts;

/* Define some constants... */
Yes = 1;
No = 0;

/* Display comment info if 1st arg = ? and Exit */
DisplayUsage:
If arg(1)='?' then do;
   Parse source . . name .;
   Say; Say name;
   Do n = 1 by 1;
      line=sourceline(n);
      If 0 < pos('*/',line) then exit 1;
      If n//15 = 0 then do;
         say; say 'Press <Enter> to continue...';
         pull ans;
      end;  /* Do */
      Say line;
   End;
End;

If Program \= '' then call Program ProcOpts;

'exit';
