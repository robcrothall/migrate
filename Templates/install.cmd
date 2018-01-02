/* **********************************************************************
*  *               Copyright (c) IBM Corporation, 1994                  *
*  *                       All Rights Reserved                          *
*  **********************************************************************
*
*             IBM OS/2 Bonus Pak Installation Utility Setup
*/

   /* Initalize Environment:
   *  This command file attempts to improve application load time by
   *  unpacking application files (EXE & DLL) to harddrive. DLL load time
   *  from removable media is about 45secs slower loadtime from hardrive.
   *
   *  To avoid NLV translation requirements, all errors are filtered
   *  and defered to the OSO0001.MSG file for appropriate translated text.
   */
   '@echo off'
   trace off

   /* Parse Call Path Info
   */
   Parse Source . . callPath

   /* Load in function library
   */
   Call RxFuncAdd "SysLoadFuncs","RexxUtil","SysLoadFuncs"
   Call SysLoadFuncs

   /* Strip program name
   */
   rcp = REVERSE(callPath)
   callPathDir = REVERSE(substr(rcp,POS("\",rcp)+1))

   /* Create Queue to catch system error messages
   */
   rcode = RXQUEUE('delete', errq)
   errq = RXQUEUE('create')
   new = RXQUEUE('set', errq)

   /* Define stem of files to be copied
   */
   MaxCopyIndex = 6
   Files. = ""
   Files.0 = MaxCopyIndex
   Files.1 = "BPIU.@"
   Files.2 = "INFOHWAY.CMD"
   Files.3 = "INFOHWY1.ICO"
   Files.4 = "INFOHWY2.ICO"
   Files.5 = "INET1.ICO"
   Files.6 = "INET2.ICO"

   /* Determine bootdrive
   */
   CurDir = DIRECTORY()
   SrcDir = callPathDir
   if (SubStr(SrcDir,Length(SrcDir),1) \= "\") then
     SrcDir = SrcDir||"\"
   BootDrive = GetBootDrive()
   if (BootDrive == "") then
     do
      /* ;OS2 is a required somewhere in the path directory!
      */
      'helpmsg SYS0010 | RXQUEUE 'errq
       call DumpErrMsg
       call Done
     end
   InsPath = TRANSLATE(BootDrive||"\OS2\INSTALL")

   /* Determine Multimedia Status
   */
   fMMInstalled = value("MMBASE",,"OS2ENVIRONMENT")
   MMLen = LENGTH(fMMInstalled)
   if (MMLen > 0) then
     if (Substr(fMMInstalled,MMLen,1) == ";") then
       fMMInstalled = Substr(fMMInstalled,1,MMLen-1)

   /* Verify Source Files
   */
   do i = 1 to MaxCopyIndex
     rc = VerifySourcePath( SrcDir||Files.i )
     if ( rc == 1 ) then
       call Done
   end

   /* Check and Clean Dirty System
   */
   InsDir = DIRECTORY(InsPath)
   if (InsDir == InsPath) then
     do
       CleanDir = InsDir||"\BPIU"
       TargetDir = DIRECTORY(CleanDir)
       if (TargetDir == CleanDir) then
         do
           call DeleteFiles CleanDir
           InsDir = DIRECTORY(InsPath)
           rc = SysRmDir(CleanDir)
           if (rc \= 0) then
             do
               'helpmsg sys'||rc||' | RXQUEUE 'errq
               call DumpErrMsg
               call Done
             end
         end
     end
    else do
           /* \OS2\INSTALL is a required path directory!
           */
           'helpmsg SYS0010 | RXQUEUE 'errq
            call DumpErrMsg
            call Done
         end

   /* Run Installation Utility
   */
   tmpDir = DIRECTORY(InsPath)
   if (tmpDir \= "") then
     do
       if (MMLen > 0) then
         call PlayMusic SrcDir, fMMInstalled
       rc = SysMkDir("BPIU")
       if (rc \= 0) then
         do
           'helpmsg sys'||rc||' | RXQUEUE 'errq
           call DumpErrMsg
           call Done
         end
       NewDir = InsDir||"\BPIU"
       tmpDir = DIRECTORY(NewDir)
       do t = 2 to Files.0
         copystr = SrcDir||Files.t||' '||tmpDir||'\'||Files.t
         'copy 'copystr
       end
       success = UnpackFiles(SrcDir, tmpDir, 1)
       if (success == 0) then
         do
           BPIU Left(SrcDir,1)
           /* Update Workplace Shell Desktop with Information Highway Folder
           */
           'call 'tmpdir'\'Files.2
           call DeleteFiles tmpDir
           tempDir = DIRECTORY(InsDir)
           rc = SysRmDir(tmpDir)
           if (rc \= 0) then
             do
               'helpmsg sys'||rc||' | RXQUEUE 'errq
               call DumpErrMsg
               call Done
             end
           tmpDir = DIRECTORY(SrcDir)
         end
     end


Done:
   rc = RXQUEUE('delete', errq)
   OriginalDir = DIRECTORY(CurDir)
   exit

/* Procedures and Functions
*/

VerifySourcePath: Procedure Expose errq

   Parse Arg file;

   fExists = Stream(file,'c','query exists')
   if (fExists == "")
     then do
           'helpmsg SYS002 | RXQUEUE 'errq
            call DumpErrMsg
            return 1
          end

return 0

UnpackFiles: Procedure Expose Files. errq

   Parse Arg SrcPath, TargetPath, index;

   if (SubStr(SrcPath,Length(SrcPath),1) == "\") then
     unpackstr = SrcPath||Files.index||" "||TargetPath||,
                 " /V /F  > nul 2>&1"
   else unpackstr = SrcPath||"\"||Files.index||" "||TargetPath||,
                    " /V /F > nul 2>&1"

   'unpack 'unpackstr

   if (rc \= 0) then
     do
       'helpmsg sys'||rc||' | RXQUEUE 'errq
       call DumpErrMsg
       return 1
     end

return 0

DumpErrMsg: Procedure

   do while(QUEUED() \= 0)
     parse pull line
     if (POS("SYS",line) \= 0) then
       fFound = 1
     if ((line == "") & (fFound = 1)) then
       do
         /* Empty out queue
         */
         do while(QUEUED() \= 0)
           parse pull line
         end
         leave
       end
     say line
   end

return

PlayMusic: Procedure Expose Files. errq

   Parse Arg Source, MMBase;

   Target = MMBase||"\SOUNDS"
   playstr = '"Rock-Intro" /C /MIN cmd.exe /q /c "'||MMBase||,
             '\play.cmd FILE='||Target||,
             '\BLUEJAM.MID FROM=0 TO=120000"'
   'start 'playstr

return

DeleteFiles: Procedure Expose errq

  Parse Arg dir;

  fspec = dir||"\*.*"
  call SysFileTree fspec, 'dellst', 'FO'
  do i = 1 to dellst.0
    rc = SysFileDelete(dellst.i)
    if (rc \= 0) then
      do
        'helpmsg sys'||rc||' | RXQUEUE 'errq
        call DumpErrMsg
      end
  end

return

GetBootDrive: Procedure

   PathStr = VALUE("PATH",,"OS2ENVIRONMENT")
   InsPathPos = POS(":\OS2",TRANSLATE(PathStr))
   if (InsPathPos \= 0) then
     do
       bdrive = Substr(PathStr,InsPathPos-1,2)
     end
   else bdrive = ""

return bdrive
