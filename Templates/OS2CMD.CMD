/****************************************************************************/
/* Program Header Information                                               */
/* Copyright:       Rob Crothall                                            */
/* Name:            OS2CMD.CMD                                              */
/* Written By:      Rob Crothall                                            */
/* Date:            20/08/93                                                */
/* Platform:        OS/2                                                    */
/* Version:         1.0                                                     */
/* Requires:        OS/2 > 2.0                                              */
/*                  VREXX20 program                                         */
/*                  PrxUtils                                                */
/* Description:     PM interface for selected OS/2 commands                 */
/*                      This release does not accept parameters, nor does   */
/*                      it allow the user to do anything other than execute */
/*                      the commands offered                                */
/* Modifications:   20/08/93 RJC Initial Program                            */
/*                                                                          */
/* Input:           None                                                    */
/*                                                                          */
/* Constants:       Netcmd1:  ''                    => 1st part of net cmd  */
/*                  Netcmd2:  ''                    => 2nd part of net cmd  */
/*                  Netcmd3:  "| RXQUEUE' netqueue' => 3rd part of net cmd  */
/*                  prog:     associated with program information           */
/*                  serv:     associated with network server name           */
/*                  cmd:      associated with network command               */
/*                                                                          */
/* Variables:       servnam:  Remote LAN server command will be executed on */
/*                  command:  Entire Net Admin \\???? /c Net ???? command   */
/*                  parms:    Parameters for command to be executed         */
/*                  netcmd:   Network command to be run                     */
/*                  netqueue: Name of the queue for "return data"           */
/*                  retbut1:  Name of the "button" user chose               */
/*                  retbut2:  Name of the "button" user chose               */
/*                  retbut3:  Name of the "button" user chose               */
/*                  retflag:  Return from procedure flag (1=Okay,0=NotOkay) */
/*                                                                          */
/****************************************************************************/

/* ======================================================================== */
/* Constant declarations                                                    */
/* ======================================================================== */

/* -------------------------- */
/* Program window information */
/* -------------------------- */
    progtxt.0 = 9
    progtxt.1 = ''
    progtxt.2 = '               OS/2 Command Menu'
    progtxt.3 = '                   version 1.0'
    progtxt.4 = ''
    progtxt.5 = '                   written by'
    progtxt.6 = '                  Rob Crothall'
    progtxt.7 = '           copyright Rob Crothall, 1993'
    progtxt.8 = '     portions copyright IBM Corporation, 1992'
    progtxt.9 = ' '

    prog.title='              OS/2 Command Menu'
    prog.button=1

/* ------------------------- */
/* target window information */
/* ------------------------- */
  Cat. = '';
  K = 0;
  call SysFileTree '*.*','fil','ft';
  do i = 1 to fil.0;
    Parse var fil.i yy'/'mm'/'dd'/'hh'/'min size attr fullname;
    fn = filespec('n',fullname);
    parse var fn nm '.' ext;
    if nm = 'FILES' then iterate;
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
  If Debug = Yes then Say 'Cat.0 =' Cat.0;
  If Debug = Yes then Do K = 1 to Cat.0;
     Say 'Found:' Cat.K;
  end; /* do */

    target.0  = 10;
    target.1  = 'Invalid file';
    target.2  = 'Invalid file';
    target.3  = 'Invalid file';
    target.4  = 'Invalid file';
    target.5  = 'Invalid file';
    target.6  = 'Invalid file';
    target.7  = 'Invalid file';
    target.8  = 'Invalid file';
    target.9  = 'Invalid file';
    target.10 = 'Invalid file';

    serv.title='   Target of command: '
    serv.width=  40
    serv.height= 9
    serv.button= 3

/* -------------------------------------- */
/* Network Command window information     */
/* -------------------------------------- */
    cmd.0 = 6;

    cmd.1 = 'CD  Ä  Change to another Directory'
    cmd.2 = 'Edit  Ä  View (and possibly change) a text file'
    cmd.3 = 'Delete  Ä  Delete an existing file'
    cmd.4 = 'Archive  Ä  Prepare a file for standard archive'
    cmd.5 = 'Print  Ä  Print a file'
    cmd.6 = 'Time  Ä  Displays and Sets Clock'


    cmd.title='                     OS/2 Command to run: '
    cmd.width=  70
    cmd.height= 8
    cmd.button= 3

/* --------------------------------------------- */
/* Network Command verify window information     */
/* --------------------------------------------- */
    srvlist.0=2
    srvlist.1='      Do you wish to return to '
    srvlist.2='      the "File List" window ?'

    srvlist.title=' '
    srvlist.button=6

/* --------------------------------------------- */
/* Network Command verify window information     */
/* --------------------------------------------- */
    cmdstr.0=6
    cmdstr.1='    You have chosen to run the command: '
    cmdstr.2=' '
    cmdstr.3='    On file:  '
    cmdstr.4=' '
    cmdstr.5='         Is this command correct? '
    cmdstr.6=' '

    cmdstr.title=' OS/2 Command '
    cmdstr.button=6

/* -------------------------- */
/* Please wait message window */
/* -------------------------- */
    plswait.0=3
    plswait.1=' This command can take up to three minutes.'
    plswait.2=' '
    plswait.3='             Please be patient.'

    plswait.title=' '
    plswait.button=1

/* -------------------- */
/* Error message window */
/* -------------------- */
    errmsg.0=3
    errmsg.1=' '
    errmsg.2='An error occured'
    errmsg.3=' '

    errmsg.title=' Error Window '
    errmsg.button=1

/* ------------------------- */
/* Cancel window information */
/* ------------------------- */

    cancel.0=2
    cancel.1='      Do you wish to exit'
    cancel.2='      OS/2 Command Menu?'

    cancel.title=' '
    cancel.button=6

/* ------------------------- */
/* Return information window */
/* ------------------------- */

    retinfo.title='Viewing returned information'
    retinfo.width=94
    retinfo.height=13
    retinfo.button=1

/* -------------------- */
/* Network Commands     */
/* -------------------- */
    Netcmd1=''
    Netcmd2=''


/* ======================================================================== */
/* Variable declarations                                                    */
/* ======================================================================== */
    servnam=''
    command=''
    parms=''
    netcmd=''
    retbut1=' '
    maxlines=0
    retflag=0

/* ######################################################################## */
/* Start program                                                            */
/* ######################################################################## */

'@ECHO OFF'                                     /* turn of screen echo */
'CLS'
trace r;
Say 'Use Ctrl-Esc to see the windows...';

If 0 < RxFuncQuery('VInit') then do;
  call RxFuncAdd 'VInit', 'VREXX', 'VINIT'      /* load external functions */
End;

initcode = VInit()                              /* initaialize VREXX program */
if initcode = 'ERROR' then signal ProgramErr    /* if initialize biffed, exit program */

/*signal on failure name ProgramErr  */             /* where to go if 'failure' occurs */
/*signal on halt name ProgramErr     */             /* where to go if 'halt' occurs */
/*signal on syntax name ProgramErr   */             /* where to go if 'syntax' error occurs */

/* create and set the queue for return data from network commands */
    netqueue=RXQUEUE('Create')
    call RXQUEUE 'Set', netqueue

call vdialogpos 50,50                           /* where to put windows */

/* display "Program Info" window */
    call vmsgbox prog.title,progtxt,prog.button

do forever                                      /* run program till user elects to exit */
    /* initialize all variables used */

    servnam=''
    command=''
    parms=''
    netcmd=''
    retbut1=''
    maxlines=0
    retflag=0
    retbut1=''
    retbut2=''
    retbut3=''

    call Gettarget
    do while retflag<>1
        call GetCommand
    end
    /* run the command, placing output into the queue NetQueue */
    command||'|RXQUEUE' netqueue
    call ViewInfo

end                                     /* end the "Do Forever" loop */

/* exit the program */
    call EndProgram

/****************************************************************************/
/* Procedure Information                                                    */
/* Procedure Name:      Gettarget                                           */
/* Procudure Function:  Displays the list of targets and get users choice   */
/* Procedure Notes:     This procedure displays the target List, gets the   */
/*                          users choice, and converts it to the correct    */
/*                          target name.                                    */
/****************************************************************************/
Gettarget:
/* display "File" list window */
    /* initialize "button variables" */
    retbut1=''
    retbut2=''
    retbut3=''

    do until retbut1='OK'
trace r;
        retbut1=vlistbox(serv.title,target,serv.width,serv.height,serv.button)

        if retbut1='CANCEL'
            then do
                    retbut2=vmsgbox(cancel.title,cancel,cancel.button)
                    if retbut2='YES'
                        then call EndProgram
            end /* end do loop */
    end /* end do loop */

/* save the users choice in 'target' */
    targnam=word(target.vstring,1);
pull ans;
trace o;

return

/****************************************************************************/
/* Procedure Information                                                    */
/* Procedure Name:      GetCommand                                          */
/* Procudure Function:  Display the network command list & get users choice.*/
/* Procedure Notes:     This procedure displays the "Network Command" list, */
/*                          and then gets the users choice.                 */
/****************************************************************************/
GetCommand:
/* display "Network Command" list window */
    do until retbut1='OK'
        retbut1=vlistbox(cmd.title,cmd,cmd.width,cmd.height,cmd.button)

        if retbut1='CANCEL'
            then do
                    retbut2=vmsgbox(srvlist.title,srvlist,srvlist.button)
                        if retbut2='YES'
                            then  do
                                retflag=1
                                return
                                end /* end do */
                    retbut2=vmsgbox(cancel.title,cancel,cancel.button)
                        if retbut2='YES'
                            then call EndProgram
            end /* end do loop */
    end /* end do loop */
trace r;
/* create the Network command from users choice */
    NetCmd1 = SubWord(cmd.vstring,1,1);
    Say Netcmd1 targnam;
    command=Netcmd1 targnam;
pull ans;
/* display the "Network Command Verification" window */
    cmdstr.2='              '||SUBWORD(cmd.vstring,1,1)
    cmdstr.4='              '||targnam
    retbut2=vmsgbox(cmdstr.title,cmdstr,cmdstr.button)
    if retbut2='NO'
        then do
                retflag=0
                return
             end
        else
            retflag=1

/* display the "Please Wait" message window */
/*    call vmsgbox plswait.title,plswait,plswait.button */
return

/********************************************************************************/
/* Procedure Information                                                        */
/* Procedure Name:      ViewInfo                                                */
/* Procudure Function:  Displays information returned by the network command.   */
/* Procedure Notes:     This procedure displays in a scrollable window,         */
/*                          the information returned by the network command.    */
/********************************************************************************/
ViewInfo:

    maxlines=queued()                   /* How many lines in the queue */
    retinfo.0=maxlines                  /* put number of lines into the "listbox" structure */

/* get the queued text into the "listbox" structure */
    do linenum=1 to maxlines
        parse pull retinfo.linenum
    end

/* display the "Returned information" window */
    call vlistbox retinfo.title,retinfo,retinfo.width,retinfo.height,retinfo.button

return
/****************************************************************************/
/* Procedure Information                                                    */
/* Procedure Name:      ProgramErr                                          */
/* Procudure Function:  Issue error message and exit program                */
/* Procedure Notes:     This procedure issues an "Error message" in a       */
/*                          window and then closes the VRexx program dll's  */
/*                          and then exits the LANADMN.CMD.                 */
/****************************************************************************/
ProgramErr:
 X = vmsgbox(errmsg.title,errmsg,errmsg.button)  /* display "Error Message" window */
    call EndProgram                             /* call the procedure to end LANADMN.CMD */

/****************************************************************************/
/* Procedure Information                                                    */
/* Procedure Name:      EndProgram                                          */
/* Procudure Function:  Exit the LANADMN.CMD program                        */
/* Procedure Notes:     This procedure closes the VRexx program dll's and   */
/*                          then exits the LANADMN.CMD.                     */
/****************************************************************************/
EndProgram: procedure
    call VExit
    exit
