/* Call the current MIPROFx.CMD file */
trace r;
arg Parms;
'cd \miprod';
call '\cmd\miprof15.cmd' Parms;
'start epm.exe c:\mi\soap$$jo.doc';
