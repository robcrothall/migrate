/* MOVIT.CMD */
arg fileid subdir .
'copy' fileid subdir
if rc = 0 then 'del' fileid
