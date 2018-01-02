/* Call the current MIPROFx.CMD file */
trace r;
arg Parms;
'cd \miprod2';
call '\cmd\miprof15.cmd' Parms;
