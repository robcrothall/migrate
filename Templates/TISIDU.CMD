/*--------------------------------------------------------------------------*/
/*                                                                          */
/*   OS/2 WARP REXX Script for PPP or SLIP dial-up access to the Internet   */
/*   Requires IBM Dial-Up for TCP/IP V2.0 R1.8 or later (*)                 */
/*   Will not work with IBM Dial Other Internet Providers V2.0 R1.2 (**)    */
/*                                                                          */
/*   (*)  R1.8 shipped with OS/2 WARP with WIN-OS2                          */
/*   (**) R1.2 shipped with OS/2 WARP                                       */
/*                                                                          */
/*   WARP users need to download a later version of the dialler using       */
/*   'Retrieve Software Updates' or by anonymous FTP to ftp.ibm.net,        */
/*    directory /pub/PPP                                                    */
/*                                                                          */
/*   WARP with WIN-OS2 users should download the latest version of the      */
/*    dialler                                                               */
/*                                                                          */
/*   Please register your usage of this script so I can send you updates    */
/*   Send an e-mail message to denisl@is.co.za                              */
/*                                                                          */
/*   Written for use with:                                                  */
/*     The Internet Solution                                                */
/*     Rosebank, Johannesburg, South Africa                                 */
/*                                                                          */
/*   Written by Denis Lock, Workplace Solutions                             */
/*   Based on ANNEX.CMD provided with OS/2 Warp by IBM and ideas from       */
/*     the comp.os.os2.networking.tcp-ip newsgroup (and lots of my own).    */
/*                                                                          */
/*   This file must be placed in the ..\TCPIP\BIN directory                 */
/*                                                                          */
/*   USAGE: Invoke by entering:                                             */
/*                                                                          */
/*     tisidu.cmd <dialstring> [<altph1> <altph2>]                          */
/*                                                                          */
/*   on page 1 of the "IBM Dial-Up for TCP"  "Login Sequence:" box          */
/*   Do not enter 'tisidu.cmd' in upper case - use lower case as            */
/*    shown above                                                           */
/*                                                                          */
/*   Where:                                                                 */
/*                                                                          */
/*   <dialstring> is ATDP or ATDT (Pulse or Tone dialling)                  */
/*   If an external line is used then enter ATDP0, or ATDT0,                */
/*                                                                          */
/*   <altph1> and <altph2> are alternate phone numbers to dial.             */
/*   These alternate phone numbers are optional.                            */
/*                                                                          */
/*   For example:                                                           */
/*                                                                          */
/*     tisidu.cmd ATDT 447-5588 447-5599                                    */
/*                                                                          */
/*   Modification history:                                                  */
/*   Version 2.1.01 - 25 June, 1995                                         */
/*     Cater for only one modem initialisation string                       */
/*     Wait for one second after modem initialisation before issuing        */
/*       dial command - some modems need this                               */
/*     Wait for '00' instead of '/' after CONNECT to pick up speed          */
/*   Version 2.1 - 21 June, 1995                                            */
/*     PPP and SLIP versions merged into a single script                    */
/*   Version 2.0 - 10 June, 1995 (limited release)                          */
/*     Reworked error handling - in particular timeouts                     */
/*     Reduced echos to status window                                       */
/*     Includes automatic redial on busy, etc                               */
/*     Includes session logging, see ..\TCPIP\ETC\SESSION.LOG               */
/*      This logs all attempts at connecting to the Internet                */
/*      No code is provided to produce reports from this log - this is      */
/*      left as an excercise for the user.                                  */
/*   15 May, 1995                                                           */
/*     Fixed to work with Revision 1.08h of dialler by removing echo of     */
/*       BUSY, NO CARRIER etc to status window                              */
/*   18 March, 1995                                                         */
/*     Removed need to pass <name> as a parameter                           */
/*     Minor corrections to comments                                        */
/*                                                                          */
/*    Record layout of session log                                          */
/*                                                                          */
/*       1 : S or U (Successful or Unsuccessful)                            */
/*       3 : NAME = Name (as entered on page 1 of dialler)                  */
/*      12 : SLIP or PPP (Protocol for this session)                        */
/*      17 : Phone number (Number dialled)                                  */
/*      30 : Speed (Connection speed eg 14400)                              */
/*      36 : Date (dd mmm yyyy)                                             */
/*      48 : Time (hh:mm:ss)                                                */
/*      57 : If successful - Cumulative time on-line (seconds)**            */
/*      57 : If unsuccessful - Error message                                */
/*                                                                          */
/*      ** This is the time reported by the IBM Dial-Up for TCP/IP          */
/*         program.                                                         */
/*                                                                          */
/*   Internet providers periodically change their connection procedures;    */
/*   please refer to the latest information provided by the service         */
/*   provider.                                                              */
/*                                                                          */
/*   NOTE:                                                                  */
/*   This file is supplied as a sample connection script, and does not      */
/*    constitute the endorsement of a particular Internet provider on       */
/*    the part of IBM or Workplace Solutions.                               */
/*                                                                          */
/*   Send comments and queries to denisl@is.co.za                           */
/*                                                                          */
/*--------------------------------------------------------------------------*/


/*--------------------------------------------------------------------------*/
/*  Parameters which the user may modify are all defined now                */
/*--------------------------------------------------------------------------*/

/* Define modem initialisation strings - modify as necessary for your modem */
/* See the file TCPIP\ETC\MODEM.IAK for suggested values of init1 and init2 */

init1 = 'ATB0E1F1M3Q0V1X4&A3&B1&C1&D2'      /* US Robotics Sportster 14,400 */
init2 = 'AT&H1&I0&K1&M4&N0&R2&S1S0=2S10=200'
/* init1 = 'AT&F&C1&D2S11=55'                  /* Microcom DeskPorte 28.8S     */ */
/* init2 = 'ATX2M3' */

/* You might want to experiment with these times - if they are too short    */
/* you will time out unnecessarily - if they are too long you will wait     */
/* unnecessarily in error situations.  Err on the high side.                */
wfctim  = 60 /* Seconds to wait for connection before timing out            */
wfrtim  = 60 /* Seconds to wait for prompts from host before timing out     */

cyctim  = 15  /* Seconds to wait before redialing                           */
tries   =  5  /* Number of times to dial each number                        */

/*--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------*/
/*                               Initialisation                             */
/*--------------------------------------------------------------------------*/
                                                                              
/* Load the Rexx Utility Functions if they are not already loaded           */
if RxFuncQuery( 'SysLoadFuncs' ) then do                                    
  call RxFuncAdd 'SysLoadFuncs', 'REXXUTIL', 'SysLoadFuncs'                 
  call SysLoadFuncs                                                         
end   
                                                                      
/* Check whether the dialler is configured for PPP or SLIP                  */
  if RxFuncQuery('slip_com_input')=0 then 
    protocol = 'SLIP'
  else if RxFuncQuery('ppp_com_input')=0 then
    protocol = 'PPP'
  else do
    say 'This script can only be invoked by the OS/2 WARP TCP/IP dialler'
    exit
  end   
  sl_prot = LEFT(protocol,4)   /* pad out to 4 char for session  log        */

/* Parse arguments - different for PPP and SLIP                             */
  if protocol = 'PPP' then
     parse arg interface, port, cmd, prefix, phno.2, phno.3, phno.4, phno.5
  else
     parse arg interface, prefix phno.2 phno.3 phno.4 phno.5

/* Define some constants and variables                                      */
cr   = '0d'x                        /* Carriage return                      */
null = '00'x                        /* Null                                 */

sl_phno = left(' ',12)              /* Phone number to go into session log  */
sl_baud = left(' ',5)               /* Connection speed                     */

/* Check for valid prefix                                                   */
valid = 0                                                  
valpre.0 = 4
valpre.1 = "ATDP"
valpre.2 = "ATDT"
valpre.3 = "ATDP0,"
valpre.4 = "ATDT0,"
prefix = translate(prefix)               /* change to uppercase             */
do idx = 1 to valpre.0
  if prefix = valpre.idx then do
    valid = 1                            /* got a valid prefix              */
    leave idx
  end
end
if \valid then do
   say prefix 'is an invalid dial prefix'
   exit 99
end

/* Work out how many phone numbers have been provided                       */
  do idx = 2 to 5
    if phno.idx = '' then do
      phno.0 = idx-1                          /* this is how many           */
      leave idx
    end
  end

/* Get value of ETC environment variable and construct fully qualified name */
/* of the TCPOS2.INI file                                                   */
  etcdir = Value('ETC',,OS2ENVIRONMENT)
  ini_file = etcdir || '\tcpos2.ini'
  session_file = etcdir || '\session.log'

/* Extract CURRENT_CONNECTION from TCPOS2.INI                                */
  app = Strip(SysIni(ini_file, 'CONNECTION', 'CURRENT_CONNECTION'),'T',null)
    if app = 'ERROR:' then do
       say 'Error in looking up CURRENNT_CONNECTION in .INI file'
       exit 99
    end
  log_file = etcdir || app ||'.log'

/* Extract Login-id, password, phone number and total connect time          */
  login_id = Strip(SysIni(ini_file, app, 'LOGIN_ID'),'T',null)
    if login_id = 'ERROR:' then do
       say 'Error in looking up LOGIN_ID in .INI file'
       exit 99
    end
  
  pwd = Strip(SysIni(ini_file, app, 'PWD'),'T',null)
    if pwd = 'ERROR:' then do
       say 'Error in looking up PWD in .INI file'
       exit 99
    end
  
  phno.1 = Strip(SysIni(ini_file, app, 'PHONE_NUMBER'),'T',null)
    if phno.1 = 'ERROR:' then do
       say 'Error in looking up PHONE_NUMBER in .INI file'
       exit 99
    end
  sl_phno = left(phno,12) /* pad out to 12 char for session log             */

  total_connect = Strip(SysIni(ini_file, app, 'TOTAL_CONNECT'),'T',null)
    if total_connect = 'ERROR:' then do
       say 'Error in looking up TOTAL_CONNECT in .INI file'
       exit 99
    end

  sl_app = left(app,8)   /* pad out to eight characters for session log     */
  sl_date = right(date(),11)

/*--------------------------------------------------------------------------*/
/*                              Main Line Code                              */
/*           (Got all the information we need.  Let's get going)            */
/*--------------------------------------------------------------------------*/

say 'Workplace Solutions: IDU script (V2.1) for OS/2 WARP'

/* Flush any stuff left over from previous COM activity                     */
call flush_receive

/* Initialise the modem                                                     */
call modem_init

/* Dial the service provider - don't give up on first try                   */
ctr       = 0                          /* Number of times dialled thus far  */
connected = 0                          /* If true - successful connection   */
failed    = 0                          /* If true - no dial tone or timeout */
maxtries  = tries * phno.0             /* Maximum number of times to dial   */
if phno.0 =1 then
  msg = '- will redial in' cyctim 'seconds'
else
  msg = '- all numbers tried'

do while (\connected) & (\failed) & (ctr < maxtries)
  ctr = ctr + 1
  pho = ((ctr-1)//phno.0)+1         /* Decide which phone number to use     */
  dialcmd = prefix || phno.pho

  say 'Dialing' phno.pho
  sl_phno = LEFT(phno.pho,12)       /* pad out to 12 char for session log   */
  sl_middle = sl_app sl_prot sl_phno sl_baud  sl_date
  call send dialcmd || cr

  /* Wait for connection - wait up to wfctim seconds                        */
  call waitforconn wfctim
  if ctr = maxtries then do                                                   
    msg =''                     /* don't give redial msg after last try     */
    cyctim = 0                  /* also don't sleep                         */
  end                                                                         

  if RC = 1 then connected = 1

  else if RC = 2 then do
    line =  'U' sl_middle time() 'BUSY'
    call write_session_log line                                                 
    if pho=phno.0 then do
      say "'Busy' signal received "msg     
      if  (ctr < maxtries & phno.0 \=1) then do
        say 'Will cycle through numbers again in 'cyctim' seconds'
      end
      call SysSleep cyctim
    end
    else do
      say "'Busy' signal received, will try alternate number"
      call SysSleep 1                       /* Don't redial instantaneously */
    end
  end

  else if RC = 3 then do
    line =  'U' sl_middle time() 'NO CARRIER'
    call write_session_log line                                                 
    if pho=phno.0 then do
      say "'No Carrier' signal received"msg
      if  (ctr < maxtries & phno.0 \=1) then do
        say 'Will cycle through numbers again in 'cyctim' seconds'
      end
      call SysSleep cyctim
    end
    else do
      say "'No Carrier' signal received, will try alternate number"
      call SysSleep 1                       /* Don't redial instantaneously */
    end
  end

  else if RC = 4 then do
    failed =1
    sl_phno = left(' ',12)
    sl_middle = sl_app sl_prot sl_phno sl_baud  sl_date
    line =  'U' sl_middle time() 'NO DIAL TONE'
    call write_session_log line                                                 
    say 'No dial tone - exiting'                                              
  end
                                                                         
  else if RC = numstring+1 then do                                            
    line =  'U' sl_middle time() 'TIMEOUT - CONNECT ('wfctim' secs)'
    call write_session_log line                                                 
    call send '+++'
    call waitfor 'NO CARRIER', 30
    if pho=phno.0 then do
      say 'Timeout occurred'msg
      if  (ctr < maxtries & phno.0 \=1) then do
        say 'Will cycle through numbers again in 'cyctim' seconds'
      end
      call SysSleep cyctim
    end
    else do
      say 'Timeout occurred - will try alternate number' 
      call SysSleep 1                       /* Don't redial instantaneously */
    end
    if  ctr < maxtries then do
    call modem_init /* reinitialise modem after timeout                     */
    end
  end
end  

/* Exit if not connected                                                    */
if \connected then do   
  if failed then exit 99
  else if ctr=maxtries then do
    sl_phno = left(' ',12)
    sl_middle = sl_app sl_prot sl_phno sl_baud  sl_date
    line =  'U' sl_middle time() 'MAX TRIES REACHED'
    call write_session_log line                                                
    say 'Failed to connect after 'maxtries 'tries'                          
    exit 99                                                                  
  end
end

/* Pick up speed at which connected                                         */
call waitfor '00' ,5, 'echo'
if RC = 0 then do
  parse var waitfor_buffer ' ' speed
  sl_baud = right(speed,5)
  sl_middle = sl_app sl_prot sl_phno sl_baud  sl_date
end
else do
  say 'Problem determining connection speed'
  say 'E-mail Denis Lock at denisl@is.co.za'
  exit 99
end

/* Wait for login and password prompts, and then flush anything             */
/* else to take care of trailing spaces, etc..                              */
call waitfor 'ogin:' , , 'echo' ; call flush_receive
if RC = 1 then do
  say 'Timed out waiting for login prompt'
  line =  'U' sl_middle time() 'TIMEOUT - LOGIN PROMPT ('wfrtim' secs)'
  call write_session_log line
  exit 99
end
call send login_id || cr

call waitfor 'assword:' , , 'echo' ; call flush_receive 
if RC = 1 then do
  say 'Timed out waiting for password prompt'
  line =  'U' sl_middle time() 'TIMEOUT - LOGIN PROMPT ('wfrtim' secs)'
  call write_session_log line
  exit 99
end
call send pwd || cr

/* Wait for TIS to return IP addresses */
call waitfor 'Packet mode', wfrtim , 'echo'
if RC = 1 then do
  say ''
  say 'Timed out waiting for' protocol 'to start'
  line =  'U' sl_middle time() 'TIMEOUT -' protocol 'STARTING ('wfrtim' secs)'
  call write_session_log line
  exit 99
end
call waitfor cr, 5 , 'echo'
if RC = 1 then do
  say ''
  say 'Timed out waiting for' protocol 'to start'
  line =  'U' sl_middle time() 'TIMEOUT -' protocol 'STARTING ('wfrtim' secs)'
  call write_session_log line
  exit 99
end

/* If SLIP configure IP addresses                                           */
if protocol = 'SLIP' then do
  parse var waitfor_buffer ' enabled for IP address: ' os2_addr '0d'x
  'ifconfig sl0' os2_addr 196.4.160.5 ' netmask 255.255.255.0'
  'route -fh add default 196.4.160.5 1'
end

/*  All done */
line =  'S' sl_middle time() total_connect
call write_session_log line
exit 0

/*--------------------------------------------------------------------------*/
/*                            send ( sendstring)                            */
/*..........................................................................*/
/*                                                                          */
/* Routine to send a character string off to the modem.                     */
/*                                                                          */
/*--------------------------------------------------------------------------*/

send:

  parse arg sendstring 
  if protocol = 'PPP' then
     call ppp_com_output interface , sendstring
  else
     call slip_com_output interface , sendstring
  return                                                                     

/*--------------------------------------------------------------------------*/
/*               waitfor ( waitstring , [timeout] , [echo] )                */
/*..........................................................................*/
/*                                                                          */
/* Waits for the supplied string to show up in the COM input.  All input    */
/* from the time this function is called until the string shows up in the   */
/* input is accumulated in the "waitfor_buffer" variable.                   */
/*                                                                          */
/* If timeout is specified, it says how long to wait if data stops showing  */
/* up on the COM port (in seconds).                                         */
/*                                                                          */
/* If echo is specified, waitfor_buffer is echoed (added by DNL)            */
/*                                                                          */
/*--------------------------------------------------------------------------*/

waitfor:

   parse arg waitstring , timeout , echo
   if timeout = '' then
     timeout = 60  /* 1 Minute delay if not specified */
   waitfor_buffer = '' ; done = -1; curpos = 1
   ORI_TIME=TIME('E')

   if (remain_buffer = 'REMAIN_BUFFER') then do
      remain_buffer = ''
   end

   do while (done = -1)
     if (remain_buffer \= '') then do
       line = remain_buffer
       remain_buffer = ''
     end
     else do
       if protocol = 'PPP' then
         line = ppp_com_input(interface,,10)
       else
         line = slip_com_input(interface,,10)
     end
     waitfor_buffer = waitfor_buffer || line
     index = pos(waitstring,waitfor_buffer)
     if (index > 0) then do
       remain_buffer = substr(waitfor_buffer,index+length(waitstring))
       waitfor_buffer = delstr(waitfor_buffer,index+length(waitstring))
       done = 0
     end
     if (echo \= '') then do
       call charout , substr(waitfor_buffer,curpos)
     end 
     curpos = length(waitfor_buffer)+1
     if ((done \= 0) & (TIME('E')>timeout)) then do
       done = 1
     end
   end
   timeout=0
   RC=done
 return RC

/*--------------------------------------------------------------------------*/
/*                    waitforconn [timeout]                                 */
/*..........................................................................*/
/*                                                                          */
/* Waits for CONNECT, BUSY, NO CARRIER or NO DIAL TONE to show up           */
/* in the COM input.                                                        */
/* All input from the time this function is called until the string shows   */
/* up in the input is accumulated in the "waitfor_buffer" variable.         */
/*                                                                          */
/* If timeout is specified, it says how long to wait if data stops showing  */
/* up on the COM port (in seconds).                                         */
/*                                                                          */
/* Written by Denis Lock (based on "waitfor" supplied by IBM)               */
/*                                                                          */
/*--------------------------------------------------------------------------*/

waitforconn:

   parse arg timeout

   if timeout = '' then
     timeout = 60 /* 1 Minute delay if not specified */
   waitfor_buffer = '' ; done = -1; curpos = 1
   ORI_TIME=TIME('E')

   numstring = 4
   string.1 = 'CONNECT'
   string.2 = 'BUSY'
   string.3 = 'NO CARRIER'
   string.4 = 'NO DIAL TONE'

   if (remain_buffer = 'REMAIN_BUFFER') then do
      remain_buffer = ''
   end

   do while (done = -1)
     if (remain_buffer \= '') then do
        line = remain_buffer
        remain_buffer = ''
      end
      else do
        if protocol = 'PPP' then
          line = ppp_com_input(interface,,10)
        else
          line = slip_com_input(interface,,10)
      end
      waitfor_buffer = waitfor_buffer || line

  /* Check for one of the predefined strings - CONNECT, BUSY etc             */
      do idx = 1 to numstring
        posstr.idx = pos(string.idx,waitfor_buffer)
        if (posstr.idx > 0) then do
          remain_buffer = substr(waitfor_buffer,posstr.idx+length(string.idx))
          waitfor_buffer = delstr(waitfor_buffer,posstr.idx+length(string.idx))
          done = idx
          leave idx
        end
      end
      if done = 1 then do   /* Only echo 'CONNECT'                          */
         call charout , 'CONNECT'
      end                           
      if ((done = -1) & (TIME('E')>timeout)) then do
        done = numstring+1
      end
   end
   timeout = 0
   RC = done
   return RC
/*--------------------------------------------------------------------------*/
/*                             flush_receive ()                             */
/*..........................................................................*/
/*                                                                          */
/* Routine to flush any pending characters to be read from the COM port.    */
/* Reads everything it can until nothing new shows up for 100ms, at which   */
/* point it returns.                                                        */
/*                                                                          */
/* The optional echo argument, if 1, says to echo flushed information.      */
/*                                                                          */
/*--------------------------------------------------------------------------*/

flush_receive:

   parse arg echo

   /* If echoing the flush - take care of waitfor remaining buffer */
   if (echo \= '') & (length(remain_buffer) > 0) then do
      call charout , remain_buffer
      remain_buffer = ''
   end

   /* Eat anything left in the modem or COM buffers */
   /* Stop when nothing new appears for 100ms.      */

   do until line = ''                                                         
     if protocol = 'PPP' then
       line = ppp_com_input(interface,,100)
     else
       line = slip_com_input(interface,,100)
     if echo \= '' then                                                       
        call charout , line                                                   
   end                                                                        

   return

/*--------------------------------------------------------------------------*/
/*                             modem_init ()                                */
/*..........................................................................*/
/* Routine to initialise modem                                              */
/*..........................................................................*/

modem_init:

   say 'Initialising modem'

   /* Send initialisation string 1                                          */
   call send init1 || cr
   call waitfor 'OK', 5 ; call flush_receive
   if RC = 1 then do
     say 'Modem error - initialisation string 1'
     sl_phno = left(' ',12)
     sl_middle = sl_app sl_prot sl_phno sl_baud  sl_date
     line =  'U' sl_middle time() 'MODEM ERROR STRING 1'
     call write_session_log line                                                
     exit 99
   end

   /* Send initialisation string 2                                          */
   if init2 \= '' then do        /* A few modems don't have a second string */
     call send init2 || cr
     call waitfor 'OK', 5 ; call flush_receive
     if RC = 1 then do
       say 'Modem error - initialisation string 2'
       sl_phno = left(' ',12)
       sl_middle = sl_app sl_prot sl_phno sl_baud  sl_date
       line =  'U' sl_middle time() 'MODEM ERROR STRING 2'
       call write_session_log line                                                
       exit 99
     end
   end
   say 'Modem initialised'
   /* Following required by certain modems                                  */
   call SysSleep 1    /* Don't send another command to modem immediately    */
 
   return

/*--------------------------------------------------------------------------*/
/*                         write_session_log (line)                         */
/*..........................................................................*/
/* Routine to write a record to session log                                 */
/*..........................................................................*/
                                                                              
write_session_log:
                                                                              
   parse arg line                                                             
                                                                              
   call lineout session_file , line
   if RESULT = 1  then do
      beep(262,500)
      say ''
      say 'Error in writing session log - investigate'
   end                                                                        
   return                                                                     

/*--------------------------------------------------------------------------*/
/*                               End of script                              */
/*--------------------------------------------------------------------------*/
