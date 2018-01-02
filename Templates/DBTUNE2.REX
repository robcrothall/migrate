/* To sample the queues and adjust the priorities of machines.         */
/* Reserved machines (see below) are given a priority1.                */
/* Disconnected machines are given priority3.                          */
/* Machines coming into the system for the first time or no longer     */
/* on the queues are given priority1.                                  */
/* Otherwise the priority of a machine is set between priority1 and    */
/* priority2 in proportion to the time sampled in Q1. The priority of  */
/* machines is brought down incrementally not in a single jump.        */
/*                                                                     */
/* This exec runs continuously and can be interrupted by pressing      */
/* enter and you will eventually get a VM read. Then enter HX.         */
/*                                                                     */
/* ARGUMENTS: 1. Secs between setting priorities. (default 15)         */
/*            2. Samples per second for the queues. (default 3)        */
/*            3. Priority 1 (default 64)                               */
/*            4. Priority 2 (default 96)                               */
/*            5. Priority 3 (default 99)                               */
/*                                                                     */
/* RECORDS STACKED/ RETURN CODES/ ERROR CONDITIONS:                    */
/*                                                                     */
/* Rc=1 If arg1=? - Request for info.                                  */
/* Rc=9 If user machine cannot execute the CP IND Q command.           */
/*                                                                     */
/* Written by: CRL  Date: MAY 86                                       */
/* Changed by:      Date:        To:                                   */

If arg(1)='?' then do  /* Display comment info if 1st arg = ? and Exit */
   Parse source . . name .; Say; Say name; Say;
   Do n=1
      line=sourceline(n); If left(line,2)ª='/*' then exit 1; Say line;
      End
   End

Trace Off
'DESBUF'
parse arg setint sampsec priority1 priority2 priority3 .
if setint='' then setint=15
if sampsec='' then sampsec=3
if priority1='' then priority1=64
if priority2='' then priority2=96
if priority3='' then priority3=99
res.=''
me=userid()
res.me=priority1
res.osvs1=priority1
res.applib=priority1
res.rscs=priority1
plist1.='.'
plist2.='.'
plist=1
stackrecs=queued()
do forever
   total=0
   q1.=0
   sampled.=0
   set=time('R')
   do until time('E')>setint
      do sampsec
         total=total+1
         'EXECIO * CP (LIFO STRING IND QUEUES'
         If rcª=0 then return 9
         Do queued()
            pull data
            do while dataª=''
               parse var data id q . . data
               sampled.id=sampled.id+1
               if q='Q1' then q1.id=q1.id+1
               end
            end
         end
      'CP SLEEP 1 SEC'
      end
   'CLRSCRN'
   'CP IND LOAD'
   say '         Priority D=Dsc  R=Res            To stop press ENTER then RESET until'
   say 'Userid   Old  New   Q1%  Sampled          you get VM READ....... then enter HX.'
   say
   if plist=1 then plist2.='.'; else plist1.='.'
   'QUERY NAMES (LIFO'
   do queued()
      pull data
      do while dataª=''
         parse var data 1 id 9 12 dsc 15 17 data
         if left(id,3)='LOG' & right(id,3)=dsc then iterate
         id=strip(id)
         if plist=1 then oldpri=plist1.id; else oldpri=plist2.id
         type=' '
         if res.idª='' then do
            type='R'
            newpri=res.id
            end
         else if dsc='DSC' then do
            type='D'
            newpri=priority3
            end
         else if oldpri='.' then newpri=priority1
         else if sampled.id>0 then do
            newpri=priority2-(priority2-priority1)*q1.id/sampled.id
            if newpri>oldpri then newpri=oldpri+(newpri-oldpri)/2
            newpri=trunc(newpri)
            end
         else newpri=priority1
         if newpriª=oldpri then do
            if sampled.id=0 then q1pct='.'
            else q1pct=trunc(q1.id/sampled.id*100+0.5)
            say left(id,8) right(oldpri,3) right(newpri,4) type right(q1pct,3) right(sampled.id,8)
            'CP SET PRIORITY' id newpri
            end
         if plist=1 then plist2.id=newpri; else plist1.id=newpri
         end
      end
   if plist=1 then plist=2; else plist=1
   say
   say 'Total no. of samples   ' right(total,8)
   say
   end
return 0
