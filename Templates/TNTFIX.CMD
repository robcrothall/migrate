/* TNTFIX.CMD -- An OS/2 Rexx program (Bill Hinkle [75300,2050] */
/* Fix OS2TNT.DOC so that it paginates evenly to 66 lines/page */
/* Run from OS/2 cmd line in directory of OS2TNT.DOC, creates OS2TNT.TXT */
infile = 'OS2TNT.DOC';
outfile = 'OS2TNT.TXT';
linecount = 0;
lineskip = 0;
DO WHILE LINES(infile) > 0;
 chkline = LINEIN(infile);
 linecount = linecount + 1;
 IF (POS('_',chkline) > 0) & (VERIFY(chkline,' _') = 0)
 THEN lineskip = lineskip + 1;
 ELSE fu = LINEOUT(outfile,chkline);
 fu = CHAROUT(,linecount||' lines with '||lineskip||' skipped.'||D2C(13));
END;
BEEP(1000,1);
SAY ;
SAY 'Done! ' outfile ' created.';
