/** An exec to split the DCMMIS data into dataload format */
/** Author : Elvin Kan (Persetel)                         */
/** Date   : 15 April 1994                                */
/** Changes:                                              */

say 'Start Time : ' TIME()
'ERASE HDRDATA FILE A'
'ERASE ACTIVITY DATA A'
'ERASE HDRDATA SORTFILE A'
'ERASE ACTIVITY SORTFILE A'
COUNT = 1
WLINES = 1
TRACK=1
TRACE O
BLOCK = ''
CodeLine = ''
DO FOREVER
'EXECIO 1 DISKR DCMMIS ASFILE * ' COUNT
IF RC ^= 0 THEN do
    SAY 'END   TIME : ' TIME()
    exit
    end  /* if do */
IF (COUNT/100000) = 1*TRACK THEN DO
             SAY 'DONE ' COUNT
             TRACK = TRACK + 1
           END
COUNT = COUNT + 1
CENTURY=SUBSTR(DATE('S'),1,4)
PULL LINE
  SELECT
    WHEN DATATYPE(SUBSTR(LINE,1,2))='CHAR' THEN DO
          SELECT
           WHEN SUBSTR(LINE,1,2)='SD' THEN DO
                 IF SUBSTR(LINE,5,2)='12' & SUBSTR(DATE('S'),5,2)='01' THEN CENTURY=CENTURY - 1
                 STDATE=CENTURY]]'-']]SUBSTR(LINE,5,2)]]'-']]SUBSTR(LINE,7,2)
/*          STDATE='1995-']]SUBSTR(LINE,5,2)]]'-']]SUBSTR(LINE,7,2)*/
                 LINE = STDATE
                END
           WHEN SUBSTR(LINE,1,2)='ED' THEN DO
                 IF SUBSTR(LINE,5,2)='12' & SUBSTR(DATE('S'),5,2)='01' THEN CENTURY=CENTURY - 1
                 EDDATE=CENTURY]]'-']]SUBSTR(LINE,5,2)]]'-']]SUBSTR(LINE,7,2)
/*        EDDATE='1995-']]SUBSTR(LINE,5,2)]]'-']]SUBSTR(LINE,7,2)*/
                 LINE = EDDATE
                END
           WHEN SUBSTR(LINE,1,2)='ST' THEN DO
                  STTIME=SUBSTR(LINE,5,2)]]'.']]substr(line,7,2)]]'.00'
                  LINE = STTIME
                END
           WHEN SUBSTR(LINE,1,2)='ET' THEN DO
                  EDTIME=SUBSTR(LINE,5,2)]]'.']]substr(line,7,2)]]'.00'
                  LINE = EDTIME
                END
           WHEN SUBSTR(LINE,1,2)='SN' THEN SeqNo =substr(LINE,3,6)
           WHEN SUBSTR(LINE,1,2)='TN' THEN TermNo=substr(LINE,3,6)
          OTHERWISE NOP
          END /* select */
      IF SUBSTR(LINE,1,2)='LR' ] SUBSTR(LINE,1,2)='TR' THEN ITERATE
         ELSE BLOCK=BLOCK LINE
        END  /* when do */
     WHEN DATATYPE(SUBSTR(LINE,1,2)) = 'NUM' THEN
      if block ^= ' ' then do
          'EXECIO 1 DISKW HDRDATA FILE A 0 F 113 (STR ' BLOCK
          BLOCK = ''
          CODELINE = TermNo SeqNo StDate StTime EdDate EdTime,
                    substr(line,1,4) substr(line,5,4)
          'EXECIO 1 DISKW ACTIVITY DATA A 0 F 63 (STR' CODELINE
        end /* if do */
       else do
        CODELINE = TermNo SeqNo StDate StTime EdDate EdTime,
                    substr(line,1,4) substr(line,5,4)
        'EXECIO 1 DISKW ACTIVITY DATA A 0 F 63 (STR' CODELINE
        end /* else do */
END /* select */
END/* do forever */
EXIT
