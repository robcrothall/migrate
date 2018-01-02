/* Rexx -------------------------------------------------------- *
 * Name:      SPACE.CMD                                          *
 *                                                               *
 * Function:  To add up the disk space used by all files in a    *
 *            given directory.                                   *
 *            Works in both OS/2 1.3 and 2.0. Accepts HPFS       *
 *            directory names.  If /s is specified as a parameter*
 *            this program will recurse into subdiretories.      *
 *                                                               *
 * Syntax:    SPACE <directory> [/s]                             *
 *                                                               *
 * Author:    Jose Xavier                                        *
 *            Compuserve: 71213,1142                             *
 *                                                               *
 * History:                                                      *
 *                                                               *
 * ------------------------------------------------------------- */


arg dir rsw

/* If only subdirectory switch */ 

if dir = '/s' | dir = '/S' then do
   rsw = '/S'
   dir = ''
end

if dir = '-s' | dir = '-S' then do
   rsw = '/S'
   dir = ''
end

if dir = '/?' | dir = '-?' then do
   rsw = '/?'
   dir = ''
end

if rsw = '/?' then do
   rc = usage()
   return 0
end

/* if no directory name assume current directory */

if dir = '' then
   dir = directory()

/* Create temporary queue for storing directory names */

rc  = RxQueue('Delete','DIRQ')
rc  = RxQueue('Create','DIRQ')
old = RxQueue('Set','DIRQ')

say ' '
say '        ******* SPACE USAGE FOR 'dir' ********'
say ' '

if substr(dir,length(dir),1) = '\' then
   dir = substr(dir,1,length(dir)-1)

size. = 0
name. = ' '
lev = 0
plev = 0
push dir
push lev

do while (queued() \=0)
   parse pull lev
   parse pull dirt
   if plev > 1 & lev < plev then do
      ind = plev - 1
      do while ind >= lev
         fomo = conv(size.ind)
         say substr('-------------- 'name.ind,1,60),
         right(fomo,10)
         ind = ind - 1
      end
   end
   if lev \= plev then
      plev = lev
   name.lev = dirt
   dsize   = 0
   difil   = dirt
   /* add up the sizes of all files in directory dirt */
   call add_up
   size.lev = dsize
   fomo = conv(dsize)
   say substr(difil,1,40) right(fomo,10)
   if lev \= 0 then do
      ind = lev - 1
      do while ind >= 0
         size.ind = size.ind + dsize
         ind = ind - 1
      end
   end
end

/* remove the temporary file */
'@del c:\dirf 1>nul 2>nul'

if lev > 0 then do
   lev = lev - 1
   do while lev >= 0
      fomo = conv(size.lev)
      say substr('-------------- 'name.lev,1,60),
      right(fomo,10)
      lev = lev - 1
   end
end

rc  = RxQueue('Set',old)
rc  = RxQueue('Delete','DIRQ')

return

add_up:
dtemp   = 'c:\dirf'
'@dir "'dirt'" > 'dtemp
do while lines(dtemp) > 0
   dline = linein(dtemp)
   push dline
   parse pull date time size nod file
   if time \= 'File(s)' then
      if datatype(size) = 'NUM' then
         dsize   = dsize   + size
      else do
         if size = '<DIR>' then
            if rsw = '/S' then do
               file = strip(file)
               if file \= '.' & file \= '..' then do
                  file=dirt'\'file
                  push file
                  push lev+1
               end
            end
      end
end
rc = lineout(dtemp)
'@del 'dtemp
return

conv: procedure
arg numb
   len = length(numb)
   lop = len % 3
   do lop
      if (len > lop*3) then do
         numb = insert(',',numb,len-lop*3)
         len   = len + 1
      end
      lop = lop - 1
   end
return(numb)

usage: procedure

say ' '
say 'SYNTAX: SPACE [directory] [options]'
say ' '
say '        If directory is not passed, current directory will be used.'
say ' '
say 'Options: /s or -s to report space usage of subdirectories'
say '         /? or -? help'
return (0)
