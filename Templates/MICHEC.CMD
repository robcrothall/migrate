/* Call the current MIChecxx.CMD file */
'SET MI_SITE=MI_INT';
arg Parms;
Say 'Parms:' Parms;
call 'michec05.cmd' Parms;
