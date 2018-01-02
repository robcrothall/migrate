/****************************************************************************/
/* REXX program to rebuild IBM Works Desktop - Zhitao Zeng 06/14/94         */
/****************************************************************************/
Parse Arg fpwpath fpwlan calledfromSI .
Trace 'O'
Address CMD
'@ECHO OFF'
'CLS'

Call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
Call sysloadfuncs

badcfg = 'n'
bootdrive = Substr(Translate(Value('PATH',,'OS2ENVIRONMENT')),Pos('\OS2\SYSTEM',Translate(Value('PATH',,'OS2ENVIRONMENT')))-2,2)
fpwdll = bootdrive||'\os2\dll'

inipath = Value('IBMWORKS_INI',,'OS2ENVIRONMENT')

If inipath = '' Then badcfg = 'y' 

If fpwpath = '' Then fpwpath = inipath

fpwdrive = Substr(fpwpath,1,2)

If fpwpath <> '' & Substr(fpwdrive,2,1) = ':' Then Do

  If calledfromSI<>'y' & NeedToCopyDlls(fpwdll)='y' Then Call CopyDlls
   
/****************************************************************************/
/* Create the WORKS desktop objects                                         */
/****************************************************************************/

  Say " "
  Say "Creating IBM Works Desktop ..."

  If fpwlan = '' Then fpwlan = fpwpath 
    
  Call SysRegisterObjectClass 'FpwCatalyst', fpwdll||'\FPWCAT.DLL'
  
  Call SysCreateObject 'WPFolder', 'IBM Works','<WP_DESKTOP>','ICONFILE='||fpwpath||'\FPWOBOX.ICO;ICONNFILE=1,'||fpwpath||'\FPWOBOX2.ICO;OBJECTID=<WP_FPWO_FOLD>','R'

  Call SysCreateObject 'FpwCatalyst', 'Footprint Catalyst','<WP_DESKTOP>','OBJECTID=<FPW_CATALYST>;NOTVISIBLE=YES','R'
  
  Call SysRegisterObjectClass 'FpwWPData', fpwdll||'\FPWWP.DLL'
  Call SysRegisterObjectClass 'FpwSSData', fpwdll||'\FPWSS.DLL'
  Call SysRegisterObjectClass 'FpwCHData', fpwdll||'\FPWCH.DLL'
  Call SysRegisterObjectClass 'FpwDBData', fpwdll||'\FPWDB.DLL'
  Call SysRegisterObjectClass 'FpwRWData', fpwdll||'\FPWRW.DLL'
  Call SysRegisterObjectClass 'FpwGRData', fpwdll||'\FPWGR.DLL'

/****************************************************************************/
/* Create the PIM desktop objects                                           */
/****************************************************************************/

  Call SysCreateObject 'WPProgram','Appointments','<WP_FPWO_FOLD>','ICONFILE='||fpwpath||'\appt2.ico;HELPLIBRARY=fpwpim.hlp;HELPPANEL=12000;EXENAME='||fpwpath||'\FPWPIM.EXE;PARAMETERS=-M;PROGTYPE=PM;CCVIEW=YES;OBJECTID=<WP_FPWPIMA_EXE>','R'
  Call SysCreateObject 'WPProgram','Phone/Address Book','<WP_FPWO_FOLD>','ICONFILE='||fpwpath||'\phonebk.ico;HELPLIBRARY=fpwpim.hlp;HELPPANEL=13000;EXENAME='||fpwpath||'\FPWPIM.EXE;PARAMETERS=-P;PROGTYPE=PM;CCVIEW=YES;OBJECTID=<WP_FPWPIMP_EXE>','R'
  Call SysCreateObject 'FpwGRData','Contact List','<WP_FPWO_FOLD>','TEMPLATE=YES;OBJECTID=<WP_FPWO_GRTEMP>','R'
  Call SysCreateObject 'WPProgram','Notepad','<WP_FPWO_FOLD>','ICONFILE='||fpwpath||'\notes.ico;HELPLIBRARY=fpwpim.hlp;HELPPANEL=15000;EXENAME='||fpwpath||'\FPWPIM.EXE;PARAMETERS=-N;PROGTYPE=PM;CCVIEW=YES;OBJECTID=<WP_FPWPIMN_EXE>','R'
  Call SysCreateObject 'WPProgram','Planner','<WP_FPWO_FOLD>','ICONFILE='||fpwpath||'\month.ico;HELPLIBRARY=fpwpim.hlp;HELPPANEL=12200;EXENAME='||fpwpath||'\FPWPIM.EXE;PARAMETERS=-G;PROGTYPE=PM;CCVIEW=YES;OBJECTID=<WP_FPWPIMG_EXE>','R'
  Call SysCreateObject 'WPProgram','To Do List','<WP_FPWO_FOLD>','ICONFILE='||fpwpath||'\todo.ico;HELPLIBRARY=fpwpim.hlp;HELPPANEL=16000;EXENAME='||fpwpath||'\FPWPIM.EXE;PARAMETERS=-T;PROGTYPE=PM;CCVIEW=YES;OBJECTID=<WP_FPWPIMT_EXE>','R'
  Call SysCreateObject 'WPProgram','Year Calendar','<WP_FPWO_FOLD>','ICONFILE='||fpwpath||'\year.ico;HELPLIBRARY=fpwpim.hlp;HELPPANEL=11210;EXENAME='||fpwpath||'\FPWPIM.EXE;PARAMETERS=-Y;PROGTYPE=PM;CCVIEW=YES;OBJECTID=<WP_FPWPIMY_EXE>','R'
  Call SysCreateObject 'WPProgram','Event Monitor','<WP_FPWO_FOLD>','ICONFILE='||fpwpath||'\alarm.ico;HELPLIBRARY=fpwpim.hlp;HELPPANEL=10100;EXENAME='||fpwpath||'\FPWMON.EXE;PROGTYPE=PM;CCVIEW=YES;OBJECTID=<WP_FPWPIME_EXE>','R'
  Call SysCreateObject 'WPProgram','PIM Preferences','<WP_FPWO_FOLD>','ICONFILE='||fpwpath||'\prefer.ico;HELPLIBRARY=fpwpim.hlp;HELPPANEL=17000;EXENAME='||fpwpath||'\FPWPIM.EXE;PARAMETERS=-S;PROGTYPE=PM;CCVIEW=YES;OBJECTID=<WP_FPWPIMS_EXE>','R'

  Call SysCreateObject 'WPShadow','Template','<WP_FPWO_FOLD>','SHADOWID='||fpwlan||'\template;OBJECTID=<WP_FPWO_SAMP_FOLD>','R'

  Call SysCreateObject 'FpwRWData','Report','<WP_FPWO_FOLD>','TEMPLATE=YES;OBJECTID=<WP_FPWO_RWTEMP>','R'
  Call SysCreateObject 'FpwDBData','Database','<WP_FPWO_FOLD>','TEMPLATE=YES;OBJECTID=<WP_FPWO_DBTEMP>','R'
  Call SysCreateObject 'FpwCHData','Chart','<WP_FPWO_FOLD>','TEMPLATE=YES;OBJECTID=<WP_FPWO_CHTEMP>','R'
  Call SysCreateObject 'FpwSSData','Sheet','<WP_FPWO_FOLD>','TEMPLATE=YES;OBJECTID=<WP_FPWO_SSTEMP>','R'
  Call SysCreateObject 'FpwWPData','Document','<WP_FPWO_FOLD>','TEMPLATE=YES;OBJECTID=<WP_FPWO_WPTEMP>','R'

  Call SysCreateObject 'WPShadow','ReadMe','<WP_FPWO_FOLD>','SHADOWID='||fpwpath||'\'ReadMe';OBJECTID=<WP_FPWO_README>','R'
  Call SysCreateObject 'WPProgram','IBM Works','<WP_FPWO_FOLD>','HELPLIBRARY=ibmworks.hlp;HELPPANEL=1;EXENAME='||fpwpath||'\IBMWORKS.EXE;PROGTYPE=PM;CCVIEW=YES;OBJECTID=<WP_FPWO_EXE>','R'

  'ob2templ '||fpwlan||'\template\ESTIMATE '||fpwlan||'\template\FAX '||fpwlan||'\template\MEMO '||fpwlan||'\template\BALANCES '||fpwlan||'\template\BANKRECO'
  'ob2templ '||fpwlan||'\template\BUDGET '||fpwlan||'\template\CREDITAP '||fpwlan||'\template\FORECAST '||fpwlan||'\template\INVOICE '||fpwlan||'\template\MERGELET'
Rem   'ob2templ '||fpwlan||'\template\INVENTOR '||fpwlan||'\template\TAPES'

  If calledfromSI<>'y' & badcfg = 'y' Then Do
     Call UpdateConfigSys
     Call UpdateOS2Ini
     'fpwini 'fpwpath
  End   

  If calledfromSI='y' Then Do   
     ret = SysFileTree(fpwpath||'\dllbak', 'file', 'D')
     If file.0 = 0 Then Do
        '@mkdir 'fpwpath||'\dllbak'
     End
     '@copy 'fpwdll'\fpwcat.dll 'fpwpath||'\dllbak 2>nul >nul'
     '@copy 'fpwdll'\fpwpers.dll 'fpwpath||'\dllbak 2>nul >nul'
     '@copy 'fpwdll'\fpwrec.dll 'fpwpath||'\dllbak 2>nul >nul'
     '@copy 'fpwdll'\fen20pde.dll 'fpwpath||'\dllbak 2>nul >nul'
     '@copy 'fpwdll'\fpwwp.dll 'fpwpath||'\dllbak 2>nul >nul'
     '@copy 'fpwdll'\fpwss.dll 'fpwpath||'\dllbak 2>nul >nul'
     '@copy 'fpwdll'\fpwch.dll 'fpwpath||'\dllbak 2>nul >nul'
     '@copy 'fpwdll'\fpwdb.dll 'fpwpath||'\dllbak 2>nul >nul'
     '@copy 'fpwdll'\fpwrw.dll 'fpwpath||'\dllbak 2>nul >nul'
     '@copy 'fpwdll'\fpwgr.dll 'fpwpath||'\dllbak 2>nul >nul'
  End
   
  Say " "
  Say "IBM Works Desktop created successfully!"
  
End
Else Do
  Say 'IBMWDESK.CMD - Rexx script to build the IBM Works desktop folder'
  Say ' '
  Say 'Syntax: IBMWDESK [PATH]'
  Say '        PATH - IBM Works directory'
  
  Say 'Example:'
  Say '        IBMWDESK C:\IBMWORKS'
End

Call Endit


/****************/
/* Exit program */
/****************/
Endit:
Exit 0


/***************************/
/* Change the CONFIG.SYS   */
/***************************/

UpdateConfigSys:   /* change the config.sys file for IBMWorks */
/*
'@cls'
response=''

Say '    Do you want to update 'bootdrive'\CONFIG.SYS?(Y/N)'
  Parse Upper Pull response
  If response <> 'N' Then Do
     Say '    The old 'bootdrive'\CONFIG.SYS will be created called 'bootdrive'\CONFIG.IW'
     Say ' '
     Say '    Shutdown and restart your system for these changes to take affect.'
     Say ' '
  End
  Else
     return 0
*/

oldconfig=bootdrive'\CONFIG.SYS'
newconfig=bootdrive'\CONFIG.IW'
tmpconfig=bootdrive'\IWTMP.SYS'

os2path='SET PATH'
os2libpath='LIBPATH'
os2help='SET HELP'
os2ini='SET IBMWORKS_INI'

iniflag=0

/* get the portion of pathspec without the [drive]: */
pathonly = right(fpwpath, length(fpwpath)-2)

/*
 * read the file one line at a time, and write it all out, making
 * changes accordingly - need to change path, libpath, help, IBMWORKS_INI
 */

'@del 'newconfig ' 2>nul >nul'

Do while lines(oldconfig)
    inline=linein(oldconfig)

    /******************************************/
    /* parse the line into variable and value */
    /******************************************/

    parse value inline with os2var '=' os2value

    /********************************************************/
    /* translate the variable into uppercase for comparison */
    /********************************************************/

    os2var=translate(os2var)
    Select

        /********************************************************/
        /*          For PATH                                    */
        /********************************************************/
        when os2var=os2path Then Do
            ibmwline=inline

            /* see if path is already set */
            k = pos(pathonly, translate(ibmwline))
            If k = 0 Then Do
               /*
                * see if there is a ; at the end of the value
                */
               position=lastpos(';',os2value)
               lenvalue=length(os2value)

               If position=lenvalue Then do
                   /* ; at end of value */
                   ibmwline=os2var'='os2value''fpwpath';'
               End
               Else Do
                   /* ; NOT at end of value */
                   ibmwline=os2var'='os2value';'fpwpath';'
               End
               
            End
            Else  /* see if the drive letter is not the same */
              If substr(ibmwline, k-2, 1) \= fpwdrive Then
                /* change the drive letter only */
                ibmwline = overlay(fpwdrive, ibmwline, k-2)

            /*
             * write the line out to the new config file
             */

            result=lineout(newconfig, ibmwline)

            If result=1 Then Do
                writeerror()
                return 1
            End
        End

        /********************************************************/
        /*          For LIBPATH                                 */
        /********************************************************/
        when os2var=os2libpath Then Do
            ibmwline=inline

            /* see if lib path is already set */
            k = pos(pathonly, translate(ibmwline))
            If k = 0 Then Do
               /*
                * see if there is a ; at the end of the value
                */

               position=lastpos(';',os2value)
               lenvalue=length(os2value)
 
               If position=lenvalue Then Do
                   /* ; at end of value */
                   ibmwline=os2var'='os2value''fpwpath';'
               End
               Else Do
                   /* ; NOT at end of value */
                   ibmwline=os2var'='os2value';'fpwpath';'
               End
               
            End
            Else  /* see if the drive letter is not the same */
              If substr(ibmwline, k-2, 1) \= fpwdrive Then
                /* change the drive letter only */
                ibmwline = overlay(fpwdrive, ibmwline, k-2)

            /*
             * write the line out to the new config file
             */

            result=lineout(newconfig, ibmwline)
            If result=1 Then Do
                writeerror()
                return 1
            End
        End

        /********************************************************/
        /*          For SET HELP                                */
        /********************************************************/
        when os2var=os2help Then Do
            ibmwline=inline

            /* see if lib path is already set */
            k = pos(pathonly, translate(ibmwline))
            If k = 0 Then Do
               /*
                * see if there is a ; at the end of the value
                */

               position=lastpos(';',os2value)
               lenvalue=length(os2value)

               If position=lenvalue Then Do
                   /* ; at end of value */
                   ibmwline=os2var'='os2value''fpwpath';'
               End
               Else Do
                   /* ; NOT at end of value */
                   ibmwline=os2var'='os2value';'fpwpath';'
               End
               
            End
            Else  /* see if the drive letter is not the same */
              If substr(ibmwline, k-2, 1) \= fpwdrive Then
                /* change the drive letter only */
                ibmwline = overlay(fpwdrive, ibmwline, k-2)

            /*
             * write the line out to the new config file
             */

            result=lineout(newconfig, ibmwline)
            If result=1 Then Do
                writeerror()
                return 1
            End
        End

        /********************************************************/
        /*          For SET IBMWORKS_INI                        */
        /********************************************************/

        when os2var=os2ini Then Do
            iniflag=1

            ibmwline=inline

            /* see if lib path is already set */
            k = pos(pathonly, translate(ibmwline))
            If k = 0 Then Do
               /*
                * see if there is a ; at the end of the value
                */

               position=lastpos(';',os2value)
               lenvalue=length(os2value)

               If position=lenvalue Then Do
                   /* ; at end of value */
                   ibmwline=os2var'='os2value''fpwpath';'
               End
               Else Do
                   /* ; NOT at end of value */
                   ibmwline=os2var'='os2value';'fpwpath';'
               End
               
            End
            Else  /* see if the drive letter is not the same */
              If substr(ibmwline, k-2, 1) \= fpwdrive Then
                /* change the drive letter only */
                ibmwline = overlay(fpwdrive, ibmwline, k-2)

            /*
             * write the line out to the new config file
             */

            result=lineout(newconfig, ibmwline)
            If result=1 Then Do
                writeerror()
                return 1
            End
        End


        otherwise Do
            /*
             * write the line out to the new config file
             */

            result=lineout(newconfig, inline)
            If result=1 Then Do
                writeerror()
                return 1
            End
        End

    End  /* select */

End /* Do */


/*********************************************************************/
/* if there was no SET IBMWORKS_INI variable set in CONFIG.SYS, Then */
/* put New env. variables                                            */
/*********************************************************************/

If iniflag=0 Then Do

    ibmwline='SET IBMWORKS_INI='fpwpath

    /*
     * write the line out to the new config file
     */

    result=lineout(newconfig, ibmwline)
    If result=1 Then Do
        writeerror()
        return 1
    End
End


/*********************/
/* close the files   */
/*********************/

result=lineout(newconfig)
result=lineout(oldconfig)

/********************************************************************/
/* Copy created file(CONFIG.IW) to temporary file(IWTMP.SYS),       */
/* copy original file(CONFIG.SYS) to new file(CONFIG.IW),           */
/* and copy temporary file(IWTMP.SYS) to original file(CONFIG.SYS). */
/********************************************************************/

'@copy 'oldconfig' 'tmpconfig' 2>nul >nul'

'@copy 'newconfig' 'oldconfig' 2>nul >nul'

'@copy 'tmpconfig' 'newconfig' 2>nul >nul'

'@del 'tmpconfig' 2>nul >nul'

/******************************************************************/
/*  Finished the Update                                           */
/******************************************************************/

rem Say ' '
rem Say '               'bootdrive'\CONFIG.SYS updated succesfully.'
rem Say ' '

return 0


NeedToCopyDlls: procedure
ARG fpwdll
   rc = 'n'
   
   ret = SysFileTree(fpwdll||'\fpwcat.dll', 'file', 'FO')
   If file.0 > 0 Then Do
      ret = SysFileTree(fpwdll||'\fpwrec.dll', 'file', 'FO')
      If file.0 > 0 Then Do
         ret = SysFileTree(fpwdll||'\fen20pde.dll', 'file', 'FO')
         If file.0 > 0 Then Do
            ret = SysFileTree(fpwdll||'\fpwpers.dll', 'file', 'FO')
            If file.0 > 0 Then Do
               ret = SysFileTree(fpwdll||'\fpwwp.dll', 'file', 'FO')
               If file.0 > 0 Then Do
                  ret = SysFileTree(fpwdll||'\fpwss.dll', 'file', 'FO')
                  If file.0 > 0 Then Do
                     ret = SysFileTree(fpwdll||'\fpwch.dll', 'file', 'FO')
                     If file.0 > 0 Then Do
                        ret = SysFileTree(fpwdll||'\fpwdb.dll', 'file', 'FO')
                        If file.0 > 0 Then Do
                           ret = SysFileTree(fpwdll||'\fpwrw.dll', 'file', 'FO')
                           If file.0 > 0 Then Do
                              ret = SysFileTree(fpwdll||'\fpwgr.dll', 'file', 'FO')
                              If file.0 = 0 Then rc = 'y'
                           End   
                           Else
                              rc = 'y'
                        End   
                        Else
                           rc = 'y'
                     End   
                     Else
                        rc = 'y'
                  End   
                  Else
                     rc = 'y'
               End   
               Else
                  rc = 'y'
            End   
            Else
               rc = 'y'
         End   
         Else
            rc = 'y'
      End   
      Else
         rc = 'y'
   End   
   Else
      rc = 'y'
      
   return rc   


CopyDLLs:
   '@copy 'fpwpath'\dllbak\*.* 'fpwdll' 2>nul >nul'
   return 0


UpdateOS2Ini:
   ret=SysIni(,'IBMWORKS','DLL',fpwpath)
   return ret

