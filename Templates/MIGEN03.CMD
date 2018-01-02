/*********************************************************************
   @ECHO OFF
   ECHO OS/2 Procedures Language 2/REXX not installed.
   ECHO Run Selective Installation from the Setup Folder to
   ECHO install REXX support.
   pause
   exit
 *********************************************************************
 Purpose:       Create a personality profile based on clinical evaluation
 
 Client:        Management Insight CC
 Date written:  May 1994
 Author:        Rob Crothall & Associates - RJC
 Copyright:     Copyright (1994) by Rob Crothall & Associates, South Africa.
                All rights reserved.
 
 Arguments:     
 Processing:    Initialise, including display of these comments if invoked
                  with a paramete of '?'.  Prepare to handle exception
                  conditions, if they arise.  Ensure that utility functions 
                  are loaded.
                Process parameters passed to the program, including filename
                Read the file and process it a line at a time
                  When the first category specification is found,
                    Check that all necessary parameters have values
                    Set up the basic document
                  When any category is found, save the information
                  When a driver is selected, then
                    If the category has not been read in, then
                      read in the category.
                    Find and process the driver
                At end of the request file,
                  Assemble the document
                  Perform macro substitution
                  Format the document
                  If the output file (.DOC) exists
                    Rename it with a unique extension
                  Write the file with the extension of .DOC
                  Write billing info
                Tidy up and return.
                                                          
 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Changed by:                   Date:
*/
/*********************************************************************
 *            (C) Copyright Rob Crothall & Associates 1994           *
 *********************************************************************/
/* Initialise, including display of these comments if invoked */
/* with a paramete of '?'.  Prepare to handle exception       */
/* conditions, if they arise.                                 */

/* Define some constants... */
Yes         = 1;
No          = 0;
VRexxActive = No;

/* Set options that help during debugging */
'@echo off';

Debug       = No;

If Debug = Yes then say 'At beginning...';

rc          = 0;
MI_RC       = 0;
RX_Sigl     = 0;
RX_SourceLine = 0;

Warn.       = '';
Warn.1      = 'V1.0 - Restricted - property of Rob Crothall & Associates';
Warn.2      = 'Restricted - property of Management Insight';
Warn.0      = 2;

arg ProcOpts;

Driver      = '';
Reject.     = '';
RejectIndx  = 0;
GenOK       = Yes;
MyVersion   = 1.0;
CurDir      = '';
SectMax     = 0;
Line.       = 0;
ChangedCount= 0;
Level       = '$';
Prev        = '';

miCat       = 'MICAT.CTL';
bQuiet      = No;
Skel        = 'MIREP.TXT';
miWords     = 'MIWORDS.TXT';
Print       = No;
Compress    = No;
Indent      = 5;
LineLen     = 60;
Align       = No;
a           = 'abc0def1gh2ij3kl4mn5op6qr7st8uv9wx.yz,&*ABCDEFGHI=JKLMNOPQRSTUVWXYZ';
b           = 'f1gh2ij3kl4mn5op6qr7st8uv9wx.yz,&*ABCDEFGHI=JKLMNOPQRSTUVWXYZabc0de';
c           = 'f1gh2iskfu,s;dj3kl4mn5op6qr7st8uv9wx.yz,&*ABCDEFGHI=JKLKHGFKHJFGMNO';
b           = reverse(b);

/* Display comment info if 1st arg = ? and Exit */
DisplayUsage:
If arg(1)='?' then do;  
   Parse source . . name .;
   Say; Say name;
   Do n = 1 by 1;
      line=sourceline(n);
      If 0 < pos('*/',line) then exit 1;
      If n//15 = 0 then do;
         say; say 'Press <Enter> to continue...';
         pull ans;
      end;  /* Do */
      Say line;
   End;
End;

/* Handle programming errors in a reasonable way... */

Signal on failure  name RX_Failure;
Signal on halt     name RX_Halt;
Signal on syntax   name RX_Syntax;
Signal on error    name RX_Error;
Signal on novalue  name RX_NoValue;
Signal on notready name RX_NotReady;

/* Check if utility functions have been loaded; If not, load them...*/
If 0 < RxFuncQuery('SysLoadFuncs')
  then do;
         Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
         Call SysLoadFuncs;
         Say 'RexxUtils loaded...';
       End;

If 0 < RxFuncQuery('PrxLoadFuncs')
  then do;
         Call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS';
         Call PrxLoadFuncs;
         Say 'PrxUtils loaded...';
       End;

MyQ         = 'MI01';

Parse upper arg ParmQ Rest;
If (ParmQ \= '') & (Rest = '') then MyQ = ParmQ;

NewQ        = RXQUEUE('create', MyQ);

If NewQ \= MyQ then do;
   rc       = RXQUEUE('delete', NewQ);
   Say MyQ 'exists - ' NewQ 'is not required.';
end  /* Do */

OldQ        = RXQUEUE('set', MyQ);

If Queued() > 0 then do;
   ProcOpts = LineIn('Queue:');
end /* do */
else parse upper arg ProcOpts;

Parse var ProcOpts Initiator Processor UDir UFn UExt MiscDir Rest;
Say 'Parms =' Initiator Processor UDir UFn UExt MiscDir Rest;
If Rest \= '' then do;
   Say 'Extra parameter "'||Rest||'" ignored!';
end  /* Do */
RepFileSpec = UDir || UFn || UExt;

FileOutName = UFn;
FileOutExt  = '.DOC';
FileSpec    = UDir || UFn || FileOutExt;

Direction   = 1;
/*------------- Main processing ------------------------------*/

If Debug = Yes then say 'At Initialize...';
call Initialize

/* Process parameters passed to the program, incl filename    */
If Debug = Yes then say 'At Parameters...';
Call Parameters;

/* Read the file and process it a line at a time              */
Do LineNo = 1 to 10000 by 1 until lines(RepFileSpec) = 0;

   CLine = linein(RepFileSpec);

/* Select parameters, Categories, and Drivers                 */
   Select;

     When left(CLine, 1) = '%' then Cline = '';

     When CLine = '' then do;
        /* nothing...  */
     end  /* Do */

     When verify(CLine,' -_=') = 0 then do;
        /* nothing...  */
     end  /* Do */

     When pos('D....',CLine) > 0 then do;
/*      When the first category specification is found,            */
/*        Check that all necessary parameters have values          */
/*        Set up the basic document                                */
        Parse var CLine 'D....' DriverFile '-' .;
        DriverFile = space(DriverFile);
        Call GetDrivers;
     end  /* Do */

     When pos('<--',CLine) > 0 then do;
        Parse var CLine val '<--' KeyPhrase;
        Parse var KeyPhrase KeyWord .;
        KeyPhrase = space(KeyPhrase);
        KeyWord   = space(KeyWord);
        val       = space(val);
        Select;

           When KeyWord = 'Form' then do;
           end  /* Do */

           When KeyWord = 'Version' then do;
             If val \= MyVersion then rc = Err('Ver', '002', 'I', 'Incorrect version of Profile request', LineNo, CLine);
           end  /* Do */

           When KeyWord = 'Debug' then do;
             val = translate(val);
             Say 'My Env   =' MyEnv;
             Say 'HomeBase =' HomeBase;
             If MyEnv = HomeBase then if left(val,1) = 'Y' then Debug = Yes;
           end  /* Do */

           When KeyWord = 'Report_Type' then do;

           end  /* Do */

           When KeyWord = 'Report_Style' then do;
             work. = '';
             rc = SysFileTree(val, 'WORK', 'FSO');
             If work.1 \= '' then do;
               Skel = work.1;
               Call SetUpDoc;
             end; /* do */
             else call Err 'Fil', '002', 'S', 'Report Style not found', LineNo, CLine;
           end  /* Do */

           When KeyWord = 'Report_level' then do;
             If (DataType(val) = 'NUM') | (val = '$') then Level = val;
             else call Err 'Lev', '001', 'E', 'Level not $ or number', LineNo, CLine;
           end  /* Do */

           When KeyWord = 'Report_vocab' then do;
             work. = '';
             rc = SysFileTree(val, 'work', 'FSO');
             If work.1 \= '' then do;
               MIWords = work.1;
               Call GetWords;
             end  /* Do */
             else call Err 'Fil', '002', 'S', 'Vocabulary file not found', LineNo, CLine;
           end  /* Do */

           When KeyWord = 'LineLength' then do;
             Valid = Yes;
             If DataType(val) \= 'NUM' then do;
               call Err 'Num','001','W','Line Length is not numeric', LineNo, CLine;
               Valid = No;
             end  /* Do */
             If (val < 30) | (val > 250) then do;
               Call Err 'Num','002','W','Line Length is not between 30 and 250', LineNo, CLine;
               Valid = No;
             end  /* Do */
             If Valid = Yes then LineLen = val;
           end  /* Do */

           When KeyWord = 'Indent' then do;
             Valid = Yes;
             If DataType(val) \= 'NUM' then do;
               call Err 'Num','003','W','Indent is not numeric', LineNo, CLine;
               Valid = No;
             end  /* Do */
             If (val < 3) | (val > 25) then do;
               Call Err 'Num','004','W','Indent is not between 3 and 25', LineNo, CLine;
               Valid = No;
             end  /* Do */
             If Valid = Yes then Indent = val;
           end  /* Do */

           When KeyWord = 'Align' then do;
             val = translate(val);
             If left(val,1) = 'Y' then Align = Yes;
           end  /* Do */

           When KeyWord = 'Industry' then do;
             val = translate(val);
             If val \= '' then Industry = left(val,1);
           end  /* Do */

           When KeyWord = 'Client_Name' then do;

           end  /* Do */

           When KeyWord = 'Client_Code' then do;

           end  /* Do */

           When KeyWord = 'MI_Relationship' then do;

           end  /* Do */

           When KeyWord = 'Consultant' then do;

           end  /* Do */

           When KeyWord = 'Interviewer' then do;

           end  /* Do */

           When KeyWord = 'Interview_Date' then do;

           end  /* Do */

           When KeyWord = 'Analyst' then do;

           end  /* Do */

           When KeyWord = 'Report_Creator' then do;

           end  /* Do */

           When KeyWord = 'Subj_Title' then do;
             Title = val;
           end  /* Do */

           When KeyWord = 'Subj_Firstname' then do;
             Initials = val;
           end  /* Do */

           When KeyWord = 'Subj_Surname' then do;
             Surname = val;
           end  /* Do */

           When KeyWord = 'Result_File' then do;
             Parse upper var val FileOutName '.' FileOutExt;
             FileOutName = space(FileOutName,0);
             FileOutExt  = space(FileOutExt,0);
             If length(FileOutName) > 8 then do;
               call Err 'Fil', '002', 'E', 'File name too long', LineNo, CLine;
             end  /* Do */
             If length(FileOutExt)  > 3 then do;
               call Err 'Fil', '003', 'E', 'File extension too long', LineNo, CLine;
             end  /* Do */
             If FileOutExt = '' then FileOutExt = 'DOC';
             If FileOutExt = 'ZIP' then do;
               FileOutExt = 'DOC';
               Compress = Yes;
             End;
             FileSpec = Directory ||'\'|| FileOutName || '.' || FileOutExt;

           end  /* Do */

           When KeyWord = 'Directory' then do;
             work. = '';
             rc = SysFileTree(val, 'work', 'DO');
             If work.1 \= '' then do;
               Directory = work.1;
             end  /* Do */
             else call Err 'Dir', '002', 'W', 'Target directory not found', LineNo, CLine;
             If (left(Directory,1) \= '\') & (substr(Directory,2,1) \= ':') then Directory = '\' || Directory;
           end  /* Do */

           When KeyWord = 'Subj_gender' then do;
             If verify(val,'MF') = 0 then Gender = left(val,1);
             else call Err 'Gen','001','E','Gender must be M or F', LineNo, CLine;
           end  /* Do */

           When translate(left(val,1)) = 'Y' then do; /* look for a driver in Category */
              /* look for it */
              DrvName  = Translate(KeyPhrase,'_',' ');
              DrvName  = Translate(DrvName);
              Say 'Looking for' DrvName 'in' DriverFile;
              Call SelectDriver;
           end  /* Do */

           Otherwise do;
             CLine = '';
           End;
        End  /* select */
     end  /* Do */

     Otherwise do;
       call Err 'Unk', '002', 'W', 'Line not recognised - ignored', LineNo, CLine;
     end  /* Do */

   End  /* Select */

/* When any category is found, save the information           */

/* When a driver is selected, then                            */
/*   If the category has not been read in, then               */
/*     read in the category.                                  */
/*   Find and process the driver                              */
End; /* do */
/* At end of the request file,                                */

GENERATE:
If Debug = Yes then say 'At Generate...';

/* Assemble the document                                      */

If Debug = Yes then say 'At AssembleDoc...';
Call AssembleDoc;

/* Perform macro substitution                                 */

If Debug = Yes then say 'At TailorDoc...';
Call TailorDoc;
/* Format the document                                        */

/* If the output file (.DOC) exists                           */
/*   Rename it with a unique extension                        */

/* Write the file with the extension of .DOC                  */
If Debug = Yes then say 'At WriteDoc...';
Call WriteDoc;
'f:\bat\wpmi1';
/* 'start "Formatting in WP..." /B /I /C F:\bat\wpmi1.bat'; */
If Debug = Yes then say 'At PrintDoc...';
If Print = Yes then call PrintDoc;
If Debug = Yes then say 'At ZipDoc...';
If Compress = Yes then call ZipDoc;
If Debug = Yes then say 'At WriteBilling...';
Call WriteBilling;

/* Now keep the FILES.BBS file up to date... */
If Debug = Yes then say 'At keeping FILES.BBS up to date...';
Out. = '';
Out.0 = 1;
Out.1 = FileOutName||'.'||FileOutExt Title Initials Surname;
If Compress = Yes then do;
  Out.2 = FileOutName||'.ZIP' Title Initials Surname;
  Out.0 = Out.0 + 1;
End;
mi_rc = PrxWriteFromStem('FILES.BBS', 'Out', Out.0, 1, 'Append');
/* Force any other files into FILES.BBS */
If Debug = Yes then say 'At calling BBS...';
Call BBS;

/* Write billing info                                         */
If Debug = Yes then say 'At WriteBilling...';
Call WriteBilling;

/* Now keep the FILES.BBS file up to date...                  */
If Debug = Yes then say 'At keeping FILES.BBS up to date...';
Call UpdBBSAl;

/* Tidy up and return.                                        */
Signal EndIt;

/*---------------- End of Main processing --------------------*/

CLEANUP:

  If Debug = Yes then say 'At Cleanup...';
  Say 'We got here from line' RX_Sigl;
  Say '  That is:' RX_SourceLine;
  Say 'Debug values follow:-';
  Say 'Condition:      ' RX_Condition;
  Say 'Source line no: ' RX_Sigl;
  Say 'Source line:    ' RX_SourceLine;
  Say 'Condition(C):   ' RX_Cond_C;
  Say 'Condition(I):   ' RX_Cond_I;
  Say 'Condition(D):   ' RX_Cond_D;
  Say 'Condition(S):   ' RX_Cond_S;


EndIt:

  Say 'Current Directory =' curdir;
  If Debug = Yes then say 'At EndIt...';
  if Debug = Yes then call SysSleep 5;
  'start "Read and Process Queues..." /B /I /C CheckQ.CMD' MyQ;

  call directory(curdir);
  result = endlocal();

Exit;

/*========================================================*/
/* Start of internal subroutines, in alphabetical order   */
/*========================================================*/
AssembleDoc:  /* Assemble document from individual sections */

  JAss    = 1;
  PrevAss = 'x';
  Out.    = '';
  Do Section = 0 to SectMax;
    If Debug = Yes then say 'Assemble: Section =' Section;
    If Line.Section > 0 then do IAss = 1 to Line.Section;
      MacroIn = DocOut.Section.IAss;
      If MacroIn = '' then if PrevAss = '' then iterate;
      PrevAss = MacroIn;
      Call MacroRep;
      JAss = JAss + 1;
      Out.JAss = space(MacroOut);
      If Debug = Yes then say 'Assemble: JAss =' JAss 'Out =' Out.JAss;
    End;
  End;
  Out.0 = JAss;

Return;

/*------------------------------------------------------------*/

Comma:  /* Break a number into parts  */
hun='';thou='';mil='';bill='';

len=length(numb)
pos=len-2

if pos< 0 | pos = 0 then do;hun=left(numb,len);return;end
else hun=substr(numb,pos,3)

pos=pos-3
if pos< 0 | pos = 0 then do;thou=left(numb,pos+2);return;end
else thou=substr(numb,pos,3)

pos=pos-3
if pos< 0 | pos = 0 then do;mil=left(numb,pos+2);return;end
else mil=substr(numb,pos,3)

pos=pos-3
if pos< 0 | pos = 0 then do;bill=left(numb,pos+2);return;end
else bill=substr(numb,pos,3)

return


/*------------------------------------------------------------*/

Concat:  /* Concatenate parts of a number, with commas */
if hun='' then do;
   newnum='';
   return;
end  /* Do */
else if thou='' then do;
        newnum=hun;
        return;
     end
     else if mil='' then do;
             newnum=thou','hun;
             return;
          end
          else if bill='' then do;
                  newnum=mil','thou','hun;
                  return;
               end
               else newnum=bill','mil','thou','hun;
return;


/*------------------------------------------------------------*/
Copyright:

  If bQuiet > 0 then return;
  msg.0 = 6;
  msg.1 = '               This product is copyright by';
  msg.2 = '                  Management Insight CC.';
  msg.3 = '                    All rights are reserved.';
  msg.4 = '';
  msg.5 = '           Press OK to acknowledge the rights';
  msg.6 = '  of Management Insight CC.  Press Cancel to end.';
  do itemp = 1 to msg.0;
     call SysSay msg.itemp;
  end /* do */
  call SysPause;


Return;

/*------------------------------------------------------------*/

Err:

Parse arg ErrPrefix, ErrNumber, ErrSeverity, ErrMsg, ErrLineNo, ErrLine;

RejectIndx  = RejectIndx + 2;
Reject.RejectIndx = '('||ErrLineNo||')' ErrLine;
RejectIndx  = RejectIndx + 1;
Reject.RejectIndx = '    ' ErrPrefix||'-'||ErrNumber||'-'||ErrSeverity':' ErrMsg;
If pos(ErrSeverity, 'IW') = 0 then GenOK = No;

Return;

/*------------------------------------------------------------*/

FNumb:  /* Format a number, with commas  */
parse arg numb
call comma
call concat
arg=newnum
return


/*------------------------------------------------------------*/

getBOOT:
bootdrive = Value('Path',,'OS2ENVIRONMENT')
parse upper var bootdrive bootdrive
Driveis = Substr(bootdrive,Pos('\OS2\SYSTEM',bootdrive)-2,2)
return


/*------------------------------------------------------------*/
GetCategory:

  retcd = PrxReadToStem(miCat, 'OldFiles');
  OldDesc. = '';
  If OldFiles.0 \= 'OLDFILES.0' then do I = 1 to OldFiles.0;
    Parse var OldFiles.I OldFn OldDesc.OldFn;
  end  /* Do */
  Say 'Result is:' retcd;
  Say 'Number of old file descriptions returned:' OldFiles.0;
  'del' miCat;  /* Get rid of the old one... */
  Cat. = '';
  K = 0;
  NewFiles. = '';
  call SysFileTree '*.*','fil','ft';
  do i = 1 to fil.0;
    Parse var fil.i yy'/'mm'/'dd'/'hh'/'min size attr fullname;
    fn = filespec('n',fullname);
    parse var fn nm '.' ext;
    if nm = 'FILES' then iterate;
    NewFiles.fn = 'Y';
    K = K + 1;
    Cat.K = fn OldDesc.fn;
  end /* do */
  Cat.0 = K;
  /* Sort into alphabetic order by file name ... */
  Do I = 1 to Cat.0;
    Do J = I to Cat.0;
      If Cat.I > Cat.J then do;
        Temp = Cat.I;
        Cat.I = Cat.J;
        Cat.J = Temp;
      End;
    End;
  End;

  If K > 0 then retcd = PrxWriteFromStem(miCat, 'Cat', K, 1, 'Replace');
     else If OldFiles.0 \= 'OLDFILES.0' then 'del' miCat;
  K = 0;
  Do I = 1 to Cat.0;
    If Industry \= '$' 
      then if left(Cat.I, 1) = '$' 
             then nop;
             else if left(Cat.I, 1) = Industry 
                    then nop;
                    else iterate;
      else nop;
    If Level \= '$'
      then if substr(Cat.I, 2, 1) = '$'
             then nop;
             else if substr(Cat.I, 2, 1) = Level
                    then nop;
                    else iterate;
      else nop;
    K = K + 1;
    If I \= K then do;
      Cat.K = Cat.I;
      Cat.I = '';
    end  /* Do */
  End;
  Cat.0 = K;
  If Debug = Yes then Say 'Number of files found:    ' K;
  If Debug = Yes then Say 'Cat.0 =' Cat.0;
  If Debug = Yes then Do K = 1 to Cat.0;
     Say 'Found:' Cat.K;
  end; /* do */
Return;

/*------------------------------------------------------------*/

GetConfigSys:

FATC=0; HPFSC=0; TIMESLICE ='Dynamic'; buffers=''; pridiskio=''; fcbs=''; files=''; rmsize='';
iopl=''; maxwait=''; memman=''; swploc=''; warnsize=''; swpisize=''; threads=''; pmonbufsize='';
tracebuf=''; protect=''; acvalues=''; setac=''; v1=''; v2=''; v3=''; v4=''; fatCachesize=0; FatLW='';
Fatt=''; cache='0'; crecl=''; auto=''; ifs=driveis'\OS2\HPFS.IFS'; file=''; sys=''; acheckl=''; acheckval='';

do until lines(driveis"\"configsys) = 0
  fline=linein(driveis"\"configsys)
  parse var fline parm "=" values
  if parm = "BUFFERS" then buffers = values
  else if parm = "PRIORITY_DISK_IO" then pridiskio = values
     else if parm = "FCBS" then fcbs = values
     else if parm = "FILES" then files = values
     else if parm = "RMSIZE" then rmsize = values
     else if parm = "IOPL" then iopl = values
     else if parm = "MAXWAIT" then maxwait = values
     else if parm = "MEMMAN" then memman = values
     else if parm = "SWAPPATH" then parse var fline "=" swploc warnsize swpisize
     else if parm = "THREADS" then threads = values
     else if parm = "PRINTMONBUFSIZE" then pmonbsiz = values
     else if parm = "TRACEBUF" then tracebuf = values
     else if parm = "PROTECTONLY" then protect = values
     else if parm = "TIMESLICE" then timeslice = values
     else if parm = "DISKCACHE" then do      /* DISKCACHE */
              FATC=1
              parse var values any "AC:" acvalues
              if acvalues = ''  then setac = ''
               else setac = ",AC:"acvalues
                 parse var values v1 "," v2 "," v3 "," v4
                 fatCacheSize = v1
                 dskcache = 'Yes'
               if v2 = "LW" then  FatLW = 'LW'
                else if v3 = 'LW' then fatlw = 'LW'
                else if v4 = 'LW' then fatlw = 'LW'
                else if verify(v2,'1234567890') then  NOP
                else fatt = v2
                if \verify(v2,'1234567890') then fatt = v2
                else if \verify(v3,'1234567890') then fatt = v3
                else if  \verify(v4,'1234567890') then fatt = v4
                end
                 else if parm = "IFS" then do
                   parse var fline parm "=" ifs cache1 crecl1 auto1
                   parse var ifs fileSys"."sys
                   if IFS = driveis"\OS2\HPFS.IFS" then do; HPFSC=1;parse upper var values  '/CACHE:' cache '/CRECL:' crecl '/AUTOCHECK:'Acheckval; end;
                   else nop
                   if acheckval = '' then acheckl=''
                   else acheckl = " /AUTOCHECK:"Acheckval
                   end
END
return


/*------------------------------------------------------------*/
GetDetails:
  /* Ask for details of this profile, and set up variables... */
  prompt. = '';
  prompt.0 = 9;
  if MyEnv = HomeBase then prompt.0 = prompt.0 + 1;
  prompt.1 = 'Industry:';
  prompt.2 = 'Level:';
  prompt.3 = 'Title (e.g. Mrs):';
  prompt.4 = 'Initials/First name:';
  prompt.5 = 'Surname:';
  prompt.6 = 'Gender (M/F):';
  prompt.7 = 'Directory:';
  prompt.8 = 'Billing code:';
  prompt.9 = 'Filename:';
  prompt.10 = 'Debug:';

  width.  = 10;
  width.0 = prompt.0;
  width.1 = 1;
  width.2 = 1;
  width.3 = 10;
  width.4 = 25;
  width.5 = 25;
  width.6 = 1;
  width.7 = 20;
  width.8 = 8;
  width.9 = 12;
  width.10 = 1;

  hide.  = 0;
  hide.0 = prompt.0;
  hide.1 = 0;
  hide.2 = 0;
  hide.3 = 0;
  hide.4 = 0;
  hide.5 = 0;
  hide.6 = 0;
  hide.7 = 0;
  hide.8 = 0;
  hide.9 = 0;
  hide.10 = 0;

  answer.  = '';
  answer.0 = prompt.0;
  answer.1 = '$';
  answer.2 = '$';
  answer.3 = 'Mr';
  answer.4 = 'Joe';
  answer.5 = 'Soap';
  answer.6 = 'm';
  answer.7 = '\mi';
  answer.8 = 'test';
  answer.9 = '';
  answer.10 = 'N';

  Heading = 'Please enter subject details';
  Correct = No;
  Do until (Correct = Yes);
/*    mirc = VMultBox(Heading, prompt, width, hide, answer, 3);*/
/*    If mirc \= 'OK' then signal CLEANUP;*/
    If answer.9 = '' then do; 
      answer.9 = left(answer.5,6,'$')||left(answer.4,2);
      answer.9 = space(answer.9,0)||'.DOC';
    End;
    Heading = 'Please enter ALL details';
    Do I = 1 to answer.0;
      If (answer.I = '') then signal TryAgain;
    End;
    if MyEnv = HomeBase then if 'Y' = Translate(answer.10) then Debug = Yes;
    Industry = Translate(answer.1);
    Level    = answer.2;
    Title    = answer.3;
    Initials = answer.4;
    Surname  = answer.5;
    Gender      = Translate(answer.6);
    Directory= Translate(answer.7);
    Billing  = answer.8;
    Heading = 'Gender should be M or F';
    If 0 = pos(Gender, 'MF') then iterate;
    /* Check existence of Directory */
    /* Check existence of miWords file */
    /* If Directory\FILES.BBS does not exist, ensure that \MAX\FILEAREAS.CTL
         is updated.  Run SILT in another session. */
    /* Check that FileOut does not exist in Directory */
    /* Check that Billing is valid */
    Correct = Yes;

TryAgain:
  End;

Return;

/*------------------------------------------------------------*/

getDriveInfo:

a = 1;
do a = 1 to 25;
  d.a = '';
end;

dmap  = SysDriveMap('c:', 'LOCAL');
parse value dmap with d.1 d.2 d.3 d.4 d.5 d.6 d.7 d.8 d.9 d.10 d.11 d.12 d.13 d.14 d.15 d.16 d.17 d.18 d.19 d.20 d.21 d.22 d.23 d.24 D.25;
FAT   = 'NO';
HPFS  = 'NO';
a     = 1;
drive = d.a;
do while (d.a \= '');
  rc        = SysMkDir(drive'\'muchtoolargeforFAT);
  if rc=206 then do;
    FAT     = 'YES';
    Type.a  = 'FAT';
  end;
  else do;
    if rc=19 then Type.a = 'CD-ROM';
    else do;
      HPFS   = 'YES';
      type.a = 'HPFS';
      call SysRmDir(drive'\'muchtoolargeforfat);
    end;
  end;
  dinfo.a   = SysDriveInfo(d.a);
  parse var dinfo.a d.a ":" free.a total.a label.a;
  pfree.a   = free.a/total.a;
  pfree.a   = 100*pfree.a;
  pfree.a   = trunc(pfree.a,2);
  a         = a+1;
  drive     = d.a;
end;

return;

/*------------------------------------------------------------*/
GetDrivers:

  Section  = 0;
  Driver.  = '';
  Category = DriverFile;
  mi_rc = PrxReadToStem(Category, 'In');
  Say 'Category =' Category ' In.1 =' In.1;
  If (In.1 \= Warn.1) & (In.1 \= Warn.2) then do;
      Say 'Wrong version of Driver file' Category;
      Signal CLEANUP;
  End;
  DrNo = 0;
  Do I = 2 to In.0;  /* Select drivers from Category file */
    In.I = translate(In.I, b, a);
    In.I = reverse(In.I);
    If I < 11 then say In.I;
    Do J = 1 to words(In.I);
      work = word(In.I, J);
      work = Translate(work);
      If left(work, 1) = '&' then do;
        Parse var work Keyword '=' value;
        Select;
          When Keyword = '&DRIVER' then do;
            DrEnd.DrNo   = I - 1;
            Say 'Driver=' value 'found';
            DrNo         = DrNo + 1;
            Driver.DrNo  = value;
            DrStart.DrNo = I;
          End;
          Otherwise;
            Nop;
        End;
      End;
    End;
  End;

/*  temp     = Driver.DrNo;  */
  DrEnd.DrNo = In.0;
  Driver.0   = DrNo;

Return;

/*------------------------------------------------------------*/

GetWords:
  DupWord. = 0;
  retcd = PrxReadToStem(miWords, 'NewWords');
  If NewWords.0 = 'NEWWORDS.0' then do;
    say 'No replacement words found';
    Return;
  end; /* do */
  else do;
    say NewWords.0 'lines found in Word Replacement file';
    If (NewWords.1 \= Warn.1) & (NewWords.1 \= Warn.2) then do;
      Say 'Wrong version of' miWords;
      Signal CLEANUP;
    End;
  end; /* do */
  J = 1;

  do I = 2 to NewWords.0;
    NewWords.I = translate(NewWords.I, b, a);
    NewWords.I = reverse(NewWords.I);
    Parse var NewWords.I WInd.J WLevel.J WSex.J TheWord.J WRepl.J;
    If WInd.J = '*' then iterate;
    If WInd.J = '' then iterate;
    If length(TheWord.J) < 2 then do;
      msg.  = '';
      msg.0 = 5;
      msg.1 = 'Line' I ': Keyword "' || TheWord.J || '" is too short.';
      msg.5 = 'It has been ignored.';

      do itemp = 1 to msg.0;
         call SysSay msg.itemp;
      end /* do */
      call SysPause;
      
    End; /* do */
    If left(TheWord.J,1) \= '&' then do;
      msg.  = '';
      msg.0 = 5;
      msg.1 = 'Line' I ': Keyword "' || TheWord.J || '" should start with "&".';
      msg.5 = 'It has been ignored.';
      do itemp = 1 to msg.0;
         call SysSay msg.itemp;
      end /* do */
      call SysPause;

    End; /* do */

    T1 = WInd.J;
    T2 = WLevel.J;
    T3 = WSex.J;
    T4 = TheWord.J;
    K = DupWord.T1.T2.T3.T4;

    If K > 0 then do;
      msg.  = '';
      msg.0 = 5;
      msg.1 = 'Line' I ':' NewWords.I;
      msg.2 = 'is a duplicate keyword for';
      msg.3 = 'Line' K ':' NewWords.K;
      msg.5 = 'It has been ignored.';
      do itemp = 1 to msg.0;
         call SysSay msg.itemp;
      end /* do */
      call SysPause;
    End; /* do */
    Else DupWord.T1.T2.T3.T4 = I;

    J = J + 1;
  end  /* Do */

  NewWords.0 = J - 1;
  Say NewWords.0 'replacement phrases were found';

Return;

/*------------------------------------------------------------*/

Initialize:

'@ECHO OFF'
result = setlocal();

/*********************************************************************
 * Find what our home directory is, and where we are being           *
 * executed from.                                                    *
 * We will also save the value of various environmental variables.   *
 *********************************************************************/
curdir = directory();

parse source opsys invoked myname;
myname     = translate(myname);
e_drive    = left(myname,2)
temp       = reverse(myname);
ObjectName = myname;
parse var temp 'DMC.'e_name'\'e_path;
e_path     = reverse(e_path)'\'
e_name     = reverse(e_name)
HomeBase   = 'RobC';
Path       = value('PATH',,'OS2ENVIRONMENT')
DPath      = value('DPATH',,'OS2ENVIRONMENT')
Help       = value('HELP',,'OS2ENVIRONMENT')
BookShelf  = value('BOOKSHELF',,'OS2ENVIRONMENT')
BookMgr    = value('BOOKMGR',,'OS2ENVIRONMENT')
ReadIBM    = value('READIBM',,'OS2ENVIRONMENT')
MyEnv      = value(substr(e_name,1,5),,'OS2ENVIRONMENT');
/************************************************
 * Make sure that all paths end in a ;          *
 ************************************************/
if right(PATH,1) <> ';'
  then PATH = PATH';'
if right(DPATH,1) <> ';'
  then DPATH = DPATH';'
if right(HELP,1) <> ';'
  then HELP = HELP';'

/************************************************
 * Find Boot Drive for OS2.                     *
 ************************************************/
parse upper var Path b_drive'\OS2;'.
b_drive = right(b_drive,2)
if debug=Yes then say 'Op Sys  =' opsys;
if debug=Yes then say 'Invoked =' invoked;
if debug=Yes then say 'My name =' myname;
if debug=Yes then say 'E drive =' e_drive;
if debug=Yes then say 'E path  =' e_path;
if debug=Yes then say 'E name  =' e_name;
if debug=Yes then say 'B drive =' b_drive;
if debug=Yes then say 'My env  =' MyEnv;

InitVariables:
getBOOT:
bootdrive     = Value('Path',,'OS2ENVIRONMENT')
parse upper var bootdrive bootdrive
BootDrive     = Substr(bootdrive,Pos('\OS2\SYSTEM',bootdrive)-2,2)

CharSet:
/* Foreground colors, not highlighted*/
black         ='[30m[1A';
red           ='[31m[1A';
green         ='[32m[1A';
yellow        ='[33m[1A';
blue          ='[34m[1A';
white         ='[37m[1A';
/* Foreground colors, highlighted*/
hblack        ='[1;30m[1A';
hred          ='[1;31m[1A';
hgreen        ='[1;32m[1A';
hyellow       ='[1;33m[1A';
hblue         ='[1;34m[1A';
hwhite        ='[1;37m[1A';
blue_o_white  ='[34;47m[1A';
white_o_blue  ='[37;44m[1A';
white_o_red   ='[37;41m[1A';
/* Cursor movement */
cursor_up     ='[1A';      /* Cursor up 1 line*/
cursor_up2    ='[2A';      /* Cursor up 2 lines*/
cursor_down   ='[1B';      /* Cursor down 1 line*/
cursor_right  ='[1C';      /* Cursor right 1 space*/
cr5           ='[9C';      /* Cursor right 5 spaces*/

normal        ='[0m[1A';  /* Restore default attrib. and color    */
reverse       ='[7m[1A';  /* Reverse video*/
highlight     ='[1m[1A';  /* Highlight*/
invisible     ='[8m[1A';  /* Invisible*/

return;


/*------------------------------------------------------------*/
MacroRep:  /* Replace symbolic parameters in the document     */
           /*   by the details (e.g. Name) captured earlier.  */

    ChangedCount = 0;
    If Debug = Yes then say 'Start of MacroRep';
    MacroOut = '';
    If MacroIn = '' then MacroIn = '&SP';
    Rest     = MacroIn;
    If Debug = Yes then say 'Rest =' Rest;
    KStart   = 1;
    WordLen  = 0;
    WordRep  = '';
    Changed  = No;
    J = 0;
    JMax = 0;
    Do while((J < words(Rest)) & (JMax < 100000));
      /* Find a target string starting with '&' */
      J = J + 1;
      JMax = JMax + 1;
      If Debug = Yes then do;
        say 'Rest =' Rest;
        say 'J =' J '    JMax =' JMax;
      end  /* Do */

      Target = word(Rest, J);
      If left(Target, 1) \= '&' then iterate;
      If length(Target) < 2 then iterate;
      parse var Target Keyword '=' Value;
      KStart = wordindex(Rest, J);
      KLength = length(Target);
      KeyWordUp = Translate(Target);
      WordLen = 0;
      Select;

        When abbrev(KeyWordUp,'&DRIVER') then do;
           WordLen = KLength;
           If Debug = Yes then do;
             WordRep = substr(Target,2);
             WordLen = KLength;
           End;
           Else WordRep = '';
        end; /* Do */

        When abbrev(KeyWordUp, '&SECTION') then do;
           WordLen = KLength;
           If Debug = Yes then do;
             WordRep = substr(Target,2);
             WordLen = KLength;
           End;
           Else WordRep = '';
        end; /* Do */

        When abbrev(KeyWordUp, '&TITLE') then do;
           WordLen = 6;
           WordRep = Title;
        end; /* Do */

        When abbrev(KeyWordUp, '&INITIALS') then do;
           WordLen = 9;
           WordRep = Initials;
        end; /* Do */

        When abbrev(KeyWordUp, '&SURNAME') then do;
           WordLen = 8;
           WordRep = Surname;
        end; /* Do */

        When abbrev(KeyWordUp, '&UTITLE') then do;
           WordLen = 7;
           WordRep = translate(Title);
        end; /* Do */

        When abbrev(KeyWordUp, '&UINITIALS') then do;
           WordLen = 10;
           WordRep = translate(Initials);
        end; /* Do */

        When abbrev(KeyWordUp, '&USURNAME') then do;
           WordLen = 9;
           WordRep = translate(Surname);
        end; /* Do */

        When abbrev(KeyWordUp, '&DATE') then do;
           WordLen = 5;
           WordRep = date('L');
        end; /* Do */

        Otherwise;

      End; /* select */

      Do L = 1 to NewWords.0 while(WordLen = 0);
         If Debug = Yes then say Keyword '=' TheWord.L Gender '=' WSex.L Level '=' WLevel.L Industry '=' WInd.L;
         If abbrev(KeyWord, TheWord.L) then if (Gender = WSex.L | WSex.L = '$') then if (pos(Level, WLevel.L)>0 | WLevel.L = '$') then if (pos(Industry, WInd.L)>0 | WInd.L  = '$') then do;
            WordLen = length(TheWord.L);
            WordRep = WRepl.L;
         end; /* do */
      end L; /* Do */
      If Debug = Yes then say 'WordLen =' WordLen;
      If Debug = Yes then nop;
      If WordLen > 0 then do;
         Changed = Yes;
         ChangedCount = ChangedCount + 1;
         If (WordRep = '') & (WordLen = Klength) then do;
            WordLen = WordLen + 1;
         End;

         If KStart > 1 then Rest = substr(Rest, 1, KStart-1) || WordRep || substr(Rest, KStart+WordLen);
           Else Rest = WordRep || substr(Rest, KStart+WordLen);
         If Debug = Yes then Say 'Rest =' Rest;
         If Debug = Yes then Say 'J =' J;
         J = max(0, J-10);
      end;  /* Do */
    End; /* do */
    MacroOut = Rest;
    If Debug = Yes then say 'End of MacroRep';

Return;


/*------------------------------------------------------------*/
Parameters:  /* Handle default options and parameters passed to us... */

  Do I = 1 to 0; /*words(ProcOpts);*/

    work = word(ProcOpts, I);
    parse var work Keyword '=' parm;
    parm = strip(parm);

    Select
      when Keyword = 'MICAT' then miCat = parm;
      when Keyword = 'MIWORDS' then miWords = parm;
      when Keyword = 'QUIET' then If left(parm,1) = 'Y' then bQuiet = Yes;
      when Keyword = 'SKEL' then Skel = parm;
      when Keyword = 'PRINT' then If left(parm,1) = 'Y' then Print = Yes;
      when Keyword = 'DEBUG' then If left(parm,1) = 'Y' then Debug = Yes;
      when Keyword = 'INDENT' then Indent = parm;
      when Keyword = 'LINELEN' then LineLen = parm;
      when Keyword = 'ALIGN' then If left(Parm,1) = 'Y' then Align = Yes;
      otherwise;
        msg.1 = 'Parameter' word(ProcOpts, I) 'is not recognised';
        msg.2 = 'and has been ignored.';
        msg.0 = 2;
        do itemp = 1 to msg.0;
           call SysPause msg.itemp;
        end /* do */
    end;  /* select */
  end; /* do */

Return;

/*------------------------------------------------------------*/
PrintDoc:

  If Print = Yes then 'Print' FileSpec;
Return;

/*------------------------------------------------------------*/

RX_Failure:
  RX_Condition  = 'Failure';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

RX_Halt:
  RX_Condition  = 'Halt';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

RX_Syntax:
  RX_Condition  = 'Syntax';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

RX_Error:
  RX_Condition  = 'Error';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

RX_NoValue:
  RX_Condition  = 'NoValue';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

RX_NotReady:
  RX_Condition  = 'NotReady';
  RX_Sigl       = Sigl;
  RX_SourceLine = sourceline(sigl);
  RX_Cond_C     = condition('C');
  RX_Cond_I     = condition('I');
  RX_Cond_D     = condition('D');
  RX_Cond_S     = condition('S');
  Signal CLEANUP;

/*------------------------------------------------------------*/

SelectDriver:
 
  DrNo = 0;
  Do L = 1 to Driver.0;
     If Driver.L = DrvName then do;
        DrNo = L;
        leave L;
     end  /* Do */
  end /* do */
  If DrNo = 0 then do;
     call err 'Req', '001', 'E', 'Driver name invalid', LineNo, CLine;
     return;
  end  /* Do */
  sel.  = '';
  sel.0 = 0;
  Section = 0;
  Do L = DrStart.DrNo to DrEnd.DrNo;
    Do J = 1 to words(In.L);
      work = word(In.L, J);
      work = Translate(work);
      If left(work, 1) = '&' then do;
        Parse var work Keyword '=' value;
        Select;
          When Keyword = '&SECTION' then do;
            Section = value;
            If Section > SectMax then SectMax = Section;
            If Debug = Yes then In.L = Category ':' Driver ':' In.L;
          End;
          Otherwise;
            Nop;
        End;
      End;
    End;
    Line.Section = Line.Section + 1;
    K = Line.Section;
    DocOut.Section.K = In.L;
    if Debug = Yes then do;
      Say 'In.L =' In.L;
      nop;
    End; /* do */
  End;

Return;

/*------------------------------------------------------------*/

SetUpDoc:  /* Set up the skeleton document */

  DocOut. = '';
  mirc = PrxReadToStem(Skel, 'In');
  If In.0 = 'IN.0' then do;
    msg.1 = 'File' Skel 'not found. Process abandoned.';
    msg.0 = 1;
    rb    = VMsgBox('Parameter error?', msg, 2);
    signal CLEANUP;
  End;
  If (In.1 \= Warn.1) & (In.1 \= Warn.2) then do;
      Say 'Wrong version of Category file';
      Signal CLEANUP;
  End;
  InSect  = 0;
  Sect    = 0;
  Section = 0;
  SectMax = 0;
  Line.   = 0;
  Do I = 2 to In.0;
    In.I = translate(In.I, b, a);
    In.I = reverse(In.I);
    Do J = 1 to words(In.I);
      work = word(In.I, J);
      If left(work, 1) = '&' then do;
        Parse var work Keyword '=' value;
        Select;
          When Keyword = '&SECTION' then do;
            Section = value;
            W1 = wordindex(In.I, J) - 1;
            W2 = wordindex(In.I, J+1);
            If Debug \= Yes then do;
              If W2 > W1 then In.I = substr(In.I, 1, W1) || substr(In.I, W2);
            End;
            If Section > SectMax then SectMax = Section;
          End;
          Otherwise;
            Nop;
        End;
      End;
    End;
    Line.Section = Line.Section + 1;
    K = Line.Section;
    DocOut.Section.K = In.I;
  End;
Return;

/*------------------------------------------------------------*/

SysPause:
  parse arg prompt;
  if prompt='' then prompt='Press Enter key when ready . . .';
  call SysSay prompt;
  call syssleep 5;
  say
return

/*------------------------------------------------------------*/
SysSay:
  parse arg string
  call charout 'STDOUT', string
return;

/*------------------------------------------------------------*/
TailorDoc:  /* Format the lines                               */

  If Debug = Yes then say 'Start of TailorDoc';
  IndentSt= 0;
  NewOut. = '';
  Line    = 1;

  Do I = 1 to Out.0;
    Rest    = Out.I;
    If Debug = Yes then say 'Out.'||I '=' Rest;
    Do while Rest \= '';
      Parse var Rest Next Rest;
      NextU = translate(Next);
      If (NextU = '&SP') & (Align = Yes) then do;
         If translate(Prev) = '&SP' then Line = Line + 1;
         else Line = Line + 2;
         IndentSt = 0;
         Iterate;
      end  /* Do */
      If (NextU = '&BR') & (Align = Yes) then do;
         Line = Line + 1;
         IndentSt = 0;
         Iterate;
      end  /* Do */
      If (Next = '*') then do;
         If (Align = Yes) then do;
            Line = Line + 1;
            Next = Next || copies(' ',Indent-2);
            IndentSt = 1;
         end  /* Do */
         else Next = '&BR'||Next||'&IN';
      end /* do */
      If length(NewOut.Line) + length(Next) + 1 > LineLen then do;
         Call RightAlign;
         Line = Line + 1;
         If IndentSt > 0 then NewOut.Line = copies(' ',IndentSt * Indent - 1);
      end /* do */

      If length(NewOut.Line) = 0 then NewOut.Line = Next;
/*      else If (left(NextU,1) = '&')|(left(Prev,1) = '&') then NewOut.Line = NewOut.Line||Next;*/
           else NewOut.Line = NewOut.Line Next;

      Prev = Next;
    end /* do */
  end /* do */

  NewOut.0 = Line;
  If Debug = Yes then say 'End of TailorDoc';
Return;


/*------------------------------------------------------------*/
TailorDoc2:  /* Format the lines                               */

  If Debug = Yes then say 'Start of TailorDoc';

  NewOut. = '';
  Line = 1;
  Do I = 1 to Out.0;
    Rest    = Out.I;
    If Debug = Yes then say 'Out.'||I '=' Rest;
    Star = left(Rest, 1);
    J = LineLen;
    If translate(word(Rest,1)) = '&SP' then do;
       Line = Line + 1;
       Star = '';
       iterate;
    end  /* Do */
    Do LineSeg = 1 to 1000 while(length(Rest) > 0);
      If Lineseg = 1 then do;
        If length(Rest) <= LineLen then do;
          NewOut.Line = Rest;
          Rest = '';
        End;
        Else do;
          J = lastpos(' ', Rest, Linelen);
          NewOut.Line = left(Rest, J-1);
          Call RightAlign;
          Rest = substr(Rest, J+1);
        End;
      End;
      Else if Star = '*' then do;
             If length(Rest) <= (Linelen - Indent) then do;
               NewOut.Line = left(' ', Indent, ' ') || Rest;
               Rest = '';
             End;
             Else do;
               J = lastpos(' ', Rest, Linelen-Indent);
               NewOut.Line = left(' ', Indent, ' ') || left(Rest, J-1);
               Call RightAlign;
               Rest = substr(Rest, J+1);
             End;
           End;
           Else do;
             If length(Rest) <= Linelen then do;
               NewOut.Line = Rest;
               Rest = '';
             End;
             Else do;
               J = lastpos(' ', Rest, Linelen);
               NewOut.Line = left(Rest, J-1);
               Call RightAlign;
               Rest = substr(Rest, J+1);
             End;
           End;
      Line = Line + 1;
    End;
  End I; /* do */
  NewOut.0 = Line;
  If Debug = Yes then say 'End of TailorDoc';
Return;

/*------------------------------------------------------------*/
RightAlign:

  If Debug = Yes then do;
    Say 'Start of RightAlign. Direction =' Direction;
    Say 'NewOut' Line '=' NewOut.Line;
  End;
  MinWords = 4;
  If Direction > 0 then do;
    If word(NewOut.Line,1) = '*' then LStart = 3;
    Else LStart = 2;
    LEnd = words(NewOut.Line);
    LIncr = 1;
    Direction = -1;
  End;
  Else do;
    LStart = Words(NewOut.Line);
    If word(NewOut.Line,1) = '*' then LEnd = 3;
    Else LEnd = 2;
    LIncr = -1;
    Direction = 1;
  End;

  Do while((Align = Yes) & (length(NewOut.Line) < LineLen) & (words(NewOut.Line) > MinWords));
    If Debug = Yes then do;
      Say 'Line length =' length(NewOut.Line);
      Say 'Line =' NewOut.Line;
      Say 'Do L =' LStart 'to' LEnd 'by' LIncr;
    End;
    Do L = LStart to LEnd by LIncr while (LineLen > length(NewOut.Line));
      NewOut.Line = insert(' ',NewOut.Line,wordindex(NewOut.Line,L)-1);
    End;
  End;
Return; /* RightAlign */

/*------------------------------------------------------------*/

Welcome:
echo on
'prompt $p$E[0;'34';'47';'5';'5'm]'
echo off
'cls'
call SysCurState 'OFF'
call sysCurPos '4', '0'

msg.0  =12
msg.1  = blue
msg.2  = cr5 cr5' ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿'
msg.3  = cr5 cr5' ³                                ³ '
msg.4  = cr5 cr5' ³  D o c U G e n   1.0           ³'
msg.5  = cr5 cr5' ³                                ³      '
msg.6  = cr5 cr5' ³                                ³'
msg.7  = cr5 cr5' ³                                ³'
msg.8  = cr5 cr5' ³                                ³'
msg.9  = cr5 cr5' ³                                ³'
msg.10 = cr5 cr5' ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
msg.11 = hblue
msg.12 = cr5 '        Copyright (c) 1994 Rob Crothall & Associates       '

msg.13 = '         If needed, please Maximize SCREEN SIZE then Press Enter to Continue    '
do i =1  to msg.0
       say msg.i
       end
call SysCurPos '19','0'

say red;
call sysCurPos '7', '22'
call syssay 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
call sysCurPos '8', '21'
call syssay 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'


say;
say red;
call sysCurPos '9', '21'
call syssay 'Go'
call sysCurPos '9', '23'
call syssay ' as fast as'
call sysSleep 1


call sysCurPos '9', '35'
call syssay '32 bits'
call sysSleep 1


call sysCurPos '11', '30'
call syssay ' will'
call sysSleep 1


call sysCurPos '11', '35'
call syssay ' take'
call sysSleep 1


say blue;
call sysCurPos '11', '41'
call syssay 'you!'
call sysSleep 1

say hblack;
call sysCurPos '15', '0'

SAY'         If needed, please Maximize SCREEN SIZE ...'

call sysSleep 1
say red;
call sysCurPos '14', '26'

CALL SYSPAUSE ObjectName
call SysCurState 'ON'


'cls'
echo on
'prompt $p$E[0;'34';'47';'5';'5'm]'
echo off
'cls'
return

/*------------------------------------------------------------*/
WriteBilling:
  'e:';
  'cd \MI';
  Out. = '';
  Out.1 = date() time() ProcOpts;
  Out.0 = 1;
  mi_rc = PrxWriteFromStem('BILL.RCD','Out',Out.0,1,'Append');
  mi_rc = PrxWriteFromStem(UDir||UFn||'.ERR', 'Reject', RejectIndx, 1, 'Replace');
Return;

/*------------------------------------------------------------*/
WriteDoc:
  'cd' Directory;
  If NewOut.0 > 0 then mi_rc = PrxWriteFromStem(FileSpec,'NewOut',NewOut.0,1,'Replace');
  'del e:\mi\mi1.doc';
  If NewOut.0 > 0 then mi_rc = PrxWriteFromStem('e:\mi\mi1.doc','NewOut',NewOut.0,1,'Replace');
/*  If NewOut.0 > 0 then 'command /k c:\wp51\wp.exe' FileSpec;*/

Return;

/*------------------------------------------------------------*/
ZipDoc:
  'cd' Directory;
  'PKZip' FileOutName FileSpec;
Return;

