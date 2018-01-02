/* DESCRIPTION:                                                        */
/* Readies the oldest tape in a GDG for writing and writes a label     */
/* using the DBLABWRT EXEC. This EXEC also uses the DBTAPE2 EXEC       */
/* to attach a tape unit and instruct the operator to mount the        */
/* correct volid.                                                      */
/*                                                                     */
/* ARGUMENTS: 1. Virtual tape address (181-184)                        */
/*            2. Filename of tape GDG file.                            */
/*            3. Filetype of tape GDG file.                            */
/*            4. Filemode of tape GDG file.                            */
/*            5. Density (1600 or 6250).    default: 1600              */
/*            6. Owner field (max 8 chars). default: userid()          */
/*                                                                     */
/*                                                                     */
/* RECORDS STACKED/ RETURN CODES/ ERROR CONDITIONS:                    */
/*                                                                     */
/* Rc=1 If arg1=? - Request for info.                                  */
/* Rc>1 If user terminates or GDG file not in order (see below)        */
/*                                                                     */
/* Written by: CRL  Date: JUL 86                                       */
/* Changed by:      Date:        To:                                   */

If arg(1)='?' then do  /* Display comment info if 1st arg = ? and Exit */
   Parse source . . name .; Say; Say name; Say;
   Do n=1
      line=sourceline(n); If left(line,2)ª='/*' then exit 1; Say line;
      End
   End

Trace Off

arg vaddr fn ft fm den owner .

'EXEC DBTAPGDG OLDEST' fn ft fm
if rcª=0 then return rc
pull . volid .
'EXEC DBTAPE2' volid vaddr 'EXIT Y Y'
if rcª=0 then return rc
'EXEC DBLABWRT' volid vaddr den owner
return rc
