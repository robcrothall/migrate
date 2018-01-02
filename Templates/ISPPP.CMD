/*--------------------------------------------------------------------------*/
/*                                                                          */
/*     OS/2 WARP REXX Script for PPP dial-up access to the Internet         */
/*     Tested with PPP v2.0 Gamma (as released on December 21, 1994)        */
/*                                                                          */
/*     Customised for use with Proxima Information X-change cc (PiX)        */
/*     PO Box 3036, Northcliff, 2115, South Africa (011) 678-0097           */
/*                                                                          */
/*     Customised by Denis Lock, Workplace Solutions                        */
/*     Based on ANNEX.CMD provided with OS/2 Warp by IBM and ideas from     */
/*     the comp.os.os2.networking.tcp-ip newsgroup (and some of my own).    */
/*                                                                          */
/*     Date of last modification : 7 January 1995                           */
/*     Send comments and queries to denisl@is.co.za                         */
/*                                                                          */
/*     NOTE: This file is supplied as a sample connection script, and       */
/*           does not constitute the endorsement of a particular Internet   */
/*           provider on the part of IBM, ISG or Workplace Solutions.       */
/*                                                                          */
/*     USAGE: Invoke by entering:                                           */
/*                                                                          */
/*          pixppp.cmd                                                      */
/*          <name>                                                          */
/*                                                                          */
/*     on page 1 of the "IBM Dial-Up for TCP"  "Login Sequence:" box.       */
/*     Where <name> is value which was entered in the "Name:" field (the    */
/*     very first field on page 1) of the dialler notebook.  This entry is  */
/*     is case sensitive - enter it exactly the same way in both places.    */
/*     There appears to be a bug in the dialler - don't enter 'pixppp.cmd'  */
/*     in upper case - use lower case as shown above.                       */
/*                                                                          */
/*     Internet providers periodically change their connection procedures;  */
/*     please refer to the latest information provided by the service       */
/*     provider.                                                            */
/*                                                                          */
/*--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------*/
/*                   Initialization and Main Script Code                    */
/*--------------------------------------------------------------------------*/

parse arg interface, comport, cmd, app

/* Define some frequently used strings                                      */
cr   = '0d'x                            /* Carriage return                  */
crlf = '0d0a'x                          /* Carriage return-line feed        */
null = '00'x                            /* Null                             */

/* Make sure there isn't a CRLF at the end of the parameter passed by user  */
poscr = pos(cr,app)                     /* chck if crlf exists              */
if poscr > 0 then do
  app = left(app,pos(cr,app)-1)         /* get rid of it if it exists       */
end

/*--------------------------------------------------------------------------*/
/* Define modem initialisation strings and dial prefix                      */
/* Modify as necessary for your modem and telephone                         */
/*--------------------------------------------------------------------------*/
init1='ATB0E1F1M3Q0V1X4&A3&B1&C1&D2'  /* US Robotics Sportster 14,400       */
init2='AT&H1&I0&K1&M4&N0&R2&S1S0=2'

init1='ATE1';
init2='AT&C1&E1*E1';

prefix='ATDT'                         /* Pulse, no outside line required    */

/* Load the Rexx Utility Functions if they are not already loaded           */
if RxFuncQuery( 'SysLoadFuncs' ) then do
   call RxFuncAdd 'SysLoadFuncs', 'REXXUTIL', 'SysLoadFuncs'
   call SysLoadFuncs 
end

/* Get value of ETC environment variable and construct fully qualified name */
/* of the TCPOS2.INI file                                                   */
etcdir = Value('ETC',,OS2ENVIRONMENT)
ini_file = etcdir || '\tcpos2.ini'      

/* Extract Login-id, password, phone number and provider from TCPOS2.INI    */
phone_number = Strip(SysIni(ini_file, app, 'PHONE_NUMBER'),'T',null)
  if phone_number = 'ERROR:' then do
     say 'Error in looking up PHONE_NUMBER in .INI file'
     exit 1
  end

login_id = Strip(SysIni(ini_file, app, 'LOGIN_ID'),'T',null)
  if login_id = 'ERROR:' then do
     say 'Error in looking up LOGIN_ID in .INI file'
     exit 1
  end

pwd = Strip(SysIni(ini_file, app, 'PWD'),'T',null)
  if pwd = 'ERROR:' then do
     say 'Error in looking up PWD in .INI file'
     exit 1
  end

provider = Strip(SysIni(ini_file, app, 'PROVIDER'),'T',null)
  if provider = 'ERROR:' then do
     say 'Error in looking up PROVIDER in .INI file'
     exit 1
  end

/*--------------------------------------------------------------------------*/
/* Okay, got all the information we need.  Let's get going                  */
/*--------------------------------------------------------------------------*/
say ''
say 'PPP Connection Script - ' provider
say '(Using interface' interface' on 'comport')'

/* Flush any stuff left over from previous COM activity                     */
call flush_receive

/* Initialise the modem                                                     */
say ''                                                    
say 'Initialising modem...'

/* Send initialisation string 1                                             */
call send init1 || cr
call waitfor 'OK', 5 ; call flush_receive 'echo'
 if RC = 1 then do
    say 'Modem error - initialisation string 1 =' init1
    exit 99
 end
/* Send initialisation string 2                                             */
call send init2 || cr
call waitfor 'OK', 5 ; call flush_receive 'echo'
 if RC = 1 then do
    say 'Modem error - initialisation string 2 =' init2
    exit 99
  end

/* Dial the service provider - don't give up on first try                   */

maxtries  = 5                          /* Maximum number of times to redial */
ctr       = 0                          /* Number of times dialled thus far  */
connected = 0                          /* If true - successful connection   */
failed    = 0                          /* If true - no dial tone or timeout */
dialcmd   = prefix || phone_number

do while (\connected) & (\failed) & (ctr < maxtries)
  ctr = ctr + 1

  say 'Now dialing' phone_number
  call send dialcmd || cr

  /* Wait for connection - wait up to 60 seconds                            */
  call waitforconn 60

  if RC = 1 then connected = 1
  else if RC = 2 then do
    say ' - Busy signal received.  Will redial in 15 seconds'
    call SysSleep 15
  end
  else if RC = 3 then do
    say ' - No Carrier signal received.  Will redial in 15 seconds'
    call SysSleep 15
  end
  else if RC = 4 then failed =1  /* NO DIAL TONE */
  else if RC = 5 then failed =1  /* Timed out    */
end  

/* Exit if not connected                                                    */
if \connected then do   
  if failed then do
     say ''
     say 'Failure to connect - exiting'
     exit 99
  end
  else if ctr=maxtries then do
     say ''
     say 'Failure to connect after 'maxtries+1 'tries'
     exit 99
  end
end

/* Wait for login and password prompts, and then flush anything             */
/* else to take care of trailing spaces, etc..                              */
call waitfor 'ogin:' ; call flush_receive     /* 'echo' */
call send login_id || cr
call waitfor 'assword:' ; call flush_receive  /* 'echo' */
call send pwd || cr

/*  All done                                                                */
say ''
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
   call ppp_com_output interface , sendstring

   return


/*--------------------------------------------------------------------------*/
/*                    waitfor ( waitstring , [timeout] )                    */
/*..........................................................................*/
/*                                                                          */
/* Waits for the supplied string to show up in the COM input.  All input    */
/* from the time this function is called until the string shows up in the   */
/* input is accumulated in the "waitfor_buffer" variable.                   */
/*                                                                          */
/* If timeout is specified, it says how long to wait if data stops showing  */
/* up on the COM port (in seconds).                                                         */
/*                                                                          */
/*--------------------------------------------------------------------------*/

waitfor:

   parse arg waitstring , timeout

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
         line = ppp_com_input(interface,,10)
      end
      waitfor_buffer = waitfor_buffer || line
      index = pos(waitstring,waitfor_buffer)
      if (index > 0) then do
         remain_buffer = substr(waitfor_buffer,index+length(waitstring))
         waitfor_buffer = delstr(waitfor_buffer,index+length(waitstring))
         done = 0
      end
      call charout , substr(waitfor_buffer,curpos)
      curpos = length(waitfor_buffer)+1
      if ((done \= 0) & (TIME('E')>timeout)) then do
        call lineout , ' WAITFOR: timed out '
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
        line = ppp_com_input(interface,,10)
      end
      waitfor_buffer = waitfor_buffer || line

/* Check for one of the predefined strings - CONNECT, BUSY etc               */
      do idx = 1 to numstring
        posstr.idx = pos(string.idx,waitfor_buffer)
        if (posstr.idx > 0) then do
          remain_buffer = substr(waitfor_buffer,posstr.idx+length(string.idx))
          waitfor_buffer = delstr(waitfor_buffer,posstr.idx+length(string.idx))
          done = idx
          leave idx
        end
      end
      call charout , substr(waitfor_buffer,curpos)
      curpos = length(waitfor_buffer)+1
      if ((done = -1) & (TIME('E')>timeout)) then do
        call lineout , ' WAITFORCONN: timed out '
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
     line = ppp_com_input(interface,,100)
     if echo \= '' then
        call charout , line
   end

   return

