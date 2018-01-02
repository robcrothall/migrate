/* */
/*Purpose:      Create a translated copy of a text file

 Client:        Management Insight CC
 Date written:  June 1991
 Author:        Rob Crothall & Associates
 Copyright:     Copyright (1993) by Management Insight CC, South Africa.
                All rights reserved.

 Return codes:  Rc=1   If arg1=? - Request for info.
                Rc=9   If invalid parms.

 Written by:    Rob Crothall   Date: Nov 1993
 Changed by:    Rob Crothall   Date:          To:
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

/* Debug = Yes; */
 
Call RxFuncAdd 'VInit', 'VREXX', 'VINIT';
mi_rc = VInit();
Say 'VRexx initialisation =' mi_rc;

Say 'VRexx version' VGetVersion();
If Debug = Yes then Say 'Press Enter to continue..';
If Debug = Yes then nop;
 
Call Parameters;
Call Copyright;
'cd \misource';
Call GetCategory;
Warn. = '';
Warn.1 = 'Restricted - property of Management Insight';
Section = 0;
CatTitle = 'Select Category for conversion';
/* Now display the filename and description for selection */
Do forever; /* ...or at least until they select the CANCEL button... */
TryNext:
  Reject = No;
  mi_rc = '';
  mi_rc = vlistbox(CatTitle, Cat, 35, 14, 3);
  If mi_rc = 'CANCEL' then do;
    BoxTitle = 'Exit confirmation';
    msg.0 = 5;
    msg.1 = 'The selected files have been copied to \MIPROD';
    msg.2 = '  in a format suitable for distribution.';
    msg.3 = '';
    msg.4 = 'Press OK to end.';
    msg.5 = 'Press CANCEL to select another Category.';

    call VDialogPos 50, 50;

    rb = VMsgBox(BoxTitle, msg, 3);
    if rb = 'OK' then signal GENERATE;
    else iterate;
  End;
  Driver. = '';
  Category = word(Cat.vstring,1);
  CatTitle = 'Selected' Category;
  'cd \misource';
  mi_rc = PrxReadToStem(Category, 'In');
  If In.1 = Warn.1 then do;
    msg.0 = 4;
    msg.1 = 'This Category has already been converted.';
    msg.2 = '';
    msg.3 = '';
    msg.4 = 'Please check your directories!';

    call VDialogPos 50, 50;
    rb = VMsgBox('Critical Error', msg, 2);
    signal CLEANUP;
  end  /* Do */
  DrNo = 0;
  Say Category 'selected for translation...';
  DrvName. = 0;
  Do I = 1 to In.0;  /* Check drivers from Category file */
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
              Reject = Yes;
              call VDialogPos 50, 50;
              rb = VMsgBox('Critical Error', msg, 3);
              if rb = 'CANCEL' then signal CLEANUP;
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
    In.I = translate(In.I, a, b);
    In.I = reverse(In.I);
  End;
  if Reject = No then do;
    'cd \miprod';
    mi_rc = PrxWriteFromStem(Category, 'Warn', 1, 1, 'Replace');
    mi_rc = PrxWriteFromStem(Category, 'In', In.0, 1, 'Append');
    Say Category 'has been successfully translated.';
    'copy' Category 'D:\max\file\mmuk';
end;
  else say Category 'has been REJECTED';
End;

GENERATE:

CLEANUP:
  Say 'That''s all, folks!';
  call VExit;

EndIt:

Exit;


/*------------------------------------------------------------*/
Copyright:

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
  b=reverse(b);
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
  trace o;
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
  If Debug = Yes then Say 'Number of files found:    ' K;
  If Debug = Yes then Say 'Cat.0 =' Cat.0;
  If Debug = Yes then Do K = 1 to Cat.0;
     Say 'Found:' Cat.K;
  end; /* do */
Return;
/*------------------------------------------------------------*/
Parameters:  /* Handle default options and parameters passed to us... */

  miCat    = 'MICAT.CTL';
  bQuiet   = No;
  Skel     = 'MIREP.TXT';
  miWords  = 'MIWORDS.TXT';
  a='abc0def1gh2ij3kl4mn5op6qr7st8uv9wx.yz,&*ABCDEFGHI=JKLMNOPQRSTUVWXYZ';
  Print    = No;
  Debug    = No;
  Compress = No;
  Indent   = 5;
  LineLen  = 65;
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
Return;
c='f1gh2iskfu,s;dj3kl4mn5op6qr7st8uv9wx.yz,&*ABCDEFGHI=JKLKHGFKHJFGMNO';

