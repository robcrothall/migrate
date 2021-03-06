/*Purpose:      Create a personality profile based on clinical evaluation
 
 Client:        Management Insight CC
 Date written:  June 1991
 Author:        Consolidated Share Registrars Limited
 Copyright:     Copyright (1993) by Management Insight CC, South Africa.
                All rights reserved.
 
 Arguments:     These are in the form KEYWORD=...  KEYWORD2=...
                Separate the end of one parameter from the next with a space.

   QUIET=YES | NO  Suppresses copyright messages and other information displays.

   PRINT=YES | NO  The generated report should be printed as soon as it is ready.
                   Default is YES.

   DEBUG=YES | NO  Various sections are traced when this is set to Yes.
                   Default is NO.

 Processing:    Initialise, including display of these comments if invoked
                  with a paramete of '?'.  Prepare to handle exception
                  conditions, if they arise.  Ensure that utility functions 
                  are loaded.
                Process keyword parameters passed to the program.
                Display copyright information and get acknowledgement.
                Get details of the FROM and TO directories.
                Read the FROM directory and descriptions of the files
                  found.
                Offer the files for selection until CANCEL button
                  is pressed.  For each file selected, confirm the move command
                  and move it.
                Print a report of the files moved.
                Compress the file using PKZIP, if required.
                Add a description to the FILES.BBS bulletin board index.
                Tidy up and return to the Workplace Shell.
                                                          
 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Written by:    Rob Crothall   Date: June 1993
 Changed by:                   Date:          To:
*/

/* Set options that help during debugging */
'@echo off';
rc = 0;
MI_RC = 0;
trace o;
arg ProcOpts;

/* Define some constants... */
Yes = 1;
No = 0;

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

/* For those who start this from an OS/2 Full Screen session... */
say 'Use Ctrl-Esc to see the windows...';

/* Handle programming errors in a reasonable way... */
Signal on failure name CLEANUP;
Signal on halt name CLEANUP;
Signal on syntax name CLEANUP;

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
Say PrxUtilsVersion();

Call RxFuncAdd 'VInit', 'VREXX', 'VINIT';
mi_rc = VInit();
Say 'VRexx initialisation =' mi_rc;
If mi_rc = 'ERROR' then signal EndIt;
Say 'VRexx version' VGetVersion();

/*------------- Main processing ------------------------------*/

Call Parameters;
Call Copyright;
Call GetDetails;
Call GetFiles;

Section = 0;
/* Now display the filename and description for selection */
Do forever; /* ...or at least until they select the CANCEL button... */
  mi_rc = vlistbox('Select file to be moved', Cat, 35, 14, 3);
  If mi_rc = 'CANCEL' then leave;
  File = word(Cat.vstring,1);
  'move' File Target;
 
End;
Call WriteDoc;
If Print = Yes then call PrintDoc;
If Compress = Yes then call ZipDoc;
Call WriteBilling;

/* Now keep the FILES.BBS file up to date... */
Out. = '';
Out.0 = 1;
Out.1 = FileOutName||'.'||FileOutExt Title Initials Surname;
If Compress = Yes then do;
  Out.2 = FileOutName||'.ZIP' Title Initials Surname;
  Out.0 = Out.0 + 1;
End;
mi_rc = PrxWriteFromStem('FILES.BBS', 'Out', Out.0, 1, 'Append');
/* Force any other files into FILES.BBS */
Call BBS;

/*---------------- End of Main processing --------------------*/

CLEANUP:
  call VExit;

EndIt:
  'cd \mi';
Exit;

/*========================================================*/
/* Start of internal subroutines, in alphabetical order   */
/*========================================================*/
AssembleDoc:  /* Assemble document from individual sections */
  If Debug = yes then trace o;
  J = 0;
  Out. = '';
  Do Section = 0 to SectMax;
    If Debug = Yes then say 'Assemble: Section =' Section;
    If Line.Section > 0 then do I = 1 to Line.Section; 
      J = J + 1;
      Out.J = DocOut.Section.I;
      If Debug = Yes then say 'Assemble: J =' J 'Out =' Out.J;
    End;
  End;
  Out.0 = J;
  If Debug = Yes then trace o;
Return;

/*------------------------------------------------------------*/
Copyright:
  If bQuiet > 0 then return;

  msg.0 = 5;
  msg.1 = '      This product is copyright by';
  msg.2 = '          Management Insight CC.';
  msg.3 = '         All rights are reserved.';
  msg.4 = '';
  msg.5 = '     Press OK to acknowledge the rights';
  msg.6 = 'of Management Insight CC.  Press Cancel to end.';

  call VDialogPos 50, 50;

  rb = VMsgBox('Copyright Message', msg, 3);
  if rb = 'OK' then nop;
  else signal CLEANUP;
Return;

/*------------------------------------------------------------*/
GetCategory:
  retcd = PrxReadToStem(miCat, 'OldFiles');
  OldDesc. = '';
  If OldFiles.0 = 'OLDFILES.0' then say 'No previous' miCat 'file found';
    else do I = 1 to OldFiles.0;
       Parse var OldFiles.I OldFn OldDesc.OldFn;
    end  /* Do */
  Say 'Result is:' retcd;
  Say 'Number of old file descriptions returned:' OldFiles.0;
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
GetDetails:
  /* Ask for details of this profile, and set up variables... */
  prompt. = '';
  prompt.0 = 9;
  prompt.1 = 'Industry:';
  prompt.2 = 'Level:';
  prompt.3 = 'Title (e.g. Mrs):';
  prompt.4 = 'Initials/First name:';
  prompt.5 = 'Surname:';
  prompt.6 = 'Sex (M/F):';
  prompt.7 = 'Directory:';
  prompt.8 = 'Billing code:';
  prompt.9 = 'Filename:';

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

  If Debug = Yes then trace r;
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
      If (answer.I = '') then Iterate;  
    End;
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
    /* If Directory\FILES.BBS does not exist, ensure that \MAX\FILEAREAS.CTL
         is updated.  Run SILT in another session. */
    /* Check that FileOut does not exist in Directory */
    /* Check that Billing is valid */
    Correct = Yes;
  End;
If Debug = Yes then trace o;
Return;


/*------------------------------------------------------------*/
Parameters:  /* Handle default options and parameters passed to us... */

  miCat = 'MICAT.CTL';
  bQuiet = No;
  Skel = 'MIREP.TXT';
  Print = No;
  Debug = No;
  Compress = No;
  Do I = 1 to words(ProcOpts);
    If Debug = Yes then trace r;
    work = word(ProcOpts, I);
    parse var work Keyword '=' parm;
    parm = strip(parm);
    If Debug = Yes then pull ans;
    Select
      when Keyword = 'MICAT' then miCat = parm;
      when Keyword = 'QUIET' then If left(parm,1) = 'Y' then bQuiet = Yes;
      when Keyword = 'SKEL' then Skel = parm;
      when Keyword = 'PRINT' then If left(parm,1) = 'Y' then Print = Yes;
      when Keyword = 'DEBUG' then If left(parm,1) = 'Y' then Debug = Yes;
      otherwise;
        msg.1 = 'Parameter' word(ProcOpts, I) 'is not recognised';
        msg.2 = 'and has been ignored.';
        msg.0 = 2;
        rb = VMsgBox('Parameter error?', msg, 3);
        If rb = 'CANCEL' then signal CLEANUP;
    end;  /* select */
  end; /* do */
If Debug = Yes then trace o;
trace o;
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
  InSect  = 0;
  Sect    = 0;
  Section = 0;
  SectMax = 0;
  Line.   = 0;
  Do I = 1 to In.0;
    Do J = 1 to words(In.I);
      work = word(In.I, J);
      If left(work, 1) = '&' then do;
        Parse var work Keyword '=' value;
        Select;
          When Keyword = '&SECTION' then do;
            Section = value;
            W1 = wordindex(In.I, J) - 1;
            W2 = wordindex(In.I, J+1);
            If W2 > W1 then In.I = substr(In.I, 1, W1) || substr(In.I, W2);
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
TailorDoc:  /* Replace symbolic parameters in the document    */
            /*   by the details (e.g. Name) captured earlier. */
  Do I = 1 to Out.0;
    Rest    = Out.I;
    Out.I   = '';
    Do while (Rest \= ' ');
      /* Find a target string starting with '&' */
      Parse var Rest First '&' Target' 'Rest;
      If left(Rest, 1) \= '&' then Rest = ' ' || Rest;
      Out.I = Out.I || First;                  
      If Target = '' then Leave;               /* nothing more to do... */
      Punct = right(Target, 1);                /* handle punctuation */
      If pos(Punct, ',.;:)!') > 0 then do; 
        TargetLength = length(Target) - 1;
        Target = substr(Target, 1, TargetLength);
      End;
      Else Punct = '';
      Parse var Target KeyWord '=' Value;      /* extract the keyword & value */
      KeyWordUp = Translate(KeyWord);
      Select;
        When KeyWordUp = 'DRIVER' then iterate;  
        When KeyWordUp = 'SECTION' then iterate;
        When KeyWordUp = 'TITLE' then Out.I = Out.I || Title || Punct;
        When KeyWordUp = 'INITIALS' then Out.I = Out.I Initials || Punct;
        When KeyWordUp = 'SURNAME' then Out.I = Out.I Surname || Punct;
        When KeyWord   = 'Her' & Sex = 'F' then Out.I = Out.I || 'Her' || Punct;
        When KeyWord   = 'her' & Sex = 'F' then Out.I = Out.I || 'her' || Punct;
        When KeyWord   = 'Her' & Sex = 'M' then Out.I = Out.I || 'His' || Punct;
        When KeyWord   = 'her' & Sex = 'M' then Out.I = Out.I || 'him' || Punct;
        When KeyWord   = 'She' & Sex = 'F' then Out.I = Out.I || 'She' || Punct;
        When KeyWord   = 'she' & Sex = 'F' then Out.I = Out.I || 'she' || Punct;
        When KeyWord   = 'She' & Sex = 'M' then Out.I = Out.I || 'He' || Punct;
        When KeyWord   = 'she' & Sex = 'M' then Out.I = Out.I || 'he' || Punct;
        When KeyWordUp = 'HERSELF' & Sex = 'F' then Out.I = Out.I || 'herself' || Punct;
        When KeyWordUp = 'HERSELF' & Sex = 'M' then Out.I = Out.I || 'himself' || Punct;
        When KeyWordUp = 'DATE' then Out.I = Out.I || date('L') || Punct;
        Otherwise;
          Out.I = Out.I || '& ';               /* stand-alone '&' */
          If Value \= '' then Rest = KeyWord || '=' || Value Rest;
          Else Rest = KeyWord Rest;
      End; /* select */
    End; /* do */  
  End; /* do */  
Return;

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
  If Debug = Yes then trace r;
  'cd' Directory;
  If Out.0 > 0 then mi_rc = PrxWriteFromStem(FileSpec,'Out',Out.0,1,'Replace');
/*  If Out.0 > 0 then 'command /k c:\wp51\wp.exe' FileSpec;*/
  If Debug = Yes then trace o;
Return;

/*------------------------------------------------------------*/
ZipDoc:
  'cd' Directory; 
  'PKZip' FileOutName FileSpec;
Return;

