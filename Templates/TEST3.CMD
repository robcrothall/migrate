/*  */
trace r;
action = value(TEST3,,'OS2ENVIRONMENT');
say action;
'SET TEST3=DONE';
pull nul;
if action \= 'DONE' then 'dir \*.*';
