/****************************************************************************/
/* Program Header Information                                               */
/* Copyright:       Wm. Eric Brunsen                                        */
/* Name:            LANADM.CMD                                              */
/* Written By:      Wm. Eric Brunsen                                        */
/* Date:            12/07/92                                                */
/* Platform:        OS/2                                                    */
/* Version:         1.0                                                     */
/* Requires:        OS/2 > 2.0                                              */
/*                  VREXX20 program                                         */
/*                  IBM LAN Server > 1.3                                    */
/* Description:     PM interface for Net Admin commands                     */
/*                      This release does not accept parameters, nor does   */
/*                      it allow the user to do anything other than "view"  */
/*                      data returned by command (no Modification of data   */
/*                      on the server.                                      */
/* Modifications:   11/12/92 WEB Initial Program                            */
/*                                                                          */
/* Input:           None                                                    */
/*                                                                          */
/* Constants:       Netcmd1:  'Net admin \\'        => 1st part of net cmd  */
/*                  Netcmd2:  ' /C Net '            => 2nd part of net cmd  */
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
    progtxt.2 = '               LAN Administrator'
    progtxt.3 = '                   version 1.0'
    progtxt.4 = ''
    progtxt.5 = '                   written by'
    progtxt.6 = '               Wm. Eric Brunsen'
    progtxt.7 = '            Modified by Rob Crothall'
    progtxt.8 = '        copyright Wm. Eric Brunsen, 1992'
    progtxt.9 = '     portions copyright IBM Corporation, 1992'
    progtxt.10= ' '

    prog.title='              LAN Administrator'
    prog.button=1

/* ------------------------- */
/* Server window information */
/* ------------------------- */

    server.0  = 8
    server.1  = 'CSR00 - CSR Database Server 1 '
    server.2  = 'CSR01 - Primary Processor Server '
    server.3  = 'CSR02 - Counter '
    server.4  = 'CSR03 - SCO Unix - Accounts '
    server.5  = 'CSR04 - SB Processor 2 '
    server.6  = 'CSR05 - JFH Processor 3 '
    server.7  = 'CSR06 - GD Processor 4 '
    server.8  = 'CSR07 - RJC Processor 5 '

    serv.title='   Server to run command on: '
    serv.width=  40
    serv.height= 9
    serv.button= 3

/* -------------------------------------- */
/* Network Command window information     */
/* -------------------------------------- */
    cmd.0  = 21

    cmd.1 = 'Access  Ä  Controls Access Profiles'
    cmd.2 = 'Accounts  Ä  Sets the Netlogon Service Role, Password Expiration, and User Time'
    cmd.3 = 'Alias  Ä  Controls Alias Definitions'
    cmd.4 = 'Audit  Ä  Lists and Clears the Contents of Network Audit Trail'
    cmd.5 = 'Comm  Ä  Controls Serial Device Queues'
    cmd.6 = 'Config  Ä  Lists and Changes Configuration Parameters'
    cmd.7 = 'Device  Ä  Lists and Stops Use of Shared Serial Devices'
    cmd.8 = 'Error  Ä  Lists and Clears the Network Error Log'
    cmd.9 = 'File  Ä  Lists and Closes Files That Are Open'
    cmd.10= 'Group  Ä  Displays and Updates Groups'
    cmd.11= 'Name  Ä  Manages Messaging Names'
    cmd.12= 'Print  Ä  Manages Network Spooler Queues'
    cmd.13= 'Session  Ä  Displays and Disconnects User Sessions to a Server'
    cmd.14= 'Share  Ä  Starts and Lists Network Services'
    cmd.15= 'Statistics  Ä  Displays and Clears Workstation Usage Statistics'
    cmd.16= 'Status  Ä  Lists Network Shares and Server Definition Information'
    cmd.17= 'Time  Ä  Displays and Sets Clock'
    cmd.18= 'Use  Ä  Lists, Connects, and Disconnects Shared Resources'
    cmd.19= 'User  Ä  Lists, Adds, Removes, and Modifies User Accounts'
    cmd.20= 'View  Ä  Lists Server Names and Resource Information'
    cmd.21= 'Who  Ä  Lists Information on Users'

/****************************************************************************/
/*          Commands not implemented in the first release                   */
/****************************************************************************/
/*                                                                          */
/*    cmd.3 = 'Admin  Ä  Runs Administrative Commands on a Remote Server'   */
/*    cmd.8 = 'Continue  Ä  Continues Network Programs and Services'        */
/*    cmd.9 = 'Copy  Ä  Copies and Files Locally and Remotely'              */
/*    cmd.13= 'Foward  Ä  Routes Incoming Messages and Cancels Forwarding'  */
/*    cmd.15= 'Help  Ä  Lists Syntax and Use of NET Commands'               */
/*    cmd.16= 'Log  Ä  Starts and Stops Message Logging'                    */
/*    cmd.17= 'Move  Ä  Moves Files Locally and Remotely'                   */
/*    cmd.19= 'Password  Ä  Changes Passwords'                              */
/*    cmd.20= 'Pause  Ä  Syspends Requester and Server Services'            */
/*    cmd.22= 'Run  Ä  Runs a Program or Command on a Remote Server'        */
/*    cmd.23= 'Send  Ä  Sends Messages and Files'                           */
/*    cmd.28= 'Stop  Ä  Stops Network Services'                             */
/****************************************************************************/

    cmd.title='                     Network Command to run: '
    cmd.width=  70
    cmd.height= 8
    cmd.button= 3

/* --------------------------------------------- */
/* Network Command verify window information     */
/* --------------------------------------------- */
    srvlist.0=2
    srvlist.1='      Do you wish to return to '
    srvlist.2='      the "Server List" window ?'

    srvlist.title=' '
    srvlist.button=6

/* --------------------------------------------- */
/* Network Command verify window information     */
/* --------------------------------------------- */
    cmdstr.0=6
    cmdstr.1='    You have chosen to run the command: '
    cmdstr.2=' '
    cmdstr.3='    On server:  '
    cmdstr.4=' '
    cmdstr.5='         Is this command correct? '
    cmdstr.6=' '

    cmdstr.title=' Network Command '
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
    cancel.2='      LAN Administrator?'

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
    Netcmd1='Net admin \\'
    Netcmd2=' /C Net '


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
Say 'Use Ctrl-Esc to see the windows...';
   
call RxFuncAdd 'VInit', 'VREXX', 'VINIT'        /* load external functions */
initcode = VInit()                              /* initaialize VREXX program */
if initcode = 'ERROR' then signal ProgramErr    /* if initialize biffed, exit program */

signal on failure name ProgramErr               /* where to go if 'failure' occurs */
signal on halt name ProgramErr                  /* where to go if 'halt' occurs */
signal on syntax name ProgramErr                /* where to go if 'syntax' error occurs */

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

    call GetServer
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
/* Procedure Name:      GetServer                                           */
/* Procudure Function:  Displays the list of servers and get users choice   */
/* Procedure Notes:     This procedure displays the Server List, gets the   */
/*                          users choice, and converts it to the correct    */
/*                          server name.                                    */
/****************************************************************************/
GetServer:
/* display "Server" list window */
    /* initialize "button variables" */
    retbut1=''
    retbut2=''
    retbut3=''

    do until retbut1='OK'
        retbut1=vlistbox(serv.title,server,serv.width,serv.height,serv.button)

        if retbut1='CANCEL'
            then do
                    retbut2=vmsgbox(cancel.title,cancel,cancel.button)
                    if retbut2='YES'
                        then call EndProgram
            end /* end do loop */
    end /* end do loop */

/* save the users choice in 'server' */
    servnam=word(server.vstring,1);

/* get the servers name from users choice 
    select
        when servnam='Administration 1 '
            then servnam='MS00'
        when servnam='Administration 2 '
            then servnam='MS00'
        when servnam='Campus Union Building '
            then servnam='MS00'
        when servnam='College of Business '
              then servnam='CB00'
        when servnam='Computer Services '
            then servnam='CS00'
        when servnam='Education/Technology '
             then servnam='ED00'
        when servnam='Fine Arts '
             then servnam='MS00'
        when servnam='Liberal Arts '
             then servnam='MS00'
        when servnam='MIS Production '
             then servnam='MS00'
        when servnam='MIS Development '
             then servnam='MD00'
        when servnam='Student Academic Lab '
             then servnam='SL00'
        when servnam='Student Academic Services '
             then servnam='SS00'
    end  end select statement */

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

/* create the Network command from users choice */
    command=Netcmd1||servnam||Netcmd2||SUBWORD(cmd.vstring,1,1)

/* display the "Network Command Verification" window */
    cmdstr.2='              '||SUBWORD(cmd.vstring,1,1)
    cmdstr.4='              '||servnam
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