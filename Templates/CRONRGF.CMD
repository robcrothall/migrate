/*
program: cronrgf.cmd
type:    REXXSAA-OS/2, OS/2 2.0
purpose: Unix-like cron; allow to repeatedly execute commands at given date/time
         defined in a control file
version: 1.0
date:    1992-06-10

author:  Rony G. Flatscher
         RONY@AWIWUW11.BITNET
         rony@wu-wien.ac.at

needs:   DATERGF.CMD, some RxFuncts (loaded automatically)

usage:   CRONRGF [/Test] cronfile

    
    Reads file 'cronfile' and executes command[s] repeatedly according to it.
    'cronfile' has to be formatted like in Unix; unlike the Unix-version a '%' is
    treated like any other character; empty lines and ones starting with
    a semi-colon (;) are ignored.
   
    If switch '/Test' is given, the file is read and the user is presented
    with the date/times and commands to be executed upon them.
   
    example:  CRONRGF /TEST testcron
              execute statements in file 'testcron' in testmode

    example for a control-file:

        ; Sample file for CRONRGF.CMD
        ;
        ; This is a comment (starts with a semicolumn)
        ; empty lines are ignored too...
        
        
        ; LAYOUT OF THE CRON-FILE:
        ;    * * * * * command
        ; or
        ;    minute hour day month weekday command
        ; where minute  ranges from 0-59,
        ;       hour    ranges from 0-23,
        ;       day     ranges from 1-31,
        ;       month   ranges from 1-12,
        ;       weekday ranges from 1-7 (1 = Monday, 2 = Tuesday, ..., 7 = Sunday)
        ;
        ; you can give a list of values, separated by a comma (,), e.g. "1,3,7"
        ; you can give a range of values, separated by a dash (-), e.g. "1-5"
        ; you can give a star (*) instead of a value, meaning entire range of all valid values
        ;
        ; the given command is only executed when all criteriae are fullfilled !
        ;
        ; restriction: unlike to Unix, the percent-sign (%) is treated like any other character
        ;
        
        ; the following command "@ECHO HI, I am Nr. 1 to be echoed every minute" would be
        ; executed every minute
        *  *  *  *  *  @ECHO Hi, I am Nr. 1 to be echoed every minute & pause
        
        59 23 31 12 5 command, one minute before year's end, and only if the last day is a Friday
        
        ; comment: every year at 17:45 on June 7th:
        45 17  7  6  *  dir c:\*.exe
        
        ; comment: on every full quarter of an hour 
        ;          at midnight, 6 in the morning, noon, 6 in the evening
        ;          on the 1st, 15th and 31st of 
        ;          every month on
        ;          weekdays only
        0,15,30,45   0,6,12,18   1,15,31   *   *   backup c:\*.* d:\ /s
        
        ; at noon on every day, if it is a weekday:
        0 12 * * 1-5 XCOPY Q:\* D:\ /s
        
        ; every minute in January, March, May, July, September and November:
        *  *  *  1,3,5,7,9,11  *  dir c:\*.cmd
        
        ; at the last day of the year at 23:01, 23:02, 23:03, 23:05, 23:20, 23:21,
        ; 23:22, 23:23, 23:24, 23:25, 23:30, 23:31, 23:32, 23:33, 23:34, 23:35,
        ; 23:59
        1,2,3,5,20-25,30-35,59   23   31   12   *   COPY D:\*.log E:\backup
        
        ; make backups of OS2.INI and OS2SYS.INI on every first monday of a month,
        ; at 9 o'clock in the morning
        0 9 1-7 * 1 showini /bt d:\os2\os2.ini
        0 9 1-7 * 1 showini /bt d:\os2\os2sys.ini
        
        ; at midnight on every month:
        0 0 1 * * tapebackup /all
        
        ; execute every minute, no restrictions:
        *  *  *  *  *  @ECHO Hi, I am Nr. 2 to be echoed every minute & pause
        
        ; execute every minute in January, February, March only !
        * *  *  1,2,3  *  any-command any-arguments
        
        ; execute every day at midnight
        0 0 * * * any-command any-arguments
        
        ; execute every wednesday at midnigth !
        0 0 * * 3 any-command any-arguments
        
        ; this is a comment which concludes the sample file ===========================

All rights reserved, copyrighted 1992, no guarantee that it works without
errors, etc. etc.

donated to the public domain granted that you are not charging anything (money
etc.) for it and derivates based upon it, as you did not write it,
etc. if that holds you may bundle it with commercial programs too

you may freely distribute this program, granted that no changes are made
to it

Please, if you find an error, post me a message describing it, I will
try to fix and rerelease it to the net.

*/
SIGNAL ON HALT

global. = ""            /* default for global */
global.eTestmode = "0"  /* default: no testmode */

stemSchedule. = ""      /* default for empty array elements */
iSchedule = 0           /* schedule counter */

IF ARG() = 0 THEN SIGNAL usage

PARSE ARG "/"switch filein      /* get filename */

IF switch <> "" THEN
DO
   IF TRANSLATE(SUBSTR(switch, 1, 1)) = "T" THEN global.eTestmode = "1"
   ELSE 
   DO
      SAY "CRONRGF: unknown switch: [/" || switch ||"]."
      SAY
      CALL BEEP 2500, 100
      SIGNAL usage              /* wrong switch */
   END
END
ELSE                            /* no switch given */
   PARSE ARG filein

filein = STRIP(filein)          /* get rid of leading and trailing spaces */
global.eFilein = STREAM(filein, "C", "QUERY EXISTS")

IF global.eFilein = "" THEN
DO
   SAY "CRONRGF: file [" || filein || "] does not exist."
   EXIT
END

/* check whether RxFuncs are loaded, if not, load them */
IF RxFuncQuery('SysLoadFuncs') THEN
DO
    /* load the load-function */
    CALL RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'       

    /* load the Sys* utilities */
    CALL SysLoadFuncs                                                 
END


line_no = 1             /* line-number */
DO WHILE LINES(filein) > 0
   line = LINEIN(filein)

   /* no empty lines and no comments */
   IF line = "" | SUBSTR(STRIP(line), 1, 1) = ";" THEN ITERATE

   SAY "parsing [" || line || "]"

   IF check_it_out(line, line_no) > 0 THEN
   DO
      iSchedule = iSchedule + 1
      global.original.line_no = line
      stemSchedule.iSchedule =  DATE("S") TIME() "NOK" line_no  /* NOK = not o.k., get next date/time */
      line_no = line_no + 1
   END
END
SAY

CALL STREAM filein, "C", "CLOSE"        /* make sure file is closed */

global.0 = iSchedule                    /* set number of array elements */
stemSchedule.0 = iSchedule              /* set number of array elements */

IF iSchedule > 0 THEN
   CALL dispatch                                /* start dispatching */

SAY "CRONRGF: Nothing to schedule. Program ended."

EXIT




/*
        FOREVER-LOOP
*/
DISPATCH: PROCEDURE EXPOSE global. stemSchedule.
   DO FOREVER
     SAY RIGHT("", 79, "=")
     SAY
     SAY "Processing commands given in:"                /* show user which file is being used */
     SAY
     SAY "  [" || global.eFilein || "]"
     SAY

     CALL schedule_next
     /* show user which command(s) will be executed when */
     PARSE VAR stemSchedule.1 1 next_date_time 18       /* get next date/time */

     SAY "command[s] being scheduled on:" next_date_time
     SAY

     DO i = 1 TO stemSchedule.0
        PARSE VAR stemSchedule.i 1 tmp_date_time 18 status index

        IF next_date_time <> tmp_date_time THEN LEAVE
        IF status = "OK" THEN
        DO
           SAY "  [" || VALUE("global." || index || ".eCommand.eValues") || "]"
        END
     END
     SAY

     /* get actual DATE/TIME */
     act_date_time = DATE("S") TIME()
     difference = DATERGF(next_date_time, "-S", act_date_time)

     IF difference > 0 THEN seconds_to_sleep = DATERGF(difference, "SEC") % 1
                       ELSE seconds_to_sleep = 0

      IF global.eTestmode THEN
      DO
         SAY RIGHT("", 79, "=")
         SAY "Testmode (dispatch):    next_invocation =" next_date_time
         SAY "Testmode (dispatch):   actual date/time =" act_date_time
         SAY "Testmode (dispatch): difference in days =" difference "=" seconds_to_sleep "seconds"
         SAY RIGHT("", 79, "=")

         SAY "Testmode (dispatch):"
         SAY "   input:"
         DO i = 1 TO global.0
            SAY "     [" || RIGHT(i, LENGTH(global.0)) ||"]" global.original.i
         END
         SAY RIGHT("", 79, "=")

         SAY "   schedule list:"
         DO i = 1 TO stemSchedule.0
            PARSE VAR stemSchedule.i . . . gIndex 
            SAY "    " stemSchedule.i "[" || VALUE("global." || gIndex || ".eCommand.eValues") || "]"
         END 
         SAY RIGHT("", 79, "=")

         SAY 'Press any key to continue, "q" to quit.'
         CALL BEEP 500, 100
         IF TRANSLATE(SysGetKey("NOECHO")) = "Q" THEN SIGNAL halt
      END
      ELSE
      DO
         /* 
            take care of DosSleep()-unsigned long; to be safe just sleep a maximum 
            of 31 days (= 31 * 24 * 60 * 60  == 2.678.400 seconds) at a time
         */
         thirtyone = 2678400
         DO WHILE seconds_to_sleep > 0
            IF seconds_to_sleep > thirtyone THEN        /* more than 31 days to sleep */
            DO
               sleeping         = thirtyone             /* sleep for 31 days */
               seconds_to_sleep = seconds_to_sleep - thirtyone
            END
            ELSE
            DO
               sleeping         = seconds_to_sleep
               seconds_to_sleep = 0
            END

            CALL SysSleep sleeping                      /* sleep */
         END
   
         DO i = 1 TO stemSchedule.0
           PARSE VAR stemSchedule.i 1 date_time 18 status index
   
           IF date_time > next_date_time THEN
              LEAVE

           IF status = "OK" THEN
           DO
              /* 
                 start an own minimized session which closes automatically after the
                 command was executed:
              */
              commandString = VALUE('global.' || index || '.eCommand.eValues')
              title = '"CRONRGF:' date_time STRIP(commandString) '"'
              ADDRESS CMD "@START" title '/C /WIN /MIN /B "' || commandString || '"'
           END
         END
      END

      /* change the status of the executed programs to "NOK" */
      DO i = 1 TO stemSchedule.0
         PARSE VAR stemSchedule.i 1 date_time 18 status index
 
         IF date_time > next_date_time THEN
            LEAVE

         stemSchedule.i = date_time "NOK" index
      END
   END

   RETURN



/*
    calculate the schedule times, sort them in ascending order
*/
SCHEDULE_NEXT: PROCEDURE EXPOSE global. stemSchedule.
   /* 
      as long as no viable date/time to schedule was found, iterate
   */
   main_run = 0
   DO WHILE WORD(stemSchedule.1, 3) <> "OK"
      main_run = main_run + 1                           /* count loops until a valid day was found for any of the commands */

      IF global.eTestmode THEN
         SAY "Testmode (scheduling): main loop =" main_run

      IF main_run > 50 THEN
      DO
         SAY "CRONRGF: aborting after 2500 attempts to produce a valid date!"
         EXIT -1
      END

      DO i = 1 TO stemSchedule.0
         PARSE VAR stemSchedule.i 1 year 5 month 7 day 9 10 hour 12 13 minute 15 18 disp_status glob_index
   
         IF disp_status = "OK" THEN ITERATE             /* not yed scheduled */
         old_year  = year
         old_month = month
         old_day   = day
         old_hour  = hour
   
         /* defaults */
         first_minute = WORD(global.glob_index.eMinute.eValues, 1)
         first_hour   = WORD(global.glob_index.eHOur.eValues, 1)
         first_day    = WORD(global.glob_index.eDay.eValues, 1)
         first_month  = WORD(global.glob_index.eMonth.eValues, 1)


         /* minute */
         DO j = 1 TO global.glob_index.eMinute.0
            tmp = WORD(global.glob_index.eMinute.eValues, j)
            IF tmp > minute THEN LEAVE
         END
   
         IF j > global.glob_index.eMinute.0 THEN        /* minutes to wrap around */
            hour   = hour + 1
         ELSE                                           /* minutes within same hour */
            minute = tmp
   
         /* hour */
         DO j = 1 TO global.glob_index.eHour.0
            tmp = WORD(global.glob_index.eHour.eValues, j)
            IF tmp >= hour THEN LEAVE
         END
   
         IF j > global.glob_index.eHour.0 THEN          /* hours to wrap around */
            day    = day + 1
         ELSE                                           /* hours within same day */
            hour   = tmp
    
         ok = "NOK"                                     /* default: no date found yet */
         run = 0
         DO 50                                          /* try 50 times to produce a valid date */
            run = run + 1
            /* day */
            DO j = 1 TO global.glob_index.eDay.0
               tmp = WORD(global.glob_index.eDay.eValues, j)
               IF tmp >= day THEN LEAVE
            END
      
            IF j > global.glob_index.eDay.0 THEN        /* days to wrap around */
            DO
               day    = first_day
               month  = month + 1
            END
            ELSE                                        /* days within same month */
               day    = tmp
      
      
            /* month */
            DO j = 1 TO global.glob_index.eMonth.0
               tmp = WORD(global.glob_index.eMonth.eValues, j)
               IF tmp >= month THEN LEAVE
            END
      
            IF j > global.glob_index.eMonth.0 THEN      /* months to wrap around */
            DO
               day    = first_day
               month  = first_month
               year   = year + 1
            END
            ELSE                                        /* months within same year */
            DO
               IF month <> tmp THEN                     /* did the month change ? */
                  day = first_day

               month  = tmp
            END
      

            SELECT
               WHEN old_year < year | old_month < month | old_day < day THEN 
                    next_invocation = year || month || day first_hour || ":" || first_minute || ":00"
               WHEN old_hour < hour THEN
                    next_invocation = year || month || day       hour || ":" || first_minute || ":00"
               OTHERWISE
                    next_invocation = year || month || day       hour || ":" ||       minute || ":00"
            END  

            IF global.eTestmode THEN
               SAY "Testmode (scheduling): next_invocation =" next_invocation DATERGF(next_invocation, "DN")

            /* check whether day-of-week is o.k. */
            IF DATERGF(next_invocation, "M") = "" THEN  /* illegal date produced, e.g. 19950231 ? */
            DO
               day   = first_day
               month = month + 1
               IF month > 12 THEN
               DO
                 month = first_month
                 year  = year + 1
               END
               ITERATE
            END


            next_Weekday = DATERGF(next_invocation, "DI")  /* get weekday */
      
            /* using POS because weekdays are in the form of 01, 02, ..., 07 */
            IF POS(next_Weekday, global.glob_index.eWeekday.eValues) = 0 THEN      /* invalid weekday ? */
            DO
               next_invocation = DATERGF(next_invocation, "+", "1")     /* add one day to present date */
               PARSE VAR next_invocation 1 year 5 month 7 day 9

               ITERATE
            END

            ok = " OK"                                  /* o.k. to invoke, because valid date */
            LEAVE
         END 

         IF global.eTestmode THEN
         DO
            SAY "Testmode (scheduling): date/time-loop =" run "time[s]"
            SAY
         END

   
         /*
            format in schedule list:
            DATE TIME STATUS INDEX-INTO-GLOBAL-ARRAY
         */
         stemSchedule.i = next_invocation ok glob_index
      END
   
      CALL sort_schedule_list
   END

   RETURN

/*
    sort the schedule list in ascending order
*/
SORT_SCHEDULE_LIST: PROCEDURE EXPOSE stemSchedule.
   length = 21          /* length of SUBSTR to compare, includes status */
   /* define M for passes */
   M = 1
   DO WHILE (9 * M + 4) < stemSchedule.0
      M = M * 3 + 1
   END

   /* sort stem */
   DO WHILE M > 0
      K = stemSchedule.0 - M
      DO J = 1 TO K
         Q = J
         DO WHILE Q > 0
            L = Q + M
            IF SUBSTR(stemSchedule.Q, 1, length) <= SUBSTR(stemSchedule.L, 1, length) THEN LEAVE
            /* switch elements */
            tmp            = stemSchedule.Q
            stemSchedule.Q = stemSchedule.L
            stemSchedule.L = tmp
            Q = Q - M
         END
      END
      M = M % 3
   END

   RETURN





/*
   analyze

*/

CHECK_IT_OUT: PROCEDURE EXPOSE global.
 
to_parse = ARG(1)
line_no  = ARG(2)

PARSE VAR to_parse sMinute sHour sDay sMonth sWeekday sCommand

line_no = setup_minutes(sMinute, line_no)       /* setup minute-values */

IF line_no <> 0 THEN                            /* setup hour-values */
   line_no = setup_hours(sHour, line_no)

IF line_no <> 0 THEN                            /* setup day-values */
   line_no = setup_days(sDay, line_no)

IF line_no <> 0 THEN                            /* setup month-values */
   line_no = setup_months(sMonth, line_no)

IF line_no <> 0 THEN                            /* setup weekday-values */
   line_no = setup_weekdays(sWeekday, line_no)

IF line_no <> 0 THEN                            /* setup command-values */
DO
   global.line_no.eCommand.0       = 1
   global.line_no.eCommand.eValues = sCommand
END

RETURN line_no

/*
        parse and setup minutes
        ARG(1) - minute string
        ARG(2) - index into global array
*/
SETUP_MINUTES: PROCEDURE EXPOSE global.
   sMinute = ARG(1)
   iIndex = ARG(2)
   default.0 = 60
   default.values = "00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19",
                    "20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39",
                    "40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59"

   string = parse_it("eMinute", sMinute, iIndex, 0, 59, default.0, default.values)

   IF string <> "" THEN
   DO
      SAY "CRONRGF: error in minute-format [" || string || "]"
      SAY
      RETURN 0
   END

   RETURN iIndex



/*
        parse and setup hours
        ARG(1) - hour string
        ARG(2) - index into global array
*/
SETUP_HOURS: PROCEDURE EXPOSE global.
   sHour = ARG(1)
   iIndex = ARG(2)
   default.0 = 23
   default.values = "00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19",
                    "20 21 22 23"

   string = parse_it("eHour", sHour, iIndex, 0, 23, default.0, default.values)

   IF string <> "" THEN
   DO
      SAY "CRONRGF: error in hour-format [" || string || "]"
      SAY
      RETURN 0
   END

   RETURN iIndex




/*
        parse and setup days
        ARG(1) - day string
        ARG(2) - index into global array
*/
SETUP_DAYS: PROCEDURE EXPOSE global.
   sDay = ARG(1)
   iIndex = ARG(2)
   default.0 = 31
   default.values = "   01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19",
                    "20 21 22 23 24 25 26 27 28 29 30 31"

   string = parse_it("eDay", sDay, iIndex, 1, 31, default.0, default.values)

   IF string <> "" THEN
   DO
      SAY "CRONRGF: error in day-format [" || string || "]"
      SAY
      RETURN 0
   END

   RETURN iIndex




/*
        parse and setup months
        ARG(1) - month string
        ARG(2) - index into global array
*/
SETUP_MONTHS: PROCEDURE EXPOSE global.
   sMonth = ARG(1)
   iIndex = ARG(2)
   default.0 = 12
   default.values = "01 02 03 04 05 06 07 08 09 10 11 12"

   string = parse_it("eMonth", sMonth, iIndex, 1, 12, default.0, default.values)

   IF string <> "" THEN
   DO
      SAY "CRONRGF: error in month-format [" || string || "]"
      SAY
      RETURN 0
   END

   RETURN iIndex




/*
        parse and setup weekdays
        ARG(1) - weekday string
        ARG(2) - index into global array
*/
SETUP_WEEKDAYS: PROCEDURE EXPOSE global.
   sWeekday = ARG(1)
   iIndex = ARG(2)
   default.0 = 7
   default.values = "01 02 03 04 05 06 07"

   string = parse_it("eWeekday", sWeekday, iIndex, 1, 7, default.0, default.values)

   IF string <> "" THEN
   DO
      SAY "CRONRGF: error in weekday-format [" || string || "]"
      SAY
      RETURN 0
   END

   RETURN iIndex







/*
        parse values, list, setup array
        ARG(1) = eName ("element name" in array)
        ARG(2) = string containing numbers
        ARG(3) = index into global array
        ARG(4) = lower bound (inclusive)
        ARG(5) = upper bound (inclusive)
        ARG(6) = default number of elements
        ARG(7) = default values
*/

PARSE_IT: PROCEDURE EXPOSE global.
   eName       = ARG(1)
   sValues        = ARG(2)
   iIndex         = ARG(3)
   lower          = ARG(4)
   upper          = ARG(5)
   default.0      = ARG(6)
   default.values = ARG(7)


   tmp = "global.iIndex." || eName || "."            /* build string of array-e-Name */
   lastValue = 0

   IF sValues = "*" THEN                /* build all legal values */
   DO
      INTERPRET(tmp || "0 =" default.0)
      INTERPRET(tmp || "eValues =" default.values)
      RETURN ""
   END

   INTERPRET(tmp || "0 = 0")                            /* set number of elements to 0 */
   INTERPRET(tmp || 'eValues = ""')                     /* delete values */

   DO WHILE sValues <> ""
      IF POS(",", sValues) > 0 THEN                     /* list of values ? */
        PARSE VAR sValues tmpValue "," sValues
      ELSE
      DO
        tmpValue = sValues                              
        sValues = ""
      END

      IF POS("-", tmpValue) > 0 THEN                    /* range of values ? */
      DO
         PARSE VAR tmpValue start "-" end
      END
      ELSE                                              /* single value */
      DO
         start = tmpValue
         end   = tmpValue
      END



      /* error in values ? */
      IF start < lastValue | start < lower | start > end | ,
         end > upper | ,
         \DATATYPE(start, "N") | \DATATYPE(end, "N") THEN
      DO
         INTERPRET(tmp || '0  = ""')                    /* delete number of array elements */
         INTERPRET(tmp || 'eValues = ""')               /* delete values */
         SELECT
            WHEN \DATATYPE(start, "N") THEN err_msg = '"' || start || '"' "is not numeric" '(part in error: "' || tmpValue || '")' 
            WHEN \DATATYPE(end,   "N") THEN err_msg = '"' || end   || '"' "is not numeric" '(part in error: "' || tmpValue || '")' 
            WHEN start < lastValue     THEN err_msg = start "<" lastValue "= lower bound"  '(part in error: "' || tmpValue || '")'
            WHEN start < lower         THEN err_msg = start "<" lower "= lower bound"      '(part in error: "' || tmpValue || '")'
            WHEN start > end           THEN err_msg = start ">" end                        '(part in error: "' || tmpValue || '")'
            WHEN end   > upper         THEN err_msg = end   ">" upper "= upper bound"      '(part in error: "' || tmpValue || '")'
            OTHERWISE NOP
         END  

         RETURN err_msg
      END
 
      /* build values */
      DO i = start TO end
         INTERPRET(tmp || "0 = " || tmp || "0 + 1")     /* increase counter for number of elements */
         INTERPRET(tmp || "eValues = " || tmp || "eValues" RIGHT(i, 2, "0"))   /* add the next value */
      END

      lastValue = i
   END 

   RETURN ""




USAGE:
   SAY "CRONRGF.CMD - Unix-like cron; executes commands in file repeatedly."
   SAY
   SAY "usage:"
   SAY
   SAY "      CRONRGF [/Test] cronfile"
   SAY 
   SAY "Reads file 'cronfile' and executes command[s] repeatedly according to it."
   SAY "'cronfile' has to be formatted like in Unix; unlike the Unix-version a '%' is"
   SAY "treated like any other character; empty lines and ones starting with"
   SAY "a semi-colon (;) are ignored."
   SAY
   SAY "If switch '/Test' is given, the file is read and the user is presented"
   SAY "with the date/times and commands to be executed upon them."
   SAY
   SAY "example:  CRONRGF /TEST crontest"
   SAY "          execute statements in file 'crontest' in testmode"
   EXIT

HALT:
   CALL STREAM filein, "C", "CLOSE"             /* make sure, file is closed */
   SAY "CRONRGF: User interrupted program."
   EXIT -1
