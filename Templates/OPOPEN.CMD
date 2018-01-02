/* OPOPEN.CMD */
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs
objectid = '<TEST2_SYSLVIO>'
call SysSetObjectData objectid, 'OPEN=DEFAULT;'
