/* DESCRIPTION: Display a menu of options (read from a parameter file) */
/*              and execute the command associated with the selected   */
/*              option.                                                */
/*                                                                     */
/* ARGUMENTS: 1. Name of the parameter file.  Default filename         */
/*               is "MENU", and default filetype is "SCRIPT".          */
/*                                                                     */
/* RECORDS STACKED/ RETURN CODES/ ERROR CONDITIONS:                    */
/*                                                                     */
/* Rc=1 If arg1=? - Request for info.                                  */
/*                                                                     */
/* WRITTEN BY: R Crothall   DATE: Dec 90                               */
/* CHANGED BY:              DATE:        TO:                           */

Parse source . . name .;
If arg(1)='?' then do  /* Display comment info if 1st arg = ? and Exit */
   Say; Say name; Say;
   Do n=1
      line=sourceline(n); If left(line,2)^='/*' then exit 1; Say line;
      End
   End

Trace Off
Parse Arg fname ftype fmode .;
zcontrol = 'ZFABATCH';
/*                                                                     */
/* Find out who we are and the ID of RSCS...                           */
'id (stack lifo)';
if queued() > 0 then pull zvmid . znode . zrscs .;
/*                                                                     */
/* Set up default menu name, if parameter was not passed...            */
if fname = ' ' then fname = zvmid;
if ftype = ' ' then ftype = 'SCRIPT';
if fmode = ' ' then fmode = '*';
/*                                                                     */
/* Check that the menu description file exists...                      */
state fname ftype fmode
if rc > 0 then do;
  say 'Parameter file' fname ftype fmode 'not found';
  'sleep 5 sec';
  fname = name;
  state fname ftype fmode
  if rc > 0 then do;
     say 'Parameter file' fname ftype fmode 'not found';
     'sleep 5 sec';
     exit rc;
  end;
end;
/*  Stack the contents of the file    */
cmd. = '';
Text. = '';
Data. = '';
'execio * diskr' fname ftype fmode '1 (stem DATA.';
if datatype(Data.0) ^= 'NUM' then Data.0 = 0;
Title = 'Application Menu';
Footer = 'Type the number of the selected option and press Enter';
options = 0;
do i = 1 to Data.0;
  parse var Data.i first '$' last;
  first = strip(first);
  select
    when substr(first,1,1) = '*' then nop;
    when translate(first) = 'TITLE' then Title = strip(last);
    when translate(first) = 'FOOTER' then Footer = strip(last);
    otherwise;
         options = options + 1;
         cmd.options = first;
         Text.options = strip(last,t);
  End;
End;
/*                                                                     */
/* Check that the menu description file exists...                      */
Head = zvmid 'at' znode '-' time() 'on' date();
Error = '';
Do forever;
  'clrscrn';
  say centre(Title,linesize());
  say centre(Head,linesize()); say;
  do i = 1 to options;
    say right(I,3) Text.i;
  end;
  If Error ^= '' then do;
    Say;
    Say copies('-',linesize()-3);
    Say 'Text entered =' selection;
    Say Error;
    Say copies('-',linesize()-3);
  end;
  Say; Say Footer;
  Say '(Enter 0 to exit)';
  pull selection .;
  Error = '';
  Select;
    when selection = '' then do;
      'clrscrn';
      exit;
      end;
    when datatype(selection) ^= 'NUM'
      then Error = 'Please enter a number between 0 and' options;
    when selection = 0 then do;
      'clrscrn';
      exit selection;
      end;
    when selection > options
      then Error = 'Please enter a number between 0 and' options;
    when selection < 1 then signal Numentry;
    otherwise  /* Execute the command */
      Say 'About to execute command:' cmd.selection;
      cmd.selection;
      rcc = rc;
      Say 'Return code =' rcc;
      If rcc ^= 0 then do;
        say 'Execution was not successful';
        'sleep 5 sec';
        End;
  End;
End;
exit;
