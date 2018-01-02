/*   */
count = 1;
linecnt = 0;
arg argopts;
parse var argopts infile .;
outfil = infile || '.';
i = pos('.',outfil);
outfil = substr(outfil,1,i);
do while(lines(infile) > 0);
   line = linein(infile);
   myrc = lineout(outfil,line);
   if pos('#',line) > 0 then do;
      linecnt = linecnt + 1;
      if linecnt > 999 then do;
         linecnt = 0;
         say 'File ' outfil 'has been written';
         count = count + 1;
      end  /* Do */
   end  /* Do */
end /* do */
