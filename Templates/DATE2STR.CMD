/*
program: date2str.cmd
type:    REXXSAA-OS/2
purpose: allow formatting of sorted date into string pattern
version: 1.1
date:    1991-05-20
changed: 1992-06-18, removed bundling to ATRGF.CMD etc., RGF
author:  Rony G. Flatscher,
         Wirtschaftsuniversit„t/Vienna
         RONY@AWIWUW11.BITNET
         rony@wu-wien.ac.at

needs:   DATERGF.CMD

usage:   DATE2STR(SDATE, PATTERN[, DELIMITER])
         see enclosed Tutorial "RGFSHOW.CMD" and syntax below

All rights reserved, copyrighted 1991, 1992, no guarantee that it works without
errors, etc. etc.

donated to the public domain granted that you are not charging anything
(money etc.) for it and derivates based upon it, as you did not write it,
etc. if that holds you may bundle it with commercial programs too

Please, if you find an error, post me a message describing it, I will
try to fix and rerelease it to the net.

usage:    DATE2STR(SDATE, PATTERN[, DELIMITER])


syntax:
    SDATE ...... sorted date (YYYYMMDD)
    PATTERN .... string with embedded date-tokens led in by '%'
    DELIMITER .. one character overriding standard delimiter '%'

    date-tokens take the form (results shown for sorted date "19940106"):

    token:  => result:

    %y[y]   => 94       ... two digit year
    %yyy[y] => 1994     ... four digit year

    %m      => 3        ... monthnumber without leading null
    %mm     => 03       ... monthnumber with leading null if one digit
    %mmm    => Jan      ... monthname with three letters (mixed case)
    %MMM    => JAN      ... monthname with three letters (uppercase)
    %mmmm   => January  ... monthname in full (mixed case)
    %MMMM   => JANUARY  ... monthname in full (uppercase)

    %d      => 6        ... daynumber without leading null
    %dd     => 06       ... daynumber with leading null if one digit
    %ddd    => Thu      ... dayname with three letters (mixed case)
    %DDD    => THU      ... dayname with three letters (uppercase)
    %dddd   => Thursday ... dayname in full (mixed case)
    %DDDD   => THURSDAY ... dayname in full (uppercase)

    %w      =>   1      ... week-no. without leading null
    %ww     =>  01      ... week-no. with leading null

    %j      =>   6      ... Julian days without leading nulls
    %jj     =>  06      ... Julian days with one leading null if one digit
    %jjj    => 006      ... Julian days with leading nulls (3 digits width)
*/

IF ARG(1) = '' | ARG(1) = '?' THEN SIGNAL usage

date = ARG(1)
pattern = ARG(2)
IF ARG(3) = '' THEN delimiter = '%'     /* default delimiter */
ELSE
   IF LENGTH(ARG(3)) <> 1 THEN DO
      errmsg = ARG(3)': delimiter must be ONE character only'
      SIGNAL error
   END
   ELSE delimiter = ARG(3)

result_date2str = pattern
pattern2 = TRANSLATE(pattern)
dayname   = datergf(date, "DN") /* get dayname */

IF dayname = '' THEN DO         /* error in sorted date ? */
   errmsg = ARG(1)': illegal date'
   SIGNAL error
END

monthname = datergf(date, "MN") /* get monthname   */
week      = datergf(date, "W")  /* get week        */
julian    = datergf(date, "J")  /* get Julian date */

index = 1
token_nr = 1

/*
    token.x.type    ... type of token
    token.x.start   ... start position of token
    token.x.length  ... length of token
    x = token number in pattern
*/

char_nr = LENGTH(pattern)

DO index = 1 TO char_nr
   letter = SUBSTR(pattern2, index, 1)
   IF letter = delimiter THEN DO
      token.token_nr.start = index              /* start of token with delimiter */
      index = index + 1

      IF index > char_nr THEN LEAVE             /* end of pattern ? */

      letter = SUBSTR(pattern2, index, 1)

      IF letter = delimiter THEN DO             /* successive delimiters */
         index = index - 1                      /* reset index */
         ITERATE
      END
      i2 = 1                                    /* length of symbol */

      SELECT
         WHEN letter = 'Y' THEN                 /* year in hand ? */
              DO
                 DO index = index + 1 TO char_nr
                    IF SUBSTR(pattern2, index, 1) = 'Y' THEN i2 = i2 + 1
                    ELSE LEAVE
                 END

                 IF i2 > 2 THEN token.token_nr.type = 12     /* year: 4 digits */
                 ELSE token.token_nr.type = 11               /* year; 2 digits */
              END

         WHEN letter = 'M' THEN                 /* month in hand ? */
              DO
                 DO index = index + 1 TO char_nr
                    IF SUBSTR(pattern2, index, 1)  = 'M' THEN i2 = i2 + 1
                    ELSE LEAVE
                 END

                 SELECT
                    WHEN i2 = 1 THEN token.token_nr.type = 21  /* digit without leading null */

                    WHEN i2 = 2 THEN token.token_nr.type = 22  /* digit with leading null */

                    WHEN i2 = 3 THEN
                         IF SUBSTR(pattern, token.token_nr.start+1, 1) = 'm' THEN
                            token.token_nr.type = 23           /* three mixed letters     */
                         ELSE
                            token.token_nr.type = 24           /* three uppercase letters */

                    OTHERWISE DO
                         IF SUBSTR(pattern, token.token_nr.start+1, 1) = 'm' THEN
                            token.token_nr.type = 25           /* full name mixed letters     */
                         ELSE
                            token.token_nr.type = 26           /* full name uppercase letters */
                       END
                 END
              END

         WHEN letter = 'D' THEN                    /* day in hand ? */
              DO
                 DO index = index + 1 TO char_nr
                    IF SUBSTR(pattern2, index, 1) = 'D' THEN i2 = i2 + 1
                    ELSE LEAVE
                 END

                 SELECT
                    WHEN i2 = 1 THEN token.token_nr.type = 31  /* digit without leading null */

                    WHEN i2 = 2 THEN token.token_nr.type = 32  /* digit with leading null */

                    WHEN i2 = 3 THEN
                         IF SUBSTR(pattern, token.token_nr.start+1, 1) = 'd' THEN
                            token.token_nr.type = 33           /* three mixed letters     */
                         ELSE
                            token.token_nr.type = 34           /* three uppercase letters */

                    OTHERWISE DO
                         IF SUBSTR(pattern, token.token_nr.start+1, 1) = 'd' THEN
                            token.token_nr.type = 35           /* full name mixed letters     */
                         ELSE
                            token.token_nr.type = 36           /* full name uppercase letters */
                       END
                 END
              END

         WHEN letter = 'J' THEN                    /* Julian day in hand ? */
              DO
                 DO index = index + 1 TO char_nr
                    IF SUBSTR(pattern2, index, 1) = 'J' THEN i2 = i2 + 1
                    ELSE LEAVE
                 END

                 SELECT
                    WHEN i2 = 1 THEN token.token_nr.type = 41  /* digit without leading null   */

                    WHEN i2 = 2 THEN token.token_nr.type = 42  /* digit with leading null      */

                    OTHERWISE token.token_nr.type = 43         /* digit with two leading nulls */
                 END
              END

         WHEN letter = 'W' THEN                    /* week in hand ? */
              DO
                 DO index = index + 1 TO char_nr
                    IF SUBSTR(pattern2, index, 1) = 'W' THEN i2 = i2 + 1
                    ELSE LEAVE
                 END

                 IF i2 = 1 THEN token.token_nr.type = 51   /* digit without leading null   */
                 ELSE token.token_nr.type = 52             /* digit with leading null */
              END

         OTHERWISE NOP
      END
      index = index - 1                 /* reduce index, as it will be incremented on top */
      token.token_nr.length = i2 + 1    /* length of token, including delimiter */
      token_nr = token_nr + 1           /* increase token count */
   END

END

token_nr = token_nr - 1                 /* adjust token count */

IF token_nr > 0 THEN DO                 /* if tokens found overlay them */
    DO i = token_nr TO 1 BY -1
       SELECT
          WHEN token.i.type < 20 THEN   /* year to format */
               IF token.i.type = 11 THEN tmp = SUBSTR(date, 3, 2)  /* two year digits */
               ELSE tmp = SUBSTR(date, 1, 4)                      /* all year digits */

          WHEN token.i.type < 30 THEN   /* month to format */
               SELECT
                  WHEN token.i.type = 21 THEN           /* no leading zeros */
                      tmp = SUBSTR(date, 5, 2) % 1

                  WHEN token.i.type = 22 THEN           /* two digits       */
                      tmp = SUBSTR(date, 5, 2)

                  WHEN token.i.type = 23 | token.i.type = 24 THEN DO
                        tmp = SUBSTR(monthname, 1, 3)  /* first three letters */
                        IF token.i.type = 24 THEN tmp = TRANSLATE(tmp)
                      END

                  OTHERWISE DO                         /* all letters */
                     tmp = monthname
                     IF token.i.type = 26 THEN tmp = TRANSLATE(tmp)
                  END
               END

          WHEN token.i.type < 40 THEN   /* day to format */
               SELECT
                  WHEN token.i.type = 31 THEN           /* no leading zeros */
                      tmp = SUBSTR(date, 7, 2) % 1

                  WHEN token.i.type = 32 THEN           /* two digits       */
                      tmp = SUBSTR(date, 7, 2)

                  WHEN token.i.type = 33 | token.i.type = 34 THEN DO
                        tmp = SUBSTR(dayname, 1, 3)    /* first three letters */
                        IF token.i.type = 34 THEN tmp = TRANSLATE(tmp)
                      END

                  OTHERWISE DO                         /* all letters */
                     tmp = dayname
                     IF token.i.type = 36 THEN tmp = TRANSLATE(tmp)
                  END
               END

          WHEN token.i.type < 50 THEN   /* Julian day to format */
               DO
                  tmp = SUBSTR(Julian, 5, 3)
                  SELECT
                     WHEN token.i.type = 41 THEN   /* no leading zeros */
                        tmp = tmp % 1

                     WHEN token.i.type = 42 THEN DO  /* two digits, leading zero if necessary */
                          tmp = tmp % 1
                          IF tmp < 100 THEN
                             tmp = RIGHT(tmp, 2, '0')
                        END

                     OTHERWISE NOP                /* all three Julian digits */
                  END
               END

          OTHERWISE                     /* week to format */
                IF tmp = 52 THEN tmp = RIGHT(week, 2, '0')
                ELSE tmp = week
       END
       /* prepare string according to received pattern */
       right_part = SUBSTR(result_date2str, (token.i.start + token.i.length))
       result_date2str = SUBSTR(pattern, 1, token.i.start - 1)||tmp||right_part
    END
END


RETURN result_date2str         /* return value */
/* end of main routine */


USAGE:
/* define some colors to demonstrate them */
esc    = '1B'x          /* define ESCape character */
red    = esc||"[31m"    /* ANSI.SYS-control for red foreground */
yellow = esc||"[33m"    /* ANSI.SYS-control for yellow foreground */
cyan   = esc||"[36m"    /* ANSI.SYS-control for cyan foreground */
normal = esc||"[0m"     /* ANSI.SYS-control for resetting attributes to normal */

SAY
SAY cyan'DATE2STR:'normal' format string with date-tokens'
SAY
SAY red'usage:'yellow'    DATE2STR(SDATE, PATTERN[, DELIMITER])'
SAY
SAY red'syntax:'
SAY cyan'    SDATE'normal' ...... sorted date (YYYYMMDD)'
SAY cyan'    PATTERN'normal' .... string with embedded date-tokens led in by "'cyan'%'normal'"'
SAY cyan'    DELIMITER'normal' .. one character overriding standard delimiter "%"'
SAY
SAY '    date-tokens take the form (results shown for sorted date "'cyan'19940106'normal'"):'
SAY
SAY '    token:  => result:'
SAY
SAY cyan'    %y[y]'normal'   => 'cyan'94       'normal'... two digit year'
SAY cyan'    %yyy[y]'normal' => 'cyan'1994     'normal'... four digit year'
SAY
SAY cyan'    %m      'normal'=> 'cyan'3        'normal'... monthnumber without leading null'
SAY cyan'    %mm     'normal'=> 'cyan'03       'normal'... monthnumber with leading null if one digit'
SAY cyan'    %mmm    'normal'=> 'cyan'Jan      'normal'... monthname with three letters (mixed case)'
SAY cyan'    %MMM    'normal'=> 'cyan'JAN      'normal'... monthname with three letters (uppercase)'
SAY cyan'    %mmmm   'normal'=> 'cyan'January  'normal'... monthname in full (mixed case)'
SAY cyan'    %MMMM   'normal'=> 'cyan'JANUARY  'normal'... monthname in full (uppercase)'
SAY
SAY cyan'    %d      'normal'=> 'cyan'6        'normal'... daynumber without leading null'
SAY cyan'    %dd     'normal'=> 'cyan'06       'normal'... daynumber with leading null if one digit'
SAY cyan'    %ddd    'normal'=> 'cyan'Thu      'normal'... dayname with three letters (mixed case)'
SAY cyan'    %DDD    'normal'=> 'cyan'THU      'normal'... dayname with three letters (uppercase)'
SAY cyan'    %dddd   'normal'=> 'cyan'Thursday 'normal'... dayname in full (mixed case)'
SAY cyan'    %DDDD   'normal'=> 'cyan'THURSDAY 'normal'... dayname in full (uppercase)'
SAY
SAY cyan'    %w      'normal'=> 'cyan'  1      'normal'... week-no. without leading null'
SAY cyan'    %ww     'normal'=> 'cyan' 01      'normal'... week-no. with leading null'
SAY
SAY cyan'    %j      'normal'=> 'cyan'  6      'normal'... Julian days without leading nulls'
SAY cyan'    %jj     'normal'=> 'cyan' 06      'normal'... Julian days with one leading null if one digit'
SAY cyan'    %jjj    'normal'=> 'cyan'006      'normal'... Julian days with leading nulls (3 digits width)'
SAY
SAY red'examples:'normal
SAY '    (1) with default escape character being: 'cyan'%'
SAY yellow'        DATE2STR(19940106, "%dddd, %d. %mmmm in the year %yyyy")'normal
SAY '        results in:'
SAY yellow'        "Thursday, 6. January in the year 1994"'normal
SAY
SAY '    (2) with escape character being: 'cyan'!'
SAY yellow'        DATE2STR(19940106, "!DDD, !dd. !MMMM in the year !yy", "!")'normal
SAY '        results in:'
SAY yellow'        "THU, 06. JANUARY in the year 94"'normal

EXIT

ERROR:
/* error message on device "STDERR" */
'@ECHO DATE2STR: 'errmsg' >&2'
EXIT ''

