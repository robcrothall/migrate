/* HOR:  HORizontal edit         Version 831125      */
/* Written by Martin Klein (KLEIN at VABVM1)         */
/*         Program Product Development Centre VIENNA */
trace off
/* init variables     */
position=0
cofrom=0
mofrom=0
colen=0
molen=0
cm.1='DD'
cm.2='CC'
cm.3='MM'
cm.4='XX'
command=''
pfcommand=''
verline=''
tabline=''
copydone='NO'
parse arg target
if target='?' then do
   help hor
   exit
   end
if target='' then do
Address Command 'SET CMSTYPE HT'
  Address Command 'GLOBALV SELECT HOR STACK TARGET'
  if queued()>0 then do
    parse pull target
    if target='' then target='1'
  end
  else target='1'
Address Command 'SET CMSTYPE RT'
end
'COMMAND TRANSFER VERIFY'
pull ver .
'COMMAND SET VERIFY OFF'
'COMMAND TRANSFER LINE'
pull start
'COMMAND LOCATE' target
'COMMAND TRANSFER POINT'
parse pull oldpoint
'COMMAND SET POINT .HOREND'
'COMMAND LOCATE :'start
target= '.HOREND'
/* get XEDIT values   */
'COMMAND TRANSFER MASK'
parse pull mask
'COMMAND TRANSFER NULLS MSGMODE'
pull nulls msgmode1 msgmode2
'COMMAND TRANSFER SCALE CURLINE RESERVED'
pull scale scline cline reslines
if scline=cline-1 ] find(reslines,cline-1)>0 then horres=cline
else horres=cline-1
'COMMAND SET MASK IMMED';
'COMMAND SET NULLS OFF'
msg='>> C=Copy,M=Move,F=Fol,U=Abov,P=Pre,A=Add,
I=Ins,D=Del,"=Dup,R=Rep,O=Ovl,X=Xfer'
'COMMAND SET RESERVED' horres  'H' msg
'COMMAND SET MSGMODE OFF'
Address Command 'SET CMSTYPE HT'
'COMMAND EXTRACT /SPILL/'
if spill.0=1 then do
  'COMMAND SET SPILL OFF'
  rel=r3
end
else rel=r2
Address Command 'GLOBALV SELECT HOR STACK CHAR'
if queued()>0 then do
  parse pull cmdlchar
  if cmdlchar^='' then cmdlchar=translate(left(cmdlchar,1),'  ','bB')
  else cmdlchar='?'
end
else cmdlchar='?'
Address Command 'SET CMSTYPE RT'
cul=0
read:
firstz='YES'
/* build the hor command line */
'COMMAND UP'
'COMMAND TRANSFER ZONE'
pull zo1 zo2
'COMMAND ADD'
'COMMAND NEXT 1'
'COMMAND CL :' zo1
'COMMAND CR' copies(cmdlchar,zo2-zo1+1)
if cul>0 & cuc>0 then 'COMMAND CURSOR FILE' cul cuc
'COMMAND TRANSFER LINE'
pull line
/* wait for input           */
read1: 'COMMAND READ ALL TAG NUMBER'
if rc^=5 then do                       /*New XEDIT                    */
  flag=0
  do while queued()>0
    pull prefix rest
    if prefix='CMD' & rest^=' ' then do;command=rest;flag=1;end
    if prefix='PFK' then do;parse var rest . pfcommand;flag=1;end
    if prefix='FIL' then do;flag=1;end
    if prefix='PRF' & rel=r3 then do;flag=1
       parse var rest . . prfline prfcommand; ':'prfline
       'COMMAND LPREFIX' prfcommand; ':'line; end
  end
end                                    /*                             */
if rc=5 then do                        /*Old XEDIT                    */
  'COMMAND READ ALL NUMBER'
  flag=0
  do while queued()>0
    pull prefix rest
    if datatype(prefix)^='NUM' & prefix^=' ' then do
        command=prefix rest;flag=1;end
    if datatype(prefix)='NUM' then flag=1
  end
end                                    /*                             */
'COMMAND TRANSFER CURSOR'
pull . . cul cuc
/* read the command line          */
'COMMAND STACK 1'
parse pull cmdl
cmdl=translate(cmdl,' ',cmdlchar)
if cmdl=' ' then signal exit
parse upper var cmdl cmdlt
/* modify the block commands to normal commands (e.g. 'dd dd' to 'd5')*/
do x=1 to 4
   dd1=pos(cm.x,cmdlt)
   do while (dd1>0 & (verify(cmdlt,'IOR','M')>dd1 ] verify(cmdlt,'IOR','M')=0))
     tl=verify(substr(cmdlt,dd1),cm.x)
     if tl=0 then tl=length(substr(cmdlt,dd1))
     else tl=tl-1
     if tl>2 then do
       cmdl=overlay(tl]]copies(' ',tl-length(tl)-1),cmdl,dd1+1)
       parse upper var cmdl cmdlt
       dd1=pos(cm.x,cmdlt)
     end
     else do
       dd2=pos(cm.x,cmdlt,dd1+2)
       if dd2>0 then do
         cmdl=overlay('  ',cmdl,dd2)
         cmdl=overlay(dd2-dd1+2]]' ',cmdl,dd1+1)
         parse upper var cmdl cmdlt
         dd1=pos(cm.x,cmdlt)
       end
       else do
         cmdl=overlay('2 ',cmdl,dd1+1)
         dd1=0
       end
     end
   end
 end
/* scan the command line and invoke the necessary subroutines */
do i = zo1 to zo2
  parse upper value substr(cmdl,i,1) with cmd
  if substr(cmdl,i)=' ' then leave
  if cmd=' ' then iterate
  if datatype(cmd)='NUM' then iterate
  select
    when cmd='D' then call delete
    when cmd='I' then call insrt
    when cmd='A' then call add
    when cmd='R' then call repl
    when cmd='O' then call over
    when cmd='"' then call dupl
    when cmd='F' then call foll
    when cmd='U' then call here
    when cmd='P' then call prec
    when cmd='C' then call copy
    when cmd='M' then call move
    when cmd='X' then call tran
    when cmd='Z' then call zone
    when cmd='T' then call trun
    when cmd='V' then call veri
    when cmd='H' then call verh
    when cmd=';' then call tabs
    Otherwise
      COMMAND MSGMODE ON
      COMMAND EMSG 'No valid command'
      COMMAND SET MSGMODE OFF
  end
end
/* do the actual copy command */
if position>0 & cofrom>0 then do
  'COMMAND :' line+1
  'COMMAND STACK' target cofrom colen
  'COMMAND :' line+1
  ins=position
  n=1
  call insrt1
  cofrom=0
  colen=0
  position=0
  copydone='YES'
end
/* do the actual move command and xfer command */
if position>0 & mofrom>0 & copydone='NO' then do
  'COMMAND :' line+1
  'COMMAND STACK' target mofrom molen
  'COMMAND :' line
  if s='DELETE' then do
    cmdl=overlay(molen]]' ',cmdl,mofrom+1)
    i=mofrom
    call delete
  end
  if s='BLANK' then do
    savecmdl=cmdl
    cmdl=copies(' ',length(cmdl))
    cmdl=overlay(copies('_',molen),cmdl,mofrom)
    i=mofrom-1
    call over
    cmdl=savecmdl
  end
  if position>=mofrom+molen & s='DELETE' then ins=position-molen
  else ins=position
  n=1
  'COMMAND :' line+1
  call insrt1
  mofrom=0
  molen=0
  position=0
end
copydone='NO'
/* do the actual TAB and VERIFY commands */
if verline^='' then do
  'COMMAND SET VERIFY' ver verline
  verline=''
end
if tabline^='' then do
  'COMMAND SET TABS' tabline
  tabline=''
end
/* delete the command line and loop back for next run */
'COMMAND :' line
'COMMAND DELETE 1'
signal read
exit:
/* process pfcommands and XEDIT cmdline, loop back for next run */
if flag=1 then do
  'COMMAND :' line
  'COMMAND DELETE 1'
  command=translate(command.'"',"'")
  if command^='' then interpret "'"command"'"
  command=''
  pfcommand=translate(pfcommand,'"',"'")
  if pfcommand^='' then interpret "'"pfcommand"'"
  pfcommand=''
  'COMMAND TRANSFER LINE CURSOR'
  pull line . . cul cuc
  signal read
end
/* delete command line, reset XEDIT values and exit */
'COMMAND DELETE 1'
'COMMAND SET MASK IMMED' mask
'COMMAND SET NULLS' nulls
if rel=r3 then 'COMMAND SET SPILL OFF'
'COMMAND SET MSGMODE' msgmode1 msgmode2
'COMMAND LOCATE .HOREND'
'COMMAND SET POINT .HOREND OFF'  /******* fix by bucky ******/
if rel=r2 & oldpoint^='' then
  'COMMAND SET POINT .']]oldpoint
'COMMAND :' start
'COMMAND SET RESERVED' horres 'OFF'
'COMMAND SET SCALE' scale scline
'COMMAND SET VER' ver
exit
delete:
/********* process DELETE command ********/
parse value substr(cmdl,i+1) with n .
if datatype(n)^='NUM' then n=1
'COMMAND CLOCATE :' i
'COMMAND CDELETE' n
cmdl=delstr(cmdl,i,n)
'COMMAND REPEAT' target
'COMMAND :' line
i=i-1
return
add:
/******** process ADD command ********/
parse value substr(cmdl,i+1) with n .
if datatype(n)^='NUM' then n=1
if position=0 then 'COMMAND CLOCATE :' i+1
else do
 'COMMAND CLOCATE :' position
 position=0
end
'COMMAND CINSERT' copies(' ',n)
cmdl=overlay(' ',cmdl,i)
cmdl=insert(copies(' ',n),cmdl,i)
do until rc=1 ] rc=2 ] rc=0
  'COMMAND REPEAT' target
end
'COMMAND :' line
return
insrt:
/******** process INSERT command ********/
parse value substr(cmdl,i+1) with text
text=strip(text,'t')
text=translate(text,' ','_')
if position=0 then 'COMMAND CLOCATE :' i+1
else do
 'COMMAND CLOCATE :' position
 position=0
end
'COMMAND CINSERT' text
cmdl=' '
do until rc=1 ] rc=2 ] rc=0
  'COMMAND REPEAT' target
end
'COMMAND :' line
return
repl:
/******** process REPLACE command ********/
parse value substr(cmdl,i+1) with text
test=strip(text,'t')
text=translate(text,' ','_')
'COMMAND CLOCATE :' i+1
'COMMAND CREPLACE' text
cmdl=' '
'COMMAND REPEAT' target
'COMMAND :' line
return
over:
/******** process OVERLAY command ********/
parse value substr(cmdl,i+1) with text
'COMMAND CLOCATE :' i+1
text=strip(text,'T')
'COMMAND COVERLAY' text
cmdl=' '
'COMMAND REPEAT' target
'COMMAND :' line
return
insrt1:
/*******************************************************************/
/* handle the target processing for COPY, MOVE, XFER and DUPLICATE */
/*******************************************************************/
do while queued()>0
parse pull text
text=copies(text,n)
'COMMAND CLOCATE :' ins
if t='INSERT' then
  'COMMAND CINSERT' text
if t='REPLACE' then
  'COMMAND CREPLACE' text
if t='OVERLAY' then
  'COMMAND COVERLAY' text
'COMMAND NEXT'
end
if t='INSERT' then
  cmdl=insert(copies(' ',length(text)),cmdl,i)
'COMMAND :' line
return
dupl:
/******** process DUPLICATE command ********/
from=i
ins=from+1
if substr(cmdl,i+1,1)='"' then do
  tl=verify(substr(cmdl,i),'"')
  if tl=0 then tl=length(tempstr)
  else tl=tl-1
  if tl>2 then do
    ins=i+tl
    i=i+tl-1
  end
  else do
    j=pos('""',cmdl,i+2)
    if j>0 then do; ins=j+2; i=j+1; end
    else do; ins=i+2; i=i+1; end
  end
end
parse value substr(cmdl,ins) with n .
if datatype(n)^='NUM' then n=1
len=ins-from
'COMMAND :' line+1
'COMMAND STACK' target from len
'COMMAND :' line+1
t='INSERT'
call insrt1
return
copy:
/******** set source pointer for COPY command ********/
cofrom=i
parse value substr(cmdl,i+1) with colen .
if datatype(colen)^='NUM' then colen=1
return
move:
/******** set source pointer for MOVE command ********/
mofrom=i
s='DELETE'
parse value substr(cmdl,i+1) with molen .
if datatype(molen)^='NUM' then molen=1
return
tran:
/******** set source pointer for XFER command ********/
mofrom=i
s='BLANK'
parse value substr(cmdl,i+1) with molen .
if datatype(molen)^='NUM' then molen=1
return
foll:
/******** process FOLLOWING command ********/
/******** (set target pointer for COPY, MOVE XFER) ********/
position=i+1
t='INSERT'
return
prec:
/******** process PRECEEDING command ********/
/******** (set target pointer for COPY, MOVE XFER) ********/
position=i
t='INSERT'
return
here:
/******** process UPON command ********/
/******** (set target pointer for COPY, MOVE XFER) ********/
position=i
t='REPLACE'
return
trun:
/******** process TRUNCATION command ********/
'COMMAND SET TRUNC' i
return
zone:
/******** process ZONE command ********/
IF firstz='YES' then do
  firstz='NO'
  zone1=i
end
else do
  firstz='YES'
  zone2=i
  'COMMAND SET ZONE' zone1 zone2
end
return
veri:
/******** process VERIFY command ********/
verline=verline i
return
verh:
/******** process VERIFYHEX command ********/
if words(verline)>1 then do
 if words(verline,words(verline)-1)='H' then
  verline=verline i
 else
  verline=verline 'H' i
end
else
  verline-verline 'H' i
return
tabs:
/******** process TABS command ********/
tabline=tabline i
return
