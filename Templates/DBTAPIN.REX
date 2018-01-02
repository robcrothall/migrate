/* DESCRIPTION:                                                        */
/* Readies the current tape in a GDG for reading. This uses DBTAPE2    */
/* to attach a tape unit and instruct the operator to mount the        */
/* correct volid.                                                      */
/*                                                                     */
/* ARGUMENTS: 1. Virtual tape address (181-184)                        */
/*            2. Filename of tape GDG file.                            */
/*            3. Filetype of tape GDG file.                            */
/*            4. Filemode of tape GDG file.                            */
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

arg vaddr fn ft fm .

'EXEC DBTAPGDG CURRENT' fn ft fm
if rcª=0 then return rc
pull . volid .
'EXEC DBTAPE2' volid vaddr 'EXIT N Y'
if rcª=0 then return rc
'TAPE FSF (' vaddr
return 0
