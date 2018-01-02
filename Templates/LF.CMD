/* DESCRIPTION:                                                        */
/* Listfiles is equivalent of the CMS filelist display and is used     */
/* in the same way. For more details browse LF.HLP                     */
/*                                                                     */
/* Note: If you change this program, it should be optimised-           */
/*       Enter REXX /O LF.REX with the prompt on the directory where   */
/*       the file is resident.                                         */
/*                                                                     */
/* ARGUMENTS: 1. see LF.HLP                                            */
/*            2.                                                       */
/*                                                                     */
/* RECORDS STACKED/ RETURN CODES/ ERROR CONDITIONS:                    */
/*                                                                     */
/* Rc=1 If arg1=? - Request for info.                                  */
/* Rc=9 If invalid parms.                                              */
/*                                                                     */
/* Written by: CRL  Date: MAY 88                                       */
/* Changed by:      Date:        To:                                   */

If arg(1)='?' then do  /* Display comment info if 1st arg = ? and Exit */
   Parse source . . name .; Say; Say name; Say;
   Do n=1
      line=sourceline(n); If left(line,2)^='/*' then exit 1; Say line;
      End
   End

Trace O

/* set paths for help and work files differently if on network */
/*uname=!%UNAME%;*/
uname='!';
if uname='!' then do
   hp='C:\BAT\'      /* path for help file LF.HLP */
   wp='C:\TEMP\'          /* path for work files disk */
   end
else do
   hp='N:\PUBLIC\TOOLS\'  /* path for help file LF.HLP */
   wp='P:\'uname'\'       /* path for work files disk */
   end

/* colours: text    protect entries errors  messag  locates */
            ct= 10; cp= 11; ce= 15; cx= 64; cm=112; cl=112

/* symbols: */
/* all          path         name         ext          left         right */
sa=d2c(142); sp=d2c(157); sn=d2c(165); se=d2c(144); sl=d2c(242); sr=d2c(243)

plen=37       /* max length of the char string for path */
llen=53+plen  /* line length */
d.=''; lastcmd.=''; lastmax=20  /* max no. of commands stored */
lcom0=0; lcom1=0;
line.=0; pline.=0
x=1
xnew=1; xno=1; xlist=1; xword=1
lfnew=0; end=0
/*cursor.0=cursortype(6,7)*/
arg parms1
call init parms1
if rc>0 then return rc

do until end
   k=inkey()
   if length(k)=1 then kd=c2d(k); else kd=-c2d(substr(k,2,1))
   select
      when kd=  8 then call entered       /* DOS Backspace */
      when kd=  9 then call tab
      when kd= 13|kd=27 then call enter   /* Enter or Esc */
      when kd>=32 then call text
      when kd=-15 then call tabup
      when kd=-18 then do; k=se; call text; end;  /* Alt-E */
      when kd=-19 then do; k=sr; call text; end;  /* Alt-R */
      when kd=-25 then do; k=sp; call text; end;  /* Alt-P */
      when kd=-30 then do; k=sa; call text; end;  /* Alt-A */
      when kd=-38 then do; k=sl; call text; end;  /* Alt-L */
      when kd=-49 then do; k=sn; call text; end;  /* Alt-N */
      when kd=-59 then call f1
      when kd=-60 then call f2
      when kd=-61 then call f3
      when kd=-62 then call f4
      when kd=-63|kd=-88 then call f5        /* F5 or Shift-F5 */
      when kd=-64|kd=-89 then call f6        /* F6 or Shift-F6 */
      when kd=-65|kd=-90 then call f7        /* F7 or Shift-F7 */
      when kd=-66|kd=-91 then call f8        /* F8 or Shift-F8 */
      when kd=-67 then call f9
      when kd=-68 then call f10
      when kd=-71 then call home
      when kd=-72 then call cursoru
      when kd=-73 then call pgup
      when kd=-75 then call cursorl
      when kd=-77 then call cursorr
      when kd=-79 then call end
      when kd=-80 then call cursord
      when kd=-81 then call pgdown
      when kd=-82 then call ins
      when kd=-83 then call del
      when kd=-98 then call sort 'A 5 8'   /* Ctrl-F5 */
      when kd=-134 then call f12
      when kd=-132|kd=-118 then call swop  /* Ctrl-Pgup or Ctrl-Pgdown */
      otherwise
      end
   end
do w=1 to xno
   x=word(xlist,w)
   call charout w2.x; call dosdel w2.x
   end
parse var cursor.0 c1 c2
call cursortype c1,c2
'CLS'
return 0

cursord:
if row.x<23 then do; row.x=row.x+1; call cursor row.x,col.x; return 0; end;
if line.x+20>=d.x.0 then return 0
line.x=line.x+1
call scrwrite 1,61,right('Lines' line.x'/'min(d.x.0,line.x+20) 'of' d.x.0,20),,,cp
call scrput 3,1,scrread(4,1,1600,'B'),'B'
l=line.x+20; i=23
call showline
return 0

cursorl:
if col.x=1|(row.x=2 & col.x=lprompt) then do; col.x=80; call cursoru; end
else do; col.x=col.x-1; call cursor row.x,col.x; end; return 0

cursorr:
if col.x=80 then do; if row.x=23 then col.x=lprompt; else col.x=1; call cursord; end
else do; col.x=col.x+1; call cursor row.x,col.x; end; return 0

cursoru:
if row.x=2 then do; row.x=23; call cursor row.x,col.x; return 0; end
if row.x>3 then do; row.x=row.x-1; call cursor row.x,col.x; return 0; end;
if line.x=1 then return 0
line.x=line.x-1
call scrwrite 1,61,right('Lines' line.x'/'min(d.x.0,line.x+20) 'of' d.x.0,20),,,cp
call scrput 4,1,scrread(3,1,1600,'B'),'B'
l=line.x; i=3
call showline
return 0

del:
if row.x=2 then l='command'; else l=line.x+row.x-3
if col.x=1 then d.x.l=substr(d.x.l,2); else d.x.l=strip(substr(d.x.l,1,col.x-1)substr(d.x.l,col.x+1),'T')
call del2; return 0

del2:
if row.x=2 then call scrwrite row.x,lprompt,substr(d.x.l,lprompt),80-lprompt+1,,ce
else do; d=charin(w2.x,l+(l-1)*llen,80); call scrwrite row.x,1,d,80,,ct
call scrwrite row.x,1,d.x.l,,,ce; end
return 0

end:
if row.x=2 then l='command'; else l=line.x+row.x-3
if col.x=1 then d.x.l=''; else d.x.l=substr(d.x.l,1,col.x-1)
call del2; return 0

enter:
call enter1; call enter2
if line.x>0 & ^lfnew then call enter3
if kd=27 then do; end=1; return 0; end
if lfnew then do; call lfnew; return 0; end
'PAUSE'; call enter4; return 0

enter1:
s.x.1=scrread(1,1,80,'B')
s.x.24=scrread(24,1,80,'B')
s.x.25=scrread(25,1,80,'B')
'CLS'; call charout w2.x
return 0

enter2:
l='command'; d=strip(d.x.l); d.x.l=''; call lastcmd0 d
if d^='' then do
   say dosdrive()':'doscd()'>'d; call execute;
   end
return 0

enter3:
parse arg command
if command^='' then do; if row.x=2 then return 0;
   l=line.x+row.x-3; if l>d.x.0 then return 0
   call linex; call linkin; return 0;
   end;
if pline.x=0 then return 0
l=f.x.0; do while l<99999; call linex; if lfnew then leave; l=f.x.l; end
return 0

enter4:
call scrput 1,1,s.x.1,'B'
call prom
if row.x=2 then col.x=lprompt; else col.x=1; call show row.x,col.x
call scrput 24,1,s.x.24,'B'
call scrput 25,1,s.x.25,'B'
return 0

entered:
l='command'; d=strip(d.x.l)
call lastcmd0 d
if d='' then return 0
d=translate(d)
if left(d,1)='&' then d=substr(d,2)
if datatype(d,'W') then do
   if left(d,1)<='-' then line.x=line.x+d; else line.x=d
   call shift
   end
else if d='TOP' then do; line.x=1;     call  shift; end
else if d='BOT' then do; line.x=d.x.0; call shift; end
else if left(d,1)='/' then call target
else do
   row.x=2; col.x=lprompt; call cursor row.x,col.x
   call scrwrite 2,47,'Error E1: Unknown editing command.',,,cx
   end
return 0

execute:
if kd=27 then do; queue d; return 0; end;
parse upper var d d1 d2
select
   when d1='LF' then do; lfnew=1; lfparms=d2; end
   otherwise interpret "'"d"'"
   end
return 0

f1: call enter1; 'LIST'  hp'LF.HLP'; call enter4; return 0

f2: call enter1; call enter3 'LIST'; call enter4; return 0

f3: call lfdel; return 0

f4: call enter1; call enter3 'KEDIT'; call enter4; return 0

f5: call sort '11 22'; return 0

f6: call sort '20 22 11 18'; return 0

f7: call sort 'D 24 32'; return 0

f8: call sort 'D 40 41 34 38 44 51'; return 0

f9: call refresh; return 0

f10: call lastcmd1; return 0

f12: call lastcmd1; return 0

lfdel:
call charout w2.x; call dosdel w2.x
call xdel; if xno=0 then do; end=1; return 0; end
parse var cursor.x c1 c2; call cursortype c1,c2; call enter4
call scrwrite 1,1,xword'/'xno,10,,cp; call cursor row.x,col.x; return 0

lfnew:
lfnew=0; cursor.x=cursortype(6,7); call xadd; call init d2; return 0

home:
row.x=2; col.x=lprompt; call cursor row.x,col.x; return 0

init:
arg parms
p=pos('/S',parms)
if p>0 then do
   fs.x=left(parms,p-1)
   opts.x='TR SORTA P SORTD D'
   end
else if pos('(',parms)>0 then parse var parms fs.x '(' opts.x
else do; fs.x=parms; opts.x='SORTD D'; end
y=parsefn(fs.x)
if y='' & fs.x^='' then do; say 'Invalid parms'; return 9; end
if y='' then do; fs.x='*.*'; y=parsefn(fs.x); end
parse var y drive.x path name ext .
if drive.x='-' then drive.x=dosdrive()
if path='-' then do;
   if doscd()='\' | drive.x^=dosdrive() then path='\'; else path=doscd()'\';
   end
if name='-' then do; name='*'; if ext='-' then ext='*'; end
if ext='-' then ext=' '
defpath.x=''
if pos('ENV',opts.x)>0 then fs.x=name'.'ext
else do
   fs.x=drive.x':'path||name'.'ext
   if pos('TR',opts.x)=0 then defpath.x=' 'drive.x':'path
   end

w1=''; do i=1 until w1^=''; if dosdir(wp'LF1.'i,,'HS')='' then w1=wp'LF1.'i; end
w2.x=''; do i=1 until w2.x^=''; if dosdir(wp'LF2.'i,,'HS')='' then w2.x=wp'LF2.'i; end
call lineout w1; call dosdel w1

'CLS'; call scrwrite 1,1,xword'/'xno,10,,cp
if refresh()>0 then do; call dosdel w1; return 9; end
call scrwrite 24,1,'F1-Help         F2-Browse       F3-Exit         F4-KEDIT        F5- Sort(Name)  ',,,cp
call scrwrite 25,1,'F6-Sort(ext)    F7-Sort(Size)   F8-Sort(Date)   F9-Refresh      F10-Recall      ',,,cp
return 0

ins:
if ins.x then do; ins.x=0; call cursortype 6,7; end
else do;          ins.x=1; call cursortype 3,7; end
return 0

lastcmd0:
parse arg lc
lcom1=lcom0
if lc=''|lc=lastcmd.lcom0 then return 0
lcom0=lcom0+1; if lcom0>lastmax then lcom0=1; lcom1=lcom0
lastcmd.lcom0=lc
return 0

lastcmd1:
call scrwrite 2,lprompt,lastcmd.lcom1,80-lprompt+1,,ce
l='command'; d.x.l=left(,lprompt-1)lastcmd.lcom1
lcom1=lcom1-1; if lcom1=0 then lcom1=lastmax; return 0

linex:
if d.x.l='' & command='' then return 0
if command^='' then d=command
else do; d=strip(d.x.l)
   if d='=' then d=prevcmd.x; if d='' | substr(d,1,1)='*' then return 0
   prevcmd.x=d; end
t=charin(w2.x,l+(l-1)*llen,llen); n=strip(substr(t,11,8))
e=strip(substr(t,20,3)); p=strip(substr(t,54,plen)); aa=p||n'.'e
if translate(d)='CX' then a=strip(substr(t,5,4)) aa; else a=aa
if translate(d,,sa||sn||se||sp||sl||sr)^=d then do
   d=' 'd
   do while pos(sa,d)>0; y=pos(sa,d); d=left(d,y-1)a||substr(d,y+1); end
   do while pos(sn,d)>0; y=pos(sn,d); d=left(d,y-1)n||substr(d,y+1); end
   do while pos(se,d)>0; y=pos(se,d); d=left(d,y-1)e||substr(d,y+1); end
   do while pos(sp,d)>0; y=pos(sp,d); d=left(d,y-1)p||substr(d,y+1); end
   do while pos(sl,d)>0; y=pos(sl,d); d=left(d,y-1)left(p,2)substr(d,y+1); end
   do while pos(sr,d)>0; y=pos(sr,d); d=left(d,y-1)substr(p,3)substr(d,y+1); end
   d=strip(d)
   end
else d=d a
if command='' then say dosdrive()':'doscd()'>'d
call execute
if command='' | d.x.l='' then do
   if dosdir(aa,,'HSD')='' then d.x.l='*missing'; else d.x.l='*'; end
return 0

linkclr:
if pline.x=0 then return 0
pline.x=0; i=f.x.0
do while i<99999; j=f.x.i; f.x.i=''; b.x.i=''; d.x.i=''; i=j; end;
return 0

linkin:
if l>d.x.0 then return 0
if pline.x=0 then do; f.x.0=99999; b.x.99999=0; end
j=pline.x; pline.x=l
if l>j then do while l>j; j=f.x.j; end;
else   do while l<=b.x.j; j=b.x.j; end;
if l=j then return 0
i=b.x.j; f.x.i=l; f.x.l=j; b.x.j=l; b.x.l=i; return 0

prom:
prompt=dosdrive()':'doscd()'>'; lprompt=length(prompt)+1
call scrwrite 2,1,prompt,80,,cp; return 0

pgup:   line.x=line.x-20; call show 3,1; return 0

pgdown: line.x=line.x+20; call show 3,1; return 0

refresh:
parse upper value parsefn(fs.x) with . . fn ft
if fn='ARCFILES' & ft='BF' then opts.x='TR SORTA P N E'
call scrwrite 1,11,'LF' fs.x '('opts.x,80,,cp
call charout w2.x; call dosdel w2.x
call linkclr
d.x.0=0; fileid=fs.x
if drive.x^='*' then call refresh2
else do i=65; d=d2c(i)
   if dosdisk('T',d)=-1 then do; if i>66 then leave; else iterate; end
   if defpath.x^='' then defpath.x=overlay(d,defpath.x,2)
   fileid=overlay(d,fs.x); call refresh2; end
ins.x=0; call cursortype 6,7; prevcmd.x=''
line.x=1; call prom; call show 3,1; return 0

refresh2:
call cursor 2,11
if fn='ARCFILES' & ft='BF' then do; call refresh2a; return 0; end;
'LISTFILE' fileid '(DATE' opts.x '>'w1
do l=d.x.0+1 while lines(w1)
   call charout w2.x,left(left(,10)linein(w1) defpath.x,llen),l+(l-1)*llen
   end
d.x.0=l-1; call lineout w1; call dosdel w1
return 0

refresh2a:
call lineout(fileid)
do l=d.x.0+1 while lines(fileid)
   d=linein(fileid)
   call charout w2.x,substr(d,42,10)left(d,43)substr(d,52,plen),l+(l-1)*llen
   end
d.x.0=l-1;
return 0

shift:
if left(lastcmd.lcom0,1)^='&' then do; call prom; d.x.l=''; end;
call show 2,lprompt; return 0

show:
arg row.x,col.x; i=2
if d.x.0=0 then line.x=0
else if line.x<1 then line.x=1; else if line.x>d.x.0 then line.x=d.x.0
call scrwrite 1,58,right('Lines' line.x'/'min(d.x.0,line.x+20) 'of' d.x.0,23),,,cp
if line.x>0 then do l=line.x to line.x+20
   i=i+1
   call showline
   end
call cursor row.x,col.x; return 0

showline:
d=charin(w2.x,l+(l-1)*llen,80)
call scrwrite i,1,d,80,,ct; call scrwrite i,1,d.x.l,,,ce
return 0

sort:
arg sortkeys
if kd>=-66 & kd<=-63 then sortkeys='A 54' llen sortkeys
call cursor 1,80
do l=1 to d.x.0
   call lineout w1,charin(w2.x,l+(l-1)*llen,llen)d.x.l
   end;
call lineout w1
queue '  sort *' sortkeys
queue '  file'
'KEDIT' w1 '(NOPROF NOSCREEN'
call linkclr
do l=1 to d.x.0
   d=linein(w1)
   call charout w2.x,left(d,llen),l+(l-1)*llen
   ld=length(d)
   if ld>llen then do; d.x.l=substr(d,llen+1,ld-llen); call linkin; end
   end;
call lineout w1; call dosdel w1
line.x=1; call show 3,1; return 0

swop:
if xno=1 then return 0
cursor.x=cursortype(); call enter1
if kd=-132 then do; xword=xword-1; if xword=0 then xword=xno; end
else do;            xword=xword+1; if xword>xno then xword=1; end
x=word(xlist,xword); 'CLS'
parse var cursor.x c1 c2; call cursortype c1,c2; call enter4
call scrwrite 1,1,xword'/'xno,10,,cp; call cursor row.x,col.x; return 0

tab:
col.x=1; call cursor row.x,col.x; call cursord; return 0;

tabup:
col.x=1; call cursor row.x,col.x; call cursoru; return 0;

target:
call cursor 1,80
call scrwrite 2,62,,19,,ce
d1=substr(d,2)
if row.x<3 then l1=line.x
else l1=line.x+row.x-2
do l=l1 to d.x.0 until pos(d1,d2)>0
   d2=charin(w2.x,l+(l-1)*llen,llen)
   end
if l>d.x.0 then do
   call scrwrite 2,70,' Wrapped.. ',,,cm
   do l=1 to l1-1 until pos(d1,d2)>0
      d2=charin(w2.x,l+(l-1)*llen,llen)
      end
   if l=l1 then do;
      call scrwrite 2,62,' Target not found. ',,,cm
      row.x=2; col.x=lprompt; call cursor row.x,col.x; return 0
      end
   end
l0=l
if l0>line.x+20 | l0<line.x then do
   line.x=l0; call show 3,1
   end
pos=1; row.x=l0-line.x+3; col.x=1; call cursor row.x,col.x
do forever
   pos=pos(d1,d2,pos)
   if pos=0 then leave
   call scrwrite row.x,pos,d1,,,cl
   pos=pos+length(d1)
   end
if left(lastcmd.lcom0,1)^='&' then do
   call scrwrite 2,lprompt,,70-lprompt,,ce; l='command'; d.x.l=''
   end
return 0

text:
if row.x=2 then l='command'; else do; l=line.x+row.x-3; call linkin; end;
if ins.x then do
   if col.x=1 then d.x.l=k||d.x.l;
   else d.x.l=substr(d.x.l,1,col.x-1)k||substr(d.x.l,col.x)
   call scrwrite row.x,1,d.x.l,,,ce
   if row.x=2 then call scrwrite 2,1,prompt,,,cp
   end
else do
   d.x.l=overlay(k,d.x.l,col.x); call scrwrite row.x,col.x,k,,,ce; end
call cursorr; return 0

xadd:
xnew=xnew+1; xt=''
do w=1 to xno; xt=xt word(xlist,w); if w=xword then xt=xt xnew; end
xlist=xt; xno=xno+1; xword=xword+1; x=xnew; return 0

xdel:
xt=''; do w=1 to xno; if w^=xword then xt=xt word(xlist,w); end
xlist=xt; xno=xno-1; xword=max(1,xword-1); x=word(xlist,xword); return 0
