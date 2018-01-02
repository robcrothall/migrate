/* OPBYEBYE.CMD */
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs

objectid = '<TEST2_FOLDER>'
call SysDestroyObject objectid
