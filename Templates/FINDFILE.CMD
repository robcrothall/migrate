/* FINDFILE.CMD - REXX to find requested file by mask */
/* ================================================================== */
/* Syntax:  see syntax at end of program.                             */
/* Function:  given a filespec mask, optional drive list, FINDFILE    */
/* uses REXX SysFileTree to construct a list of file names matching   */
/* the given filespec mask (which has usual DOS wild cards).  The     */
/* output is then passed to the OS/2 Editor for access, or the user   */
/* can request browse of the output using the BROWSE keyword.         */
/* ================================================================== */
/* This program is written in REXX for OS/2 2.0 You can make this a   */
/* desktop program object by "create another" program object and      */
/* specifying "PMREXX.EXE" as the program name and the name of this   */
/* REXX file:  FINDFILE.CMD as the parameter, giving the full path    */
/* name:  C:\$CMD\FINDFILE.CMD   for example.  This program is in the */
/* Public Domain.  Written by Bruce E. Hogman, Sr. Systems Engineer,  */
/* EDS Corp., for US DOE/EIA, Washington DC, 1992.                    */
/*                                                                    */
/*            ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿             */
/*            ³ Author:  Bruce E. H”gman  BIX:  bhogman ³             */
/*            ³ NaSpa:  HogmBru3  CompuServ: 72050,1327 ³             */
/*            ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ             */
/*                                                                    */
/* ================================================================== */
'@echo off'
/* Load RexxUtils at startup */
call RxFuncAdd 'SysLoadFuncs','RexxUtil','SysLoadFuncs'
call SysLoadFuncs
environ=address()
do forever
say ' '
dphrase=""
say 'Enter search values -or- null reply to END -or- ? for help'
parse pull filespec drvstr opts
cwd=directory()
if '\'\=substr(cwd,length(cwd),1) then cwd=cwd||'\'
editfile=cwd||'FINDFILE.TXT'
if filespec="" then exit
if filespec="?" then do
   call syntax; iterate;
end;
browse=0
browse=pos("BRO",TRANSLATE(opts))
if browse>0 then do
   editfile=""
end
rmt= pos("RE",TRANSLATE(opts)) | pos("RM",TRANSLATE(opts))
rmtstr="LOCAL"
rphrase="(LOCAL drives only)"
if rmt>0 then do
   rmtstr="USED"
   rphrase="(REMOTE drives also)"
end
if browse<1 then do
   irc=SysFileDelete(editfile)
   isc=stream(editfile,'c','open write')
   if isc\='READY:' then do
      utxt="Can't open" editfile "for output.  Continue in BROWSE mode?"
      utitl="Error opening output file."
      if environ='PMREXX' then do
         uact=RxMessageBox(utxt,utitl,'OKCANCEL','ERROR')
      end
      else do
         say utitl utxt
         parse pull rply
         if 'Y'=translate(substr(rply,1,1)) then uact=1
         else uact=2
      end
      if uact>1 then exit
      editfile=""
      browse=1
   end
end
if drvstr = '*' | drvstr="" then do
   drvmap=SysDriveMap('A:',rmtstr)
   dphrase="ALL by default"
end
else do
   dphrase="as specified"
   drvmap=""
   do i=1 to length(drvstr);
      drvmap=drvmap||substr(drvstr,i,1)||": "
   end
end
idrv=1
ioc=LINEOUT(editfile,"Drives to search =" drvmap)
ioc=lineout(editfile,"   " dphrase rphrase)
do while idrv<length(drvmap)
   xdrv=substr(drvmap,idrv,2)
   ifo=""
   ifo=sysdriveinfo(xdrv);
   if ifo\="" then do
      isc=lineout(editfile," ")
      irc=SysFileTree(xdrv||"\"||filespec,fstr,BSO)
      isc=lineout(editfile,"Drive: " xdrv " found" fstr.0 'files using "'||filespec||'"')
      do i=1 to fstr.0
         isc=LINEOUT(editfile,fstr.i)
      end
   end
   else do
      isc=LINEOUT(editfile,"Drive: " xdrv "is NOT READY - bypassed.")
   end
   fstr.0=0
   idrv=idrv+3
end
if browse=0 then do
   isc=stream(editfile,'c','close')
   'e' editfile
end
end /* do forever */
syntax: procedure;
   say ' '
   say 'Syntax of FINDFILE:'
   say ' '
   say 'FINDFILE file_spec_mask [drv_letters] [options]'
   say ' '
   say '   file_spec_mask  like:  f*.exe '
   say ' '
   say 'Optional parameters:'
   say ' '
   say '   drv_letters     like:  cdefgh  or * for all local drives'
   say ' '
   say '   options:  REMOTE       for remote drives - use only with * for drives'
   say '             BROWSE       to browse the output.  Default is to invoke '
   say '                          the OS/2 Editor to view the list.'
   say ' '
   say 'Default operation, if only the file_spec is given, is to search'
   say 'all LOCAL drives, all subdirectories, and display the list of files.'
   say 'Use * for drives to search all local and remote drives.'
   say ' '
   say 'Examples:'
   say ' '
   say '   findfile f*.exe cdef'
   say '   findfile *.inf * remote'
   say '   findfile d:\*.wp '
   RETURN
