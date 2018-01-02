/* Description.....                                                    */
/*                                                                     */
/*                                                                     */
/*                                                                     */
/* ARGUMENTS: 1. ?                                                     */
/*            2. ?                                                     */
/*                                                                     */
/*                                                                     */
/* RECORDS STACKED/ RETURN CODES/ ERROR CONDITIONS:                    */
/*                                                                     */
/* Rc=1 If arg1=? - Request for info.                                  */
/*                                                                     */
/* Written by: XXX  Date: MMM YY                                       */
/* Changed by:      Date:        To:                                   */

If arg(1)='?' then do  /* Display comment info if 1st arg = ? and Exit */
   Parse source . . name .; Say; Say name; Say;
   Do n=1
      line=sourceline(n); If left(line,2)ª='/*' then exit 1; Say line;
      End
   End

Trace Off

/* Get args */

Parse upper arg fn ft .
rem.=''                         /* Initialise remember storage */
rootfn=fn                       /* Set fn ft of root */
rootft=ft
treeft=left(ft,4,'$')³³'TREE'   /* Set ft of TREE file */
treefm='A'                      /* Set disk on which to create TREE's */
Stackrecs=Queued()              /* Count recs already on stack        */
'MAKEBUF'                       /* Make a buffer for use by this exec */


/* Start TREE file for first file of the given fn ft */
/* File subroutine will set the filemode of the file in rootfm */

filerc=File(fn ft)
If filerc>0 then do
   'DROPBUF'
   Return filerc
   End

/* Store module names */

mod.=0
'LISTFILE * MODULE * (FIFO'
Do Queued()-Stackrecs
   pull modname .
   mod.modname=1
   end

/* Analyse current file */

Do lineno=1
   'EXECIO 1 DISKR' fn ft rootfm '(LIFO'  /* Get next line from file */
   If rcª=0 then leave
   Parse pull line
   word1=word(line,1)
   if lineno=1 then                  /* Establish type of file */
           if word1='&CONTROL'   then type='EXEC'
      else if word1='&TRACE  '   then type='EXEC2'
      else if left(word1,2)='/*' then type='REXX'
      else                            type='OTHER'
   line2=line                        /* prepare line according to type */
   if type='EXEC' ³ type='EXEC2' then do
      if left(word1,1)='*' then line2=''     /* eliminate comments and */
      if word1='&TYPE' then line2=''         /* typed lines */
      End
   else if type='REXX' ³ type='OTHER' then do
      Upper line2                            /* translate to uppercase */
      line2=translate(line2,'    ',';''*"')  /* eliminate ; ' * and " */
      End
   Do wordno=1 to words(line2)        /* Process each word in line2 */
      word=word(line2,wordno)
      if wordª='EXEC' & mod.word=1 then do     /* MODULE name */
         Call File(word 'MODULE' lineno line)
         End
      if word='EXEC' then do                   /* EXEC */
         wordno=wordno+1
         execname=word(line2,wordno)          /* get name */
         if execname='' then leave
         if length(execname)>8 then leave
         'SET CMSTYPE HT'
         'STATE' execname 'EXEC *'
         Staterc=rc
         'SET CMSTYPE RT'
         If Staterc=20 then leave
         execname2=execname
         Upper execname2
         If execname2ª=execname then leave
         Call File(execname2 'EXEC' lineno line)
         End
      End /* word */
   End /* line */
                                /* Close open files */
'FINIS' fn ft rootfm
'FINIS' fn treeft treefm

Push 'FILE'                     /* Sort TREE file */
Push 'SORT * 22 28 19 20 1 17'
'XEDIT' fn treeft treefm

'DROPBUF'                       /* Drop buffer used by this exec */

Return

/* subroutine to handle creation of all TREE files and screen messages */

File: procedure expose rem. rootfn rootft rootfm treeft treefm stackrecs

parse arg fn ft lineno line
treeft2=left(ft,4,'$')³³'TREE'

                             /* file is not new */
if rem.ft.fnª='' then do
   fm=rem.ft.fn
   return logerr()
   end

                             /* is this a root file */
if fn=rootfn & ft=rootft then root=1; else root=0

                             /* stack files of given fn ft */
'SET CMSTYPE HT'; 'LISTFILE' fn ft '* (FIFO DATE'
'SET CMSTYPE RT'
no=queued()-stackrecs

if no=0 then do              /* fn ft does not exist on any disk */
   'SET CMSTYPE HT'; 'ERASE' fn treeft2 treefm
   'SET CMSTYPE RT'
   if root then return 9
   fm='**'
   rem.ft.fn=fm                    /* remember fm */
   return logerr()
   end

                             /* get fm date time of first fn ft file */
Pull 19 fm 21 57 mm 59 60 dd 62 63 yy 65 66 time 74
datetime=yy³³'/'³³translate(mm,'0',' ')³³'/'³³dd time
If root then rootfm=fm

If ft='MODULE' then do       /* modules are not analysed */
   Call Basfil
   return logerr()
   End

Stackrecs2=Queued()          /* look for latest corresp ft TREE file */
'SET CMSTYPE HT'; 'LISTFILE' fn treeft2 '* (LIFO DATE'
'SET CMSTYPE RT'
treefm2=''; treedatetime2=''
Do queued()-stackrecs2
   Pull 19 treefmx 21 57 mm 59 60 dd 62 63 yy 65 66 time 74
   treedatetimex=yy³³'/'³³translate(mm,'0',' ')³³'/'³³dd time
   'EXECIO 1 DISKR' fn treeft2 treefmx '1 (LIFO FINIS'
   pull fn2 ft2 . 22 type2 25 38 datetime2 55
   if fn2=fn & ft2=ft & type2='BAS' & datetime=datetime2 then do
      if treedatetimex > treedatetime2 then do
         treedatetime2 = treedatetimex
         treefm2 = treefmx
         End
      End
   End

If treefm2='' then do        /* no corresp tree file exists */
   'SET CMSTYPE HT'; 'ERASE' fn treeft2 treefm
   'SET CMSTYPE RT'
   Call Basfil
   If root then return 0
   Call Logerr
   Call dbtree fn ft            /* call DBTREE recursively */
   Say
   Say 'Continuing TREE file for' rootfn rootft fm 'on' treefm³³'-disk.'
   Say
   Return 0
   End

If treefm2ª='' then do  /* corresp tree file does exist */
   treefm21=left(treefm2,1)
   If ªroot then do
      Call Basfil
      Call Logerr
      End
   If treefm21ª=treefm then do
      Say
      Say 'Copying TREE file for' fn ft fm 'from' treefm21³³'-disk to' treefm³³'-disk.'
      Say
      End
   If treefm21ª=treefm ³ treedatetime2<date('O') then do
      'COPYFILE' fn treeft2 treefm2 '= =' treefm '(REPLACE'
      End
   If root then Return 1; else Return 0
   End

Exit

Logerr:                      /* subroutine to add LOG and ERR recs */
   fn=left(fn,8); ft=left(ft,8); lineno=right(lineno,4)
   logrc=0
   if fm='**' then do
      logrc=9
      push fn ft fm 'ERR'³³lineno line
      Call Write
      End
   push fn ft fm 'LOG'³³lineno line
   Call Write
   say  fn ft fm 'LOG'³³lineno left(line,50)
   Return logrc

Basfil:                      /* subroutine to add BAS and FIL recs */
   rem.ft.fn=fm                    /* remember fm */
   fn=left(fn,8); ft=left(ft,8);
   fm2=fm
   if root then do
      type='BAS'
      Say
      Say 'Creating TREE file for' fn ft fm 'on' treefm³³'-disk.'
      Say
      End
   else type='FIL'
   Do i=1 to no
      if i>1 then do
         Pull 19 fm2 21 57 mm 59 60 dd 62 63 yy 65 66 time 74
         datetime=yy³³'/'³³translate(mm,'0',' ')³³'/'³³dd time
         End
      Push fn ft fm2 type '    Dated: ' datetime ' file' i 'of' no
      Call Write
      End
   Return

Write:                       /* subroutine to write to TREE file */
   'EXECIO 1 DISKW' rootfn treeft treefm '0 V 132'
   Return
