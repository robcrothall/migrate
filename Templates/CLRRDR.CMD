/***********************************************************************/
/*  This EXEC will scan all the reader files in the system and         */
/*  purge all PROFS files older than 21 days and all VM PRINT  files   */
/*  older than 07 days.....                                            */
/*                                                                     */
/***********************************************************************/

    'execload IGDATE EXEC *'

GETRDR:
    /*******************************************************/
    /*  Get all RDR files in PROGRAM STACK                 */
    /*******************************************************/
    "EXECIO * CP (BUF 1200000 STRING QUERY RDR ALL"

    Cbdate = Date(B)
    Cyyyy  = Substr(Date(S),1,4)
    Cmm    = Substr(Date(S),5,2)

    pull Head
    Totcnt = queued()
    Do Cnt = 1 to Totcnt
       Pull Line
       Ownerid  = Substr(Line,1,8)
       File     = Substr(Line,10,4)
       Type     = Substr(Line,64,8)
       Fmm      = Substr(Line,39,2)
       Fdd      = Substr(Line,42,2)
       If Fmm   > Cmm Then
          Cyyyy = Cyyyy - 1
       Fdate    = Cyyyy]]Fmm]]Fdd
       Fbdate   = IGdate(B,Fdate)         /* Get BASEDATE for file */
       Fage     = Cbdate - Fbdate
       If Fage  < 8  then iterate         /* Any file    < 8  Days */
       If Type  = "INFOGOLD" ,
       &  Fage  < 22 then iterate         /* PROFS files < 21 Days */
       "EXECIO 0 CP (STRING PURGE" Ownerid "RDR" File
    End

   "DESBUF"


QUIT:
   Say " "
   Say "End of Program"
   Exit
