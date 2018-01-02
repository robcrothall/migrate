/*********************************************************************
   @ECHO OFF
   ECHO OS/2 Procedures Language 2/REXX not installed.
   ECHO Run Selective Installation from the Setup Folder to
   ECHO install REXX support.
   pause
   exit
 *********************************************************************
 Purpose:       Convert the Standard Bank tapes from IBM format to ASCII
 
 Client:        Consolidated Share Registrars Limited
 Date written:  18 Aug 95
 Author:        Rob Crothall & Associates - RJC
 Copyright:     Copyright (1994) by Rob Crothall & Associates, South Africa.
                All rights reserved.
 
 Arguments:     These are in the form KEYWORD=...  KEYWORD2=...
                Separate the end of one parameter from the next with a space.
 
   QUIET=YES | NO  Suppresses copyright messages and other information displays.

   PRINT=YES | NO  The generated report should be printed as soon as it is ready.
                   Default is YES.

   DEBUG=YES | NO  Various sections are traced when this is set to Yes.
                   Default is NO.

   LINELEN=60      The line length at which output text should be wrapped.

   INDENT=5        Number of characters to indent.

   ALIGN=YES | NO  Align the right side of the report

   BLKSIZE=4100    Blksize as specified to Unix DD utility

   FNAME=test      File name, including full path and extension.

 Processing:    Initialise, including display of these comments if invoked
                  with a paramete of '?'.  Prepare to handle exception
                  conditions, if they arise.  Ensure that utility functions 
                  are loaded.
                Process keyword parameters passed to the program.
                Display copyright information and get acknowledgement.
                Read record
                do while not end-of-file
                   extract record type
                   case
                      when tape-header then call convert-tape-header
                      when acc-header then call convert-acc-header
                      when acc-details then call convert-acc-details
                      when acc-trailer then call convert-acc-trailer
                      when tape-trailer then call convert-tape-trailer
                      when code-record then call convert-code-record
                   end-case
                   Write converted record
                   Read record
                end /* do */
                Print control report
                Tidy up and return to the Workplace Shell.
                                                          
 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Written by:    Rob Crothall   Date: Aug 1995
 Changed by:                   Date:
*/
/*********************************************************************
 *            (C) Copyright Rob Crothall & Associates 1994           *
 *********************************************************************/

/* Define some constants... */
Yes = 1;
No = 0;
VRexxActive = No;

Directory = 'd:\ftp\csra\';
File_name = 'test';
File_ext  = 'dat';
File_in = Directory || File_name || '.' || File_ext;

Char_read = 0;
Blksize   = 4150;
Block_count = 0;
Record_count = 0;
Ignore_count = 0;
TapeHeadCnt  = 0;
TapeTrailCnt = 0;
AccHeadCnt   = 0;
AccTrailCnt  = 0;
AccDetCnt    = 0;



EBCDIC_hex = '404A4B4C4D4E4F505A5B5C5D5E5F60616A6B6C6D6E6F797A7B7C7D7E7F';
EBCDIC_hex = EBCDIC_hex || '818283848586878889919293949596979899';
EBCDIC_hex = EBCDIC_hex || 'A1A2A3A4A5A6A7A8A9C0C1C2C3C4C5C6C7C8C9';
EBCDIC_hex = EBCDIC_hex || 'D0D1D2D3D4D5D6D7D8D9E0E2E3E4E5E6E7E8E9';
EBCDIC_hex = EBCDIC_hex || 'F0F1F2F3F4F5F6F7F8F9FA';
EBCDIC_tab = x2c(EBCDIC_hex);
ASCII_tab  = ' *.<(+|&!$*);~-/|,%_>?`:#@''="abcdefghijklmnopqr~stuvwxyz';
ASCII_tab  = ASCII_tab || '{ABCDEFGHI}JKLMNOPQR\STUVWXYZ0123456789|';
P_Err  = 0;
P_Pack = '';
P_Char = '';
If length(EBCDIC_tab) \= length(ASCII_tab) then do;
   Say 'EBCDIC and ASCII tables are not equal - call developer!';
   return;
end  /* Do */

/* Set options that help during debugging */
'@echo off';

Debug = No;
/*If Debug = Yes then call trace('r');*/
If Debug = Yes then say 'At beginning...';

rc = 0;
MI_RC = 0;
Warn. = '';
Warn.1 = 'V1.0 - Restricted - property of Rob Crothall';
arg ProcOpts;

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

/*Signal on failure name CLEANUP;
Signal on halt name CLEANUP;
Signal on syntax name CLEANUP;*/
Signal on notready name Control_print;

/* Check if utility functions have been loaded; If not, load them...*/
If 0 < RxFuncQuery('SysLoadFuncs')
  then do;
         Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
         Call SysLoadFuncs;
       End;

If 0 < RxFuncQuery('PrxLoadFuncs')
  then do;
         Call RxFuncAdd 'PrxLoadFuncs', 'PRXUTILS', 'PRXLOADFUNCS';
         Call PrxLoadFuncs;
       End;
If Debug = Yes then Say PrxUtilsVersion();

If Debug = Yes then say 'Loading VRexx...';

If Debug = Yes then Say 'Press Enter to continue..';
If Debug = Yes then pull nul;

Direction = 1;
/*------------- Main processing ------------------------------*/

If Debug = Yes then say 'At Initialize...';
call Initialize
If Debug = Yes then say 'At Parameters...';
Call Parameters;
/* Call Welcome; */

/* ... Do the main processing ... */

/* Read record                                                */
Rec_in = charin(File_in,,8);
Char_read = Char_read + 8;
Rec_hex = '';
Rec_hex = c2x(Rec_in);
If Debug = Yes then Say 'Rec_hex =' Rec_hex;

Block_count = Block_count + 1;
Block_length = c2d(substr(Rec_in,1,2))-8;
Rec_length   = c2d(substr(Rec_in,5,2))-4;
If Debug = Yes then Say 'Block length =' Block_length;
If Debug = Yes then Say 'Rec length   =' Rec_length;

Rec_in = charin(File_in,,Rec_length);
Char_read = Char_read + Rec_length;
Record_count = Record_count + 1;
If Debug = Yes then Say 'Char read    =' Char_read;
Block_length = Block_length - Rec_length;

/* Delete any previous version of the converted files         */
Out_file = Directory||File_name||'.01';
'del' Out_file;
Out_file = Directory||File_name||'.02';
'del' Out_file;
Out_file = Directory||File_name||'.03';
'del' Out_file;
Out_file = Directory||File_name||'.04';
'del' Out_file;
Out_file = Directory||File_name||'.05';
'del' Out_file;

/* do while not end-of-file                                   */
End_of_file = No;

do while (\End_of_file);
   Out_rec = '';

/* Prepare for debug...                                       */
   Rec_hex = '';
   Rec_hex = c2x(Rec_in);
   If Debug = Yes then Say 'Rec_hex =' Rec_hex;

/*   extract record type                                      */
   Rec_type = translate(substr(Rec_in,21,2), ASCII_tab, EBCDIC_tab);

/* Extract common fields                                      */
   P_Pack = substr(Rec_in,1,5);
   call Get_packed;
   Cust_no = P_Char;

   P_Pack = substr(Rec_in,6,2);
   call Get_packed;
   Cust_suff = P_Char;

   P_Pack = substr(Rec_in,8,5);
   call Get_packed;
   Branch = P_Char;

   P_Pack = substr(Rec_in,13,8);
   call Get_packed;
   Account = P_Char;

/*                                                            */
   Select
/*     when tape-header                                       */
     when Rec_type = '01' then do;
        TapeHeadCnt = TapeHeadCnt + 1;
        Cust_name = translate(substr(Rec_in,23,30), ASCII_tab, EBCDIC_tab);
        P_Pack = substr(Rec_in,53,4);
        call Get_packed;
        Tape_date = right(P_char,6);
        Out_rec = Cust_no || Cust_suff || Branch || Account || Cust_name;
        Out_rec = Out_rec || Tape_date;
        Out_file = Directory||File_name||'.'||Rec_type;
        call lineout Out_file, Out_rec;
        If Debug = Yes then say Out_rec;
      end;
/*     when acc-header                                        */
     when Rec_type = '02' then do
        AccHeadCnt = AccHeadCnt + 1;
        P_Pack = substr(Rec_in,23,6);
        call Get_packed;
        Open_bal = P_char;
        Out_rec = Cust_no || Cust_suff || Branch || Account || Open_bal;
        Out_file = Directory||File_name||'.'||Rec_type;
        call lineout Out_file, Out_rec;
        If Debug = Yes then say Out_rec;
      end;
/*     when acc-details                                       */
     when Rec_type = '03' then do
        AccDetCnt = AccDetCnt + 1;
        P_Pack = substr(Rec_in,23,3);
        call Get_packed;
        Stmt = P_char;
        P_Pack = substr(Rec_in,26,3);
        call Get_packed;
        TCode = P_char;
        TType = translate(substr(Rec_in,29,4), ASCII_tab, EBCDIC_tab);
        P_Pack = substr(Rec_in,33,5);
        call Get_packed;
        TDate = right(P_char,8);
        P_Pack = substr(Rec_in,38,5);
        call Get_packed;
        Cheque_No = right(P_char,7);
        P_Pack = substr(Rec_in,43,6);
        call Get_packed;
        Amount = P_char;
        Narrative = translate(substr(Rec_in,49), ASCII_tab, EBCDIC_tab);
        Out_rec = Cust_no || Cust_suff || Branch || Account || Stmt;
        Out_rec = Out_rec || TCode || TType || TDate || Cheque_no;
        Out_rec = Out_rec || Amount || Narrative;
        Out_file = Directory||File_name||'.'||Rec_type;
        call lineout Out_file, Out_rec;
        If Debug = Yes then say Out_rec;
      end;

/*     when acc-trailer                                       */
     when Rec_type = '04' then do
        AccTrailCnt = AccTrailCnt + 1;
        P_Pack = substr(Rec_in,23,5);
        call Get_packed;
        TCount = P_char;
        P_Pack = substr(Rec_in,28,6);
        call Get_packed;
        TVal = P_char;
        P_Pack = substr(Rec_in,34,6);
        call Get_packed;
        Close_bal = P_char;
        Out_rec = Cust_no || Cust_suff || Branch || Account || TCount;
        Out_rec = Out_rec || TVal || Close_bal;
        Out_file = Directory||File_name||'.'||Rec_type;
        call lineout Out_file, Out_rec;
        If Debug = Yes then say Out_rec;
      end;

/*     when tape-trailer                                      */
     when Rec_type = '05' then do
        TapeTrailCnt = TapeTrailCnt + 1;
        P_Pack = substr(Rec_in,23,3);
        call Get_packed;
        TCount = P_char;
        P_Pack = substr(Rec_in,28,6);
        call Get_packed;
        TVal = P_char;
        P_Pack = substr(Rec_in,34,6);
        call Get_packed;
        TRec_cnt = P_char;
        Out_rec = Cust_no || Cust_suff || Branch || Account || TCount;
        Out_rec = Out_rec || TVal || TRec_cnt;
        Out_file = Directory||File_name||'.'||Rec_type;
        call lineout Out_file, Out_rec;
        If Debug = Yes then say Out_rec;
      end;

/*     when code-record                                       */
     when Rec_type = '99' then do;
        Ignore_count = Ignore_count + 1;
      end  /* Do */

     Otherwise
      Say 'Record type (' Rec_type ') not recognised - record ignored';
      Ignore_Count = Ignore_Count + 1;
/*   end-case                                                 */
   end;

/*   Read record                                              */
Next_rec:

   If Block_length < 1 then do;
      If Debug = Yes then call trace('i');
      Rec_length = Blksize - Char_read + 1;
      If Rec_length > 0 then Rec_in = charin(File_in,,Rec_length);
      Char_read = 0;
      If lines(File_in) then Rec_in = charin(File_in,,8);
      else do;
         End_of_file = Yes;
         Signal Control_print;
      end  /* Do */
      Char_read = Char_read + 8;
      Block_count = Block_count + 1;
      If Debug = Yes then say 'Block count =' Block_count;
      Rec_hex = '';
      Rec_hex = c2x(Rec_in);
      If Debug = Yes then Say 'Rec_hex =' Rec_hex;
      Block_length = c2d(substr(Rec_in,1,2))-8;
      Rec_length   = c2d(substr(Rec_in,5,2))-4;
      If Debug = Yes then Say 'Block length =' Block_length;
      If Debug = Yes then Say 'Rec length   =' Rec_length;
      Rec_in = charin(File_in,,Rec_length);
      Char_read = Char_read + Rec_length;
      Record_count = Record_count + 1;
      Block_length = Block_length - Rec_length;
      If Debug = Yes then call trace('n');
      If Debug = Yes then Say 'Remaining length of block =' Block_length;
   end  /* Do */
   else do;
      If Debug = Yes then say 'Block length =' Block_length;
      Rec_in = charin(File_in,,4);
      Char_read = Char_read + 4;
      If Debug = Yes then Say 'Length read =' length(Rec_in);
      Rec_hex = '';
      Rec_hex = c2x(Rec_in);
      If Debug = Yes then Say 'Rec_hex =' Rec_hex;
      Rec_length   = c2d(substr(Rec_in,1,2))-4;
      If Debug = Yes then Say 'Rec length   =' Rec_length;
      Rec_in = charin(File_in,,Rec_length);
      Char_read = Char_read + Rec_length;
      Record_count = Record_count + 1;
      If Debug = Yes then say 'Record No =' Record_count;
      If Debug = Yes then Say 'Char read   =' Char_read;
      If Debug = Yes then Say 'Length read =' length(Rec_in);
      Block_length = Block_length - Rec_length - 4;
      If Debug = Yes then Say 'Remaining length of block =' Block_length;
   end  /* Do */
end /* do */
/* Print control report                                       */
Control_print:
    Say 'CSR Bank Rconciliation System   -   Control Report';
    Say;
    Say 'Program: ' e_path||e_name||'.'||e_ext 'running under' opsys;
    Say 'Date run:' date();
    Say 'Time run:' time();
    Say;
    Say 'Customer Number:     ' Cust_no Cust_suff;
    Say 'Customer name:       ' Cust_name;
    Say 'Tape date:           ' Tape_date;
    Say;
    Say 'Blocks read         =' Block_count;
    Say 'Records read        =' Record_count;
    Say;
    Say 'Records ignored     =' Ignore_count;
    Say;
    Say 'Tape headers        =' TapeHeadCnt;
    Say 'Account headers     =' AccHeadCnt;
    Say 'Detail transactions =' AccDetCnt;
    Say 'Account trailers    =' AccTrailCnt;
    Say 'Tape trailers       =' TapeTrailCnt;
    Say;
    Say;
    Say '         ****  End of Report  ****';

/*---------------- End of Main processing --------------------*/

CLEANUP:

  If Debug = Yes then say 'At Cleanup...';
  If VRexxActive = Yes then Say 'Closing VRexx';
  If VRexxActive = Yes then call VExit;
  VRexxActive = No;

EndIt:

  If Debug = Yes then say 'At EndIt...';
  if debug = Yes then say 'Press Enter to continue...';
  if debug = Yes then pull nul;
  call directory  curdir
  endlocal

Exit;

/*========================================================*/
/* Start of internal subroutines, in alphabetical order   */
/*========================================================*/
AssembleDoc:  /* Assemble document from individual sections */
  If Debug = Yes then say 'At AssembleDoc...';

  JAss = 1;
  Out. = '';
  Do Section = 0 to SectMax;
    If Debug = Yes then say 'Assemble: Section =' Section;
    If Line.Section > 0 then do IAss = 1 to Line.Section;
      If (DocOut.Section.IAss = ' ') then JAss = JAss + 2;
      Else if substr(DocOut.Section.IAss, 1, 1) = '*' then JAss = JAss + 1;
      Out.JAss = Out.JAss || ' ' || DocOut.Section.IAss;
      MacroIn = Out.JAss;
      Call MacroRep;
      Out.JAss = space(MacroOut);
      If left(Out.JAss, 2) = '* ' then Out.JAss = insert(left(' ',Indent-2,' '),Out.JAss,2);
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

  If Debug = Yes then say 'At Copyright...';
  If bQuiet > 0 then return;
  msg.0 = 6;
  msg.1 = '               This product is copyright by';
  msg.2 = '             Consolidated Share Registrars Limited';
  msg.3 = '                    All rights are reserved.';
  msg.4 = '';
  msg.5 = '           Press OK to acknowledge the rights';
  msg.6 = '  of Consolidated Share Registrars.  Press Cancel to end.';

  call VDialogPos 50, 50;

  rb = VMsgBox('Copyright Message', msg, 3);
  if rb = 'OK' then nop;
  else signal CLEANUP;

Return;

/*------------------------------------------------------------*/

FNumb:  /* Format a number, with commas  */
parse arg numb
call comma
call concat
arg=newnum
return


/*---------------------------------------------------------------*/
Get_Packed:  /* Convert a packed decimal field to ASCII          */
             /* P_Pack - a field that contains a packed no       */
             /* P_Char - a field that contains the result        */
             /* P_Err  - zero if successful                      */
             /*          8 if P_Pack contained an invalid number */
  trace n;
  P_Err  = 8;
  P_Char = '';
  P_Len  = length(P_Pack);
  If (P_Len = 0) | (P_Len > 8) then return;
  P_Work = c2x(P_Pack);
  P_Sign = right(P_Work,1);
  If (P_Sign = 'C') | (P_Sign = 'F') then P_Sign = '0';
  else if P_Sign = 'D' then P_Sign = '-';
  P_Char = P_Sign || left(P_Work, P_Len * 2 - 1);
  If datatype(P_Char,'N') then P_Err = 0;

return;

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
  prompt.6 = 'Sex (M/F):';
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
    mirc = VMultBox(Heading, prompt, width, hide, answer, 3);
    If mirc \= 'OK' then signal CLEANUP;
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
    Sex      = Translate(answer.6);
    Directory= Translate(answer.7);
    Billing  = answer.8;
    FileOut  = Translate(answer.9);
    Parse upper var FileOut FileOutName '.' FileOutExt;
    FileOutName = space(FileOutName,0);
    FileOutExt  = space(FileOutExt,0);
    Heading = 'File Name is more than 8 characters';
    If length(FileOutName) > 8 then iterate;
    Heading = 'File Extension is more than 3 chars';
    If length(FileOutExt)  > 3 then iterate;
    If FileOutExt = '' then FileOutExt = 'DOC';
    If FileOutExt = 'ZIP' then do;
      FileOutExt = 'DOC';
      Compress = Yes;
    End;
    If left(Directory,1) \= '\' then Directory = '\' || Directory;
    FileSpec = Directory ||'\'|| FileOutName || '.' || FileOutExt;
    Heading = 'Sex should be M or F';
    If 0 = pos(Sex, 'MF') then iterate;
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
a=1
do a = 1 to 25
d.a=''
end

dmap = SysDriveMap('c:', 'LOCAL')
parse value dmap with d.1 d.2 d.3 d.4 d.5 d.6 d.7 d.8 d.9 d.10 d.11 d.12 d.13 d.14 d.15 d.16 d.17 d.18 d.19 d.20 d.21 d.22 d.23 d.24 D.25
FAT= 'NO'
HPFS= 'NO'
a=1
drive=d.a
do while d.a\=''
rc=SysMkDir(drive'\'muchtoolargeforFAT)
if rc=206  then do
    FAT = 'YES'
    Type.a = 'FAT'
    end
else do
        if rc=19 then Type.a = 'CD-ROM'
        else do;
        HPFS = 'YES'
        type.a = 'HPFS'
        call SysRmDir(drive'\'muchtoolargeforfat)
        end;end
dinfo.a=SysDriveInfo(d.a)
parse var dinfo.a d.a ":" free.a total.a label.a
pfree.a=free.a/total.a
pfree.a=100*pfree.a
pfree.a=trunc(pfree.a,2)
a=a+1
drive=d.a
end
return

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
    If NewWords.1 \= Warn.1 then do;
      Say 'Wrong version of MIWORDS.TXT';
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

      call VDialogPos 50, 50;

      rb = VMsgBox('Error in MIWords file:', msg, 3);
      if rb = 'OK' then iterate I;
        else signal CLEANUP;
      
    End; /* do */
    If left(TheWord.J,1) \= '&' then do;
      msg.  = '';
      msg.0 = 5;
      msg.1 = 'Line' I ': Keyword "' || TheWord.J || '" should start with "&".';
      msg.5 = 'It has been ignored.';

      call VDialogPos 50, 50;

      rb = VMsgBox('Error in MIWords file:', msg, 3);
      if rb = 'OK' then iterate I;
        else signal CLEANUP;
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

      call VDialogPos 50, 50;

      rb = VMsgBox('Error in MIWords file:', msg, 3);
      if rb = 'OK' then iterate I;
        else signal CLEANUP;
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
  setlocal

  /*********************************************************************
   * Find what our home directory is, and where we are being           *
   * executed from.                                                    *
   * We will also save the value of various environmental variables.   *
   *********************************************************************/
  curdir = directory()

  parse source opsys invoked myname;
/*  myname     = translate(myname); */
  e_drive    = left(myname,2)
  temp       = reverse(myname);
  ObjectName = myname;
  parse var temp e_ext'.'e_name'\'e_path;
  e_path     = reverse(e_path)'\'
  e_name     = reverse(e_name)
  e_ext      = reverse(e_ext)
  HomeBase   = 'RobC';
  Path       = value('PATH',,'OS2ENVIRONMENT')
  DPath      = value('DPATH',,'OS2ENVIRONMENT')
  Help       = value('HELP',,'OS2ENVIRONMENT')
  BookShelf  = value('BOOKSHELF',,'OS2ENVIRONMENT')
  BookMgr    = value('BOOKMGR',,'OS2ENVIRONMENT')
  ReadIBM    = value('READIBM',,'OS2ENVIRONMENT')
  MyEnv      = value(e_name,,   'OS2ENVIRONMENT');
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
MacroRep:  /* Replace symbolic parameters in the document    */
           /*   by the details (e.g. Name) captured earlier. */
    If ChangedCount = 'CHANGEDCOUNT' then ChangedCount = 0;
    If ChangedCount < 0 then call trace('r');
    If Debug = Yes then say 'Start of MacroRep';
    MacroOut = '';
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
      If Debug = Yes then call trace('r');
      Do L = 1 to NewWords.0 while(WordLen = 0);
         If Debug = Yes then say Keyword '=' TheWord.L Sex '=' WSex.L Level '=' WLevel.L Industry '=' WInd.L;
         If abbrev(KeyWord, TheWord.L) then if (Sex = WSex.L | WSex.L = '$') then if (pos(Level, WLevel.L)>0 | WLevel.L = '$') then if (pos(Industry, WInd.L)>0 | WInd.L  = '$') then do;
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
         J = 0;
         If Debug = Yes then nop;
      end;  /* Do */
    End; /* do */
    MacroOut = Rest;
    If Debug = Yes then say 'End of MacroRep';

Return;


/*------------------------------------------------------------*/
Parameters:  /* Handle default options and parameters passed to us... */

  miCat    = 'MICAT.CTL';
  bQuiet   = No;
  Skel     = 'MIREP.TXT';
  miWords  = 'MIWORDS.TXT';
  Print    = No;
/*  Debug    = No; */
  Compress = No;
  Indent   = 5;
  LineLen  = 60;
  Align    = No;
  Do I = 1 to words(ProcOpts);

    work = word(ProcOpts, I);
    parse var work Keyword '=' parm;
    parm = strip(parm);
    If Debug = Yes then nop;
    Select
      when Keyword = 'MICAT' then miCat = parm;
      when Keyword = 'MIWORDS' then miWords = parm;
      when Keyword = 'QUIET' then If left(parm,1) = 'Y' then bQuiet = Yes;
      when Keyword = 'SKEL' then Skel = parm;
      when Keyword = 'PRINT' then If left(parm,1) = 'Y' then Print = Yes;
      when Keyword = 'DEBUG' then If left(parm,1) = 'Y' then Debug = Yes;
      when Keyword = 'INDENT' then Indent = parm;
      when Keyword = 'LINELEN' then LineLen = parm;
      when Keyword = 'BLKSIZE' then Blksize = parm;
      when Keyword = 'FNAME' then do;

        fname      = translate(parm);
        fdrive     = left(fname,2)
        temp       = reverse(fname);
        parse var temp File_ext'.'File_name'\'Directory;
        Directory  = reverse(Directory)'\'
        File_name  = reverse(File_name)
        File_ext   = reverse(File_ext)
        File_in    = Directory || File_name || '.' || File_ext;

      end  /* Do */
      otherwise;
        msg.1 = 'Parameter' word(ProcOpts, I) 'is not recognised';
        msg.2 = 'and has been ignored.';
        msg.0 = 2;
        do j = 1 to msg.0;
           Say msg.j;
        end /* do */
    end;  /* select */
  end; /* do */

Return;

/*------------------------------------------------------------*/
PrintDoc:
  If Print = Yes then 'Print' FileSpec;
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
  If In.1 \= Warn.1 then do;
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
 
  NewOut. = '';
  Line = 0;
  Do I = 1 to Out.0;
    Rest    = Out.I;
    If Debug = Yes then say 'Out.'||I '=' Rest;
    Star = left(Rest, 1);
    J = LineLen;
    Line = Line + 1;
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
    If Star = '*' then LStart = 3;
    Else LStart = 2;
    LEnd = words(NewOut.Line);
    LIncr = 1;
    Direction = -1;
  End;
  Else do;
    LStart = Words(NewOut.Line);
    If Star = '*' then LEnd = 3;
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
msg.4  = cr5 cr5' ³ Standard Bank Tape Conversion  ³'
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
  'cd \MI';
  Out. = '';
  Out.1 = Billing date() FileSpec Title Initials Surname;
  Out.0 = 1;
  mi_rc = PrxWriteFromStem('BILL.RCD','Out',Out.0,1,'Append');
Return;

/*------------------------------------------------------------*/
WriteDoc:
  'cd' Directory;
  If NewOut.0 > 0 then mi_rc = PrxWriteFromStem(FileSpec,'NewOut',NewOut.0,1,'Replace');
/*  If NewOut.0 > 0 then 'command /k c:\wp51\wp.exe' FileSpec;*/

Return;

/*------------------------------------------------------------*/
ZipDoc:
  'cd' Directory;
  'PKZip' FileOutName FileSpec;
Return;

