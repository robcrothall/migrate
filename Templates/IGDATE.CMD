/***************************************************************/
/* EXEC to enhance the current REXX DATE FUNCTIONS.            */
/* This EXEC works the same as the REXX DATE functions         */
/* but it allow you to give additional information also.       */
/* Eg. You can give the specific date you want to work with.   */
/*                                                             */
/*     Format: IGDATE(Option,]Date    ]) --> For all options   */
/*                           ]Jul Date]  --> For all options   */
/*                           ]Days    ]  --> For option Z only */
/*                                                             */
/*             Date     must be in the form YYYYMMDD           */
/*             Jul Date must be in the form YYYYDDD            */
/*             Days     must be in the form of a WHOLE NUMBER  */
/*                                                             */
/* This EXEC is based on the Gregorian calender.               */
/* Author:     H.S. Eloff   (INFOGOLD)                         */
/* Date:       91/09/11                                        */
/* Changed:    91/12/12                                        */
/***************************************************************/
Arg Opt,Date
If Date = " " Then
   Return Date(Opt)

Date = Strip(Date,B,"'")
If Length(Date) = 7 Then           /* If input was Julian date */
   Call NORMDATE

If Opt = B Then Signal BASE
If Opt = C Then Signal CENT
If Opt = D Then Signal DAYS
If Opt = E Then Signal EURO
If Opt = J Then Signal JULIAN
If Opt = M Then Signal MONTH
If Opt = N Then Signal NORMAL
If Opt = O Then Signal ORDERED
If Opt = S Then Signal SORTED
If Opt = U Then Signal USA
If Opt = W Then Signal WEEKDAY
If Opt = Z Then Signal ZDATE
Say "INVALID OPTION - ("Opt") with DATE paremeter"
Return 8


BASE:
    /***********************************************************/
    /*            Convert a DATE to BASEDATE format            */
    /***********************************************************/
    Call VALID
    Call GETBASE
    Return Totdays


CENT:
    /***********************************************************/
    /*            Convert a DATE to CENTURY format             */
    /***********************************************************/
    Call VALID
    Call GETBASE
    Bdays = Totdays
    Date  = 19000101
    Call VALID
    Call GETBASE
    Cendays = Bdays - Totdays + 1
    Return Cendays


DAYS:
    /***********************************************************/
    /*            Convert a DATE to DAYS format                */
    /***********************************************************/
    Call VALID
    Call CALJUL
    Return Julday


EURO:
    /***********************************************************/
    /*            Convert a DATE to EUROPEAN format            */
    /***********************************************************/
    Call VALID
    Return Days"/"Month"/"YY


JULIAN:
    /***********************************************************/
    /*            Convert a DATE to JULIAN format              */
    /***********************************************************/
    Call VALID
    Call CALJUL
    Return Juldate


MONTH:
    /***********************************************************/
    /*            Convert a DATE to MONTH format               */
    /***********************************************************/
    Call VALID
    Call GETMONTH
    Return Substr(Mthnames,(Month*10)+1,10)


NORMAL:
    /***********************************************************/
    /*            Convert a DATE to NORMAL format              */
    /***********************************************************/
    Call VALID
    Call GETMONTH
    Return Days Substr(Substr(Mthnames,(Month*10)+1,10),1,3) Year


ORDERED:
    /***********************************************************/
    /*            Convert a DATE to ORDERED format             */
    /***********************************************************/
    Call VALID
    Return YY"/"Month"/"Days


SORTED:
    /***********************************************************/
    /*            Convert a DATE to SORTED format              */
    /***********************************************************/
    Call VALID
    Return Year]]Month]]Days


USA:
    /***********************************************************/
    /*            Convert a DATE to USA format                 */
    /***********************************************************/
    Call VALID
    Return Month"/"Days"/"YY


WEEKDAY:
    /***********************************************************/
    /*            Convert a DATE to WEEKDAY format             */
    /***********************************************************/
    Call VALID
    Call GETBASE
    Weekdays = "Monday    ",
             ]]"Thuesday  ",
             ]]"Wednesday ",
             ]]"Thursday  ",
             ]]"Friday    ",
             ]]"Saturday  ",
             ]]"Sunday    "
    Return Substr(Weekdays,((Totdays // 7)*10)+1,10)


ZDATE:
    /***********************************************************/
    /*            Work out the DATE if the DAYS are given.     */
    /***********************************************************/
    Days = Strip(Date)
    If Datatype(Days,W) ^= 1,
     ] Length(Days) > 8 Then Do
       Say 'INVALID DAYS -' Days
       Exit 8
    End

    Year   = Days % 365.2425
    If Days // 365.2425 >= 365 Then Year = Year + 1

    Leaps   = (Year % 4) -(Year % 100) + (Year % 400)
    Fuldays = (Year * 365) + Leaps
    Julday  = Days - Fuldays + 1          /* From 0001-01-01  */
    Year    = Year + 1

    Call CALDAYS

    Tstmth = 0
    Month  = 1

    Do I = 4 to 37 by 3
       Tstmth = Tstmth + Substr(Mthday,I,2)
       If Julday <= Tstmth Then Leave
       Month = Month + 1
    End

    Tstmth = Tstmth - Substr(Mthday,I,2)
    Day    = Julday - Tstmth

    Year  = Right(Year,4,'0')
    Month = Right(Month,2,'0')
    Day   = Right(Day,2,'0')
    Return Year]]Month]]Day


/***************************************************************/
/*                   COMON ROUTINES                            */
/***************************************************************/


NORMDATE:
    /*---------------------------------------------------------*/
    /* ROUTINE to CONVERT a JULIAN DATE to a NORMAL DATE       */
    /*---------------------------------------------------------*/
    Year   = Substr(Date,1,4)
    Julday = Substr(Date,5,3)
    Call CALDAYS
    If Leap   = 'n',
    &  Julday > 365 Then Do
       Say 'INVALID JULIAN DAYS'
       Exit 8
    End

    Month   = 0
    Fuldays = 0

    Do I = 4 To Length(Mthday) By 3
       Month = Month + 1
       Tstdays = Substr(Mthday,I,2)
       If Fuldays + Tstdays >= Julday Then Leave
       Fuldays = Fuldays + Tstdays
    End

    Day   = Julday - Fuldays
    Day   = Right(Day,2,0)
    Month = Right(Month,2,0)
    Date  = Year]]Month]]Day
    Return


GETBASE:
    /*---------------------------------------------------------*/
    /* Routine to convert a DATE to BASEDATE format            */
    /*---------------------------------------------------------*/
    Leaps   = (Year % 4) - (Year % 100) + (Year % 400)
    If Leap = 'y' Then Leaps = Leaps - 1
    Call CALJUL
    Totdays = ((Year-1) * 365) + Leaps + Julday - 1
    Return


VALID:
    /*---------------------------------------------------------*/
    /* ROUTINE to VALIDATE the DATE parameter.                 */
    /*---------------------------------------------------------*/
    Date  = Strip(Date)
    Year  = Substr(Date,1,4)
    YY    = Substr(Date,3,2)
    Month = Substr(Date,5,2)
    Days  = Substr(Date,7,2)

    If Datatype(Date,W) ^= 1,
     ] Length(Date) ^= 8,
     ] Year  < 1 ,
     ] Month > 12,
     ] Days  < 1  Then Do
       Say "INVALID DATE -" Date
       Exit 8
    End

    Call CALDAYS

    If Days > Substr(Mthday,(Month*3)+1,2) Then Do
       Say 'INVALID DAYS FOR DATE -' Year'-'Month'-'Days
       Exit 8
    End
    Return


CALDAYS:
    /*---------------------------------------------------------*/
    /* ROUTINE to CALCULATE the number of DAYS PER MONTH.      */
    /*---------------------------------------------------------*/
    Leap = 'n'
    If Year // 4    = 0 Then Leap = 'y'
    If Year // 100  = 0 Then Leap = 'n'
    If Year // 400  = 0 Then Leap = 'y'

    Feb = 28
    If Leap = 'y' Then Feb = 29

    Mthday  = '00 31 ']]Feb]]' 31 30 31 30 31 31 30 31 30 31'
    Return


CALJUL:
    /*---------------------------------------------------------*/
    /* ROUTINE to CALCULATE the JULIAN DATE.                   */
    /*---------------------------------------------------------*/
    Julday = Days
    Do I = 1 to (Month * 3)  by 3
       Julday = Julday + Substr(Mthday,I,2)
    End
    Juldate = YY]]Julday
    Return


GETMONTH:
    /*---------------------------------------------------------*/
    /* ROUTINE to GET the name of the MONTH.                   */
    /*---------------------------------------------------------*/
    Mthnames = "          ",
             ]]"January   ",
             ]]"February  ",
             ]]"March     ",
             ]]"April     ",
             ]]"May       ",
             ]]"June      ",
             ]]"July      ",
             ]]"August    ",
             ]]"September ",
             ]]"October   ",
             ]]"November  ",
             ]]"December  "
    Return
