/* Load REXXUTIL */
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs

/* The basic call is listed next.                                          */
/* result = SysCreateObject(classname, title, location, setup)             */

Say 'Constructing a folder with all books'

classname='WPFolder'
title='BookShelf!'
location='<WP_DESKTOP>'
setup='OBJECTID=<WP_BOOKSHELF>;'
Call BldObj

classname = 'WPProgram'
location = '<WP_BOOKSHELF>'
base_setup='PROGTYPE=PM;EXENAME=\OS2\VIEW.EXE;'
/* Put bookshelf stuff */
BS = VALUE('BOOKSHELF',,'OS2ENVIRONMENT');
Say BS
Do While (BS <> "")
    Parse Var BS Path ";" BS
    If (Path <> "") Then Do
        Path = STRIP(Path)
        If (RIGHT(Path,1) <> "\") Then
            Path = Path || "\"
        PrevQ = Queued()
        "DIR "Path"*.INF /F | RXQUEUE"
        NowQ = Queued()
        Do i = NowQ to PrevQ+1 by -1
            Parse Pull file .
            start = LASTPOS("\", file) + 1
            last = LASTPOS(".", file) - 1
            len = last - start + 1
            title = TRANSLATE(SUBSTR(file, start, len))
            setup = base_setup || "PARAMETERS="title";"
            Call BldObj
        End /* do */
 
    End  /* Do */
End /* do */

Exit

/* Build Object */
BldObj:
call charout ,'Building: 'title

result = SysCreateObject(classname, title, location, setup)

If result=1 Then call charout ,'...   Object created!'
Else             call charout ,'...   Not created! Return code='result

Say '';
Return
