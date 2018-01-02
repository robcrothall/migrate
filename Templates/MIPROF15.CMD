/* */
 /*Purpose:      Create a personality profile based on clinical evaluation
 
 Client:        Management Insight CC
 Date written:  June 1991
 Author:        Consolidated Share Registrars Limited
 Copyright:     Copyright (1993) by Management Insight CC, South Africa.
                All rights reserved.
 
 Arguments:     These are in the form KEYWORD=...  KEYWORD2=...
                Separate the end of one parameter from the next with a space.

   MICAT=filespec  Use this file to associate industry classifications and
                   descriptions with the files in the current directory for
                   selecting categories.  If this file is not specified, the
                   default will be 'MICAT.CTL' in the current directory.  If the
                   file is not found, it is created.
                                                                  
   QUIET=YES | NO  Suppresses copyright messages and other information displays.

   SKEL=MIREP.TXT  Skeleton file that will be used as a base on which to build
                   the report.  Default is MIREP.TXT.

   MIWORDS=MIWORDS.TXT  File containing User-defined keywords which are
                        replaced by a word or a phrase.

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
                Get details of the Client and the Subject.
                Read in the document skeleton selected by parameter.
                Read the current directory and descriptions of the files
                  (Categories) found.  Ignore those which do not belong to
                  the specified Industry or 'All Industries'.
                Offer the Categories for selection until CANCEL button
                  is pressed.  For each Category selected, offer 'Drivers'
                  for selection.  For each Driver selected, save the associated
                  text in the appropriate Section of the final document.
                Assemble the selected text into the correct sequence.
                Tailor the document by replacing keywords in the text by
                  Subject-specific details (e.g. name, title, etc).
                Write the completed document as ASCII text to the directory
                  specified.
                Print a copy of the text, if required.
                Compress the file using PKZIP, if required.
                Add a description to the FILES.BBS bulletin board index.
                Tidy up and return to the Workplace Shell.
                                                          
 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Written by:    Rob Crothall   Date: May 1993
 Changed by:    Rob Crothall   Date: Sep 1993 To: Add replaceably words
                                                  which depend on industry
*/

/* Set options that help during debugging */
'@echo off';
rc = 0;
MI_RC = 0;
trace o;
Warn. = '';
Warn.1 = 'Restricted - property of Management Insight';
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

/* Debug = Yes; */
trace o;
Call RxFuncAdd 'VInit', 'VREXX', 'VINIT';
mi_rc = VInit();
Say 'VRexx initialisation =' mi_rc;

Say 'VRexx version' VGetVersion();
If Debug = Yes then Say 'Press Enter to continue..';
If Debug = Yes then nop;
trace o;
/*------------- Main processing ------------------------------*/

Call Parameters;
Call Copyright;
Call GetWords;
Call GetDetails;
Call SetUpDoc;
Call GetCategory;

Section = 0;
CatTitle = 'Select First Category';
/* Now display the filename and description for selection */
Do forever; /* ...or at least until they select the CANCEL button... */
  mi_rc = vlistbox(CatTitle, Cat, 35, 14, 3);
  If mi_rc = 'CANCEL' then do;
    BoxTitle = 'Exit confirmation';
    msg.0 = 5;
    msg.1 = 'Are you ready to generate the report';
    msg.2 = '  for' Title Initials Surname||'?'
    msg.3 = '';
    msg.4 = 'Press OK to start generating the document.';
    msg.5 = 'Press CANCEL to select another Category.';

    call VDialogPos 50, 50;

    rb = VMsgBox(BoxTitle, msg, 3);
    if rb = 'OK' then signal GENERATE;
    else iterate;
  End;
  Driver. = '';
  Category = word(Cat.vstring,1);
  CatTitle = 'Selected' Category;
  mi_rc = PrxReadToStem(Category, 'In');
  If In.1 \= Warn.1 then do;
      Say 'Wrong version of Category file';
      Signal CLEANUP;
  End;
  DrNo = 0;
  DrvName. = 0;
  Do I = 2 to In.0;  /* Select drivers from Category file */
    In.I = translate(In.I, b, a);
    In.I = reverse(In.I);
    Do J = 1 to words(In.I);
      work = word(In.I, J);
      work = Translate(work);
      If left(work, 1) = '&' then do;
        Parse var work Keyword '=' value;
        Select;
          When Keyword = '&DRIVER' then do;
            If Debug = Yes then trace o;
            temp = Driver.DrNo;
            DrEnd.temp = I - 1;
            DrNo = DrNo + 1;
            If DrvName.value = 0 then do;
              DrvName.value = 1;
              If Debug = Yes then say 'Driver =' value;
            End;
            Else do;
              msg.0 = 4;
              msg.1 = 'Driver named "' || value || '" has been';
              msg.2 = 'duplicated within Category "' || Category || '"';
              msg.3 = '';
              msg.4 = 'Please fix the problem and start again.';

              call VDialogPos 50, 50;
              rb = VMsgBox('Critical Error', msg, 2);
              signal CLEANUP;
            End;
            Driver.DrNo = value;
            DrStart.value = I;
            If Debug = Yes then trace o;
          End;
          Otherwise;
            Nop;
        End;
      End;
    End;
  End;
  If Debug = Yes then trace o;
  temp = Driver.DrNo;
  DrEnd.temp = In.0;
  Driver.0 = DrNo;
  sel.  = '';
  sel.0 = 0;
  mi_rc = 'OK';
  DrvTitle = 'Select first driver';

  Do while (mi_rc = 'OK');
    mi_rc = vlistbox(DrvTitle, Driver, 60, 14, 3);
    If mi_rc = 'CANCEL' then leave;
    temp = Driver.vstring;
    DrvTitle = 'Selected' temp;
    Do L = DrStart.temp to DrEnd.temp;
      Do J = 1 to words(In.L);
        work = word(In.L, J);
        work = Translate(work);
        If left(work, 1) = '&' then do;
          Parse var work Keyword '=' value;
          Select;
            When Keyword = '&SECTION' then do;
              Section = value;
              If Section > SectMax then SectMax = Section;
              If Debug = Yes then In.L = Category ':' Driver.vstring ':' In.L;
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
  End;
End;

GENERATE:

Call AssembleDoc;
Call TailorDoc;
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

/* Display completion message */
msg.0 = 4;
msg.1 = 'The personality profile was written to file:';
msg.2 = ' ';
msg.3 = FileOutName||'.'||FileOutExt;
msg.4 = 'in directory' Directory;

call VDialogPos 50, 50;

rb = VMsgBox('End of generation', msg, 1);
if rb = 'OK' then nop;
else signal CLEANUP;

/*---------------- End of Main processing --------------------*/

CLEANUP:
  Say 'That''s all, folks!';
  call VExit;

EndIt:
  'cd \mi';
Exit;

/*========================================================*/
/* Start of internal subroutines, in alphabetical order   */
/*========================================================*/
AssembleDoc:  /* Assemble document from individual sections */
  If Debug = Yes then trace o;
  J = 1;
  Out. = '';
  Do Section = 0 to SectMax;
    If Debug = Yes then say 'Assemble: Section =' Section;
    If Line.Section > 0 then do I = 1 to Line.Section; 
      If (DocOut.Section.I = ' ') then J = J + 2;
      Else if substr(DocOut.Section.I, 1, 1) = '*' then J = J + 1;
      Out.J = Out.J || ' ' || DocOut.Section.I;
      Out.J = space(Out.J);
      If left(Out.J, 2) = '* ' then Out.J = insert(left(' ',Indent-2,' '),Out.J,2);
      If Debug = Yes then say 'Assemble: J =' J 'Out =' Out.J;
    End;
  End;
  Out.0 = J;
  If Debug = Yes then trace o;
Return;

/*------------------------------------------------------------*/
Copyright:

  b=reverse(b);
  If bQuiet > 0 then return;
  If Debug = Yes then trace o;
  msg.0 = 6;
  msg.1 = '               This product is copyright by';
  msg.2 = '                  Management Insight CC.';
  msg.3 = '                    All rights are reserved.';
  msg.4 = '';
  msg.5 = '           Press OK to acknowledge the rights';
  msg.6 = '  of Management Insight CC.  Press Cancel to end.';

  call VDialogPos 50, 50;

  rb = VMsgBox('Copyright Message', msg, 3);
  if rb = 'OK' then nop;
  else signal CLEANUP;
  If Debug = Yes then trace o;

Return;

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

  If Debug = Yes then trace o;
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
If Debug = Yes then trace o;
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
Parameters:  /* Handle default options and parameters passed to us... */

  miCat    = 'MICAT.CTL';
  bQuiet   = No;
  Skel     = 'MIREP.TXT';
  miWords  = 'MIWORDS.TXT';
  Print    = No;
  Debug    = No;
  Compress = No;
  Indent   = 5;
  LineLen  = 65;
  a='abc0def1gh2ij3kl4mn5op6qr7st8uv9wx.yz,&*ABCDEFGHI=JKLMNOPQRSTUVWXYZ';
  Do I = 1 to words(ProcOpts);
    If Debug = Yes then trace o;
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
      otherwise;
        msg.1 = 'Parameter' word(ProcOpts, I) 'is not recognised';
        msg.2 = 'and has been ignored.';
        msg.0 = 2;
        rb = VMsgBox('Parameter error?', msg, 3);
        If rb = 'CANCEL' then signal CLEANUP;
    end;  /* select */
  end; /* do */
If Debug = Yes then trace o;
b='f1gh2ij3kl4mn5op6qr7st8uv9wx.yz,&*ABCDEFGHI=JKLMNOPQRSTUVWXYZabc0de';
c='f1gh2iskfu,s;dj3kl4mn5op6qr7stuv9wx.yz,&*=ABCDEFGHI=JKLKHGFKHJFGMNO';
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
TailorDoc:  /* Replace symbolic parameters in the document    */
            /*   by the details (e.g. Name) captured earlier. */

  If Debug = Yes then say 'Start of TailorDoc';
  NewOut. = '';
  Line = 0;
  Do I = 1 to Out.0;
    Rest    = Out.I;
    If Debug = Yes then say 'Out.'||I '=' Rest;
    KStart  = 1;
    WordLen = 0;
    WordRep = '';
    Changed = No;
    J = 0;
    JMax = 0;
    Do while((J < words(Rest)) & (JMax < 100000));
      /* Find a target string starting with '&' */
      J = J + 1;
      JMax = JMax + 1;
      If Debug = Yes then say 'Rest =' Rest;
      If Debug = Yes then say 'J =' J '    JMax =' JMax;
      Target = word(Rest, J);
      If left(Target, 1) \= '&' then iterate;
      If length(Target) < 2 then iterate;
      parse var Target Keyword '=' Value;
      KStart = wordindex(Rest, J);
      KLength = length(Target);
      KeyWordUp = Translate(Target);
      If Debug = Yes then nop;
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
      If Debug = Yes then nop;
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
         If Debug = Yes then trace o;
         Changed = Yes;
         If (WordRep = '') & (KStart > 1) then do;
            KStart = KStart - 1;
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
    If Changed = Yes then if (Rest = '' | Rest = ' ') then iterate;
    Star = left(Rest, 1);
/*************************************    Rest = Rest || ' ';*/
    J = LineLen;
    Do LineSeg = 1 to 1000;
      Line = Line + 1;
      If Lineseg = 1 then do;
        If length(Rest) <= LineLen then do;
          NewOut.Line = Rest;
          Rest = '';
        End;
        Else do;
          J = lastpos(' ', Rest, Linelen);
          NewOut.Line = left(Rest, J);
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
               NewOut.Line = left(' ', Indent, ' ') || left(Rest, J);
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
               NewOut.Line = left(Rest, J);
               Rest = substr(Rest, J+1);
             End;
           End;
      If length(Rest) = 0 then leave;
    End;
  End I; /* do */
  NewOut.0 = Line;
  If Debug = Yes then say 'End of TailorDoc';
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
  If Debug = Yes then trace o;
  'cd' Directory;
  If NewOut.0 > 0 then mi_rc = PrxWriteFromStem(FileSpec,'NewOut',NewOut.0,1,'Replace');
/*  If NewOut.0 > 0 then 'command /k c:\wp51\wp.exe' FileSpec;*/
  If Debug = Yes then trace o;
Return;

/*------------------------------------------------------------*/
ZipDoc:
  'cd' Directory; 
  'PKZip' FileOutName FileSpec;
Return;

