/*
program: timeit.cmd
type:    REXXSAA-OS/2
purpose: time the duration of a program (command)
usage:   TIMEIT program [arguments]
needs:   DATERGF.CMD, DATE2STR.CMD
version: 1.1
date:    1991-05-20
changed: 1991-08-02: show duration correctly, if timing over a day, use DATERGF(),
                     DATE2STR() ---Rony G. Flatscher

author:  Rony G. Flatscher,
         Wirtschaftsuniversit„t/Vienna
         RONY@AWIWUW11.BITNET
         flatscher@wu-wien.ac.at

All rights reserved, copyrighted 1991, no guarantee that it works without
errors, etc. etc.

donated to the public domain granted that you are not charging anything
(money etc.) for it and derivates based upon it, as you did not write it,
etc. if that holds you may bundle it with commercial programs too

Please, if you find an error, post me a message describing it, I will
try to fix and rerelease it to the net.
*/

IF ARG() = 0 | ARG(1) = '?' THEN SIGNAL usage

global.format_date = "%yyyy-%mm-%dd"            /* format string for dates */

PARSE ARG arguments
SAY '*** TIMEIT:  command:' arguments
SAY '*** TIMEIT: executing command ...'
SAY

Start = date('S') time('L') time('R')   /* get date/time & reset timer */
'@CALL 'arguments                       /* execute whatever came in */
End = date('S') time('L') time('E')     /* get date/time & elapsed time */
SAY
SAY '*** TIMEIT: command ended.'


PARSE VAR Start Starting_DATE Starting_TIME .
PARSE VAR End   Ending_DATE   Ending_TIME   Elapsed_TIME

SAY
SAY '*** TIMEIT:  command:' arguments
SAY '*** TIMEIT:  started:' date2str(Starting_DATE,global.format_date) Starting_TIME
SAY '*** TIMEIT:    ended:' date2str(Ending_DATE,global.format_date) Ending_TIME
SAY

/* show elapsed seconds (= duration) as "[days] hh:mm:ss" */
fraction = DATERGF(Elapsed_TIME, "SECR")  /* get number of days */

IF fraction >= 1 THEN                     /* lasted one or more days */
   tmp = fraction % 1 "day(s) "
ELSE
   tmp = ''

/* get formatted time from decimal time fraction */
tmp = tmp || DATERGF(DATERGF(Elapsed_TIME, "SECR"), "FR")

SAY '*** TIMEIT: duration:' tmp
SAY '*** TIMEIT: end of TIMEIT.'
EXIT

USAGE:
SAY
SAY 'TIMEIT: time the duration of a program (command)'
SAY
SAY 'usage:  TIMEIT program [arguments]'
SAY
EXIT

