/**
17-Apr-93	Brust	first edit

@	Search.CMD

Function:	sucht Text in mehreren ASCII-Dateien

Aufruf von :	OS/2 Prompt

Parameter:	"Suchstring" Filenamen
**/

parse arg string files sub
parse source creater
vernam="OS/2"
versys=SysOS2Ver()
datum=date()
zeit=time()
matchnr=0
linenr=0
call INIT

say word(creater,3)' at 'datum' 'zeit' under 'vernam' 'versys
if files='' then files='*.*'

if string='' then signal usage

say yellow'searching for'red string normal'in'red files normal

if (sub='/S'  | sub='/s') then
				do
					call SysFileTree files, 'file', 'FS'
					dump=sysfiletree('*','dirnr','DS')
					say 'subdirectories are included'
				end
			else
				do
					call SysFileTree files, 'file', 'F'
					dump=sysfiletree('*','dirnr','D')
				end
if file.0 = 0 then 
		do
			say yellow'no files matching'red files yellow'found'normal
			exit
		end
do i=1 to file.0
datei=word(file.i,5)
/** say cyan'searching in'red datei normal **/
drop found.
call SysFileSearch string,datei,'found.','N'
if found.0 = 0 then
		do
			/** say yellow'no lines found matching'red string yellow'in'red datei normal  **/
		end
	else
		do
			say
			say cyan'file 'datei' matched: 'normal
			do t=1 to found.0
					say found.t
					linenr = linenr +1
			end	
			matchnr = matchnr +1
		end

end
say
say 'a total of 'file.0' files and 'dirnr.0' directories are searched'
if matchnr=0 then say 'no file matched'
if matchnr=1 then say matchnr' file matched'
if matchnr>1 then say matchnr' files matched'
if linenr=0 then say 'no lines matched'
if linenr=1 then say linenr' lines matched'
if linenr>1 then say linenr' lines matched'


drop i file found t 
exit

USAGE:
say 'Usage: 'yellow word(creater,3)' string [filenames [/S]]'normal
say 'if no filename is given, *.* is assumed'
say 'use /S to include sub-directories'
say red'Note:'normal'textsearch is case sensitive'

exit

INIT:
esc    = '1B'x          /* define ESCape character */
red    = esc||"[31m"    /* ANSI.SYS-control for red foreground */
yellow = esc||"[33m"    /* ANSI.SYS-control for yellow foreground */
cyan   = esc||"[36m"    /* ANSI.SYS-control for cyan foreground */
normal = esc||"[0m"     /* ANSI.SYS-control for resetting attributes to normal */
RETURN