/* DESCRIPTION:                                                        */
/* Maintains a tape GDG file allowing the user to do the following.    */
/* CREATE:   Create a GDG file interactively.                          */
/* CURRENT:  Obtain the volser of the current file.                    */
/* OLDEST:   Obtain the volser of the oldest file.                     */
/* FORWARD:  Cycle the GDG forward making the volser of the oldest     */
/*           file the current file.                                    */
/* BACKWARD: Cycle the GDG backward making the volser of the current   */
/*           file the oldest file.                                     */
/*                                                                     */
/* A GDG is a sequence, usually of three tapes, where the oldest tape  */
/* is overwritten when the file is updated. See software support for   */
/* further details.                                                    */
/*                                                                     */
/* ARGUMENTS: 1. Action (CREATE, CURRENT, ... as above).               */
/*            2. Filename of GDG.                                      */
/*            3. Filetype of GDG.                                      */
/*            4. Filemode of GDG. (default A)  ***                     */
/*                                                                     */
/* *** The GDG file must be on a disk to which you have R/W access     */
/*     for CREATE, FORWARD or BACKWARD. However for FORWARD and        */
/*     BACKWARD the GDG file can be on the X-disk. The EXEC will exit  */
/*     only once the X-disk has been updated and re-accessed.          */
/*                                                                     */
/* RECORDS STACKED/ RETURN CODES/ ERROR CONDITIONS:                    */
/*                                                                     */
/* Rc=1 If arg1=? - Request for info.                                  */
/*    6 Action code invalid.                                           */
/*    7 Fileid invalid.                                                */
/*    8 GDG file already exists or disk not R/W (CREATE).              */
/*    9 GDG file not on R/W disk or X-disk (FORWARD, BACKWARD).        */
/*    0 GDG action successful and following record stacked LIFO:       */
/*      * volid userid date time  (if action = 1 or 2 )                */
/*              ---------------- machine creating file and when        */
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

arg action fn ft fm .
if fm='' then fm='A'

if find('CREATE CURRENT OLDEST FORWARD BACKWARD',action)=0 then return 6

'STATE ' fn ft fm
if rcª=0 & rcª=28 then return 7
if rc=28 & actionª='CREATE' then return 7
if rc=0  & action ='CREATE' then return 8

'Q DISK' fm '(LIFO'
pull . . . access .
pull
if action='CREATE' & accessª='R/W' then return 8
if (action='FORWARD' ³ action='BACKWARD') & accessª='R/W' & left(fm,1)ª='X' then return 9

if action='CREATE' then do
   'CLRSCRN'
   say 'Creating Tape GDG file:' fn ft fm
   say
   say 'Enter the volids of the tapes in the GDG separated by spaces.'
   say 'The first volid must be that of the current tape.'
   say 'A volid may be made up of numbers or letters up to 6 chars.'
   say
   pull volids
   user=left(userid(),8); dte=date('O'); tme=time()
   do while volidsª=''
      parse upper var volids volid volids
      volid=left(volid,6)
      push '*' volid user dte tme
      'EXECIO 1 DISKW' fn ft fm '0 F 80 (FINIS'
      end
   end

/* get no. of tapes in GDG */
'LISTFILE' fn ft fm '(LIFO DATE'
 pull . . . . . notapes .

if action='CURRENT' then 'EXECIO 1 DISKR' fn ft fm '1 (LIFO FINIS'

if action='OLDEST'  then 'EXECIO 1 DISKR' fn ft fm notapes '(LIFO FINIS'

if action='FORWARD' then do   /* get last rec and put it in front */
   'MAKEBUF'
   'EXECIO 1 DISKR' fn ft fm notapes '(LIFO FINIS'
   pull . volid .
   push '*' left(volid,6) left(userid(),8) date('O') time()
   'EXECIO' notapes-1 'DISKR' fn ft fm '1 (FIFO FINIS'
   call write
   'DROPBUF'
   end

if action='BACKWARD' then do   /* get first rec and put it at back */
   'MAKEBUF'
   'EXECIO 1 DISKR' fn ft fm '1 (LIFO FINIS'
   pull data
   'EXECIO' notapes-1 'DISKR' fn ft fm '2 (FIFO FINIS'
   queue data
   call write
   'DROPBUF'
   end

return 0

write:

   if left(fm,1)ª='X' then do
      'SET CMSTYPE HT'
      'ERASE DBTAPGDG $TEMP' fm
      'SET CMSTYPE RT'
      'EXECIO' notapes 'DISKW DBTAPGDG $TEMP' fm '1 F 80 (FINIS'
      'ERASE' fn ft fm
      'RENAME DBTAPGDG $TEMP' fm fn ft fm
      end

   else do
      'Q DISK MAX (LIFO'
      pull . . wm .
      pull
      'SET CMSTYPE HT'
      'ERASE DBTAPGDG $TEMP' wm
      'RENAME' fn ft wm 'DBTAPGDG $TEMP ='
      'EXECIO' notapes 'DISKW' fn ft wm '1 F 80 (FINIS'
      datetime=date('O')³³time()
      'EXEC APPLIB' fn ft wm
      'ERASE' fn ft wm
      'RENAME DBTAPGDG $TEMP' wm fn ft '='
      do until datetimex>datetime
         'CP SLEEP 1 SEC'
         'ACC 31A X'
         'LISTFILE' fn ft fm '(LIFO DATE'
         if rcª=0 then iterate
         pull . . . . . . . dte tme .
         dte=right(dte,8,'0'); tme=right(tme,8,'0')
         datetimex=substr(dte,7,2)³³'/'³³substr(dte,1,5)³³tme
         end
      'SET CMSTYPE RT'
      end

return 0
