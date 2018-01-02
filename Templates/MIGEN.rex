/* Call the current MIGenxx.CMD file */
'SET MI_SITE=MI_INT';
arg Parms;
Say 'Parms:' Parms;

call 'migen06.cmd' Parms;
