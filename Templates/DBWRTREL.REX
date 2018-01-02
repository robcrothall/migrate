/* */
Trace 'Off'
Parse arg Arg1      /* Display description of EXEC if 1st argument = ? */
If Arg1=? then do
   Parse source . . Execname .
   Say '                                                                '
   Say Execname ' - Exec written in REXX to do the following:           '
   Say '                                                                '
   Say 'Changes access to a disk from write to multiple read. Message is'
   Say 'sent to all users currently linked to the disk in read mode.    '
   Say '                                                                '
   Say 'Arguments: 1. Machine owning disk (e.g. APPEXT)                 '
   Say '           2. Address of disk on owner machine (e.g. 456)      '
   Say '           3. Address of disk on user  machine (e.g. 456)       '
   Say '           4. Filemode of disk on user machine (e.g. W)         '
   Say '                                                                '
   Say 'Records stacked/ Return Codes/ Error Conditions:                '
   Say '                                                                '
   Say 'Rc=1 If arg1=? - Request for info.                              '
   Say 'Rcª=0 Return code from unsuccessful attempt to link to disk.    '
   Say '                                                                '
   Say 'Written by: CRL  Date: OCT 85                                   '
   Say 'Changed by:      Date:        To:                               '
   Exit 1
   End
Parse upper arg MACHINE ADDR1 ADDR2 MODE
'CP LINK' MACHINE ADDR1 ADDR2 'RR'
If RCª=0 then do
   Say ''
   Say 'Press ENTER to continue:'
   Pull .
   Exit RC
   End
'ACCESS' ADDR2 MODE
'SENTRIES'; RECS1=RC
'EXECIO * CP (LIFO STRING Q LINKS' ADDR2
'SENTRIES'; RECS2=RC
Do RECS2-RECS1
   Parse pull REC
   Do while RECª=''
      Parse var REC USER . . REC
      If USER=Userid() then Iterate
/*    'CP M' USER Userid() 'has released' MACHINE ADDR1 'disk from write mode.' */
      End
   End
Exit
