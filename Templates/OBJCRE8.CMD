 

 /* FOLDER.CMD: Sample code using REXXUTIL's SysCreateObject function    */
 /* Builds a folder on the DeskTop and places some program objects in it.*/
 /* Mike Lamb: MIKELAMB/KGNVMC                                           */
 /* Load REXXUTIL */
 call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
 call sysloadfuncs
 
 /*The basic call is listed next.                                           */
 /*rc=SysCreateObject(classname, title, location <,setup>, <,duplicateflag>)*/
 
 call SysCls
 Say '';Say 'Using REXXUTILs to Add a Folder and Program Objects...'
 
 Say '';Say 'Press Y to add Test Folder to Desktop...';Say '';
 parse upper value SysGetKey('NOECHO') with key
 If key<>'Y' Then Exit
 
 /* All of the routines pass parameters to a subroutine to perform the call */
 classname='WPFolder'
 title='Test Folder'
 location='<WP_DESKTOP>'
 setup='OBJECTID=<TEST_FOLDER>'
 Call BldObj
 
 Say '';Say 'Now go and open up the folder, currently no items are there.'
 Say 'Press ENTER and we will add a few program objects...'
 key=SysGetKey()
 
 Say 'Place a program object into the folder...';Say '';
 classname='WPProgram'
 title='SYSLEVEL-FULLSCR'
 location='<TEST_FOLDER>'
 setup='OBJECTID=<TEST_SYSL>;'||,
       'EXENAME=\OS2\SYSLEVEL.EXE;'||,
       'PROGTYPE=FULLSCREEN;'
 Call BldObj
 
 classname='WPProgram'
 title='CHKDSK-PM'
 location='<TEST_FOLDER>'
 setup='OBJECTID=<TEST_PMCK>;'||,
       'EXENAME=\OS2\PMCHKDSK.EXE;'||,
       'MINIMIZED=YES;'||,
       'PROGTYPE=PM;'
 Call BldObj
 
 classname='WPProgram'
 title='SYSLEVEL-VIO'
 location='<TEST_FOLDER>'
 setup='OBJECTID=<TEST_SYSLVIO>;'||,
       'EXENAME=\OS2\SYSLEVEL.EXE;'||,
       'PROGTYPE=WINDOWABLEVIO;'
 Call BldObj
 
 classname='WPProgram'
 title='MEM-Fullscreen'
 location='<TEST_FOLDER>'
 setup='OBJECTID=<TEST_MEMFUL>;'||,
       'EXENAME=\OS2\MDOS\MEM.EXE;'||,
       'PROGTYPE=VDM;'||,
       'PARAMETERS=/?;'||,
       'NOAUTOCLOSE=YES;'
 Call BldObj
 
 classname='WPProgram'
 title='MEM-WindowVDM'
 location='<TEST_FOLDER>'
 setup='OBJECTID=<TEST_MEMWIN>;'||,
       'EXENAME=\OS2\MDOS\MEM.EXE;'||,
       'PROGTYPE=WINDOWEDVDM;'||,
       'PARAMETERS=/?;'||,
       'NOAUTOCLOSE=YES;'
 Call BldObj
 Say '';Say 'All done, to remove objects drag to shredder...'
 
 Exit
 
 /* Build Object */
 BldObj:
 call charout ,'Building: 'title
 
 /* Build object using REPLACE as duplicateflag */
 result = SysCreateObject(classname, title, location, setup, 'R')
 
 If result=1 Then call charout ,'...   Object created!'
 Else             call charout ,'...   Not created! Return code='result
 
 Say '';
 Return
 

 

 /* SHADOW.CMD: Sample code using REXXUTIL's SysCreateObject function    */
 /* Builds shadows on the DeskTop and Startup Folder                     */
 /* Mike Lamb: MIKELAMB/KGNVMC                                           */
 /* Load REXXUTIL */
 call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
 call sysloadfuncs
 
 Call SysCls
 Say '';Say 'Using REXXUTILs to Add Shadow Objects...'
 
 /* The titles and objectid's are found from the \OS2\INI.RC file */
 
 Say '';Say 'First lets place some items on the Desktop...'
 title='Enhanced Editor'; objid='<WP_EPM>'   ; loc='<WP_DESKTOP>'; call AddShad
 title='OS/2 Window'    ; objid='<WP_OS2WIN>'; loc='<WP_DESKTOP>'; call AddShad
 title='System Clock'   ; objid='<WP_CLOCK>' ; loc='<WP_DESKTOP>'; call AddShad
 
 Say '';Say 'You can even make shadow objects of files...'
 title='CONFIG.SYS'; objid='C:\CONFIG.SYS' ; loc='<WP_DESKTOP>'; call AddShad
 
 Say '';Say 'Now lets place an item in the Startup Folder...'
 title='System Clock'   ; objid='<WP_CLOCK>' ; loc='<WP_START>'  ; call AddShad
 
 Say '';Say 'All done, to remove objects drag to shredder...'
 
 Exit
 
 AddShad:
 Say '';Say 'Press Y to add shadow object: 'title' to 'loc
 parse upper value SysGetKey('NOECHO') with key
 If key='Y' Then Do
 
    /* Build object using FAIL as duplicateflag */
    result=SysCreateObject('WPShadow', title, loc, 'SHADOWID='objid, 'F')
 
    If result=1 Then Say 'Object created'
    Else             Say 'Not created, return code='result
 End
 Return
 

 

 /* FLDSHAD.CMD: Sample code using REXXUTIL's SysCreateObject function   */
 /* Builds a folder on the DeskTop places a program object in it then    */
 /* places a shadow of the program object on the DeskTop.                */
 /* Mike Lamb: MIKELAMB/KGNVMC                                           */
 /* Load REXXUTIL */
 call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
 call sysloadfuncs
 
 /*The basic call is listed next.                                           */
 /*rc=SysCreateObject(classname, title, location <,setup>, <,duplicateflag>)*/
 
 call SysCls
 Say '';Say 'Using REXXUTILs to Add Folder/Program/Shadow Objects...'
 
 Say '';Say 'Press Y to add Test Folder to Desktop...';Say '';
 parse upper value SysGetKey('NOECHO') with key
 If key<>'Y' Then Exit
 
 classname='WPFolder'
 title='Test Folder'
 location='<WP_DESKTOP>'
 setup='OBJECTID=<TEST2_FOLDER>'
 Call BldObj
 
 Say '';Say 'Press Y to place a program object into the folder...';Say '';
 parse upper value SysGetKey('NOECHO') with key
 If key<>'Y' Then Exit
 
 classname='WPProgram'
 title='SYSLEVEL-VIO'
 location='<TEST2_FOLDER>'
 setup='OBJECTID=<TEST2_SYSLVIO>;'||,
       'EXENAME=\OS2\SYSLEVEL.EXE;'||,
       'PROGTYPE=WINDOWABLEVIO;'
 Call BldObj
 
 Say '';
 Say 'Press Y to place a shadow of the program object on the Desktop...';
 Say '';
 parse upper value SysGetKey('NOECHO') with key
 If key<>'Y' Then Exit
 
 classname='WPShadow'
 title='SYSLEVEL-VIO'
 location='<WP_DESKTOP>'
 setup='SHADOWID=<TEST2_SYSLVIO>'
 Call BldObj
 
 Say '';Say 'All done, to remove objects drag to shredder...'
 
 Exit
 
 /* Build Object */
 BldObj:
 call charout ,'Building: 'title
 
 /* Build object using REPLACE as duplicateflag */
 result = SysCreateObject(classname, title, location, setup, 'R')
 
 If result=1 Then call charout ,'...   Object created!'
 Else             call charout ,'...   Not created! Return code='result
 
 Say '';
 Return
 

 

 /* STARTDOS.CMD: Sample code using REXXUTIL's SysCreateObject function  */
 /* Starts a DOS program using specific DOS VDM settings.  This is       */
 /* particularly useful for LAN execution that requires NET USE commands.*/
 /* The example invokes the PKZIP.EXE program using files setting of 45  */
 /* Rick McGuire:  MCGUIRE/GDLVM7                                        */
 /* Load REXXUTIL */
 call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
 call sysloadfuncs
 
 /* The basic call is listed next.                                          */
 /* result = SysCreateObject(classname, title, location, setup)             */
 
 classname='WPProgram'
 title='My DOS Program'
 location='<WP_NOWHERE>'                  /* place in invisible folder      */
 program='EXENAME=C:\PKZIP.EXE;'          /* DOS program name               */
 type='PROGTYPE=WINDOWEDVDM;'             /* type of DOS session (windowed) */
 startup='STARTUPDIR=C:\;'                /* startup directory              */
 settings='SET DOS_FILES=45;'             /* required DOS settings          */
 open='OPEN=DEFAULT;'                     /* open now                       */
 
 call SysCreateObject classname, title, location,,
     program||type||startup||settings||open, 'REPLACE'
 Return
 

 

 /* REBUILD.CMD: Sample code using REXXUTIL's SysCreateObject function   */
 /* Can be used to rebuild objects created during the installation of    */
 /* your OS/2 system. The \OS2\INSTALL\INI.RC file contains information  */
 /* that can be used by the SysCreateObject function.                    */
 /* The INI.RC file is used by MAKEINI.EXE to create your OS2.INI file   */
 /* Syntax:  Enter  "REBUILD ?" for complete syntax                      */
 /* Mike Lamb: MIKELAMB/KGNVMC                                           */
 '@ECHO OFF'
 /* Load REXXUTIL */
 call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
 call sysloadfuncs
 
 Arg parms
 cmdparms=parms /* Save command line parms for later processing */
 
 /* Until REXXUTIL offers a function call to retrieve the OS2 boot drive   */
 /* we assume the environment variable COMSPEC has location of boot drive. */
 BtDrv=filespec('drive',value('COMSPEC',,'OS2ENVIRONMENT'))
 
 parse upper var cmdparms type '(' inifile .
 /* If user does not enter location of *.RC file then try to find it */
 If inifile='' Then inifile=BtDrv||'\OS2\INI.RC'
 rcx=stream(inifile,'C','Q EXISTS')
 If rcx='' Then Do
    Say '';Say '';Say inifile 'not found'
    Return
 End
 type=left(type,1)
 If verify(type,'FPOA') Then Signal Helper
 
 /* Initialize tables and table counters */
 iniftab.=''; iniptab.='' iniotab.=''; /*Folders, Programs, Others */
 iniflns=0;   iniplns=0;  iniolns=0;
 initab.='';  inilns=0;
 Call stream inifile,'C','CLOSE'
 Do while lines(inifile)>0  /* Read RC file into tables */
    lne=linein(inifile)
    parse var lne '"PM_InstallObject"' lne
    If lne\='' Then Do
       parse var lne '"'rest1'" 'lne
       parse var lne '"'setup'"'
       parse var rest1 title';'object';'location
       If object='WPFolder' Then Do
          iniflns=iniflns+1
          iniftab.1.iniflns=object;   iniftab.2.iniflns=title;
          iniftab.3.iniflns=location; iniftab.4.iniflns=setup;
       End
       Else If object='WPProgram' Then Do
          iniplns=iniplns+1
          iniptab.1.iniplns=object;   iniptab.2.iniplns=title;
          iniptab.3.iniplns=location; iniptab.4.iniplns=setup;
       End
       Else Do
          iniolns=iniolns+1
          iniotab.1.iniolns=object;   iniotab.2.iniolns=title;
          iniotab.3.iniolns=location; iniotab.4.iniolns=setup;
       End
    End
 End
 Call stream inifile,'C','CLOSE'
 
 /* Calculation for screen loop */
 parse value SysTextScreenSize() with row col
 scrsz=row-12
 
 If type='F' | type='A' Then Do; /* Folder routine */
    objt='Folder'; inilns=iniflns;
    Do i=1 to inilns; Do j=1 to 4;
       initab.j.i=iniftab.j.i
    End; End;
    Call DispSel
 End;
 If type='P' | type='A' Then Do; /* Program routine */
    objt='Program'; inilns=iniplns;
    Do i=1 to inilns; Do j=1 to 4;
       initab.j.i=iniptab.j.i
    End; End;
    Call DispSel
 End;
 If type='O' | type='A' Then Do; /* Other routine */
    objt='Other'; inilns=iniolns;
    Do i=1 to inilns; Do j=1 to 4;
       initab.j.i=iniotab.j.i
    End; End;
    Call DispSel
 End;
 Return; /* When get here done with processing */
 
 /* Routine to display objects and allow selection */
 DispSel:
 key=''
 Do while key\='Q'
    Call SysCls; Say '';Say objt' objects found in: 'inifile;Say '';
    Do i=1 to inilns
       If trunc(i/scrsz)==i/scrsz Then Call Promptx 1
       If key='Q' Then leave
       n=right('  '||i,3)||') '||left(initab.2.i||copies(' ',30),30)
       n=n||left(initab.3.i||copies(' ',20),20)
       Say n
    End
    If key\='Q' Then Call Promptx 0
 End
 Return
 
 /* Screen loop routine also calls object build routine */
 Promptx: Arg scr
 Say '';Say 'To attempt to rebuild an object enter the number of the object'
 If scr=0 Then Say 'or enter Q to quit...'
 Else Say 'or press enter to show next screen...  Or enter Q to Quit...'
 pull key .
 If (key>=1) & (key <=inilns) then,
     rcx=BldIt(initab.1.key,initab.2.key,initab.3.key,initab.4.key)
 If scr=1 Then Do;
    Call SysCls;Say '';Say objt' objects found in: 'inifile;Say '';
 End;
 Return
 
 /* Routine to build object */
 BldIt: Parse Arg object,title,location,setup
 If object='WPFolder' Then Do
    call SysCls
    Say '';Say '';
    Say 'WARNING: Any attempt to rebuild a folder object will first'
    Say '         delete each and every object in that folder!!!!'
    Say ''
    Say 'If you really do want to rebuild: 'title
    Say 'Press Y, any other key will not rebuild.'
    parse upper value SysGetKey('NOECHO') with key
    If key<>'Y' Then Return ''
 End
 Say 'SysCreateObject('object', 'title', 'location', 'setup', R)'
 /* Build object using REPLACE as duplicateflag */
 result = SysCreateObject(object, title, location, setup, 'R')
 If result=1 Then Say '...   Object created!'
 Else             Say '...   Not created! Return code='result
 Say '';Say 'Press ENTER to continue...'
 Pull ans
 Return result
 
 /* Syntax help */
 Helper:
 call SysCls
 Say '';Say ''; Say 'REBUILD:'
 Say 'Routine to rebuild system installed objects listed in *.RC files.'
 Say 'Can be used as an alternative to using the MAKEINI command.'
 Say 'Your INI.RC file is used by MAKEINI.EXE during installation to'
 Say 'create your OS2.INI file.'
 Say '';
 Say 'Any attempt to rebuild an object first deletes any object that'
 Say 'is using that same <objectid>. This can be useful if you want to'
 Say 'restore an object back to its original installed state. This can'
 Say 'also be bad since if you rebuild a folder it first deletes all'
 Say 'objects in it since that is its initial install state.'
 Say ''; Say 'Syntax:';Say '';
 Say 'REBUILD object [(filespec]'
 Say '';Say 'Valid objects A(ll), F(olders), P(rograms), O(ther)'
 Say 'Can also can use (filespec for name of *.RC file, default is \OS2\INI.RC'
 Exit
 

 

 /* OBJECTID.CMD: Sample code using REXXUTIL's SysIni function.          */
 /* Routine will display the OBJECTIDs known to the WorkPlace Shell      */
 /* Mike Lamb: MIKELAMB/KGNVMC                                           */
 '@ECHO OFF'
 /* Load REXXUTIL */
 call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
 call sysloadfuncs
 
 /* List ObjectIds */
 App='PM_Workplace:Location'
 call SysIni 'USER', App, 'All:', 'Keys'
 if Result \= 'ERROR:' then do
    Call SysCls
    Say '';Say '';Say 'Listing ObjectId information';Say '';
    parse value SysTextScreenSize() with row col
    j=row-10
    Do i=1 to Keys.0
       If trunc(i/j)==i/j Then Do
          Say '';Say 'Press any key to show next screen...'
          key=SysGetKey()
          Call SysCls
          Say '';Say '';Say 'Listing ObjectId information';Say '';
       End
       Say Keys.i
    End
 End
 Else Say 'Error querying for' App
 Return
 

 

 /* ICONRES.CMD: Sample code using REXXUTIL's SysCreateObject function   */
 /* Routine will create a folder containing many icons available in      */
 /* installed DLLs on an OS/2 V2 system. Shows how to use the setup      */
 /* string parm: ICONRESOURCE                                            */
 /* Mike Lamb: MIKELAMB/KGNVMC                                           */
 '@ECHO OFF'
 /* Load REXXUTIL */
 call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
 call sysloadfuncs
 
 call SysCls
 Say '';
 Say 'Using REXXUTILs to demonstrate use of the ICONRESOURCE parameter.'
 Say 'A folder will be created and populated with various icons found'
 Say 'in some installed DLL files.'
 Say '';
 Say 'ICONRESOURCE is a SysCreateObject setup string parameter, has syntax:'
 Say '';
 Say '  ICONRESOURCE=id module       Ex:  ICONRESOURCE=3 PMWP;'
 Say '  id=number of the icon resource, module=filename of the DLL'
 Say ''; Say 'NOTE: Over 70 icons, program will run for a minute or two.'
 Say '      After program ends the WPS will continue to resolve objects, also'
 Say '      the building of the objects adds approx 100K to your OS2.INI.'
 Say '';Say 'Press Y to add the folder to Desktop and populate...';Say '';
 parse upper value SysGetKey('NOECHO') with key
 If key<>'Y' Then Exit
 
 /* Build folder for icons */
 call charout ,'Building: ICONRESOURCE Icon Folder'
 result = SysCreateObject('WPFolder', 'ICONRESOURCE^Icon Folder',,
         '<WP_DESKTOP>', 'OBJECTID=<ICN_FOLDER>;', 'R')
 If result=1 Then call charout ,'...   Object created!'
 Else             call charout ,'...   Not created! Return code='result
 Say '';
 classname='WPAbstract'
 location='<ICN_FOLDER>'
 /* WPCONFIG 1-13 WPPRTMRI 3-16 19-23 */
 fn='PMWP'
 Do i=1 to 75
    If i<5 | i=13 | (i>15 & i<21) | i=22 | (i>23 & i<30) | i=32 | i=33,
     | i=44 | i=46 | i=48 | i=52 | i=53 | (i>55 & i<73) Then Call BldObj
 End
 fn='WPCONFIG'
 Do i=1 to 13
    Call BldObj
 End
 fn='WPPRTMRI'
 Do i=3 to 23
    If (i<17 | i>18) Then Call BldObj
 End
 Say '';Say 'All done, to remove drag folder to shredder...'
 Exit
 
 /* Build Object */
 BldObj:
 if i<10 then j='0'||i
 else j=i
 title=fn'-'||j
 setup='ICONRESOURCE='||j||' 'fn';OBJECTID=<ICN-'fn'-'||j||'>'
 call charout ,'Building: 'title
 result = SysCreateObject(classname, title, location, setup, 'R')
 If result=1 Then call charout ,'...   Object created!'
 Else             call charout ,'...   Not created! Return code='result
 Say '';
 Return
 

