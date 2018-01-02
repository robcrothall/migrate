/* Call the current MIPROFx.CMD file */
trace r;
'SET MIPROF17=MI_INT';
arg Parms;
'cd \miprod';
call '\cmd\miprof17.cmd' Parms;
start epm.exe '\mi\soap$$jo.doc';
