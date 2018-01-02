/* RXMSG.CMD - A fragment to verify replacement of file */
call RxFuncAdd 'SysLoadFuncs', RexxUtil , 'SysLoadFuncs'
call SysLoadFuncs

do
     reply = RxMessageBox("Do you want to replace the file", ,
               "Replace File?", "YesNo", "Question")
     if reply = 7 then return
end
