/* DESCRIPTION:                                                        */
/* Analyses the age of reader files, displays the results and          */
/* creates a file DBRDRDEL ANALYSIS A with the data displayed.         */
/* This program must be run on a machine which can look at the reader  */
/* of other machines and transfer files from that reader.              */
/* Since EXECIO cannot look at more than 100 reader files at a time,   */
/* if a machine has 100 or more files, they will be temporarily        */
/* transferred to the operating machine to enable it to look at the    */
/* subsequent files.                                                   */
/* Since this process could cause problems with service machines, only */
/* the first 100 files of these machines are analysed.                 */
/* Service machines are currently determined by looking at the default */
/* project code on MACHINE CODES X, if this code is C00 then we assume */
/* it is a service machine (This can be changed if required).          */
/* We only look at the reader files of machines on MACHINE CODES X.    */
/*                                                                     */
/* Apart from producing an analysis this program can send warnings to  */
/* users about old reader files due to be deleted and also delete      */
/* reader files. See arguments below.                                  */
/* Although old service machine files are deleted, they are not sent   */
/* warning or delete notices. However the information about these      */
/* files are added to DBRDRDEL WARNINGS A and/or DBRDRDEL DELETES A.   */
/* These files contain the information for all warnings and deletes.   */
/*                                                                     */
/*                                                                     */
/* ARGUMENTS: 1. null = Do analysis only                               */
/*               WARN = Do analysis and send warnings                  */
/*               DEL  = Do analysis, send warnings and delete.         */
/*            2. Life span allowed for reader files in weeks (e.g. 4)  */
/*            3. Grace period allowed before deleting in weeks (e.g.1) */
/*                                                                     */
/* Note: If no arguments are given we do analysis,                     */
/*       otherwise 3 arguments must be supplied.                       */
/*                                                                     */
/* RECORDS STACKED/ RETURN CODES/ ERROR CONDITIONS:                    */
/*                                                                     */
/* Rc=1 If arg1=? - Request for info.                                  */
/* Rc=9 If invalid arguments                                           */
/*                                                                     */
/* Written by: CRL  Date: OCT 87                                       */
/* Changed by: CRO  Date: DEC 88 To: Use machine APPEXT as a temporary */
/*             storage for files when processing readers with more     */
/*             than 100 files. (Version 5 of VM renumbers reader files */
/*             when they are transferred.                              */

If arg(1)='?' then do  /* Display comment info if 1st arg = ? and Exit */
   Parse source . . name .; Say; Say name; Say;
   Do n=1
      line=sourceline(n); If left(line,2)^='/*' then exit 1; Say line;
      End
   End

Trace Off

/* Get arguments and set indicators for warning and deletes */
warn=0; del=0; life=0; grace=0
if arg()>0 then do
   arg action life grace .
   if grace='' then return 9
   if action='WARN' then warn=1
   else if action='DEL' then do; warn=1; del=1; end
   else return 9
   if ^datatype(life,'W') ] ^datatype(grace,'W') then return 9
   end

/* set age in days for warnings and deletes */
wdays=life*7
ddays=wdays+grace*7

/* Reaccess X disk */
'ACCESS 31A X'

/* Set days of month for use in days and yymmdd functions below */
dd.1 =  0; dd.2 = 31; dd.3 = 59; dd.4 = 90; dd.5 =120; dd.6 =151
dd.7 =181; dd.8 =212; dd.9 =243; dd.10=273; dd.11=304; dd.12=334

/* Set days of week table for use in dow function below */
d.0='SUN';d.1='MON';d.2='TUE';d.3='WED';d.4='THU';d.5='FRI';d.6='SAT'

/* set current, warning and delete dates etc. */
ctime=time()
cyymmdd=date('O')
cyy=substr(cyymmdd,1,2)
cmm=substr(cyymmdd,4,2)
cdd=substr(cyymmdd,7,2)
cdays=days(cyy,cmm,cdd)
cdow=dow(cdays)
dyymmdd=yymmdd(cdays+grace*7)
ddow=dow(cdays+grace*7)

/* Initialise file to record stats and grand total and serv mach total */
'CLRSCRN'
address command 'ERASE DBRDRDEL ANALYSIS A'
m='             ANALYSIS OF READER FILES AS AT' ctime cdow cyymmdd
call wrt1
m='         * = Service machine which has a max of 100 files analysed.'
call wrt1
m=' '
call wrt1
m='                      .....Kilobytes of spool space used grouped by file age....'
call wrt1
m='                      Days 0-7   8-14  15-21  22-28  29-35  36-42    >42   Total'
call wrt1
m='Machine    Pr.  Files ...Week1  Week2  Week3  Week4  Week5  Week6 >Week6   Total'
call wrt1
gtotal.=0; stotal.=0

/* Initialise files to record all warnings and deletes */
if warn then do
   address command 'ERASE DBRDRDEL WARNINGS A'
   m='OVER-AGE READER FILES AS AT' ctime cdow cyymmdd '(Userid 1-8)'
   call wrt2
   m='Files more than' life 'weeks old, due to be deleted in' grace,
     'weeks time.'
   call wrt2
   address command 'ERASE READER WARNING A'
   end
if del then do
   address command 'ERASE DBRDRDEL DELETES  A'
   m='READER FILES DELETED ON' cdow cyymmdd 'AT' ctime '(Userid 1-8)'
   call wrt3
   m='These files were more than' life '+' grace 'weeks old.'
   call wrt3
   address command 'ERASE READER DELETES A'
   end

/* Obtain machine list from MACHINE CODES X */
'FINIS MACHINE CODES X'
'EXECIO * DISKR MACHINE CODES X 4 (FINIS STEM MACHINE.'

/* Process the reader files of each machine. */

do i=1 to machine.0
   project=substr(machine.i,71,3)
   /* Determine if this is a service machine */
   if project='C00' then service='*'; else service=' '
   parse upper var machine.i machine .

   /* Initialise count of transferred files and machine totals */
   tfer=0; mtotal.=0

   /* Initialise indicators for warning and delete notices */
   wread=0; dread=0

   /* Extract in lots of 100 files */
   do until reader.0<101 ] service='*'
      reader.0=0
      'EXECIO 101 CP (STEM READER. STRING Q RDR' machine 'ALL'
      /* process info for each reader file */
      do j=2 to reader.0
         reader=reader.j
         /* Establish fileno and age group of reader file */
         fileno=substr(reader,10,4)
         mm    =substr(reader,39,2)
         dd    =substr(reader,42,2)
         if mm>cmm then yy=cyy-1; else yy=cyy
         age=cdays-days(yy,mm,dd)
         grp=(age-1)%7+2
         if grp<2 then grp=2
         if grp>8 then grp=8
         /* Establish no. of bytes in reader file */
         bytes=strip(substr(reader,21,8))*80
         /* Update totals */
         mtotal.1  =mtotal.1  +1
         mtotal.grp=mtotal.grp+bytes
         mtotal.9  =mtotal.9  +bytes
         gtotal.1  =gtotal.1  +1
         gtotal.grp=gtotal.grp+bytes
         gtotal.9  =gtotal.9  +bytes
         if service='*' then do
            stotal.1  =stotal.1  +1
            stotal.grp=stotal.grp+bytes
            stotal.9  =stotal.9  +bytes
            end
         /* Delete files that are too old and update files */
         if del & age>ddays then do
            if service^='*' then call delete
            m=left(machine,8) reader
            call wrt3
            'EXECIO 0 CP (STRING PURGE' machine 'RDR' fileno
            end
         else do
            /* Warn about old files */
            if warn & age>wdays then do
               if service^='*' then call warning
               m=left(machine,8) reader
               call wrt2
               end
            /* If 100 files were processed they are transferred to
               APPEXT so that we can access the other files.
               No transferring is done for service machines */
            If reader.0=101 & service^='*' then do
               'EXECIO 0 CP (STRING TRANSFER' machine 'RDR' fileno 'APPEXT'
               tfer=tfer+1; fileno.tfer=fileno
               end
            end
         end
      end
   /* Transfer user files in APPEXT back to user */
   if tfer > 0 then do
      'EXECIO 0 CP (STRING TRANSFER APPEXT RDR ALL TO' machine
      end
   /* Send off messages - if any */
   if dread then do
      address command 'FINIS READER DELETES A'
      'SF READER DELETES A TO' machine '(NOTYPE NOLOG'
      address command 'ERASE READER DELETES A'
      end
   if wread then do
      address command 'FINIS READER WARNING A'
      'SF READER WARNING A TO' machine '(NOTYPE NOLOG'
      address command 'ERASE READER WARNING A'
      end
   /* Create record for stats file if not zero */
   if mtotal.1>0 then do
      m=left(machine,8) service project right(mtotal.1,6) ' '
      /* Round bytes to nearest K and add to record */
      do j=2 to 8
         m=m right((mtotal.j+500)%1000,6)
         end
         m=m right((mtotal.9+500)%1000,7)
      /* Add record to stats file */
      call wrt1
      end
   end

/* Add grand and service totals to stats file */
m=' '
call wrt1
m='TOTAL         ' right(gtotal.1,6) ' '
/* Round bytes to nearest K and add to record */
do j=2 to 8
   m=m right((gtotal.j+500)%1000,6)
   end
m=m right((gtotal.9+500)%1000,7)
call wrt1
m=' '
call wrt1
m='TOTAL    *    ' right(stotal.1,6) ' '
/* Round bytes to nearest K and add to record */
do j=2 to 8
   m=m right((stotal.j+500)%1000,6)
   end
m=m right((stotal.9+500)%1000,7)
call wrt1
/* Close output files */
address command 'FINIS DBRDRDEL ANALYSIS A'
address command 'FINIS DBRDRDEL WARNINGS A'
address command 'FINIS DBRDRDEL DELETES  A'
return 0

/* SUBROUTINES ********************************************************/

/* Function to convert yy,mm,dd to no of days this century */
days: procedure expose dd.
arg yy,mm,dd
mm=mm+0
days=yy*365+yy%4+dd.mm+dd
if yy//4=0 & mm<3 then days=days-1
return days

/* Function to give day of week (e.g.MON) from no of days this century */
dow: procedure expose d.
arg days .
dw=days//7
return d.dw

/* Function to convert no of days this century to yy/mm/dd */
yymmdd: procedure expose dd.
arg days .
yy=days%365
d=days-yy*365-yy%4
if d<0 ] (d=0 & yy//4>0) then do
   yy=yy-1
   d=days-yy*365-yy%4
   end
if yy//4=0 then ly=1; else ly=0
d=d+ly
do mm=12 to 1 by -1
   d2=dd.mm
   if mm>2 then d2=d2+ly
   if d>d2 then leave
   end
dd=d-d2
return right(yy,2,'0')]]'/']]right(mm,2,'0')]]'/']]right(dd,2,'0')

/* routine to prepare delete notices */
delete:
if ^dread then do
   dread=1
   m='READER FILES DELETED ON' cdow cyymmdd 'AT' ctime
   call wrt5
   m=' '
   call wrt5
   m='The following reader files were more than' life 'weeks old' grace,
     'week/s ago.'
   call wrt5
   m='They have been DELETED and cannot be recovered from the reader.'
   call wrt5
   m=' '
   call wrt5
   m=reader.1
   call wrt5
   end
m=reader
call wrt5
return 0

/* routine to prepare warning notices */
warning:
if ^wread then do
   wread=1
   m='OVER-AGE READER FILES AS AT' ctime cdow cyymmdd
   call wrt4
   m=' '
   call wrt4
   m='The following files have been in your reader for more than' life,
     'weeks.'
   call wrt4
   m='They will be DELETED in' grace 'weeks time (i.e. on' ddow,
     dyymmdd]]').'
   call wrt4
   m=' '
   call wrt4
   m=reader.1
   call wrt4
   end
m=reader
call wrt4
return 0

wrt1:
'EXECIO 1 DISKW DBRDRDEL ANALYSIS A 0 F 80 (VAR M'
/* say m */
if rc^=0 then call diskfull
return

wrt2:
'EXECIO 1 DISKW DBRDRDEL WARNINGS A 0 F 90 (VAR M'
if rc^=0 then call diskfull
return

wrt3:
'EXECIO 1 DISKW DBRDRDEL DELETES A 0 F 90 (VAR M'
if rc^=0 then call diskfull
return

wrt4:
'EXECIO 1 DISKW READER WARNING A 0 F 80 (VAR M'
if rc^=0 then call diskfull
return

wrt5:
'EXECIO 1 DISKW READER DELETES A 0 F 80 (VAR M'
if rc^=0 then call diskfull
return

diskfull:
/* Transfer user files in machine back to user - if any */
do j=1 to tfer
   'EXECIO 0 CP (STRING TRANSFER RDR' fileno.j 'TO' machine
   end
'CLRSCRN'
say 'Return code = ' rc 'from an EXECIO DISKW operation.'
say 'Your A disk is probably full.'
say 'Clear space and redo DBRDRDEL exec.'
'EXEC DBSTOP'
return
