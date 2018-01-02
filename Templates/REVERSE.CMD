/* REVERSE.CMD */
arg filein fileout .
call LINEIN filein,,0
do while lines(filein)
     text = linein(filein)
     call LINEOUT fileout,reverse(text)
end
call LINEOUT fileout
call LINEIN filein
